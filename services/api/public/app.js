// Proofly Client Application Logic
const API_BASE = '/api/v1';

let currentUser = null;
let currentToken = localStorage.getItem('proofly_token') || null;
let currentOrg = null;

// DOM Elements
const tabs = document.querySelectorAll('.nav-btn');
const tabContents = document.querySelectorAll('.tab-content');
const navAuthSection = document.getElementById('nav-auth-section');

// Tab Switching
tabs.forEach((btn) => {
  btn.addEventListener('click', () => {
    tabs.forEach((b) => b.classList.remove('active'));
    tabContents.forEach((c) => c.classList.remove('active'));

    btn.classList.add('active');
    const tabId = btn.getAttribute('data-tab');
    document.getElementById(tabId).classList.add('active');

    if (tabId === 'issuer-tab') {
      loadIssuerCertificates();
    }
  });
});

// Check URL params for direct actions (e.g. ?verify=CERT-... or ?claim=...)
window.addEventListener('DOMContentLoaded', async () => {
  const urlParams = new URLSearchParams(window.location.search);
  const verifyParam = urlParams.get('verify');
  const claimParam = urlParams.get('claim');

  if (currentToken) {
    await fetchCurrentUser();
  } else {
    renderAuthButtons();
  }

  if (verifyParam) {
    document.querySelector('[data-tab="verify-tab"]').click();
    document.getElementById('verify-input').value = verifyParam;
    performVerification(verifyParam);
  } else if (claimParam) {
    document.querySelector('[data-tab="claim-tab"]').click();
    document.getElementById('claim-token-input').value = claimParam;
    performClaimInspect(claimParam);
  }
});

// ==========================================
// Auth Handlers
// ==========================================

const authModal = document.getElementById('auth-modal');
const btnLoginModal = document.getElementById('btn-login-modal');
const btnRegisterModal = document.getElementById('btn-register-modal');
const btnCloseAuth = document.getElementById('btn-close-auth');
const btnSwitchAuth = document.getElementById('btn-switch-auth');
const authForm = document.getElementById('auth-form');

let isRegisterMode = false;

btnLoginModal?.addEventListener('click', () => openAuthModal(false));
btnRegisterModal?.addEventListener('click', () => openAuthModal(true));
btnCloseAuth?.addEventListener('click', () => authModal.classList.add('hidden'));

btnSwitchAuth?.addEventListener('click', () => {
  openAuthModal(!isRegisterMode);
});

function openAuthModal(registerMode) {
  isRegisterMode = registerMode;
  authModal.classList.remove('hidden');
  document.getElementById('auth-modal-title').textContent = registerMode ? 'Create Proofly Account' : 'Sign In to Proofly';
  document.getElementById('auth-modal-subtitle').textContent = registerMode
    ? 'Start issuing or receiving blockchain-verified certificates'
    : 'Access your organization and certificates';
  document.getElementById('btn-submit-auth').textContent = registerMode ? 'Create Account' : 'Sign In';
  document.getElementById('group-name').classList.toggle('hidden', !registerMode);
  document.getElementById('group-role').classList.toggle('hidden', !registerMode);
  document.getElementById('auth-switch-text').textContent = registerMode ? 'Already have an account?' : "Don't have an account?";
  btnSwitchAuth.textContent = registerMode ? 'Sign In' : 'Register';
}

authForm?.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('auth-email').value;
  const password = document.getElementById('auth-password').value;
  const name = document.getElementById('auth-name').value;
  const role = document.getElementById('auth-role').value;

  try {
    const endpoint = isRegisterMode ? `${API_BASE}/auth/register` : `${API_BASE}/auth/login`;
    const payload = isRegisterMode ? { email, password, name, role } : { email, password };

    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Authentication failed');

    currentToken = data.token;
    localStorage.setItem('proofly_token', currentToken);
    authModal.classList.add('hidden');

    await fetchCurrentUser();
    alert(`Welcome, ${data.user.name}!`);
  } catch (err) {
    alert(err.message);
  }
});

async function fetchCurrentUser() {
  if (!currentToken) return;
  try {
    const res = await fetch(`${API_BASE}/auth/me`, {
      headers: { Authorization: `Bearer ${currentToken}` },
    });
    if (!res.ok) {
      logout();
      return;
    }
    const data = await res.json();
    currentUser = data.user;
    currentOrg = data.organizations && data.organizations.length > 0 ? data.organizations[0] : null;

    renderAuthButtons();
    loadIssuerCertificates();
  } catch (err) {
    logout();
  }
}

function logout() {
  currentToken = null;
  currentUser = null;
  currentOrg = null;
  localStorage.removeItem('proofly_token');
  renderAuthButtons();
  loadIssuerCertificates();
}

function renderAuthButtons() {
  if (currentUser) {
    navAuthSection.innerHTML = `
      <div style="display:flex; align-items:center; gap:12px;">
        <span style="font-size:13px; font-weight:600;">${currentUser.name}</span>
        <button class="btn btn-sm btn-outline" id="btn-logout">Logout</button>
      </div>
    `;
    document.getElementById('btn-logout')?.addEventListener('click', logout);
  } else {
    navAuthSection.innerHTML = `
      <button class="btn btn-outline" id="btn-login-modal">Sign In</button>
      <button class="btn btn-primary" id="btn-register-modal">Create Account</button>
    `;
    document.getElementById('btn-login-modal')?.addEventListener('click', () => openAuthModal(false));
    document.getElementById('btn-register-modal')?.addEventListener('click', () => openAuthModal(true));
  }
}

// ==========================================
// Verification Logic
// ==========================================

const btnVerify = document.getElementById('btn-verify');
const verifyInput = document.getElementById('verify-input');
const verifyResult = document.getElementById('verify-result');

btnVerify?.addEventListener('click', () => {
  const query = verifyInput.value.trim();
  if (query) performVerification(query);
});

verifyInput?.addEventListener('keyup', (e) => {
  if (e.key === 'Enter') {
    const query = verifyInput.value.trim();
    if (query) performVerification(query);
  }
});

async function performVerification(certificateId) {
  verifyResult.classList.remove('hidden');
  verifyResult.innerHTML = `<div class="text-center py-4">🔍 Verifying against Polygon Amoy smart contract...</div>`;

  try {
    const res = await fetch(`${API_BASE}/verify/${encodeURIComponent(certificateId)}`);
    const data = await res.json();

    if (!res.ok && data.status === 'NOT_FOUND') {
      verifyResult.innerHTML = `
        <div class="verify-badge-large status-invalid">❌ Certificate Not Found</div>
        <p class="text-muted">No credential matching ID <strong>${certificateId}</strong> was found on Proofly or Polygon Amoy.</p>
      `;
      return;
    }

    const isRevoked = data.isRevoked || data.status === 'REVOKED';
    const isValid = data.isValid && !isRevoked;

    const statusBadge = isRevoked
      ? `<span class="verify-badge-large status-invalid">⚠️ CERTIFICATE REVOKED</span>`
      : isValid
      ? `<span class="verify-badge-large status-valid">✅ CRYPTOGRAPHICALLY VALID & ANCHORED</span>`
      : `<span class="verify-badge-large status-pending">⏳ PENDING CONFIRMATION</span>`;

    const qrUrl = `${window.location.origin}/verify/${data.certificateNumber}`;

    verifyResult.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:20px;">
        <div style="flex:1; min-width:260px;">
          ${statusBadge}
          <h2 style="margin: 12px 0 6px;">${data.title || 'Digital Certificate'}</h2>
          <p style="font-size:16px; color: #38BDF8; font-weight: 600; margin-bottom: 16px;">Issued to: ${data.recipientName || 'N/A'}</p>
        </div>

        <div style="background: white; padding: 10px; border-radius: 14px; display:flex; flex-direction:column; align-items:center; box-shadow: 0 4px 16px rgba(0,0,0,0.3);">
          <div id="verify-qr-container"></div>
          <span style="color: #1E293B; font-size: 10px; font-weight: 700; margin-top: 6px;">SCAN TO VERIFY</span>
        </div>
      </div>

      <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin: 20px 0;">
        <div class="stat-card">
          <div class="stat-title">Certificate Number</div>
          <div class="stat-value mono" style="font-size: 15px;">${data.certificateNumber}</div>
        </div>
        <div class="stat-card">
          <div class="stat-title">Issuing Organization</div>
          <div class="stat-value" style="font-size: 15px;">${data.organization ? data.organization.name : 'Verified Issuer'}</div>
        </div>
        <div class="stat-card">
          <div class="stat-title">Issue Date</div>
          <div class="stat-value" style="font-size: 15px;">${data.issueDate}</div>
        </div>
      </div>

      <div style="background: rgba(0,0,0,0.3); padding: 16px; border-radius: 10px; margin-top: 16px; font-size: 13px;">
        <div style="margin-bottom: 6px;"><strong>SHA-256 Document Hash:</strong> <span class="mono" style="color: #94A3B8; word-break: break-all;">${data.documentHash || 'Anchored on-chain'}</span></div>
        <div><strong>Polygon Amoy Tx:</strong> 
          ${
            data.blockchain?.txHash
              ? `<a href="${data.blockchain.polygonscanUrl}" target="_blank" style="color: #38BDF8; text-decoration: underline;">${data.blockchain.txHash.slice(0, 16)}... (View on Polygonscan)</a>`
              : '<span class="text-muted">Direct Registry Record</span>'
          }
        </div>
      </div>
    `;

    setTimeout(() => {
      const qrEl = document.getElementById('verify-qr-container');
      if (qrEl && typeof QRCode !== 'undefined') {
        new QRCode(qrEl, {
          text: qrUrl,
          width: 100,
          height: 100,
          colorDark: '#0F172A',
          colorLight: '#FFFFFF',
          correctLevel: QRCode.CorrectLevel.M,
        });
      }
    }, 50);
  } catch (err) {
    verifyResult.innerHTML = `<div class="status-invalid" style="padding:12px; border-radius:8px;">Error during verification: ${err.message}</div>`;
  }
}

// Drag & Drop PDF Hashing
const pdfDropZone = document.getElementById('pdf-drop-zone');
const pdfFileInput = document.getElementById('pdf-file-input');

pdfDropZone?.addEventListener('click', () => pdfFileInput.click());

pdfDropZone?.addEventListener('dragover', (e) => {
  e.preventDefault();
  pdfDropZone.style.borderColor = '#38BDF8';
});

pdfDropZone?.addEventListener('dragleave', () => {
  pdfDropZone.style.borderColor = 'rgba(255, 255, 255, 0.12)';
});

pdfDropZone?.addEventListener('drop', (e) => {
  e.preventDefault();
  pdfDropZone.style.borderColor = 'rgba(255, 255, 255, 0.12)';
  if (e.dataTransfer.files.length > 0) {
    handlePdfFile(e.dataTransfer.files[0]);
  }
});

pdfFileInput?.addEventListener('change', (e) => {
  if (e.target.files.length > 0) {
    handlePdfFile(e.target.files[0]);
  }
});

async function handlePdfFile(file) {
  verifyResult.classList.remove('hidden');
  verifyResult.innerHTML = `<div class="text-center py-4">⏳ Calculating SHA-256 checksum for "${file.name}"...</div>`;

  const arrayBuffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = '0x' + hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');

  try {
    const res = await fetch(`${API_BASE}/verify/hash`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ documentHash: hashHex }),
    });
    const data = await res.json();

    if (!res.ok) {
      verifyResult.innerHTML = `
        <div class="verify-badge-large status-invalid">❌ Tampered or Unregistered Document</div>
        <p>The document checksum (<span class="mono">${hashHex.slice(0, 16)}...</span>) was not found in the Polygon proof registry.</p>
      `;
      return;
    }

    verifyResult.innerHTML = `
      <div class="verify-badge-large status-valid">✅ FILE INTEGRITY VERIFIED (MATCHES BLOCKCHAIN PROOF)</div>
      <h3>${data.title}</h3>
      <p style="color:#38BDF8; font-weight:600;">Recipient: ${data.recipientName}</p>
      <div class="mono" style="background:rgba(0,0,0,0.3); padding:12px; border-radius:8px; margin-top:12px; font-size:12px; word-break:break-all;">
        Computed SHA-256: ${hashHex}
      </div>
    `;
  } catch (err) {
    verifyResult.innerHTML = `<div class="status-invalid" style="padding:12px;">Error verifying hash: ${err.message}</div>`;
  }
}

// ==========================================
// Issuer Logic
// ==========================================

const issueModal = document.getElementById('issue-modal');
const btnOpenIssueModal = document.getElementById('btn-open-issue-modal');
const btnCloseIssue = document.getElementById('btn-close-issue');
const issueForm = document.getElementById('issue-form');

btnOpenIssueModal?.addEventListener('click', async () => {
  if (!currentUser) {
    openAuthModal(false);
    return;
  }

  // If user has no organization yet, create default one
  if (!currentOrg) {
    const orgName = prompt('Enter your Organization Name (e.g. Acme University):');
    if (!orgName) return;
    const slug = orgName.toLowerCase().replace(/[^a-z0-9]/g, '-') + '-' + Math.floor(Math.random() * 1000);

    const res = await fetch(`${API_BASE}/organizations`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentToken}`,
      },
      body: JSON.stringify({ name: orgName, slug }),
    });
    const orgData = await res.json();
    currentOrg = orgData.organization;
  }

  issueModal.classList.remove('hidden');
});

btnCloseIssue?.addEventListener('click', () => issueModal.classList.add('hidden'));

issueForm?.addEventListener('submit', async (e) => {
  e.preventDefault();
  if (!currentOrg) return;

  const btn = document.getElementById('btn-submit-issue');
  btn.disabled = true;
  btn.textContent = 'Generating PDF & Submitting Proof...';

  const recipient_name = document.getElementById('issue-recipient-name').value.trim();
  const recipient_email = document.getElementById('issue-recipient-email').value.trim();
  const title = document.getElementById('issue-title').value.trim();
  const description = document.getElementById('issue-description').value.trim();
  const issue_date = document.getElementById('issue-date').value || new Date().toISOString().split('T')[0];
  const expiry_val = document.getElementById('issue-expiry').value;
  const expiry_date = expiry_val ? expiry_val : undefined;

  try {
    const res = await fetch(`${API_BASE}/certificates/organizations/${currentOrg.id}/certificates`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentToken}`,
      },
      body: JSON.stringify({ recipient_name, recipient_email, title, description, issue_date, expiry_date }),
    });

    const data = await res.json();
    if (!res.ok) {
      const errMsg = data.details ? data.details.map((d) => `${d.field}: ${d.message}`).join('\n') : (data.error || 'Failed to issue certificate');
      throw new Error(errMsg);
    }

    alert(`🎉 Certificate ${data.certificate.certificate_number} created successfully!\n\nClaim Link:\n${data.certificate.claimUrl}`);
    issueModal.classList.add('hidden');
    issueForm.reset();
    loadIssuerCertificates();
  } catch (err) {
    alert(`Issue Error:\n${err.message}`);
  } finally {
    btn.disabled = false;
    btn.textContent = 'Generate PDF & Anchor on Polygon';
  }
});

// Logo Upload Handlers
const btnUploadLogo = document.getElementById('btn-upload-logo-trigger');
const orgLogoInput = document.getElementById('org-logo-file-input');

btnUploadLogo?.addEventListener('click', () => {
  if (!currentOrg) {
    alert('Please sign in with an organization account first.');
    return;
  }
  orgLogoInput?.click();
});

orgLogoInput?.addEventListener('change', async (e) => {
  const target = e.target;
  if (!currentOrg || !target.files || !target.files.length) return;
  const file = target.files[0];

  const formData = new FormData();
  formData.append('logo', file);

  if (btnUploadLogo) {
    btnUploadLogo.disabled = true;
    btnUploadLogo.textContent = 'Uploading to S3...';
  }

  try {
    const res = await fetch(`${API_BASE}/organizations/${currentOrg.id}/logo`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${currentToken}`,
      },
      body: formData,
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to upload logo');

    currentOrg.logo_url = data.logo_url;
    renderOrgProfile();
    alert('🎉 Organization logo uploaded to AWS S3 successfully! It will now automatically appear on all generated certificates.');
  } catch (err) {
    alert(`Logo Upload Failed: ${err.message}`);
  } finally {
    if (btnUploadLogo) {
      btnUploadLogo.disabled = false;
      btnUploadLogo.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
        Upload Logo (AWS S3)
      `;
    }
  }
});

function renderOrgProfile() {
  const profileCard = document.getElementById('org-profile-card');
  const orgNameEl = document.getElementById('org-display-name');
  const orgSlugEl = document.getElementById('org-display-slug');
  const orgImg = document.getElementById('org-logo-img');
  const orgPlaceholder = document.getElementById('org-logo-placeholder');

  if (!currentUser || !currentOrg) {
    if (profileCard) profileCard.style.display = 'none';
    return;
  }

  if (profileCard) profileCard.style.display = 'flex';
  if (orgNameEl) orgNameEl.textContent = currentOrg.name;
  if (orgSlugEl) orgSlugEl.textContent = `@${currentOrg.slug}`;

  if (currentOrg.logo_url && orgImg && orgPlaceholder) {
    orgImg.src = currentOrg.logo_url;
    orgImg.style.display = 'block';
    orgPlaceholder.style.display = 'none';
  } else if (orgImg && orgPlaceholder) {
    orgImg.style.display = 'none';
    orgPlaceholder.style.display = 'block';
  }
}

async function loadIssuerCertificates() {
  renderOrgProfile();
  const tbody = document.getElementById('certs-table-body');
  if (!tbody) return;

  if (!currentUser || !currentOrg) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">Please sign in with an issuer account to view credentials.</td></tr>`;
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/certificates/organizations/${currentOrg.id}/certificates`, {
      headers: { Authorization: `Bearer ${currentToken}` },
    });
    const data = await res.json();

    if (!data.certificates || data.certificates.length === 0) {
      tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">No certificates issued yet. Click "Issue New Certificate" above!</td></tr>`;
      return;
    }

    tbody.innerHTML = data.certificates
      .map((c) => {
        const statusClass = c.status.toLowerCase();
        return `
        <tr>
          <td class="mono"><strong>${c.certificate_number}</strong></td>
          <td>
            <div>${c.recipient_name}</div>
            <small class="text-muted">${c.recipient_email}</small>
          </td>
          <td>${c.title}</td>
          <td><span class="status-pill status-${statusClass}">${c.status}</span></td>
          <td class="mono" style="font-size:12px;">${c.document_hash.slice(0, 10)}...</td>
          <td>${c.issue_date}</td>
          <td>
            <a href="/api/v1/certificates/${c.id}" target="_blank" class="btn btn-sm btn-outline">PDF</a>
            <button class="btn btn-sm btn-outline" style="color:#38BDF8;" onclick="showQrModal('${c.certificate_number}', '${c.title.replace(/'/g, "\\'")}')">📱 QR</button>
            <button class="btn btn-sm btn-outline" style="color:#F87171;" onclick="revokeCert('${c.id}')">Revoke</button>
          </td>
        </tr>
      `;
      })
      .join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">Error loading certificates: ${err.message}</td></tr>`;
  }
}

window.revokeCert = async function (id) {
  if (!confirm('Are you sure you want to revoke this certificate on Polygon Amoy?')) return;
  try {
    const res = await fetch(`${API_BASE}/certificates/${id}/revoke`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentToken}`,
      },
      body: JSON.stringify({ reason: 'Revoked by organization admin' }),
    });
    if (!res.ok) throw new Error('Revocation failed');
    alert('Certificate successfully revoked.');
    loadIssuerCertificates();
  } catch (err) {
    alert(err.message);
  }
};

// ==========================================
// Claiming Logic
// ==========================================

const btnCheckClaim = document.getElementById('btn-check-claim');
const claimTokenInput = document.getElementById('claim-token-input');
const claimPreview = document.getElementById('claim-preview');

btnCheckClaim?.addEventListener('click', () => {
  const token = claimTokenInput.value.trim();
  if (token) performClaimInspect(token);
});

async function performClaimInspect(token) {
  claimPreview.classList.remove('hidden');
  claimPreview.innerHTML = `<div class="text-center py-4">Checking invitation token...</div>`;

  try {
    const res = await fetch(`${API_BASE}/claims/${token}`);
    const data = await res.json();

    if (!res.ok) {
      claimPreview.innerHTML = `<div class="status-invalid" style="padding:14px; border-radius:8px;">${data.error || 'Invalid claim token'}</div>`;
      return;
    }

    claimPreview.innerHTML = `
      <div style="background:rgba(0,0,0,0.3); padding:20px; border-radius:12px; margin-top:16px;">
        <span class="status-pill status-valid" style="margin-bottom:10px;">Token Verified</span>
        <h3>${data.certificate.title}</h3>
        <p style="color:#38BDF8; font-weight:600;">Recipient: ${data.certificate.recipientName} (${data.email})</p>
        <p class="text-muted" style="margin:10px 0;">${data.certificate.description}</p>
        
        <button class="btn btn-primary btn-block mt-4" onclick="acceptClaim('${token}')">
          Accept & Link Credential to My Account
        </button>
      </div>
    `;
  } catch (err) {
    claimPreview.innerHTML = `<div class="status-invalid" style="padding:14px;">Error: ${err.message}</div>`;
  }
}

window.acceptClaim = async function (token) {
  if (!currentUser) {
    alert('Please sign in or register an account first so we can link your credential.');
    openAuthModal(false);
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/claims/${token}/accept`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentToken}`,
      },
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to claim');

    alert(' Congratulations! Certificate has been linked to your account.');
    document.querySelector('[data-tab="verify-tab"]').click();
    document.getElementById('verify-input').value = data.certificate.certificate_number;
    performVerification(data.certificate.certificate_number);
  } catch (err) {
    alert(err.message);
  }
};

// ============================================
// QR CODE MODAL & HERO QR GENERATION
// ============================================
const qrModal = document.getElementById('qr-modal');
const btnCloseQr = document.getElementById('btn-close-qr');
const qrModalTitle = document.getElementById('qr-modal-title');
const qrModalCertNum = document.getElementById('qr-modal-cert-num');
const modalQrContainer = document.getElementById('modal-qr-container');
const btnCopyModalQrLink = document.getElementById('btn-copy-modal-qr-link');
let activeModalQrUrl = '';

btnCloseQr?.addEventListener('click', () => qrModal.classList.add('hidden'));

window.showQrModal = function (certNumber, title) {
  if (!qrModal || !modalQrContainer) return;
  activeModalQrUrl = `${window.location.origin}/verify/${certNumber}`;

  if (qrModalTitle) qrModalTitle.textContent = title || 'Certificate QR Code';
  if (qrModalCertNum) qrModalCertNum.textContent = certNumber;

  modalQrContainer.innerHTML = '';
  if (typeof QRCode !== 'undefined') {
    new QRCode(modalQrContainer, {
      text: activeModalQrUrl,
      width: 180,
      height: 180,
      colorDark: '#0F172A',
      colorLight: '#FFFFFF',
      correctLevel: QRCode.CorrectLevel.M,
    });
  }

  qrModal.classList.remove('hidden');
};

btnCopyModalQrLink?.addEventListener('click', () => {
  if (!activeModalQrUrl) return;
  navigator.clipboard.writeText(activeModalQrUrl);
  alert('Verification URL copied to clipboard!');
});

// Copy Hero QR Link
document.getElementById('btn-copy-hero-qr-url')?.addEventListener('click', () => {
  const heroCertId = document.getElementById('hero-qr-cert-id')?.textContent || 'CERT-20260826-436B4A';
  const url = `${window.location.origin}/verify/${heroCertId}`;
  navigator.clipboard.writeText(url);
  alert('Live verification test URL copied!');
});

// Initialize Hero QR Code on Load
function initHeroQr() {
  const heroContainer = document.getElementById('hero-qr-container');
  const heroCertId = document.getElementById('hero-qr-cert-id')?.textContent || 'CERT-20260826-436B4A';
  if (heroContainer && typeof QRCode !== 'undefined') {
    heroContainer.innerHTML = '';
    new QRCode(heroContainer, {
      text: `${window.location.origin}/verify/${heroCertId}`,
      width: 84,
      height: 84,
      colorDark: '#0F172A',
      colorLight: '#FFFFFF',
      correctLevel: QRCode.CorrectLevel.M,
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  setTimeout(initHeroQr, 200);
});
initHeroQr();

