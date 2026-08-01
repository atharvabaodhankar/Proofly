import { Router } from 'express';
import { AuthController } from './auth.controller';
import { validateBody } from '../../middleware/validate';
import { authenticate } from '../../middleware/auth';
import { CreateUserSchema, LoginUserSchema } from '@proofly/shared';

const router = Router();

router.post('/register', validateBody(CreateUserSchema), AuthController.register);
router.post('/login', validateBody(LoginUserSchema), AuthController.login);
router.get('/me', authenticate, AuthController.me);

export const authRoutes = router;
