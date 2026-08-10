import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import fs from 'fs';
import { authRoutes } from './modules/auth/auth.routes';
import { organizationRoutes } from './modules/organizations/organizations.routes';
import { certificateRoutes } from './modules/certificates/certificates.routes';
import { claimRoutes } from './modules/claims/claims.routes';
import { verificationRoutes } from './modules/verification/verification.routes';
import { errorHandler } from './middleware/errorHandler';

const app = express();

// Security & utility middleware
app.use(helmet());
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Local storage static file serving
const storageDir = path.resolve(process.cwd(), 'storage_uploads');
if (!fs.existsSync(storageDir)) {
  fs.mkdirSync(storageDir, { recursive: true });
}
app.use('/api/v1/storage', express.static(storageDir));

// Serve Web UI
const publicDir = path.resolve(__dirname, '../public');
if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
}

app.get('/favicon.ico', (_req, res) => res.status(204).end());

// Health check
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'proofly-api',
    network: 'polygon-amoy',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/organizations', organizationRoutes);
app.use('/api/v1/certificates', certificateRoutes);
app.use('/api/v1/claims', claimRoutes);
app.use('/api/v1/verify', verificationRoutes);

// Web App SPA Route Fallbacks
app.get(['/verify/:id', '/claim/:token', '/'], (_req, res, next) => {
  const indexPath = path.resolve(__dirname, '../public/index.html');
  if (fs.existsSync(indexPath)) {
    return res.sendFile(indexPath);
  }
  next();
});

// Global Error Handler
app.use(errorHandler);

export default app;
