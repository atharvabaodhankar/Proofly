import { Request, Response } from 'express';
import { supabaseAdmin } from '../../config/supabase';
import { UserRole, OrganizationStatus } from '@proofly/shared';

export class OrganizationController {
  public static async create(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

      const { name, slug, logo_url } = req.body;

      // Check if slug is taken
      const { data: existing } = await supabaseAdmin
        .from('organizations')
        .select('id')
        .eq('slug', slug.toLowerCase())
        .single();

      if (existing) {
        return res.status(400).json({ error: 'Organization slug is already in use.' });
      }

      // 1. Create Organization
      const { data: org, error: orgError } = await supabaseAdmin
        .from('organizations')
        .insert({
          name,
          slug: slug.toLowerCase(),
          logo_url: logo_url || null,
          status: OrganizationStatus.ACTIVE,
        })
        .select()
        .single();

      if (orgError || !org) {
        return res.status(500).json({ error: 'Failed to create organization.' });
      }

      // 2. Add creator as ORG_ADMIN
      await supabaseAdmin.from('organization_members').insert({
        organization_id: org.id,
        user_id: req.user.id,
        role: UserRole.ORG_ADMIN,
      });

      // 3. Log audit event
      await supabaseAdmin.from('audit_logs').insert({
        actor_user_id: req.user.id,
        organization_id: org.id,
        action: 'ORGANIZATION_CREATED',
        resource_type: 'organization',
        resource_id: org.id,
        metadata_json: { name, slug },
      });

      return res.status(201).json({
        message: 'Organization created successfully',
        organization: org,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  public static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;

      const { data: org, error } = await supabaseAdmin
        .from('organizations')
        .select('*, organization_members(user_id, role, users(id, name, email))')
        .eq('id', id)
        .single();

      if (error || !org) {
        return res.status(404).json({ error: 'Organization not found' });
      }

      return res.json({ organization: org });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }

  public static async addMember(req: Request, res: Response) {
    try {
      if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
      const { id: organizationId } = req.params;
      const { email, role } = req.body;

      // Verify caller is admin of this organization
      const { data: callerMember } = await supabaseAdmin
        .from('organization_members')
        .select('role')
        .eq('organization_id', organizationId)
        .eq('user_id', req.user.id)
        .single();

      if (!callerMember || (callerMember.role !== UserRole.ORG_ADMIN && req.user.role !== UserRole.PLATFORM_ADMIN)) {
        return res.status(403).json({ error: 'Only organization admins can add members.' });
      }

      // Find user by email
      const { data: targetUser } = await supabaseAdmin
        .from('users')
        .select('id, email, name')
        .eq('email', email.toLowerCase())
        .single();

      if (!targetUser) {
        return res.status(404).json({ error: 'No user registered with this email.' });
      }

      const memberRole = role || UserRole.ORG_ISSUER;

      const { data: newMember, error } = await supabaseAdmin
        .from('organization_members')
        .insert({
          organization_id: organizationId,
          user_id: targetUser.id,
          role: memberRole,
        })
        .select()
        .single();

      if (error) {
        return res.status(400).json({ error: 'User is already a member of this organization.' });
      }

      return res.status(201).json({
        message: 'Member added successfully',
        member: newMember,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}
