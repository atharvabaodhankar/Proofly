import { Router } from 'express';
import { VerificationController } from './verification.controller';

const router = Router();

router.get('/:certificateId', VerificationController.verifyById);
router.post('/hash', VerificationController.verifyByHash);

export const verificationRoutes = router;
