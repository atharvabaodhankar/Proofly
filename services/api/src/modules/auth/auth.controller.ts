import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { supabaseAdmin } from '../../config/supabase';
import { env } from '../../config/env';
import { UserRole, UserStatus } from '@proofly/shared';

export class AuthController {
  public static async register(req: Request, res: Response) {
    try {
      const { email, password, name, role } = req.body;

      // Check if user already exists
      const { data: existingUser } = await supabaseAdmin
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase())
        .single();

      if (existingUser) {
        return res.status(400).json({ error: 'User with this email already exists.' });
      }

      const passwordHash = await bcrypt.hash(password, 10);
      const userRole = role || UserRole.RECIPIENT;

      const { data: newUser, error } = await supabaseAdmin
        .from('users')
        .insert({
          email: email.toLowerCase(),
          password_hash: passwordHash,
          name,
          role: userRole,
          status: UserStatus.ACTIVE,
        })
        .select('id, email, name, role, status, created_at')
        .single();

      if (error || !newUser) {
        return res.status(500).json({ error: 'Failed to create user account.' });
      }

      const token = jwt.sign({ userId: newUser.id, email: newUser.email, role: newUser.role }, env.JWT_SECRET, {
        expiresIn: '7d',
      });

      return res.status(201).json({
        message: 'Account registered successfully',
        user: newUser,
        token,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message || 'Registration failed' });
    }
  }

  public static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      const { data: user, error } = await supabaseAdmin
        .from('users')
        .select('id, email, password_hash, name, role, status')
        .eq('email', email.toLowerCase())
        .single();

      if (error || !user) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }

      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }

      if (user.status !== UserStatus.ACTIVE) {
        return res.status(403).json({ error: 'Account is suspended or inactive.' });
      }

      const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, env.JWT_SECRET, {
        expiresIn: '7d',
      });

      return res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        token,
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message || 'Login failed' });
    }
  }

  public static async me(req: Request, res: Response) {
    try {
      if (!req.user) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      // Fetch user details & organizations
      const { data: user } = await supabaseAdmin
        .from('users')
        .select('id, email, name, role, status, email_verified_at, created_at')
        .eq('id', req.user.id)
        .single();

      const { data: orgMemberships } = await supabaseAdmin
        .from('organization_members')
        .select('role, organizations(id, name, slug, logo_url, status)')
        .eq('user_id', req.user.id);

      return res.json({
        user,
        organizations: (orgMemberships || []).map((m: any) => ({
          ...m.organizations,
          memberRole: m.role,
        })),
      });
    } catch (error: any) {
      return res.status(500).json({ error: error.message });
    }
  }
}
