import { Request, Response } from 'express';
import crypto from 'crypto';
import { supabaseAdmin } from '../../config/supabase';
import { env } from '../../config/env';
import { storageService } from '../../services/storage.service';
import { PdfService } from '../../services/pdf.service';
import { blockchainService } from '../../services/blockchain.service';
import { CertificateStatus, UserRole } from '@proofly/shared';

export class CertificateController {
  /**
   * Generates, stores, hashes, and initiates blockchain anchoring for a certificate.
   */
  public static async createAndIssue(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

      const { organizationId } = req.params;
      const { recipient_name, recipient_email, recipient_external_id, title, description, issue_date, expiry_date } = req.body;

      // 1. Verify caller is an authorized issuer/admin for this organization
      const { data: member } = await supabaseAdmin
        .from('organization_members')
        .select('role, organizations(id, name, slug, logo_url)')
        .eq('organization_id', organizationId)
        .eq('user_id', req.user.id)
        .single();

      if (!member || (member.role !== UserRole.ORG_ADMIN && member.role !== UserRole.ORG_ISSUER && req.user.role !== UserRole.PLATFORM_ADMIN)) {
        return res.status(403).json({ error: 'You are not authorized to issue certificates for this organization.' });
      }

      const org = (member as any).organizations;

      // 2. Generate unique Certificate Number
      const randomSuffix = crypto.randomBytes(3).toString('hex').toUpperCase();
      const datePart = (issue_date || new Date().toISOString().split('T')[0]).replace(/-/g, '');
      const certificateNumber = `CERT-${datePart}-${randomSuffix}`;
      
      const protocol = req.headers['x-forwarded-proto'] || req.protocol;
      const host = req.get('host') || `localhost:${env.PORT}`;
      const baseUrl = `${protocol}://${host}`;
      const verifyUrl = `${baseUrl}/verify/${certificateNumber}`;

      // Fetch organization logo if available
      let logoBuffer: Buffer | null = null;
      if (org && org.logo_url) {
        try {
          if (org.logo_url.startsWith('http')) {
            const resp = await fetch(org.logo_url);
            if (resp.ok) {
              const arrayBuf = await resp.arrayBuffer();
              logoBuffer = Buffer.from(arrayBuf);
            }
          }
        } catch (lErr) {
          console.warn('Failed to load logo for PDF rendering:', lErr);
        }
      }

      // 3. Generate Certificate PDF & compute SHA-256 document hash
      const { pdfBuffer, documentHash } = await PdfService.generateCertificate({
        certificateNumber,
        recipientName: recipient_name,
        title,
        description,
        organizationName: org.name,
        organizationLogoBuffer: logoBuffer,
        issueDate: issue_date,
        expiryDate: expiry_date,
        verifyUrl,
      });

      // 4. Upload PDF to Storage Layer (AWS S3 or Local)
      const s3ObjectKey = `organizations/${organizationId}/certificates/${certificateNumber}/certificate.pdf`;
      const { url: fileUrl } = await storageService.uploadFile(pdfBuffer, s3ObjectKey, 'application/pdf');

      // 5. Insert certificate record into PostgreSQL
      const { data: cert, error: certError } = await supabaseAdmin
        .from('certificates')
        .insert({
          certificate_number: certificateNumber,
          organization_id: organizationId,
          recipient_user_id: null, // Unclaimed initially
          recipient_name,
          recipient_email: recipient_email.toLowerCase(),
          recipient_external_id: recipient_external_id || null,
          title,
          description,
          issue_date,
          expiry_date: expiry_date || null,
          s3_object_key: s3ObjectKey,
          document_hash: documentHash,
          metadata_uri: `${baseUrl}/api/v1/certificates/${certificateNumber}/metadata`,
          status: CertificateStatus.QUEUED,
          contract_address: env.CONTRACT_ADDRESS || null,
          chain_id: env.CHAIN_ID,
        })
        .select()
        .single();

      if (certError || !cert) {
        return res.status(500).json({ error: 'Failed to record certificate in database', details: certError });
      }

      // 6. Generate secure, single-use claim token
      const rawClaimToken = crypto.randomBytes(32).toString('hex');
      const tokenHash = crypto.createHash('sha256').update(rawClaimToken).digest('hex');
      const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days validity

      await supabaseAdmin.from('certificate_claims').insert({
        certificate_id: cert.id,
        email: recipient_email.toLowerCase(),
        token_hash: tokenHash,
        expires_at: expiresAt,
      });

      const claimUrl = `${baseUrl}/claim/${rawClaimToken}`;

      // 7. Blockchain Anchoring (Async or Direct)
      let blockchainTx: { txHash: string; blockNumber: number } | null = null;
      let txError: string | null = null;

      if (env.CONTRACT_ADDRESS && env.RELAYER_PRIVATE_KEY) {
        try {
          blockchainTx = await blockchainService.issueCertificateOnChain(
            cert.id,
            certificateNumber,
            documentHash,
            cert.metadata_uri
          );

          // Update certificate with confirmed blockchain details
          await supabaseAdmin
            .from('certificates')
            .update({
              status: CertificateStatus.ISSUED,
              tx_hash: blockchainTx.txHash,
              block_number: blockchainTx.blockNumber,
              issued_at: new Date().toISOString(),
            })
            .eq('id', cert.id);
        } catch (bErr: any) {
          txError = bErr.message;
          console.warn('⚠️ Blockchain transaction queued / pending relayer:', bErr.message);
        }
      }

      // 8. Record audit log
      await supabaseAdmin.from('audit_logs').insert({
        actor_user_id: req.user.id,
        organization_id: organizationId,
        action: 'CERTIFICATE_ISSUED',
        resource_type: 'certificate',
        resource_id: cert.id,
        metadata_json: { certificateNumber, recipient_email, documentHash },
      });

      return res.status(201).json({
        message: 'Certificate created and processed successfully',
        certificate: {
          ...cert,
          status: blockchainTx ? CertificateStatus.ISSUED : cert.status,
          tx_hash: blockchainTx ? blockchainTx.txHash : null,
          block_number: blockchainTx ? blockchainTx.blockNumber : null,
          pdfUrl: fileUrl,
          verifyUrl,
          claimUrl,
          rawClaimToken, // Returned so UI or emailer can send invitation
        },
        blockchainStatus: blockchainTx
          ? { confirmed: true, txHash: blockchainTx.txHash, blockNumber: blockchainTx.blockNumber }
          : { confirmed: false, note: txError || 'Pending blockchain relayer execution' },
      });
    } catch (error: any) {
      console.error('Error creating certificate:', error);
      return res.status(500).json({ error: error.message });
    }
  }

  public static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
      let certQuery = supabaseAdmin
        .from('certificates')
        .select('*, organizations(id, name, slug, logo_url)');

      if (isUuid) {
        certQuery = certQuery.eq('id', id);
      } else {
        certQuery = certQuery.eq('certificate_number', id);
      }

      const { data: cert, error } = await certQuery.single();

      if (error || !cert) {
        return res.status(404).json({ error: 'Certificate not found' });
      }

      // Generate fresh signed/presigned download URL
      const downloadUrl = await storageService.getDownloadUrl(cert.s3_object_key, 3600);

      return res.json({
        certificate: cert,
        downloadUrl,
        verifyUrl: `${env.APP_URL}/verify/${cert.certificate_number}`,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  public static async getByOrganization(req: Request, res: Response) {
    try {
      const { organizationId } = req.params;

      const { data: certs, error } = await supabaseAdmin
        .from('certificates')
        .select('id, certificate_number, recipient_name, recipient_email, title, status, document_hash, tx_hash, issue_date, created_at')
        .eq('organization_id', organizationId)
        .order('created_at', { ascending: false });

      if (error) {
        return res.status(500).json({ error: error.message });
      }

      return res.json({ certificates: certs });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  public static async getMyCertificates(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

      // Search either claimed by recipient_user_id or matching recipient_email
      const { data: certs, error } = await supabaseAdmin
        .from('certificates')
        .select('*, organizations(id, name, slug, logo_url)')
        .or(`recipient_user_id.eq.${req.user.id},recipient_email.eq.${req.user.email}`)
        .order('created_at', { ascending: false });

      if (error) {
        return res.status(500).json({ error: error.message });
      }

      return res.json({ certificates: certs });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  public static async revoke(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
      const { id } = req.params;
      const { reason } = req.body;

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
      let certQuery = supabaseAdmin.from('certificates').select('*');

      if (isUuid) {
        certQuery = certQuery.eq('id', id);
      } else {
        certQuery = certQuery.eq('certificate_number', id);
      }

      const { data: cert, error } = await certQuery.single();

      if (error || !cert) {
        return res.status(404).json({ error: 'Certificate not found' });
      }

      // Check permissions
      const { data: member } = await supabaseAdmin
        .from('organization_members')
        .select('role')
        .eq('organization_id', cert.organization_id)
        .eq('user_id', req.user.id)
        .single();

      if (!member && req.user.role !== UserRole.PLATFORM_ADMIN) {
        return res.status(403).json({ error: 'Unauthorized to revoke this certificate' });
      }

      // 1. Submit on-chain revocation if blockchain is configured
      let revokeTx: { txHash: string; blockNumber: number } | null = null;
      if (env.CONTRACT_ADDRESS && env.RELAYER_PRIVATE_KEY) {
        try {
          revokeTx = await blockchainService.revokeCertificateOnChain(
            cert.id,
            cert.certificate_number,
            reason || 'Revoked by issuer'
          );
        } catch (bErr: any) {
          console.warn('⚠️ Blockchain revocation error:', bErr.message);
        }
      }

      // 2. Update status in database
      const { data: updatedCert } = await supabaseAdmin
        .from('certificates')
        .update({
          status: CertificateStatus.REVOKED,
          revoked_at: new Date().toISOString(),
        })
        .eq('id', cert.id)
        .select()
        .single();

      // 3. Log audit event
      await supabaseAdmin.from('audit_logs').insert({
        actor_user_id: req.user.id,
        organization_id: cert.organization_id,
        action: 'CERTIFICATE_REVOKED',
        resource_type: 'certificate',
        resource_id: cert.id,
        metadata_json: { reason, txHash: revokeTx ? revokeTx.txHash : null },
      });

      return res.json({
        message: 'Certificate revoked successfully',
        certificate: updatedCert,
        blockchainRevocation: revokeTx,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}
