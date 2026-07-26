# Proofly — System Design

> Digital credentials you can prove.

## 1. Product Overview

Proofly is a mobile-first digital certificate and credential platform.

Organizations issue certificates to recipients. Proofly stores certificate files off-chain, application/query data in PostgreSQL, and a cryptographic proof of issuance on Polygon.

Core principles:
- Recipient does not need an account before receiving a certificate.
- Recipient does not need a wallet to receive, view, or verify a certificate.
- Issuance creates the blockchain proof once.
- Claiming later only links the certificate to a Proofly account; it does not rewrite the original blockchain record.
- Blockchain is the trust/proof layer, not the application database.
- Supabase PostgreSQL is the application/query layer.
- AWS S3 stores PDFs and images.
- V1 uses Polygon Amoy; production uses Polygon PoS mainnet.
- Backend uses Express + TypeScript.

---

# 2. Core Design Principles

## 2.1 Blockchain is the proof layer

Use blockchain for:
- Certificate issuance proof
- Document hash anchoring
- Issuer identity
- Revocation state
- Other trust-critical public events

Do not use it for ordinary application data.

## 2.2 PostgreSQL is the application database

Store:
- Users
- Organizations
- Organization members
- Certificates
- Recipient relationships
- Claim state
- Verification metadata
- Blockchain transaction state
- Audit records
- Notifications

## 2.3 Files stay off-chain

Store certificate PDFs/images in AWS S3.

Only compact cryptographic proofs and selected metadata are anchored on-chain.

## 2.4 Issuance and claiming are separate

Issuing:
- Creates the certificate
- Creates the document hash
- Anchors proof on Polygon

Claiming:
- Verifies recipient control of the invited email
- Links the existing certificate to a Proofly user

Claiming does not require changing the original blockchain issuance record.

## 2.5 Reads should normally use our infrastructure

Normal Flutter screens should query PostgreSQL through Express. Add Redis/cache later when needed.

---

# 3. Actors

### Organization / Issuer
Can:
- Create/manage organization
- Add authorized issuers
- Create certificates
- Issue certificates
- Revoke certificates
- View issuance and transaction status
- Review audit history

### Recipient
Can:
- Receive certificate invitation
- Claim certificate
- Create/login to Proofly
- View/download certificates
- Share verification links
- Optionally use a wallet later

### Public Verifier
No account required:
- Scan QR code
- Open verification URL
- View public certificate status
- Confirm issuer/proof
- Check revocation state

### Platform Admin
Can:
- Manage organizations
- Inspect failed jobs/transactions
- Review audit logs
- Manage platform configuration

---

# 4. High-Level V1 Architecture

```text
                        ┌───────────────────────┐
                        │      Flutter App      │
                        │ Android / iOS         │
                        └───────────┬───────────┘
                                    │ HTTPS
                                    ▼
                        ┌───────────────────────┐
                        │    Express Backend    │
                        │ Node.js / TypeScript  │
                        └───────┬───────┬───────┘
                                │       │
                   ┌────────────┘       └─────────────┐
                   ▼                                  ▼
          ┌─────────────────┐                ┌─────────────────┐
          │ Supabase        │                │ AWS S3          │
          │ PostgreSQL      │                │ PDFs / images   │
          └────────┬────────┘                └─────────────────┘
                   │
                   │ blockchain jobs / indexed state
                   ▼
          ┌─────────────────────┐
          │ Blockchain Service  │
          │ + Event Indexer     │
          └──────────┬──────────┘
                     │ RPC
                     ▼
          ┌─────────────────────┐
          │ Polygon Amoy        │
          │ Solidity Contract   │
          └─────────────────────┘
```

---

# 5. V1 Technology Stack

## Mobile
- Flutter
- Dart

## Backend
- Node.js
- Express
- TypeScript
- Zod or Joi for validation
- Prisma or Drizzle ORM

## Database
- Supabase PostgreSQL

## Object Storage
- AWS S3

## Blockchain
- Solidity
- OpenZeppelin
- Polygon Amoy testnet
- Polygon PoS mainnet in production

## Contract Tooling
- Foundry or Hardhat

## Wallet
V1:
- MetaMask for development/testing

Later:
- Privy embedded wallets
- Account abstraction
- Pimlico

## RPC
Use a dedicated Polygon RPC provider for real development/production instead of relying on one public endpoint.

## Indexing
V1:
- Custom Node.js/TypeScript event worker

Later:
- Dedicated indexing infrastructure
- The Graph if it becomes useful

## Observability
V1:
- Structured logs
- Sentry

Later:
- OpenTelemetry
- Metrics
- Distributed tracing

---

# 6. Data Architecture

## On-chain

Store only compact, verifiable data:

```text
certificateId
issuerAddress
documentHash
issuedAt
revoked
revokedAt (optional)
metadataURI (optional)
```

Do not store:
- Full PDF
- Recipient email
- Phone number
- Passwords
- Private application data

## PostgreSQL

Store:
```text
users
organizations
organization_members
certificates
certificate_claims
blockchain_transactions
verification_logs
audit_logs
notifications
```

## S3

Store:
```text
certificate PDFs
certificate previews
organization logos
optional attachments
```

---

# 7. Certificate Lifecycle

```text
DRAFT
  ↓
READY
  ↓
QUEUED
  ↓
SUBMITTED
  ↓
CONFIRMED
  ↓
ISSUED
  │
  ├──────────────► REVOKED
  │
  └──────────────► CLAIMED
```

`CLAIMED` is an application relationship, not a replacement for the original blockchain issuance state.

---

# 8. Certificate Issuance Flow

1. Issuer enters recipient details:
   - Full name
   - Email
   - Student/employee ID (optional)

2. Issuer enters certificate details:
   - Type
   - Title
   - Description
   - Issue date
   - Expiry date (optional)

3. Express validates and creates a certificate record:
```text
certificate_id = CERT-98231
recipient_email = recipient@example.com
recipient_user_id = NULL
status = DRAFT
```

4. Generate/store certificate file in S3.

5. Calculate SHA-256 document hash.

6. Queue blockchain issuance job.

7. Blockchain service calls the certificate contract.

8. Polygon confirms the transaction.

9. Store:
```text
txHash
blockNumber
contractAddress
chainId
confirmedAt
```

10. Certificate becomes `ISSUED`.

11. Send recipient email with a claim/view link.

---

# 9. Recipient Claim Flow

## Recipient already has an account

```text
Email
  ↓
Claim link
  ↓
Login
  ↓
Verify email
  ↓
Claim
  ↓
certificate.recipient_user_id = current user
```

## Recipient has no account

```text
Email
  ↓
Claim link
  ↓
Create account
  ↓
Verify invited email
  ↓
Validate claim token
  ↓
Link certificate
```

### Important security rule

Do not let users claim all certificates matching an email just because they typed the same email.

Use a secure, random, one-time claim token in the invitation link.

Example:

```text
https://proofly.app/claim/<random-token>
```

Store only a hash of the token in PostgreSQL.

Token requirements:
- Cryptographically random
- Short-lived or single-use
- Invalidated after successful claim
- Invalidated if replaced/revoked

---

# 10. Why Claiming Does Not Change Blockchain Records

Before claim:

```text
certificate.recipient_user_id = NULL
```

After claim:

```text
certificate.recipient_user_id = USER-482
```

Blockchain remains unchanged:

```text
CERT-98231
issuer = 0x...
documentHash = 0x...
issuedAt = ...
```

This prevents unnecessary blockchain transactions.

Issuance is a blockchain trust event. Claiming is an application identity event.

---

# 11. Smart Contract

Suggested contract: `CertificateRegistry.sol`

## Functions

```solidity
function issueCertificate(
    bytes32 certificateId,
    bytes32 documentHash,
    string calldata metadataURI
) external;

function revokeCertificate(
    bytes32 certificateId
) external;

function getCertificate(
    bytes32 certificateId
) external view returns (...);
```

## Events

```solidity
event CertificateIssued(
    bytes32 indexed certificateId,
    address indexed issuer,
    bytes32 documentHash,
    string metadataURI
);

event CertificateRevoked(
    bytes32 indexed certificateId,
    address indexed issuer
);
```

## Contract rules

- Authorized issuers only
- Authorized revocation
- No duplicate certificate IDs
- No re-issuing a revoked ID
- Minimal deterministic state
- OpenZeppelin access control

---

# 12. What the Blockchain Proves

For a certificate file:

```text
certificate.pdf
      ↓
SHA-256
      ↓
documentHash
```

Blockchain contains that hash.

At verification:

```text
Downloaded certificate
      ↓
SHA-256
      ↓
computedHash
      ↓
compare with on-chain hash
```

If equal:

```text
VALID PROOF
```

If different:

```text
INVALID / MODIFIED FILE
```

---

# 13. Public Verification Flow

QR code:

```text
https://proofly.app/verify/CERT-98231
```

Flow:

```text
Scanner
  ↓
Public Verification Page
  ↓
Express API
  ↓
PostgreSQL indexed state
  ↓
Optional direct on-chain confirmation
  ↓
Verification result
```

Possible results:

```text
VALID
REVOKED
NOT_FOUND
PENDING
INVALID_PROOF
```

Normal verification should not scan the entire blockchain.

---

# 14. Blockchain Event Indexer

Events:

```text
CertificateIssued
CertificateRevoked
```

Flow:

```text
Polygon
  ↓
Contract logs
  ↓
Node indexer worker
  ↓
Parse event
  ↓
Validate block/log
  ↓
Upsert PostgreSQL
```

Maintain:

```text
lastProcessedBlock
```

Support:
- Retries
- Idempotent event handling
- Replays
- Restart from a known block
- Error logging

Blockchain events are the source for reconstructing the PostgreSQL blockchain projection.

---

# 15. Why PostgreSQL Instead of The Graph

The Graph is optional.

V1 should use our own event indexer because:
- We already use PostgreSQL for application data.
- We control the schema.
- We can join chain data with user/certificate data.
- We can replay events.
- Fewer moving parts.

The Graph can be introduced later if decentralized querying or specialized indexing needs justify it.

---

# 16. Database Schema

## users

```text
id
email
email_verified_at
name
role
status
created_at
updated_at
```

## organizations

```text
id
name
slug
logo_url
status
created_at
updated_at
```

## organization_members

```text
id
organization_id
user_id
role
created_at
```

## certificates

```text
id
certificate_number
organization_id
recipient_user_id nullable
recipient_name
recipient_email
recipient_external_id nullable

title
description
issue_date
expiry_date nullable

s3_object_key
document_hash
metadata_uri nullable

status

contract_address
chain_id
tx_hash nullable
block_number nullable

issued_at nullable
revoked_at nullable

created_at
updated_at
```

## certificate_claims

```text
id
certificate_id
email
token_hash
expires_at
used_at nullable
created_at
```

## blockchain_transactions

```text
id
certificate_id
chain_id
contract_address
tx_hash nullable
operation
status
submitted_at nullable
confirmed_at nullable
block_number nullable
error_code nullable
error_message nullable
retry_count
created_at
updated_at
```

## verification_logs

```text
id
certificate_id nullable
result
request_ip_hash nullable
user_agent nullable
created_at
```

## audit_logs

```text
id
actor_user_id nullable
organization_id nullable
action
resource_type
resource_id
metadata_json
created_at
```

---

# 17. API Design

Base path:

```text
/api/v1
```

## Auth

```text
POST /auth/register
POST /auth/login
POST /auth/verify-email
GET  /me
```

## Organizations

```text
POST /organizations
GET  /organizations/:id
POST /organizations/:id/members
```

## Certificates

```text
POST /organizations/:id/certificates
GET  /organizations/:id/certificates
GET  /certificates/:id
POST /certificates/:id/revoke
```

## Recipient

```text
GET  /me/certificates
POST /certificates/:id/claim
```

## Claims

```text
GET  /claims/:token
POST /claims/:token/accept
```

## Public verification

```text
GET /verify/:certificateId
```

## Transactions

```text
GET /transactions/:txHash
```

Worker/admin routes should not be publicly exposed.

---

# 18. S3 Layout

Example:

```text
proofly/
  organizations/
    org_<id>/
      logo/
      certificates/
        CERT-98231/
          certificate.pdf
          preview.png
```

Use private objects by default.

Use short-lived signed URLs for private downloads.

---

# 19. Authentication and Wallets

A Proofly account and a blockchain wallet are separate concepts.

V1:
- Email/password, magic link, or OTP
- MetaMask for development/issuer testing

Recipient:
- No wallet required

Later:
- Privy for embedded wallets
- Pimlico/account abstraction for sponsored transactions

Possible later UX:

```text
Proofly Login
     ↓
Embedded Wallet
     ↓
Smart account
     ↓
Sponsored blockchain transaction
```

---

# 20. V1 API/Blockchain Processing

Normal read:

```text
Flutter
  ↓ HTTPS
Express
  ↓
Auth/authorization
  ↓
PostgreSQL
  ↓
JSON
```

Issuance:

```text
Flutter
  ↓
Express
  ↓
Validate
  ↓
S3 upload
  ↓
Hash
  ↓
PostgreSQL
  ↓
Blockchain job
  ↓
Polygon
  ↓
Confirm
  ↓
Update PostgreSQL
  ↓
Email recipient
```

---

# 21. Asynchronous Blockchain Jobs

Do not wait for a full blockchain confirmation inside the normal HTTP request.

State machine:

```text
CREATED
   ↓
QUEUED
   ↓
SUBMITTED
   ↓
CONFIRMED
```

Failure:

```text
SUBMITTED
   ↓
FAILED
   ↓
RETRYING
   ↓
SUBMITTED
```

API can return:

```json
{
  "certificateId": "CERT-98231",
  "status": "PROCESSING"
}
```

---

# 22. Idempotency

Certificate issuance must be idempotent.

Use:
- Stable certificate ID
- Idempotency key
- Database uniqueness constraints
- Blockchain transaction state

Retrying an API request must not create two certificates or two issuance records for the same certificate ID.

---

# 23. Security

## Backend
- HTTPS
- Authentication
- RBAC
- Validation
- Rate limiting
- CORS
- Parameterized queries/ORM
- Secure token handling
- Secrets manager
- Audit logs

## S3
- Private bucket
- Least-privilege IAM
- Signed URLs
- Encryption
- No public write access

## Blockchain
- OpenZeppelin
- Access control
- Contract tests
- Reentrancy protection where relevant
- Separate dev/prod signer accounts
- No private keys in Flutter
- No private keys in PostgreSQL

---

# 24. Privacy

Never put private recipient data on a public blockchain.

Do not store on-chain:
- Email
- Phone
- Address
- Student ID
- Private notes

Use public-chain data only for intentional verification/proof.

---

# 25. Deployment Architecture

```text
                       INTERNET
                          │
                       Flutter
                          │
                          ▼
                  ┌──────────────┐
                  │ Express API  │
                  └──────┬───────┘
                         │
          ┌──────────────┼───────────────┐
          │              │               │
          ▼              ▼               ▼
   Supabase PG         AWS S3       Polygon Amoy
                                           │
                                           ▼
                                  Certificate Contract
                                           │
                                           ▼
                                      Event Indexer
                                           │
                                           ▼
                                      Supabase PG
```

---

# 26. Development / Testnet Configuration

```env
NODE_ENV=development

CHAIN_ID=80002
NETWORK=polygon-amoy

RPC_URL=<POLYGON_RPC>
CONTRACT_ADDRESS=<AMOY_CONTRACT>

DATABASE_URL=<SUPABASE_DEV_DATABASE>

AWS_S3_BUCKET=proofly-dev
```

Production:

```env
NODE_ENV=production

CHAIN_ID=137
NETWORK=polygon

RPC_URL=<PRODUCTION_RPC>
CONTRACT_ADDRESS=<MAINNET_CONTRACT>

DATABASE_URL=<SUPABASE_PRODUCTION_DATABASE>

AWS_S3_BUCKET=proofly-production
```

Never hardcode network-specific production addresses.

---

# 27. Version Roadmap

# V1 — Full Testnet MVP

Goal: complete end-to-end product on Polygon Amoy.

Build:
- Authentication
- Organization onboarding
- Issuer dashboard
- Recipient details
- Certificate generation
- S3 storage
- SHA-256 hashing
- Solidity certificate registry
- Polygon Amoy issuance
- Transaction tracking
- Event indexer
- Recipient email invitation
- Claim token
- Recipient account linking
- Certificate list/detail
- QR verification
- Revocation
- Basic audit log

Success:

```text
Issuer
 ↓
Issue
 ↓
Polygon proof
 ↓
Recipient email
 ↓
Claim
 ↓
My Certificates
 ↓
QR verification
```

# V2 — Production Foundation

Move to Polygon mainnet.

Add:
- Privy embedded wallets
- Better onboarding
- Background job queue
- Redis
- CDN / CloudFront
- Stronger observability
- Retry/reconciliation system
- Notifications
- Organization controls
- API integrations

Stack:

```text
Flutter
Express
Supabase PostgreSQL
AWS S3
CloudFront
Redis
Queue
Privy
Polygon Mainnet
```

# V3 — Large Scale

Add:
- Dedicated blockchain ingestion service
- Kafka/managed event bus
- PostgreSQL read replicas
- Redis cluster
- Search engine when needed
- Multiple RPC providers
- Horizontal autoscaling
- Worker pools
- Circuit breakers
- Distributed tracing
- WAF/API gateway

```text
Flutter / Web
     ↓
CDN / WAF
     ↓
API Gateway
     ↓
Express fleet
     ↓
PostgreSQL + Redis + Search
     ↓
Event Bus
     ↓
Blockchain ingestion
     ↓
Multi-RPC
     ↓
Polygon Mainnet
```

# V4 — Global / Enterprise Scale

Potential additions:
- Multi-region deployment
- Global traffic routing
- Regional caches
- Disaster recovery
- Data warehouse
- Enterprise SSO
- Tenant isolation
- Advanced compliance
- Dedicated indexing
- Automated contract monitoring
- KMS/HSM-backed key management
- Formal contract governance

---

# 28. Scalability Rules

1. Blockchain is never the hot-path database for normal UI reads.
2. Blockchain writes are asynchronous.
3. Events synchronize blockchain state into PostgreSQL.
4. Blockchain jobs and event handlers are idempotent.
5. Use multiple RPC providers at scale.
6. Keep private data off-chain.
7. Cache high-traffic verification results when needed.
8. Scale conventional infrastructure before scaling blockchain usage.

---

# 29. Failure Handling

## S3 succeeds, blockchain fails

```text
certificate.status = BLOCKCHAIN_PENDING
```

Retry blockchain job.

## Blockchain submitted, API crashes

On worker restart:
- Reconcile stored transaction state
- Check chain/RPC
- Update PostgreSQL

## Transaction permanently fails

```text
status = FAILED
retry_count++
error_message
```

## Indexer crashes

Restart from `lastProcessedBlock` and replay events.

## PostgreSQL projection becomes stale

Rebuild affected state from blockchain contract events.

---

# 30. Observability

Important metrics:

```text
API latency
DB latency
S3 upload latency
Blockchain success rate
Blockchain confirmation time
RPC error rate
Indexer lag
Queue depth
Certificate issuance failures
Verification latency
Email delivery failures
Claim conversion
```

V1:
- Structured logs
- Sentry

V3+:
- OpenTelemetry
- Distributed tracing
- Metrics
- Alerting

---

# 31. Repository Structure

```text
proofly/
│
├── apps/
│   └── mobile/
│       └── flutter/
│
├── services/
│   └── api/
│       ├── src/
│       │   ├── modules/
│       │   │   ├── auth/
│       │   │   ├── users/
│       │   │   ├── organizations/
│       │   │   ├── certificates/
│       │   │   ├── claims/
│       │   │   ├── verification/
│       │   │   └── blockchain/
│       │   ├── middleware/
│       │   ├── config/
│       │   ├── jobs/
│       │   └── app.ts
│       └── package.json
│
├── packages/
│   ├── contracts/
│   │   ├── src/
│   │   ├── test/
│   │   └── deployments/
│   └── shared/
│
├── infrastructure/
│   ├── s3/
│   ├── database/
│   └── deployment/
│
├── docs/
└── system_design.md
```

---

# 32. V1 Build Order

1. Repository setup
2. Supabase PostgreSQL schema
3. Express + TypeScript API skeleton
4. Solidity certificate contract
5. Contract tests
6. Deploy to Polygon Amoy
7. Verify contract
8. Implement blockchain service
9. Implement event indexer
10. Configure S3
11. Organization and issuer APIs
12. Certificate creation
13. Certificate issuance
14. Email invitation
15. Claim-token flow
16. Recipient account linking
17. Certificate list/detail
18. Public verification
19. Revocation
20. Flutter UI
21. Connect Flutter to API
22. Wallet integration where required
23. End-to-end tests
24. Failure/retry tests
25. Demo deployment

---

# 33. V1 Definition of Done

A complete testnet scenario works:

```text
1. Organization signs in
2. Organization creates certificate
3. Recipient has no account
4. Certificate PDF is generated/stored in S3
5. SHA-256 hash is calculated
6. PostgreSQL certificate record is created
7. Polygon Amoy transaction is submitted
8. Polygon confirms issuance
9. txHash is stored
10. Event is indexed
11. Recipient receives email
12. Recipient opens claim link
13. Recipient creates account
14. Recipient verifies invited email
15. Claim token is validated
16. Certificate is linked to the new user
17. Certificate appears in My Certificates
18. Recipient views/downloads certificate
19. Public verifier scans QR
20. Verification reports VALID
21. Issuer revokes certificate
22. Verification reports REVOKED
23. Original issuance proof remains intact
```

---

# 34. Final Architecture Philosophy

Proofly should feel like a normal modern application.

Users should not need to understand gas, RPCs, blocks, smart contracts, or wallets unless they choose to use advanced Web3 features.

Core architecture:

```text
Flutter
   ↓
Express
   ↓
Supabase PostgreSQL + AWS S3
   ↓
Blockchain Service
   ↓
Polygon
```

The platform provides:

- Simple onboarding
- Fast reads
- Reliable certificate delivery
- Tamper-evident proofs
- Public verification
- Optional Web3 ownership

> **Keep application state off-chain, anchor trust-critical proofs on-chain, and make certificate claiming an off-chain identity operation.**
