# Proofly — Production Cloud Deployment & Operations Guide (`DEPLOYMENT_GUIDE.md`)

> **Architectural Overview & Production Playbook**  
> *End-to-end instructions for deploying the Proofly API backend, PostgreSQL database on Supabase, AWS SES email delivery, AWS S3 storage, custom domain DNS on `rovel.dev`, and building the production Flutter Android APK.*

---

## 1. System Architecture Overview

```text
                          ┌────────────────────────┐
                          │   Custom Domain / DNS  │
                          │   (https://rovel.dev)  │
                          └───────────┬────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               │                                             │
               ▼                                             ▼
  ┌────────────────────────┐                    ┌─────────────────────────┐
  │ Proofly Web UI & API   │                    │ Proofly Mobile App      │
  │ (Express + TypeScript) │                    │ (Flutter Android / iOS) │
  └───────┬────────┬───────┘                    └────────────┬────────────┘
          │        │                                         │
          │        ├────────────► AWS SES (Emails) ◄─────────┤
          │        ├────────────► AWS S3 (PDFs/Assets) ◄─────┤
          │        │                                         │
          ▼        ▼                                         ▼
   ┌──────────┐ ┌──────────────────────────────────────────────┐
   │ Supabase │ │ Polygon Amoy Blockchain (Chain ID: 80002)    │
   │ Postgres │ │ Contract: 0xfb960EB42729f84C48040eBe264b1147 │
   └──────────┘ └──────────────────────────────────────────────┘
```

---

## 2. Production Environment Configuration

Create a `.env` file on your server (or add these variables in your cloud hosting provider's dashboard):

```ini
# ==========================================
# Proofly Production Environment
# ==========================================

# Server & Network
PORT=4000
NODE_ENV=production
API_BASE_URL=https://rovel.dev/api/v1
APP_URL=https://rovel.dev
JWT_SECRET=your_production_jwt_secret_key_here

# Supabase (PostgreSQL Database & Auth)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SUPABASE_SERVICE_ROLE_KEY

# Polygon Blockchain (Amoy Testnet V1 / Polygon Mainnet)
CHAIN_ID=80002
NETWORK_NAME=polygon-amoy
POLYGON_AMOY_RPC_URL=https://polygon-amoy.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY
CONTRACT_ADDRESS=0xfb960EB42729f84C48040eBe264b11473d926006
RELAYER_PRIVATE_KEY=YOUR_POLYGON_RELAYER_PRIVATE_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_API_KEY

# Storage Layer (AWS S3)
STORAGE_PROVIDER=s3
AWS_REGION=ap-south-1
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
AWS_S3_BUCKET=proofly-certificates

# Email Service (AWS SES)
EMAIL_FROM=no-reply@rovel.dev
```

---

## 3. Cloud Deployment Options

### Option A: Railway / Render (Easiest)

1. Connect your **GitHub Repository** to [Railway.app](https://railway.app) or [Render.com](https://render.com).
2. Set the **Build Command**:
   ```bash
   npm install && npm run build
   ```
3. Set the **Start Command**:
   ```bash
   npm run start:api
   ```
4. In the Environment Variables settings, paste all variables from [Section 2](#2-production-environment-configuration).
5. Add your custom domain **`rovel.dev`** in Settings ➔ Domains.

---

### Option B: AWS EC2 Deployment (Ubuntu 24.04)

#### 1. Provision EC2 Instance
- **OS**: Ubuntu Server 24.04 LTS (x86_64 or ARM64)
- **Instance Type**: `t3.small` or `t4g.small` (Free tier / Low cost)
- **Security Group Inbound Rules**:
  - `HTTP` (Port 80) ➔ `0.0.0.0/0`
  - `HTTPS` (Port 443) ➔ `0.0.0.0/0`
  - `SSH` (Port 22) ➔ `Your IP`

#### 2. Install Node.js, PM2 & Git
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs git nginx certbot python3-certbot-nginx
sudo npm install -g pm2
```

#### 3. Clone Repository & Build
```bash
git clone https://github.com/your-username/Proofly.git /var/www/proofly
cd /var/www/proofly
npm install
npm run build
```

#### 4. Configure PM2 Process Manager
```bash
# Start API server and background indexer
pm2 start npm --name "proofly-api" -- run start:api
pm2 start npm --name "proofly-indexer" -- run indexer
pm2 save
pm2 startup
```

#### 5. Configure Nginx Reverse Proxy
Edit `/etc/nginx/sites-available/proofly`:
```nginx
server {
    server_name rovel.dev www.rovel.dev;

    client_max_body_size 25M;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable site & get free SSL with Certbot:
```bash
sudo ln -s /etc/nginx/sites-available/proofly /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d rovel.dev -d www.rovel.dev
```

---

## 4. Custom Domain & DNS Setup

In your domain registrar (e.g. **Name.com**):

| Type | Host / Name | Answer / Target | TTL | Purpose |
|---|---|---|---|---|
| **A** | `@` (`rovel.dev`) | `YOUR_SERVER_PUBLIC_IP` | 300 | Web & API Root |
| **CNAME** | `www` | `rovel.dev` | 300 | WWW Redirection |
| **CNAME** | `xxxx._domainkey` | `xxxx.dkim.amazonses.com` | 300 | AWS SES DKIM 1 |
| **CNAME** | `yyyy._domainkey` | `yyyy.dkim.amazonses.com` | 300 | AWS SES DKIM 2 |
| **CNAME** | `zzzz._domainkey` | `zzzz.dkim.amazonses.com` | 300 | AWS SES DKIM 3 |

---

## 5. AWS SES Email & S3 Storage Setup

1. **AWS SES**:
   - Region: `ap-south-1` (Mumbai).
   - Domain: `rovel.dev` (DKIM records verified).
   - Production Access: In SES Console ➔ Click *"Request production access"* (Transactional, website: `https://rovel.dev`).
2. **AWS S3**:
   - Bucket: `proofly-certificates` in `ap-south-1`.
   - Brand Logo: Stored at `brand/proofly_logo.png`.
   - Certificates: Auto-uploaded under `certificates/<certNumber>.pdf`.

---

## 6. Building Production Mobile App (APK)

To build the release Android APK connected to your live production domain:

```bash
cd apps/mobile

# Build release APK with production API endpoint
flutter build apk --release --dart-define=API_URL=https://rovel.dev/api/v1
```

The compiled standalone APK will be located at:
```
apps/mobile/build/app/outputs/flutter-apk/app-release.apk
```

To host it for direct download on your site:
```bash
# Copy release APK to public web directory
cp apps/mobile/build/app/outputs/flutter-apk/app-release.apk services/api/public/proofly.apk
```

---

## 7. Useful Maintenance & Diagnostic Commands

```bash
# Check running PM2 processes
pm2 status

# View live API logs
pm2 logs proofly-api

# Check Nginx status
sudo systemctl status nginx

# Test on-chain blockchain connection
cd services/api
npx ts-node src/scripts/test-live-flow.ts

# Test AWS SES email delivery
npx ts-node -e "import { emailService } from './src/services/email.service'; emailService.sendClaimInvitation({ toEmail: 'your-email@gmail.com', recipientName: 'Admin', certificateTitle: 'Test Certificate', organizationName: 'Proofly', certificateNumber: 'TEST-001', claimUrl: 'https://rovel.dev/claim/test-token' }).then(console.log);"
```
