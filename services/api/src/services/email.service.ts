import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';
import { env } from '../config/env';
import { storageService } from './storage.service';

export interface SendClaimInvitationOptions {
  toEmail: string;
  recipientName: string;
  certificateTitle: string;
  organizationName: string;
  certificateNumber: string;
  claimUrl: string;
  organizationLogoUrl?: string | null;
}

export class EmailService {
  private sesClient: SESClient | null = null;

  constructor() {
    if (env.AWS_ACCESS_KEY_ID && env.AWS_SECRET_ACCESS_KEY) {
      this.sesClient = new SESClient({
        region: env.AWS_REGION || 'ap-south-1',
        credentials: {
          accessKeyId: env.AWS_ACCESS_KEY_ID,
          secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
        },
      });
    }
  }

  /**
   * Dispatches a prestigious, light-themed HTML email via AWS SES inviting the recipient to claim their certificate,
   * using a live signed S3 URL for the Proofly logo.
   */
  public async sendClaimInvitation(options: SendClaimInvitationOptions): Promise<{ success: boolean; messageId?: string; error?: string }> {
    if (!this.sesClient) {
      console.warn('⚠️ AWS SES not configured (missing credentials). Claim link:', options.claimUrl);
      return { success: false, error: 'AWS SES not configured' };
    }

    const claimToken = options.claimUrl.split('/claim/').pop() || '';

    // Generate authenticated signed S3 URL for the Proofly brand logo (valid for 7 days)
    let s3LogoUrl = 'https://proofly-certificates.s3.ap-south-1.amazonaws.com/brand/proofly_logo.png';
    try {
      s3LogoUrl = await storageService.getDownloadUrl('brand/proofly_logo.png', 7 * 86400);
    } catch (_) {}

    const htmlBody = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Claim Your Certificate</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #F8FAFC;
            color: #0F172A;
            margin: 0;
            padding: 32px 16px;
            -webkit-font-smoothing: antialiased;
          }
          .container {
            max-width: 580px;
            margin: 0 auto;
            background-color: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 24px;
            padding: 40px 32px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.05);
          }
          .header {
            text-align: center;
            margin-bottom: 28px;
          }
          .logo-img {
            width: 56px;
            height: 56px;
            display: block;
            margin: 0 auto 10px;
            border-radius: 12px;
          }
          .brand-name {
            font-size: 22px;
            font-weight: 800;
            color: #0F172A;
            letter-spacing: -0.5px;
          }
          .badge {
            display: inline-block;
            background-color: #ECFDF5;
            color: #059669;
            border: 1px solid #A7F3D0;
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.5px;
            margin-top: 10px;
          }
          .main-heading {
            font-size: 22px;
            font-weight: 700;
            color: #0F172A;
            text-align: center;
            margin: 0 0 10px;
            line-height: 1.3;
          }
          .intro-text {
            font-size: 15px;
            color: #475569;
            line-height: 1.6;
            text-align: center;
            margin: 0 0 28px;
          }
          .cert-card {
            background-color: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 18px;
            padding: 24px;
            margin-bottom: 30px;
          }
          .cert-org {
            font-size: 11px;
            font-weight: 700;
            color: #64748B;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            margin-bottom: 6px;
          }
          .cert-title {
            font-size: 20px;
            font-weight: 800;
            color: #1E1B4B;
            margin: 0 0 18px;
            line-height: 1.3;
          }
          .grid-row {
            display: table;
            width: 100%;
            margin-bottom: 10px;
          }
          .grid-cell-label {
            display: table-cell;
            width: 40%;
            font-size: 13px;
            color: #64748B;
            font-weight: 500;
            padding: 4px 0;
          }
          .grid-cell-value {
            display: table-cell;
            width: 60%;
            font-size: 13px;
            color: #0F172A;
            font-weight: 600;
            text-align: right;
            padding: 4px 0;
          }
          .mono {
            font-family: 'JetBrains Mono', Consolas, Monaco, monospace;
          }
          .btn-container {
            text-align: center;
            margin: 32px 0 24px;
          }
          .btn {
            background: linear-gradient(135deg, #0284C7 0%, #2563EB 100%);
            color: #FFFFFF !important;
            text-decoration: none;
            padding: 16px 36px;
            border-radius: 14px;
            font-size: 16px;
            font-weight: 700;
            display: inline-block;
            box-shadow: 0 6px 20px rgba(2, 132, 199, 0.35);
          }
          .token-box {
            background-color: #F1F5F9;
            border-radius: 12px;
            padding: 14px;
            text-align: center;
            margin-bottom: 28px;
          }
          .token-label {
            font-size: 11px;
            font-weight: 700;
            color: #64748B;
            text-transform: uppercase;
            margin-bottom: 4px;
          }
          .token-val {
            font-size: 13px;
            font-weight: 700;
            color: #0284C7;
            word-break: break-all;
          }
          .footer {
            text-align: center;
            font-size: 12px;
            color: #94A3B8;
            padding-top: 24px;
            border-top: 1px solid #E2E8F0;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <!-- Real Proofly Logo from S3 -->
            <img src="${s3LogoUrl}" alt="Proofly Logo" class="logo-img" />
            <div class="brand-name">Proofly</div>
            <div><span class="badge">✓ ON-CHAIN VERIFIED CREDENTIAL</span></div>
          </div>
          
          <h1 class="main-heading">${options.organizationName} has issued your certificate!</h1>
          <p class="intro-text">
            Hello <strong>${options.recipientName}</strong>,<br>
            You have received an official, tamper-evident digital credential anchored permanently on the <strong>Polygon Amoy blockchain</strong>.
          </p>

          <div class="cert-card">
            <div class="cert-org">${options.organizationName}</div>
            <div class="cert-title">${options.certificateTitle}</div>
            
            <div class="grid-row">
              <div class="grid-cell-label">Recipient:</div>
              <div class="grid-cell-value">${options.recipientName}</div>
            </div>
            <div class="grid-row">
              <div class="grid-cell-label">Certificate ID:</div>
              <div class="grid-cell-value mono">${options.certificateNumber}</div>
            </div>
            <div class="grid-row">
              <div class="grid-cell-label">Trust Proof:</div>
              <div class="grid-cell-value" style="color: #059669;">Polygon Amoy (Chain 80002) ✓</div>
            </div>
          </div>

          <div class="btn-container">
            <a href="${options.claimUrl}" class="btn" target="_blank">
              🚀 Accept & Claim Credential
            </a>
          </div>

          <div class="token-box">
            <div class="token-label">Or Claim in the Proofly Mobile App</div>
            <div style="font-size: 12px; color: #475569; margin-bottom: 6px;">Open the <strong>Claim</strong> tab and enter your claim token:</div>
            <div class="token-val mono">${claimToken}</div>
          </div>

          <div class="footer">
            Powered by <strong>Proofly Protocol</strong> • Decentralized Trust Registry<br>
            Smart Contract: <span class="mono">0xfb960EB42729f84C48040eBe264b11473d926006</span>
          </div>
        </div>
      </body>
      </html>
    `;

    const textBody = `
Hello ${options.recipientName},

${options.organizationName} has issued your official digital certificate "${options.certificateTitle}"!

Certificate ID: ${options.certificateNumber}
Blockchain: Polygon Amoy (Chain 80002)

To accept and link this credential to your Proofly account or mobile wallet, open:
${options.claimUrl}

Claim Token for Mobile App:
${claimToken}

Powered by Proofly Protocol
    `.trim();

    const command = new SendEmailCommand({
      Source: `Proofly <${env.EMAIL_FROM || 'no-reply@rovel.dev'}>`,
      Destination: {
        ToAddresses: [options.toEmail],
      },
      Message: {
        Subject: {
          Data: `📜 Claim Your Certificate: ${options.certificateTitle} - ${options.organizationName}`,
          Charset: 'UTF-8',
        },
        Body: {
          Html: {
            Data: htmlBody,
            Charset: 'UTF-8',
          },
          Text: {
            Data: textBody,
            Charset: 'UTF-8',
          },
        },
      },
    });

    try {
      const response = await this.sesClient.send(command);
      console.log(`📧 AWS SES email sent successfully to ${options.toEmail} (MessageId: ${response.MessageId})`);
      return { success: true, messageId: response.MessageId };
    } catch (err: any) {
      console.warn(`⚠️ AWS SES send email note: ${err.message}`);
      return { success: false, error: err.message };
    }
  }
}

export const emailService = new EmailService();
