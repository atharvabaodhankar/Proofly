-- =========================================================
-- Proofly PostgreSQL Database Schema for Supabase
-- Target: Digital Credentials & Proof Verification Platform
-- =========================================================

-- Enable pgcrypto / uuid-ossp for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified_at TIMESTAMPTZ,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'recipient',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on email
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 2. ORGANIZATIONS TABLE
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    logo_url TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on slug
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- 3. ORGANIZATION MEMBERS TABLE
CREATE TABLE IF NOT EXISTS organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'org_issuer',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_org_members_org ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user ON organization_members(user_id);

-- 4. CERTIFICATES TABLE
CREATE TABLE IF NOT EXISTS certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_number VARCHAR(100) UNIQUE NOT NULL,
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    recipient_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    recipient_name VARCHAR(255) NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    recipient_external_id VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE,
    s3_object_key TEXT NOT NULL,
    document_hash VARCHAR(66) NOT NULL,
    metadata_uri TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    contract_address VARCHAR(42),
    chain_id INTEGER NOT NULL DEFAULT 80002,
    tx_hash VARCHAR(66),
    block_number BIGINT,
    issued_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_certificates_org ON certificates(organization_id);
CREATE INDEX IF NOT EXISTS idx_certificates_recipient_user ON certificates(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_recipient_email ON certificates(recipient_email);
CREATE INDEX IF NOT EXISTS idx_certificates_doc_hash ON certificates(document_hash);
CREATE INDEX IF NOT EXISTS idx_certificates_status ON certificates(status);
CREATE INDEX IF NOT EXISTS idx_certificates_cert_num ON certificates(certificate_number);

-- 5. CERTIFICATE CLAIMS TABLE (One-time secure tokens)
CREATE TABLE IF NOT EXISTS certificate_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_id UUID NOT NULL REFERENCES certificates(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_claims_token_hash ON certificate_claims(token_hash);
CREATE INDEX IF NOT EXISTS idx_claims_cert_id ON certificate_claims(certificate_id);

-- 6. BLOCKCHAIN TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS blockchain_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_id UUID NOT NULL REFERENCES certificates(id) ON DELETE CASCADE,
    chain_id INTEGER NOT NULL DEFAULT 80002,
    contract_address VARCHAR(42) NOT NULL,
    tx_hash VARCHAR(66),
    operation VARCHAR(50) NOT NULL, -- ISSUE, REVOKE
    status VARCHAR(50) NOT NULL DEFAULT 'QUEUED', -- QUEUED, SUBMITTED, CONFIRMED, FAILED, RETRYING
    submitted_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    block_number BIGINT,
    error_code VARCHAR(100),
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bc_tx_status ON blockchain_transactions(status);
CREATE INDEX IF NOT EXISTS idx_bc_tx_cert_id ON blockchain_transactions(certificate_id);
CREATE INDEX IF NOT EXISTS idx_bc_tx_hash ON blockchain_transactions(tx_hash);

-- 7. VERIFICATION LOGS TABLE
CREATE TABLE IF NOT EXISTS verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_id UUID REFERENCES certificates(id) ON DELETE SET NULL,
    result VARCHAR(50) NOT NULL, -- VALID, REVOKED, NOT_FOUND, PENDING, INVALID_PROOF
    request_ip_hash VARCHAR(64),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verif_cert ON verification_logs(certificate_id);
CREATE INDEX IF NOT EXISTS idx_verif_result ON verification_logs(result);

-- 8. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255) NOT NULL,
    metadata_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_org ON audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_logs(resource_type, resource_id);

-- 9. INDEXER STATE TABLE
CREATE TABLE IF NOT EXISTS indexer_state (
    chain_id INTEGER PRIMARY KEY,
    last_processed_block BIGINT NOT NULL DEFAULT 0,
    contract_address VARCHAR(42) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================
-- Automatically update updated_at timestamps
-- =========================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_orgs_updated_at ON organizations;
CREATE TRIGGER trg_orgs_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_certs_updated_at ON certificates;
CREATE TRIGGER trg_certs_updated_at BEFORE UPDATE ON certificates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_bc_tx_updated_at ON blockchain_transactions;
CREATE TRIGGER trg_bc_tx_updated_at BEFORE UPDATE ON blockchain_transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
