# Proofly Design System & UI/UX Guidelines (`DESIGN.md`)

> **Impeccable Design System Specification**  
> *Unified visual language, cryptographic aesthetics, design tokens, and component patterns across Mobile (Flutter), Web (Vanilla CSS), and High-Resolution PDF Certificates.*

---

## 1. Brand Philosophy & Aesthetic Core

Proofly is the **decentralized trust layer for digital credentials on Polygon**. Its design language conveys **uncompromised cryptographic security, academic prestige, and effortless modern clarity**.

### Design Principles:
1. **Cryptographic Authenticity**: Every credential, proof, and transaction is visually anchored with verifiable hash displays, network status indicators, and direct block explorer links.
2. **Prestigious & Elevated**: Avoid generic flat designs. Use rich Ivory canvases for certificates, refined squircle cards, subtle layered elevation, and harmonious typography.
3. **Frictionless Simplicity**: Zero unnecessary steps. Instant camera QR verification without requiring wallet connections, smart deep-link claiming, and 1-click downloads.
4. **Cross-Platform Cohesion**: Consistent color tokens, typography hierarchy, and status badges across Flutter Android/iOS, Web Client, and PDF rendering.

---

## 2. Color System & Design Tokens

### Brand Primaries & Accents
| Token | Hex / Value | Role |
| :--- | :--- | :--- |
| `primary` | `#3525CD` | Core brand royal purple/indigo. Primary CTAs, hero accents, active states. |
| `primary-light` | `#4F46E5` | Lighter indigo for hover gradients and high-contrast dark-mode surfaces. |
| `cyan-accent` | `#0284C7` (Light) / `#38BDF8` (Dark) | Tech highlights, interactive links, monospace hash tags. |
| `on-primary` | `#FFFFFF` | Text/icons on primary surfaces. |

### Semantic Status Tokens
| Token | Surface / Background | Foreground / Text | Usage |
| :--- | :--- | :--- | :--- |
| `verified-success` | `#ECFDF5` (`#E6F4EA`) | `#059669` (`#137333`) | Active on-chain verified credentials & validity checkmarks. |
| `warning-expiring` | `#FFFBEB` (`#FFE0B2`) | `#D97706` (`#885500`) | Credentials approaching expiration date. |
| `error-revoked` | `#FEF2F2` (`#FFDAD6`) | `#DC2626` (`#BA1A1A`) | Revoked certificates, invalid hashes, error banners. |
| `amoy-protocol` | `#EEF2FF` | `#3525CD` | Polygon Amoy network status pill badges. |

### Light Surface Tokens (Web & Mobile Light Mode)
- **Base Canvas**: `#F8FAFC` (Ivory Snow)
- **Card Background**: `#FFFFFF` (Pure White)
- **Container Low**: `#F1F3FF`
- **Border / Hairline**: `#E2E8F0`
- **Text Main**: `#0F172A` (Deep Slate)
- **Text Muted**: `#475569`
- **Text Dim**: `#64748B`

### Dark Surface Tokens (Mobile Dark Mode)
- **Base Canvas**: `#0B0F19` (Obsidian Midnight)
- **Card Background**: `#141B2B`
- **Container Low**: `#0F172A`
- **Container High**: `#1E293B`
- **Border / Hairline**: `#334155` / `#475569`
- **Text Main**: `#F8FAFC`
- **Text Muted**: `#94A3B8`

---

## 3. Typography Scale & Hierarchy

### Font Families
- **Display & Headlines**: `Outfit` (Web) / `AppTypography.display` (Mobile)
- **Body & Controls**: `Inter`, `-apple-system`, `sans-serif`
- **Hashes & On-Chain IDs**: `JetBrains Mono`, `monospace`
- **Formal PDF Certificates**: `Helvetica-Bold` / Spaced Classical Headings

### Scale Hierarchy
| Level | Font Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display 2XL** | `32px` - `40px` | `800` (Extra Bold) | `1.15` | Hero banner titles & landing headers. |
| **Headline Lg** | `24px` - `28px` | `800` | `1.2` | Screen titles & certificate modal headers. |
| **Headline Md** | `18px` - `20px` | `700` (Bold) | `1.3` | Card titles, certificate titles, dialog headers. |
| **Body Lg** | `15px` - `16px` | `600` (Semi Bold) | `1.5` | Form labels, recipient names, button text. |
| **Body Md** | `13px` - `14px` | `400` / `500` | `1.6` | Paragraph descriptions, card bodies. |
| **Label Sm** | `10px` - `11px` | `800` | `1.0` | Badges, status pills, category tags (uppercase). |
| **Code Mono** | `12px` - `13px` | `500` / `700` | `1.4` | Certificate numbers, SHA-256 hashes, tx hashes. |

---

## 4. Elevation, Radii & Glassmorphism

### Border Radii
- **Hero / Feature Cards**: `24px` - `28px` (`BorderRadius.circular(24)`)
- **Standard Cards / Modals**: `20px` (`BorderRadius.circular(20)`)
- **Buttons & Input Fields**: `12px` - `16px` (`BorderRadius.circular(14)`)
- **Pill Badges**: `20px` (Full squircle capsule)

### Shadow System
- **Subtle Surface**: `box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05), 0 1px 2px rgba(0, 0, 0, 0.03)`
- **Card Depth**: `box-shadow: 0 4px 14px rgba(0, 0, 0, 0.05), 0 1px 3px rgba(0, 0, 0, 0.02)`
- **Elevated Hero / Floating**: `box-shadow: 0 12px 28px rgba(53, 37, 205, 0.12), 0 2px 6px rgba(0, 0, 0, 0.04)`
- **Primary CTA Glow**: `box-shadow: 0 4px 16px rgba(53, 37, 205, 0.3)`

---

## 5. Component Patterns

### 1. Primary Action Button
- **Background**: Royal Indigo `linear-gradient(135deg, #3525CD 0%, #4F46E5 100%)`
- **Text**: `#FFFFFF`, `15px`, `FontWeight.w800`, `letter-spacing: 0.5px`
- **Padding**: `14px 24px`, border-radius `14px` - `16px`
- **Micro-interaction**: Smooth `translateY(-1px)` and box shadow expansion on hover/tap.

### 2. Status Badge Pills
```html
<!-- Example Verified Pill -->
<span class="badge verified-badge">
  <span class="dot"></span>
  POLYGON AMOY VERIFIED
</span>
```
- Always includes an icon or indicator dot.
- High-contrast colored background with matching `1px` border.

### 3. Verification Result Card
- **Header**: Large status pill (`CRYPTOGRAPHICALLY VALID & ANCHORED`), Certificate Title, and Recipient Name.
- **Dynamic QR Code**: High-density QR enclosed in a white card with subtle gold/navy border and `SCAN TO VERIFY` subtitle.
- **Diagnostic Rows**:
  - `Document SHA-256 Hash` with 1-click clipboard copy.
  - `Smart Contract Address` linking to Polygon Amoy.
  - `Transaction Hash` with direct `View on Polygonscan` button.
- **Actions**: Direct `Download Certificate PDF` & `Share Verified Link`.

---

## 6. Official Certificate PDF Standards ([`pdf.service.ts`](file:///c:/Users/baodh/OneDrive/Desktop/Projects/Proofly/services/api/src/services/pdf.service.ts))

- **Layout**: Landscape A4 (`841.89 x 595.28` points).
- **Background**: Ivory White `#FCFCFD` with concentric geometric guilloche watermark.
- **Border**: Triple border (Navy 4pt `#0F172A`, Imperial Gold 1.5pt `#C59B27`, Slate hairline 0.5pt `#E2E8F0`) with 4 gold diamond corner florets.
- **Top Header**: Gold-spaced institution title (`characterSpacing: 3.5`, 13pt) + "CERTIFICATE OF RECOGNITION" (24pt).
- **Centerpiece**: 36pt Recipient Name with accent underline + 22pt Royal Navy degree title.
- **Bottom Section**: Two metadata columns (Issue Date & ID) + embedded high-res QR code card.
- **Footer**: Strictly two independent, non-overlapping center-aligned lines for protocol registry verification and direct HTTPS link.

---

## 7. UI/UX Quality Checklist

- [x] **No Placeholder Text**: All inputs start completely clean with helpful placeholder hints (no fake initial values).
- [x] **Zero Hardcoded Localhost**: All API queries route through dynamic environment variables (`API_URL` / `API_BASE_URL`).
- [x] **Deep Linking**: Seamless URL scheme handling (`proofly://claim/<token>`) with web fallback & direct APK distribution.
- [x] **Package Visibility**: Android 11+ intent filtering for web links (`https` & `http`).
- [x] **Zero Mock Data**: All verification queries check live PostgreSQL records & Polygon Amoy smart contracts.
