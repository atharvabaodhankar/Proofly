import { Router } from 'express';
import { OrganizationController } from './organizations.controller';
import { authenticate } from '../../middleware/auth';
import { validateBody } from '../../middleware/validate';
import { CreateOrganizationSchema } from '@proofly/shared';
import { z } from 'zod';

const router = Router();

const AddMemberSchema = z.object({
  email: z.string().email(),
  role: z.enum(['org_admin', 'org_issuer', 'org_viewer']).default('org_issuer'),
});

router.post('/', authenticate, validateBody(CreateOrganizationSchema), OrganizationController.create);
router.get('/:id', authenticate, OrganizationController.getById);
router.post('/:id/members', authenticate, validateBody(AddMemberSchema), OrganizationController.addMember);

export const organizationRoutes = router;
