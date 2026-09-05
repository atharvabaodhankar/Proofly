import { z } from 'zod';

// ==========================================
// Enums & Constants
// ==========================================

export enum UserRole {
  PLATFORM_ADMIN = 'platform_admin',
  ORG_ADMIN = 'org_admin',
  ORG_ISSUER = 'org_issuer',
  ORG_VIEWER = 'org_viewer',
  RECIPIENT = 'recipient',
}

export enum UserStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  PENDING = 'pending',
}

export enum OrganizationStatus {
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  VERIFIED = 'verified',
}

export enum CertificateStatus {
  DRAFT = 'DRAFT',
  READY = 'READY',
  QUEUED = 'QUEUED',
  SUBMITTED = 'SUBMITTED',
  CONFIRMED = 'CONFIRMED',
  ISSUED = 'ISSUED',
  REVOKED = 'REVOKED',
  CLAIMED = 'CLAIMED',
}

export enum BlockchainOperation {
  ISSUE = 'ISSUE',
  REVOKE = 'REVOKE',
}

export enum BlockchainTxStatus {
  QUEUED = 'QUEUED',
  SUBMITTED = 'SUBMITTED',
  CONFIRMED = 'CONFIRMED',
  FAILED = 'FAILED',
  RETRYING = 'RETRYING',
}

export enum VerificationResult {
  VALID = 'VALID',
  REVOKED = 'REVOKED',
  NOT_FOUND = 'NOT_FOUND',
  PENDING = 'PENDING',
  INVALID_PROOF = 'INVALID_PROOF',
}

// Chain Constants
export const POLYGON_AMOY_CHAIN_ID = 80002;
export const POLYGON_MAINNET_CHAIN_ID = 137;

// ==========================================
// Zod Schemas & Validation
// ==========================================

export const CreateUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2),
  role: z.nativeEnum(UserRole).default(UserRole.RECIPIENT),
});
export type CreateUserInput = z.infer<typeof CreateUserSchema>;

export const LoginUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});
export type LoginUserInput = z.infer<typeof LoginUserSchema>;

export const CreateOrganizationSchema = z.object({
  name: z.string().min(2).max(100),
  slug: z.string().min(2).max(50).regex(/^[a-z0-9-]+$/, 'Slug must be alphanumeric and lowercase with hyphens'),
  logo_url: z.string().url().optional(),
});
export type CreateOrganizationInput = z.infer<typeof CreateOrganizationSchema>;

export const IssueCertificateSchema = z.preprocess((data: any) => {
  if (data && typeof data === 'object') {
    return {
      ...data,
      recipient_name: data.recipient_name ?? data.recipientName,
      recipient_email: data.recipient_email ?? data.recipientEmail,
      recipient_external_id: data.recipient_external_id ?? data.recipientExternalId,
      issue_date: data.issue_date ?? data.issueDate,
      expiry_date: data.expiry_date ?? data.expiryDate,
    };
  }
  return data;
}, z.object({
  recipient_name: z.string().min(2),
  recipient_email: z.string().email(),
  recipient_external_id: z.string().optional().nullable(),
  title: z.string().min(2).max(200),
  description: z.string().max(2000),
  issue_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD')
    .optional()
    .nullable()
    .default(() => new Date().toISOString().split('T')[0]),
  expiry_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD')
    .optional()
    .nullable()
    .or(z.literal('')),
  metadata: z.record(z.any()).optional().nullable(),
}));
export type IssueCertificateInput = z.infer<typeof IssueCertificateSchema>;

export const RevokeCertificateSchema = z.object({
  reason: z.string().min(3).max(500).optional(),
});
export type RevokeCertificateInput = z.infer<typeof RevokeCertificateSchema>;

export const ClaimCertificateSchema = z.object({
  token: z.string().min(16),
});
export type ClaimCertificateInput = z.infer<typeof ClaimCertificateSchema>;

// ==========================================
// TypeScript Interfaces
// ==========================================

export interface User {
  id: string;
  email: string;
  email_verified_at: string | null;
  name: string;
  role: UserRole;
  status: UserStatus;
  created_at: string;
  updated_at: string;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  logo_url: string | null;
  status: OrganizationStatus;
  created_at: string;
  updated_at: string;
}

export interface OrganizationMember {
  id: string;
  organization_id: string;
  user_id: string;
  role: UserRole;
  created_at: string;
}

export interface Certificate {
  id: string;
  certificate_number: string;
  organization_id: string;
  recipient_user_id: string | null;
  recipient_name: string;
  recipient_email: string;
  recipient_external_id: string | null;
  title: string;
  description: string;
  issue_date: string;
  expiry_date: string | null;
  s3_object_key: string;
  document_hash: string;
  metadata_uri: string | null;
  status: CertificateStatus;
  contract_address: string;
  chain_id: number;
  tx_hash: string | null;
  block_number: number | null;
  issued_at: string | null;
  revoked_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface CertificateClaim {
  id: string;
  certificate_id: string;
  email: string;
  token_hash: string;
  expires_at: string;
  used_at: string | null;
  created_at: string;
}

export interface BlockchainTransaction {
  id: string;
  certificate_id: string;
  chain_id: number;
  contract_address: string;
  tx_hash: string | null;
  operation: BlockchainOperation;
  status: BlockchainTxStatus;
  submitted_at: string | null;
  confirmed_at: string | null;
  block_number: number | null;
  error_code: string | null;
  error_message: string | null;
  retry_count: number;
  created_at: string;
  updated_at: string;
}

export interface VerificationLog {
  id: string;
  certificate_id: string | null;
  result: VerificationResult;
  request_ip_hash: string | null;
  user_agent: string | null;
  created_at: string;
}

export interface AuditLog {
  id: string;
  actor_user_id: string | null;
  organization_id: string | null;
  action: string;
  resource_type: string;
  resource_id: string;
  metadata_json: Record<string, any>;
  created_at: string;
}

export interface VerificationResponse {
  certificateId: string;
  certificateNumber: string;
  status: VerificationResult;
  isValid: boolean;
  isRevoked: boolean;
  documentHash: string;
  recipientName: string;
  title: string;
  issueDate: string;
  expiryDate: string | null;
  organization: {
    id: string;
    name: string;
    slug: string;
    logoUrl: string | null;
  } | null;
  blockchain: {
    chainId: number;
    contractAddress: string;
    txHash: string | null;
    blockNumber: number | null;
    issuedAt: string | null;
    polygonscanUrl: string | null;
  };
}
