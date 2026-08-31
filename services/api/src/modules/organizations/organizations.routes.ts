import { Router } from 'express';
import multer from 'multer';
import { OrganizationController } from './organizations.controller';
import { authenticate } from '../../middleware/auth';
import { validateBody } from '../../middleware/validate';
import { CreateOrganizationSchema } from '@proofly/shared';
import { z } from 'zod';

const router = Router();

// Multer memory storage for logo images (max 5MB)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files (PNG, JPG, SVG, WebP) are allowed.'));
    }
  },
});

const AddMemberSchema = z.object({
  email: z.string().email(),
  role: z.enum(['org_admin', 'org_issuer', 'org_viewer']).default('org_issuer'),
});

router.post('/', authenticate, validateBody(CreateOrganizationSchema), OrganizationController.create);
router.get('/:id', authenticate, OrganizationController.getById);
router.post('/:id/members', authenticate, validateBody(AddMemberSchema), OrganizationController.addMember);
router.post('/:id/logo', authenticate, upload.single('logo'), OrganizationController.uploadLogo);

export const organizationRoutes = router;
