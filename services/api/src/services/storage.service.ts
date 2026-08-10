import fs from 'fs';
import path from 'path';
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { env } from '../config/env';

export interface IStorageService {
  uploadFile(buffer: Buffer, key: string, contentType: string): Promise<{ key: string; url: string }>;
  getDownloadUrl(key: string, expiresInSeconds?: number): Promise<string>;
  deleteFile(key: string): Promise<void>;
  getFile(key: string): Promise<Buffer>;
}

/**
 * Local file system storage implementation for development and testing without AWS
 */
export class LocalStorageService implements IStorageService {
  private baseDir: string;

  constructor() {
    this.baseDir = path.resolve(process.cwd(), 'storage_uploads');
    if (!fs.existsSync(this.baseDir)) {
      fs.mkdirSync(this.baseDir, { recursive: true });
    }
  }

  async uploadFile(buffer: Buffer, key: string, contentType: string): Promise<{ key: string; url: string }> {
    const filePath = path.join(this.baseDir, key);
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    fs.writeFileSync(filePath, buffer);
    const url = `${env.API_BASE_URL}/storage/${key}`;
    return { key, url };
  }

  async getDownloadUrl(key: string, _expiresInSeconds = 3600): Promise<string> {
    return `${env.API_BASE_URL}/storage/${key}`;
  }

  async deleteFile(key: string): Promise<void> {
    const filePath = path.join(this.baseDir, key);
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  }

  async getFile(key: string): Promise<Buffer> {
    const filePath = path.join(this.baseDir, key);
    if (!fs.existsSync(filePath)) {
      throw new Error(`File not found: ${key}`);
    }
    return fs.readFileSync(filePath);
  }
}

/**
 * AWS S3 Storage implementation for production & cloud storage
 */
export class S3StorageService implements IStorageService {
  private s3Client: S3Client;
  private bucket: string;

  constructor() {
    this.bucket = env.AWS_S3_BUCKET;
    this.s3Client = new S3Client({
      region: env.AWS_REGION,
      credentials: {
        accessKeyId: env.AWS_ACCESS_KEY_ID || '',
        secretAccessKey: env.AWS_SECRET_ACCESS_KEY || '',
      },
    });
  }

  async uploadFile(buffer: Buffer, key: string, contentType: string): Promise<{ key: string; url: string }> {
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    });

    await this.s3Client.send(command);
    const downloadUrl = await this.getDownloadUrl(key, 3600 * 24); // 24 hour URL
    return { key, url: downloadUrl };
  }

  async getDownloadUrl(key: string, expiresInSeconds = 3600): Promise<string> {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    return await getSignedUrl(this.s3Client, command, { expiresIn: expiresInSeconds });
  }

  async deleteFile(key: string): Promise<void> {
    const command = new DeleteObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    await this.s3Client.send(command);
  }

  async getFile(key: string): Promise<Buffer> {
    const command = new GetObjectCommand({
      Bucket: this.bucket,
      Key: key,
    });

    const response = await this.s3Client.send(command);
    const stream = response.Body as any;
    const chunks: any[] = [];
    for await (const chunk of stream) {
      chunks.push(chunk);
    }
    return Buffer.concat(chunks);
  }
}

// Automatically choose S3 if configured, or default to Local storage
export const storageService: IStorageService =
  env.STORAGE_PROVIDER === 's3' && env.AWS_ACCESS_KEY_ID && env.AWS_SECRET_ACCESS_KEY
    ? new S3StorageService()
    : new LocalStorageService();
