import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { supabaseAdmin } from '../config/supabase';
import { UserRole } from '@proofly/shared';

export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  name: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authentication required. No Bearer token provided.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_SECRET) as { userId: string };

    const { data: user, error } = await supabaseAdmin
      .from('users')
      .select('id, email, name, role, status')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired authentication token.' });
    }

    if (user.status !== 'active') {
      return res.status(403).json({ error: 'User account is not active.' });
    }

    req.user = {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role as UserRole,
    };

    next();
  } catch (err: any) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
};

export const requireRoles = (...allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized.' });
    }

    if (!allowedRoles.includes(req.user.role) && req.user.role !== UserRole.PLATFORM_ADMIN) {
      return res.status(403).json({ error: 'Forbidden: Insufficient privileges.' });
    }

    next();
  };
};
