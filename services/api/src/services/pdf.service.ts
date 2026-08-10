import PDFDocument from 'pdfkit';
import crypto from 'crypto';

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
   * Generates a modern, elegant landscape certificate PDF and computes its SHA-256 hash.
   */
  public static async generateCertificate(options: CertificatePdfOptions): Promise<GeneratedCertificate> {
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

        // Background base
        doc.rect(0, 0, width, height).fill('#0B0F19');

        // Decorative borders / gradients
        doc.lineWidth(3);
        doc.rect(20, 20, width - 40, height - 40).stroke('#2563EB');
        doc.lineWidth(1);
        doc.rect(26, 26, width - 52, height - 52).stroke('#475569');

        // Header / Organization Name
        doc
          .font('Helvetica-Bold')
          .fontSize(16)
          .fillColor('#94A3B8')
          .text(options.organizationName.toUpperCase(), 0, 55, {
            align: 'center',
            characterSpacing: 3,
          });

        // Main Title
        doc
          .font('Helvetica-Bold')
          .fontSize(34)
          .fillColor('#FFFFFF')
          .text(options.title, 0, 95, {
            align: 'center',
          });

        // Subheading
        doc
          .font('Helvetica')
          .fontSize(13)
          .fillColor('#64748B')
          .text('THIS IS TO CERTIFY THAT', 0, 155, {
            align: 'center',
            characterSpacing: 2,
          });

        // Recipient Name
        doc
          .font('Helvetica-Bold')
          .fontSize(28)
          .fillColor('#38BDF8')
          .text(options.recipientName, 0, 185, {
            align: 'center',
          });

        // Description
        doc
          .font('Helvetica')
          .fontSize(12)
          .fillColor('#CBD5E1')
          .text(options.description, 90, 235, {
            align: 'center',
            width: width - 180,
            lineGap: 4,
          });

        // Issue Date & Expiry
        const metaY = 320;
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
            .text('EXPIRY DATE', 220, metaY)
            .font('Helvetica-Bold')
            .fillColor('#F8FAFC')
            .text(options.expiryDate, 220, metaY + 14);
        }

        // Certificate ID & Proofly branding
        doc
          .font('Helvetica')
          .fontSize(10)
          .fillColor('#64748B')
          .text('CERTIFICATE ID', width - 260, metaY)
          .font('Helvetica-Bold')
          .fillColor('#F8FAFC')
          .text(options.certificateNumber, width - 260, metaY + 14);

        // Verification Footer
        const footerY = height - 60;
        doc
          .font('Helvetica')
          .fontSize(9)
          .fillColor('#64748B')
          .text(`Anchored on Polygon Amoy Blockchain • Verify authenticity at: ${options.verifyUrl}`, 0, footerY, {
            align: 'center',
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
