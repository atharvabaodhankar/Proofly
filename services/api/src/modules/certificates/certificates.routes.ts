import { Router } from 'express';
import { CertificateController } from './certificates.controller';
import { authenticate } from '../../middleware/auth';
import { validateBody } from '../../middleware/validate';
import { IssueCertificateSchema, RevokeCertificateSchema } from '@proofly/shared';

const router = Router();

// Recipient routes
router.get('/my', authenticate, CertificateController.getMyCertificates);

// Org certificate routes
router.post('/organizations/:organizationId/certificates', authenticate, validateBody(IssueCertificateSchema), CertificateController.createAndIssue);
router.get('/organizations/:organizationId/certificates', authenticate, CertificateController.getByOrganization);

// Single certificate retrieval & revocation
router.get('/:id/pdf', CertificateController.downloadPdf);
router.get('/:id/download', CertificateController.downloadPdf);
router.get('/:id', CertificateController.getById);
router.post('/:id/revoke', authenticate, validateBody(RevokeCertificateSchema), CertificateController.revoke);

export const certificateRoutes = router;
