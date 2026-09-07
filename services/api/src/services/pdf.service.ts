import PDFDocument from 'pdfkit';
import crypto from 'crypto';
import QRCode from 'qrcode';
import path from 'path';
import fs from 'fs';

export interface CertificatePdfOptions {
  certificateNumber: string;
  recipientName: string;
  title: string;
  description: string;
  organizationName: string;
  organizationLogoBuffer?: Buffer | null;
  issueDate: string;
  expiryDate?: string | null;
  verifyUrl: string;
}

export interface GeneratedCertificate {
  pdfBuffer: Buffer;
  documentHash: string; // 0x-prefixed 32-byte SHA-256 hash
}

export class PdfService {
  /**
   * Generates a prestigious, light-themed landscape certificate PDF with an embedded dynamic QR Code,
   * official Proofly Trust Seal, perfectly centered classical typography, and deterministic SHA-256 document hash.
   */
  public static async generateCertificate(options: CertificatePdfOptions): Promise<GeneratedCertificate> {
    // Generate QR Code PNG buffer encoding the dynamic verification URL
    const qrBuffer = await QRCode.toBuffer(options.verifyUrl, {
      type: 'png',
      margin: 1,
      width: 320,
      color: {
        dark: '#0F172A',
        light: '#FFFFFF',
      },
      errorCorrectionLevel: 'H',
    });

    // Try reading Proofly brand logo
    let prooflyLogoBuffer: Buffer | null = null;
    try {
      const logoPath = path.resolve(__dirname, '../../public/logo.png');
      if (fs.existsSync(logoPath)) {
        prooflyLogoBuffer = fs.readFileSync(logoPath);
      }
    } catch (_) {}

    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          layout: 'landscape',
          size: 'A4', // 841.89 x 595.28 points
          margin: 0,
        });

        const buffers: Buffer[] = [];
        doc.on('data', (chunk) => buffers.push(chunk));
        doc.on('end', () => {
          const pdfBuffer = Buffer.concat(buffers);
          const sha256Hex = crypto.createHash('sha256').update(pdfBuffer).digest('hex');
          const documentHash = `0x${sha256Hex}`;

          resolve({
            pdfBuffer,
            documentHash,
          });
        });
        doc.on('error', (err) => reject(err));

        const width = doc.page.width;
        const height = doc.page.height;

        // 1. Prestigious Ivory Background
        doc.rect(0, 0, width, height).fill('#FCFCFD');

        // Subtle background guilloche / watermark texture
        doc.save();
        doc.circle(width / 2, height / 2, 280).lineWidth(0.3).strokeColor('#F1F5F9').stroke();
        doc.circle(width / 2, height / 2, 210).lineWidth(0.3).strokeColor('#F1F5F9').stroke();
        doc.circle(width / 2, height / 2, 140).lineWidth(0.3).strokeColor('#F1F5F9').stroke();
        doc.restore();

        // 2. Triple Decorative Borders (Navy + Rich Gold + Slate Hairline)
        doc.lineWidth(4).strokeColor('#0F172A').rect(18, 18, width - 36, height - 36).stroke();
        doc.lineWidth(1.5).strokeColor('#C59B27').rect(26, 26, width - 52, height - 52).stroke();
        doc.lineWidth(0.5).strokeColor('#E2E8F0').rect(30, 30, width - 60, height - 60).stroke();

        // 3. Ornate Gold Corner Brackets with Corner Diamond Florets
        const cornerLen = 32;
        doc.lineWidth(2.5).strokeColor('#C59B27');
        // Top-Left
        doc.moveTo(26, 26 + cornerLen).lineTo(26, 26).lineTo(26 + cornerLen, 26).stroke();
        // Top-Right
        doc.moveTo(width - 26 - cornerLen, 26).lineTo(width - 26, 26).lineTo(width - 26, 26 + cornerLen).stroke();
        // Bottom-Left
        doc.moveTo(26, height - 26 - cornerLen).lineTo(26, height - 26).lineTo(26 + cornerLen, height - 26).stroke();
        // Bottom-Right
        doc.moveTo(width - 26 - cornerLen, height - 26).lineTo(width - 26, height - 26).lineTo(width - 26, height - 26 - cornerLen).stroke();

        // 4. Header: Proofly Protocol Watermark Badge (Top Right)
        if (prooflyLogoBuffer) {
          try {
            doc.image(prooflyLogoBuffer, width - 82, 38, { width: 36, height: 36 });
          } catch (_) {}
        }

        // 5. Issuing Organization Header & Logo
        let currentY = 46;
        if (options.organizationLogoBuffer) {
          try {
            const logoW = 44;
            const logoH = 44;
            doc.image(options.organizationLogoBuffer, (width - logoW) / 2, currentY, {
              fit: [logoW, logoH],
              align: 'center',
              valign: 'center',
            });
            currentY += 50;
          } catch (_) {}
        }

        // Organization Name (Classic Spaced Gold Header)
        doc
          .font('Helvetica-Bold')
          .fontSize(13)
          .fillColor('#B48C36')
          .text(options.organizationName.toUpperCase(), 0, currentY, {
            align: 'center',
            characterSpacing: 3.5,
          });

        currentY += 28;

        // "CERTIFICATE OF RECOGNITION" Title
        doc
          .font('Helvetica-Bold')
          .fontSize(24)
          .fillColor('#0F172A')
          .text('CERTIFICATE OF RECOGNITION', 0, currentY, {
            align: 'center',
            characterSpacing: 1.5,
          });

        currentY += 34;

        // Decorative Center Gold Divider with Diamond
        const divCenterX = width / 2;
        doc.lineWidth(1).strokeColor('#C59B27');
        doc.moveTo(divCenterX - 100, currentY).lineTo(divCenterX - 14, currentY).stroke();
        doc.moveTo(divCenterX + 14, currentY).lineTo(divCenterX + 100, currentY).stroke();
        // Center diamond floret
        doc.polygon(
          [divCenterX, currentY - 4.5],
          [divCenterX + 5.5, currentY],
          [divCenterX, currentY + 4.5],
          [divCenterX - 5.5, currentY]
        ).fillColor('#C59B27').fill();

        currentY += 20;

        // Presentation Line
        doc
          .font('Helvetica')
          .fontSize(10.5)
          .fillColor('#64748B')
          .text('THIS IS PROUDLY PRESENTED TO', 0, currentY, {
            align: 'center',
            characterSpacing: 2,
          });

        currentY += 24;

        // 6. Huge, Distinguished Recipient Name (36pt)
        doc
          .font('Helvetica-Bold')
          .fontSize(36)
          .fillColor('#1E1B4B')
          .text(options.recipientName, 0, currentY, {
            align: 'center',
          });

        currentY += 48;

        // Elegant Recipient underline accent
        const nameUnderlineWidth = Math.min(Math.max(options.recipientName.length * 20, 240), 520);
        doc
          .lineWidth(1.2)
          .strokeColor('#CBD5E1')
          .moveTo((width - nameUnderlineWidth) / 2, currentY - 4)
          .lineTo((width + nameUnderlineWidth) / 2, currentY - 4)
          .stroke();

        // 7. For Demonstrating Excellence in...
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('FOR SUCCESSFULLY DEMONSTRATING EXCELLENCE & COMPLETING', 0, currentY + 4, {
            align: 'center',
            characterSpacing: 1.2,
          });

        currentY += 26;

        // Certificate Subject / Degree Title (Bold Royal Navy, 22pt)
        doc
          .font('Helvetica-Bold')
          .fontSize(22)
          .fillColor('#1D4ED8')
          .text(options.title, 0, currentY, {
            align: 'center',
          });

        currentY += 34;

        // Citation / Description (Generously spaced & centered)
        if (options.description) {
          doc
            .font('Helvetica')
            .fontSize(11)
            .fillColor('#334155')
            .text(options.description, 100, currentY, {
              align: 'center',
              width: width - 200,
              lineGap: 4,
            });
        }

        // 8. Bottom Information Section & Embedded Verification QR Card
        const metaSectionY = 420;

        // --- LEFT COLUMN: Issue Date, Certificate ID, Blockchain Trust ---
        doc
          .font('Helvetica-Bold')
          .fontSize(8.5)
          .fillColor('#64748B')
          .text('ISSUE DATE', 90, metaSectionY)
          .font('Helvetica-Bold')
          .fontSize(12)
          .fillColor('#0F172A')
          .text(options.issueDate, 90, metaSectionY + 12);

        if (options.expiryDate) {
          doc
            .font('Helvetica-Bold')
            .fontSize(8.5)
            .fillColor('#64748B')
            .text('EXPIRY DATE', 90, metaSectionY + 34)
            .font('Helvetica-Bold')
            .fontSize(12)
            .fillColor('#0F172A')
            .text(options.expiryDate, 90, metaSectionY + 46);
        }

        doc
          .font('Helvetica-Bold')
          .fontSize(8.5)
          .fillColor('#64748B')
          .text('CERTIFICATE ID', 240, metaSectionY)
          .font('Helvetica-Bold')
          .fontSize(12)
          .fillColor('#0F172A')
          .text(options.certificateNumber, 240, metaSectionY + 12);

        // Blockchain Network Indicator
        doc
          .font('Helvetica-Bold')
          .fontSize(8.5)
          .fillColor('#64748B')
          .text('BLOCKCHAIN TRUST ANCHOR', 240, metaSectionY + 34)
          .font('Helvetica-Bold')
          .fontSize(10.5)
          .fillColor('#059669')
          .text('POLYGON AMOY (CHAIN ID: 80002) [ON-CHAIN]', 240, metaSectionY + 46);

        // --- RIGHT COLUMN: Embedded Dynamic QR Card ---
        const qrSize = 90;
        const qrCardX = width - 90 - qrSize;
        const qrCardY = metaSectionY - 8;

        // Card frame with gold accent & white fill
        doc
          .lineWidth(1)
          .rect(qrCardX - 6, qrCardY - 6, qrSize + 12, qrSize + 12)
          .fillAndStroke('#FFFFFF', '#C59B27');

        // QR Code Image
        doc.image(qrBuffer, qrCardX, qrCardY, {
          width: qrSize,
          height: qrSize,
          link: options.verifyUrl,
        });

        // QR Code Subtitle
        doc
          .font('Helvetica-Bold')
          .fontSize(7.5)
          .fillColor('#0F172A')
          .text('SCAN TO VERIFY LIVE', qrCardX - 25, qrCardY + qrSize + 10, {
            width: qrSize + 50,
            align: 'center',
          });

        // 9. CLEAN TWO-LINE FOOTER (Zero Merging / Zero Overlap)
        // Line 1: Trust Protocol & Smart Contract
        doc
          .font('Helvetica')
          .fontSize(8)
          .fillColor('#64748B')
          .text(
            'Verified by Proofly Protocol • Decentralized Trust Registry • Smart Contract: 0xfb960EB42729f84C48040eBe264b11473d926006',
            0,
            height - 48,
            { align: 'center', width }
          );

        // Line 2: Dedicated Verification Link
        doc
          .font('Helvetica-Bold')
          .fontSize(8.5)
          .fillColor('#0284C7')
          .text(
            `Direct Blockchain Verification: ${options.verifyUrl}`,
            0,
            height - 34,
            { align: 'center', width, link: options.verifyUrl, underline: true }
          );

        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  /**
   * Helper to compute SHA-256 hash of any arbitrary Buffer or string.
   */
  public static computeHash(data: Buffer | string): string {
    const sha256Hex = crypto.createHash('sha256').update(data).digest('hex');
    return `0x${sha256Hex}`;
  }
}
