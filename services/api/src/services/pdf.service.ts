import PDFDocument from 'pdfkit';
import crypto from 'crypto';
import QRCode from 'qrcode';

export interface CertificatePdfOptions {
  certificateNumber: string;
  recipientName: string;
  title: string;
  description: string;
  organizationName: string;
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
   * Generates a modern, elegant landscape certificate PDF with an embedded dynamic QR Code
   * and computes its deterministic SHA-256 document hash.
   */
  public static async generateCertificate(options: CertificatePdfOptions): Promise<GeneratedCertificate> {
    // Generate QR Code PNG buffer encoding the dynamic verification URL
    const qrBuffer = await QRCode.toBuffer(options.verifyUrl, {
      type: 'png',
      margin: 1,
      width: 250,
      color: {
        dark: '#090D16',
        light: '#FFFFFF',
      },
      errorCorrectionLevel: 'M',
    });

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

        // Background Base (Dark Luxury Theme)
        doc.rect(0, 0, width, height).fill('#0B0F19');

        // Decorative Dual Outer Borders
        doc.lineWidth(3);
        doc.rect(20, 20, width - 40, height - 40).stroke('#2563EB');
        doc.lineWidth(1);
        doc.rect(26, 26, width - 52, height - 52).stroke('#475569');

        // Corner Accents
        const cornerSize = 25;
        doc.lineWidth(2);
        // Top-Left
        doc.moveTo(26, 26 + cornerSize).lineTo(26, 26).lineTo(26 + cornerSize, 26).stroke('#38BDF8');
        // Top-Right
        doc.moveTo(width - 26 - cornerSize, 26).lineTo(width - 26, 26).lineTo(width - 26, 26 + cornerSize).stroke('#38BDF8');
        // Bottom-Left
        doc.moveTo(26, height - 26 - cornerSize).lineTo(26, height - 26).lineTo(26 + cornerSize, height - 26).stroke('#38BDF8');
        // Bottom-Right
        doc.moveTo(width - 26 - cornerSize, height - 26).lineTo(width - 26, height - 26).lineTo(width - 26, height - 26 - cornerSize).stroke('#38BDF8');

        // Header / Organization Name
        doc
          .font('Helvetica-Bold')
          .fontSize(16)
          .fillColor('#94A3B8')
          .text(options.organizationName.toUpperCase(), 0, 50, {
            align: 'center',
            characterSpacing: 4,
          });

        // Main Award Title
        doc
          .font('Helvetica-Bold')
          .fontSize(32)
          .fillColor('#FFFFFF')
          .text(options.title, 0, 85, {
            align: 'center',
          });

        // Subheading
        doc
          .font('Helvetica')
          .fontSize(12)
          .fillColor('#64748B')
          .text('THIS IS TO CERTIFY THAT', 0, 140, {
            align: 'center',
            characterSpacing: 2,
          });

        // Recipient Name
        doc
          .font('Helvetica-Bold')
          .fontSize(28)
          .fillColor('#38BDF8')
          .text(options.recipientName, 0, 168, {
            align: 'center',
          });

        // Description
        doc
          .font('Helvetica')
          .fontSize(12)
          .fillColor('#CBD5E1')
          .text(options.description, 90, 215, {
            align: 'center',
            width: width - 180,
            lineGap: 4,
          });

        // ==========================================
        // Metadata & Dynamic QR Code Section
        // ==========================================
        const metaY = 310;

        // Issue Date
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('ISSUE DATE', 90, metaY)
          .font('Helvetica-Bold')
          .fillColor('#F8FAFC')
          .text(options.issueDate, 90, metaY + 14);

        if (options.expiryDate) {
          doc
            .font('Helvetica')
            .fontSize(10)
            .fillColor('#64748B')
            .text('EXPIRY DATE', 90, metaY + 40)
            .font('Helvetica-Bold')
            .fillColor('#F8FAFC')
            .text(options.expiryDate, 90, metaY + 54);
        }

        // Certificate ID
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('CERTIFICATE ID', 240, metaY)
          .font('Helvetica-Bold')
          .fillColor('#F8FAFC')
          .text(options.certificateNumber, 240, metaY + 14);

        // Blockchain Network Tag
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('TRUST PROOF', 240, metaY + 40)
          .font('Helvetica-Bold')
          .fillColor('#34D399')
          .text('POLYGON AMOY (CHAIN 80002)', 240, metaY + 54);

        // QR Code Box (Right-aligned)
        const qrBoxSize = 95;
        const qrBoxX = width - 90 - qrBoxSize;
        const qrBoxY = metaY - 5;

        // White background card for crisp QR scanning
        doc.rect(qrBoxX, qrBoxY, qrBoxSize, qrBoxSize).fillAndStroke('#FFFFFF', '#38BDF8');

        // Embed QR Code
        doc.image(qrBuffer, qrBoxX + 4, qrBoxY + 4, {
          width: qrBoxSize - 8,
          height: qrBoxSize - 8,
          link: options.verifyUrl,
        });

        // QR Code Label
        doc
          .font('Helvetica-Bold')
          .fontSize(8)
          .fillColor('#38BDF8')
          .text('SCAN TO VERIFY PROOF', qrBoxX - 20, qrBoxY + qrBoxSize + 6, {
            width: qrBoxSize + 40,
            align: 'center',
          });

        // Verification Footer & Clickable Link
        const footerY = height - 50;
        doc
          .font('Helvetica')
          .fontSize(9)
          .fillColor('#64748B')
          .text(`Anchored on Polygon Amoy Blockchain • Live verification link: `, 0, footerY, {
            align: 'center',
            continued: true,
          })
          .fillColor('#38BDF8')
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
