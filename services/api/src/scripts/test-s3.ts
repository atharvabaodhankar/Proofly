import { storageService } from '../services/storage.service';
import { env } from '../config/env';

async function testS3() {
  console.log('==============================================');
  console.log('Testing AWS S3 Connection for Proofly');
  console.log('==============================================');
  console.log(`Storage Provider: ${env.STORAGE_PROVIDER}`);
  console.log(`AWS Region:       ${env.AWS_REGION}`);
  console.log(`Bucket Name:      ${env.AWS_S3_BUCKET}`);

  try {
    const testContent = Buffer.from('Proofly S3 Test Payload - ' + new Date().toISOString());
    const testKey = `test/s3-connection-test-${Date.now()}.txt`;

    console.log(`\nUploading test object to key: "${testKey}"...`);
    const { key, url } = await storageService.uploadFile(testContent, testKey, 'text/plain');
    console.log(` Upload successful! Key: ${key}`);
    console.log(` Presigned URL generated: ${url}`);

    console.log('\nReading back object from S3...');
    const readBuffer = await storageService.getFile(testKey);
    console.log(` Read back content: "${readBuffer.toString('utf8')}"`);

    console.log('\nDeleting test object from S3...');
    await storageService.deleteFile(testKey);
    console.log(' Test object cleaned up successfully.');

    console.log('\n==============================================');
    console.log(' AWS S3 IS FULLY WORKING AND CONFIGURED!');
    console.log('==============================================');
  } catch (error: any) {
    console.error('\n❌ AWS S3 test failed:', error.message);
  }
}

testS3();
