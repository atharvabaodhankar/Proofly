import { Request, Response } from 'express';
import crypto from 'crypto';
import { supabaseAdmin } from '../../config/supabase';
import { env } from '../../config/env';
import { blockchainService } from '../../services/blockchain.service';
import { VerificationResult, CertificateStatus } from '@proofly/shared';

export class VerificationController {
  /**
   * Public endpoint to verify a certificate by its certificate number or UUID.
   */
  public static async verifyById(req: Request, res: Response) {
    try {
      const { certificateId } = req.params;
      const ip = req.ip || req.headers['x-forwarded-for'] || '';
      const ipHash = crypto.createHash('sha256').update(String(ip)).digest('hex');
      const userAgent = req.headers['user-agent'] || '';

      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(certificateId);
      
      // 1. Fetch certificate from PostgreSQL
      let certQuery = supabaseAdmin
        .from('certificates')
        .select('*, organizations(id, name, slug, logo_url)');
        
      if (isUuid) {
        certQuery = certQuery.eq('id', certificateId);
      } else {
        certQuery = certQuery.eq('certificate_number', certificateId);
      }

      const { data: cert } = await certQuery.single();

      if (!cert) {
        // Log NOT_FOUND attempt
        await supabaseAdmin.from('verification_logs').insert({
          certificate_id: null,
          result: VerificationResult.NOT_FOUND,
          request_ip_hash: ipHash,
          user_agent: userAgent,
        });

        return res.status(404).json({
          status: VerificationResult.NOT_FOUND,
          isValid: false,
          isRevoked: false,
          message: 'Certificate not found on Proofly.',
        });
      }

      // Check revoked
      if (cert.status === CertificateStatus.REVOKED) {
        await supabaseAdmin.from('verification_logs').insert({
          certificate_id: cert.id,
          result: VerificationResult.REVOKED,
          request_ip_hash: ipHash,
          user_agent: userAgent,
        });

        return res.json({
          status: VerificationResult.REVOKED,
          isValid: false,
          isRevoked: true,
          certificateNumber: cert.certificate_number,
          title: cert.title,
          recipientName: cert.recipient_name,
          issueDate: cert.issue_date,
          revokedAt: cert.revoked_at,
          organization: cert.organizations,
          blockchain: {
            chainId: cert.chain_id,
            contractAddress: cert.contract_address,
            txHash: cert.tx_hash,
            polygonscanUrl: cert.tx_hash ? `https://amoy.polygonscan.com/tx/${cert.tx_hash}` : null,
          },
        });
      }

      // Check pending
      if (cert.status === CertificateStatus.QUEUED || cert.status === CertificateStatus.SUBMITTED) {
        return res.json({
          status: VerificationResult.PENDING,
          isValid: false,
          isRevoked: false,
          message: 'Certificate issuance is currently being confirmed on Polygon.',
          certificateNumber: cert.certificate_number,
        });
      }

      // Verify on-chain if contract configured
      let liveOnChain: any = null;
      if (env.CONTRACT_ADDRESS) {
        liveOnChain = await blockchainService.getOnChainCertificate(cert.certificate_number);
      }

      const isValid = cert.status === CertificateStatus.ISSUED || cert.status === CertificateStatus.CLAIMED;

      // Log successful verification
      await supabaseAdmin.from('verification_logs').insert({
        certificate_id: cert.id,
        result: isValid ? VerificationResult.VALID : VerificationResult.INVALID_PROOF,
        request_ip_hash: ipHash,
        user_agent: userAgent,
      });

      return res.json({
        status: isValid ? VerificationResult.VALID : VerificationResult.INVALID_PROOF,
        isValid,
        isRevoked: false,
        certificateId: cert.id,
        certificateNumber: cert.certificate_number,
        title: cert.title,
        description: cert.description,
        recipientName: cert.recipient_name,
        issueDate: cert.issue_date,
        expiryDate: cert.expiry_date,
        documentHash: cert.document_hash,
        organization: cert.organizations,
        blockchain: {
          chainId: cert.chain_id,
          contractAddress: cert.contract_address,
          txHash: cert.tx_hash,
          blockNumber: cert.block_number,
          issuedAt: cert.issued_at,
          polygonscanUrl: cert.tx_hash ? `https://amoy.polygonscan.com/tx/${cert.tx_hash}` : null,
          onChainRecord: liveOnChain,
        },
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Endpoint to verify a document by computing its SHA-256 and matching with on-chain records.
   */
  public static async verifyByHash(req: Request, res: Response) {
    try {
      const { documentHash } = req.body;
      if (!documentHash) {
        return res.status(400).json({ error: 'documentHash is required' });
      }

      const formattedHash = documentHash.startsWith('0x') ? documentHash : `0x${documentHash}`;

      const { data: cert } = await supabaseAdmin
        .from('certificates')
        .select('*, organizations(id, name, slug, logo_url)')
        .eq('document_hash', formattedHash)
        .single();

      if (!cert) {
        return res.status(404).json({
          status: VerificationResult.NOT_FOUND,
          isValid: false,
          message: 'No certificate matching this document hash was found.',
        });
      }

      const isRevoked = cert.status === CertificateStatus.REVOKED;
      const isValid = !isRevoked && (cert.status === CertificateStatus.ISSUED || cert.status === CertificateStatus.CLAIMED);

      return res.json({
        status: isRevoked ? VerificationResult.REVOKED : isValid ? VerificationResult.VALID : VerificationResult.PENDING,
        isValid,
        isRevoked,
        certificateNumber: cert.certificate_number,
        title: cert.title,
        recipientName: cert.recipient_name,
        issueDate: cert.issue_date,
        organization: cert.organizations,
        blockchain: {
          chainId: cert.chain_id,
          contractAddress: cert.contract_address,
          txHash: cert.tx_hash,
          polygonscanUrl: cert.tx_hash ? `https://amoy.polygonscan.com/tx/${cert.tx_hash}` : null,
        },
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}
