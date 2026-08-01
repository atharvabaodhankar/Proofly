import { Request, Response } from 'express';
import crypto from 'crypto';
import { supabaseAdmin } from '../../config/supabase';
import { CertificateStatus } from '@proofly/shared';

export class ClaimsController {
  /**
   * Validates a claim token and returns certificate details for preview before accepting.
   */
  public static async inspectClaimToken(req: Request, res: Response) {
    try {
      const { token } = req.params;
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      const { data: claim, error } = await supabaseAdmin
        .from('certificate_claims')
        .select('*, certificates(*, organizations(id, name, slug, logo_url))')
        .eq('token_hash', tokenHash)
        .single();

      if (error || !claim) {
        return res.status(404).json({ error: 'Claim link is invalid or does not exist.' });
      }

      if (claim.used_at) {
        return res.status(400).json({ error: 'This certificate has already been claimed.' });
      }

      if (new Date(claim.expires_at) < new Date()) {
        return res.status(400).json({ error: 'This claim link has expired.' });
      }

      const cert = (claim as any).certificates;

      return res.json({
        valid: true,
        email: claim.email,
        expiresAt: claim.expires_at,
        certificate: {
          id: cert.id,
          certificateNumber: cert.certificate_number,
          recipientName: cert.recipient_name,
          title: cert.title,
          description: cert.description,
          issueDate: cert.issue_date,
          organization: cert.organizations,
        },
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  /**
   * Accepts the claim and links the certificate to the authenticated user account.
   */
  public static async acceptClaim(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Please login or create an account to claim your certificate.' });

      const { token } = req.params;
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

      // 1. Fetch and validate claim token
      const { data: claim, error: claimErr } = await supabaseAdmin
        .from('certificate_claims')
        .select('*, certificates(*)')
        .eq('token_hash', tokenHash)
        .single();

      if (claimErr || !claim) {
        return res.status(404).json({ error: 'Invalid claim token.' });
      }

      if (claim.used_at) {
        return res.status(400).json({ error: 'This certificate has already been claimed.' });
      }

      if (new Date(claim.expires_at) < new Date()) {
        return res.status(400).json({ error: 'This claim link has expired.' });
      }

      const cert = (claim as any).certificates;

      // 2. Link certificate to current user
      const { data: updatedCert, error: updateErr } = await supabaseAdmin
        .from('certificates')
        .update({
          recipient_user_id: req.user.id,
          status: cert.status === CertificateStatus.ISSUED ? CertificateStatus.CLAIMED : cert.status,
        })
        .eq('id', cert.id)
        .select()
        .single();

      if (updateErr) {
        return res.status(500).json({ error: 'Failed to claim certificate.' });
      }

      // 3. Mark claim token as used
      await supabaseAdmin
        .from('certificate_claims')
        .update({ used_at: new Date().toISOString() })
        .eq('id', claim.id);

      // 4. Record audit log
      await supabaseAdmin.from('audit_logs').insert({
        actor_user_id: req.user.id,
        organization_id: cert.organization_id,
        action: 'CERTIFICATE_CLAIMED',
        resource_type: 'certificate',
        resource_id: cert.id,
        metadata_json: { userEmail: req.user.email, invitedEmail: claim.email },
      });

      return res.json({
        message: 'Certificate successfully claimed and linked to your account!',
        certificate: updatedCert,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}
