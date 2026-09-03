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
  documentHash: string; // 0x-prefixed 32-byte (64 hex chars) SHA-256 hash
}

export class PdfService {
  /**
   * Generates a prestigious, light-themed landscape certificate PDF with an embedded dynamic QR Code,
   * official Proofly Trust Seal, and computes its deterministic SHA-256 document hash.
   */
  public static async generateCertificate(options: CertificatePdfOptions): Promise<GeneratedCertificate> {
    // Generate QR Code PNG buffer encoding the dynamic verification URL (Dark navy on white)
    const qrBuffer = await QRCode.toBuffer(options.verifyUrl, {
      type: 'png',
      margin: 1,
      width: 300,
      color: {
        dark: '#1E1B4B',
        light: '#FFFFFF',
      },
      errorCorrectionLevel: 'M',
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
          size: 'A4',
          margin: 0,
        });

        const buffers: Buffer[] = [];
        doc.on('data', (chunk) => buffers.push(chunk));
        doc.on('end', () => {
          const pdfBuffer = Buffer.concat(buffers);
          // Compute SHA-256 hash
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

        // 1. Background Base (Clean Ivory White)
        doc.rect(0, 0, width, height).fill('#FCFCFD');

        // 2. Decorative Dual Outer Borders (Deep Navy & Rich Gold)
        doc.lineWidth(4);
        doc.rect(18, 18, width - 36, height - 36).stroke('#1E1B4B');
        
        doc.lineWidth(1.5);
        doc.rect(26, 26, width - 52, height - 52).stroke('#D4AF37');

        doc.lineWidth(0.5);
        doc.rect(30, 30, width - 60, height - 60).stroke('#CBD5E1');

        // 3. Gold Corner Ornamental Accents
        const cornerSize = 28;
        doc.lineWidth(2.5);
        // Top-Left
        doc.moveTo(26, 26 + cornerSize).lineTo(26, 26).lineTo(26 + cornerSize, 26).stroke('#D4AF37');
        // Top-Right
        doc.moveTo(width - 26 - cornerSize, 26).lineTo(width - 26, 26).lineTo(width - 26, 26 + cornerSize).stroke('#D4AF37');
        // Bottom-Left
        doc.moveTo(26, height - 26 - cornerSize).lineTo(26, height - 26).lineTo(26 + cornerSize, height - 26).stroke('#D4AF37');
        // Bottom-Right
        doc.moveTo(width - 26 - cornerSize, height - 26).lineTo(width - 26, height - 26).lineTo(width - 26, height - 26 - cornerSize).stroke('#D4AF37');

        // 4. Header: Proofly Protocol Watermark / Brand Badge (Top-Right)
        if (prooflyLogoBuffer) {
          try {
            doc.image(prooflyLogoBuffer, width - 78, 38, { width: 32, height: 32 });
          } catch (_) {}
        }

        // Header: Organization Logo (if uploaded) & Name
        let orgY = 46;
        if (options.organizationLogoBuffer) {
          try {
            const logoWidth = 44;
            const logoHeight = 44;
            doc.image(options.organizationLogoBuffer, (width - logoWidth) / 2, 38, {
              fit: [logoWidth, logoHeight],
              align: 'center',
              valign: 'center',
            });
            orgY = 88;
          } catch (logoErr) {
            console.warn('Could not render logo in PDF:', logoErr);
          }
        }

        doc
          .font('Helvetica-Bold')
          .fontSize(14)
          .fillColor('#D4AF37')
          .text(options.organizationName.toUpperCase(), 0, orgY, {
            align: 'center',
            characterSpacing: 3,
          });

        const titleY = options.organizationLogoBuffer ? 112 : 82;

        // 5. Main Certificate Title
        doc
          .font('Helvetica-Bold')
          .fontSize(28)
          .fillColor('#1E1B4B')
          .text(options.title, 0, titleY, {
            align: 'center',
          });

        // 6. Subheading
        const subY = titleY + 44;
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('THIS IS PROUDLY PRESENTED TO', 0, subY, {
            align: 'center',
            characterSpacing: 2,
          });

        // 7. Recipient Name
        const nameY = subY + 22;
        doc
          .font('Helvetica-Bold')
          .fontSize(26)
          .fillColor('#2563EB')
          .text(options.recipientName, 0, nameY, {
            align: 'center',
          });

        // 8. Description / Citation
        const descY = nameY + 36;
        doc
          .font('Helvetica')
          .fontSize(11)
          .fillColor('#334155')
          .text(options.description, 90, descY, {
            align: 'center',
            width: width - 180,
            lineGap: 3,
          });

        // 9. Metadata & Dynamic Scannable QR Code Section
        const metaY = 315;

        // Issue Date Column
        doc
          .font('Helvetica-Bold')
          .fontSize(9)
          .fillColor('#64748B')
          .text('ISSUE DATE', 90, metaY)
          .font('Helvetica-Bold')
          .fontSize(12)
          .fillColor('#1E1B4B')
          .text(options.issueDate, 90, metaY + 14);

        if (options.expiryDate) {
          doc
            .font('Helvetica-Bold')
            .fontSize(9)
            .fillColor('#64748B')
            .text('EXPIRY DATE', 90, metaY + 38)
            .font('Helvetica-Bold')
            .fontSize(12)
            .fillColor('#1E1B4B')
            .text(options.expiryDate, 90, metaY + 52);
        }

        // Certificate ID Column
        doc
          .font('Helvetica-Bold')
          .fontSize(9)
          .fillColor('#64748B')
          .text('CERTIFICATE ID', 250, metaY)
          .font('Helvetica-Bold')
          .fontSize(12)
          .fillColor('#1E1B4B')
          .text(options.certificateNumber, 250, metaY + 14);

        // Blockchain Network Pill
        doc
          .font('Helvetica-Bold')
          .fontSize(9)
          .fillColor('#64748B')
          .text('BLOCKCHAIN TRUST PROOF', 250, metaY + 38)
          .font('Helvetica-Bold')
          .fontSize(11)
          .fillColor('#059669')
          .text('POLYGON AMOY (CHAIN 80002) ✓', 250, metaY + 52);

        // 10. Embedded QR Code Card (Right side)
        const qrBoxSize = 96;
        const qrBoxX = width - 90 - qrBoxSize;
        const qrBoxY = metaY - 10;

        // White card with golden border
        doc.rect(qrBoxX - 4, qrBoxY - 4, qrBoxSize + 8, qrBoxSize + 8).fillAndStroke('#FFFFFF', '#D4AF37');

        // Draw the QR Code image
        doc.image(qrBuffer, qrBoxX, qrBoxY, {
          width: qrBoxSize,
          height: qrBoxSize,
          link: options.verifyUrl,
        });

        // Bold QR Code Action Label
        doc
          .font('Helvetica-Bold')
          .fontSize(8)
          .fillColor('#1E1B4B')
          .text('SCAN TO VERIFY PROOF', qrBoxX - 25, qrBoxY + qrBoxSize + 8, {
            width: qrBoxSize + 50,
            align: 'center',
          });

        // 11. Verification Footer & Interactive Link
        const footerY = height - 48;
        doc
          .font('Helvetica')
          .fontSize(9)
          .fillColor('#64748B')
          .text('Verified by Proofly Protocol • Permanent Polygon Amoy Anchor • Live link: ', 0, footerY, {
            align: 'center',
            continued: true,
          })
          .fillColor('#2563EB')
          .text(options.verifyUrl, {
            link: options.verifyUrl,
            underline: true,
          });

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
