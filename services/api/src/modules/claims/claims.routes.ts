import { Router } from 'express';
import { ClaimsController } from './claims.controller';
import { authenticate } from '../../middleware/auth';

const router = Router();

router.get('/:token', ClaimsController.inspectClaimToken);
router.post('/:token/accept', authenticate, ClaimsController.acceptClaim);

export const claimRoutes = router;
