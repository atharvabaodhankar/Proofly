import { expect } from "chai";
import { ethers } from "hardhat";
import { CertificateRegistry } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("CertificateRegistry", function () {
  let registry: CertificateRegistry;
  let admin: SignerWithAddress;
  let issuer: SignerWithAddress;
  let unauthorized: SignerWithAddress;

  const sampleCertId = ethers.keccak256(ethers.toUtf8Bytes("CERT-2026-001"));
  const sampleDocHash = ethers.keccak256(ethers.toUtf8Bytes("SHA256-OF-SAMPLE-PDF-CONTENT"));
  const sampleMetadataURI = "https://proofly.app/metadata/CERT-2026-001.json";

  beforeEach(async function () {
    [admin, issuer, unauthorized] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("CertificateRegistry");
    registry = await Factory.deploy(admin.address);
    await registry.waitForDeployment();

    // Grant ISSUER_ROLE to issuer
    const ISSUER_ROLE = await registry.ISSUER_ROLE();
    await registry.connect(admin).grantRole(ISSUER_ROLE, issuer.address);
  });

  describe("Deployment & Access Control", function () {
    it("should set deployer as admin and issuer", async function () {
      const DEFAULT_ADMIN_ROLE = await registry.DEFAULT_ADMIN_ROLE();
      const ISSUER_ROLE = await registry.ISSUER_ROLE();

      expect(await registry.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.be.true;
      expect(await registry.hasRole(ISSUER_ROLE, admin.address)).to.be.true;
      expect(await registry.hasRole(ISSUER_ROLE, issuer.address)).to.be.true;
      expect(await registry.hasRole(ISSUER_ROLE, unauthorized.address)).to.be.false;
    });
  });

  describe("Certificate Issuance", function () {
    it("should allow an authorized issuer to issue a certificate and emit CertificateIssued event", async function () {
      await expect(
        registry.connect(issuer).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI)
      )
        .to.emit(registry, "CertificateIssued")
        .withArgs(
          sampleCertId,
          issuer.address,
          sampleDocHash,
          sampleMetadataURI,
          (val: bigint) => val > 0n
        );

      const cert = await registry.getCertificate(sampleCertId);
      expect(cert.id).to.equal(sampleCertId);
      expect(cert.issuer).to.equal(issuer.address);
      expect(cert.documentHash).to.equal(sampleDocHash);
      expect(cert.metadataURI).to.equal(sampleMetadataURI);
      expect(cert.revoked).to.be.false;
      expect(cert.issuedAt).to.be.greaterThan(0);
    });

    it("should revert if an unauthorized account tries to issue", async function () {
      await expect(
        registry.connect(unauthorized).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI)
      ).to.be.revertedWithCustomError(registry, "AccessControlUnauthorizedAccount");
    });

    it("should prevent duplicate issuance of the same certificate ID", async function () {
      await registry.connect(issuer).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI);

      await expect(
        registry.connect(issuer).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI)
      ).to.be.revertedWithCustomError(registry, "CertificateAlreadyExists");
    });
  });

  describe("Certificate Revocation", function () {
    beforeEach(async function () {
      await registry.connect(issuer).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI);
    });

    it("should allow the original issuer to revoke a certificate", async function () {
      const reason = "Issued with typo in recipient name";

      await expect(registry.connect(issuer).revokeCertificate(sampleCertId, reason))
        .to.emit(registry, "CertificateRevoked")
        .withArgs(sampleCertId, issuer.address, (val: bigint) => val > 0n, reason);

      const cert = await registry.getCertificate(sampleCertId);
      expect(cert.revoked).to.be.true;
      expect(cert.revokedAt).to.be.greaterThan(0);
    });

    it("should allow the admin to revoke a certificate issued by another issuer", async function () {
      await expect(registry.connect(admin).revokeCertificate(sampleCertId, "Admin override"))
        .to.emit(registry, "CertificateRevoked");

      const cert = await registry.getCertificate(sampleCertId);
      expect(cert.revoked).to.be.true;
    });

    it("should prevent unauthorized users from revoking", async function () {
      await expect(
        registry.connect(unauthorized).revokeCertificate(sampleCertId, "Hacking attempt")
      ).to.be.revertedWithCustomError(registry, "UnauthorizedRevocation");
    });

    it("should prevent revoking an already revoked certificate", async function () {
      await registry.connect(issuer).revokeCertificate(sampleCertId, "First revocation");

      await expect(
        registry.connect(issuer).revokeCertificate(sampleCertId, "Second revocation")
      ).to.be.revertedWithCustomError(registry, "CertificateAlreadyRevoked");
    });
  });

  describe("Certificate Verification Helper", function () {
    it("should return correct verification results for valid, mismatched, and revoked certificates", async function () {
      await registry.connect(issuer).issueCertificate(sampleCertId, sampleDocHash, sampleMetadataURI);

      // Matching hash
      const [isValid, isRevoked, certIssuer] = await registry.verifyCertificate(sampleCertId, sampleDocHash);
      expect(isValid).to.be.true;
      expect(isRevoked).to.be.false;
      expect(certIssuer).to.equal(issuer.address);

      // Wrong document hash
      const wrongHash = ethers.keccak256(ethers.toUtf8Bytes("TAMPERED-DOCUMENT"));
      const [isValidTampered, isRevokedTampered] = await registry.verifyCertificate(sampleCertId, wrongHash);
      expect(isValidTampered).to.be.false;
      expect(isRevokedTampered).to.be.false;

      // After revocation
      await registry.connect(issuer).revokeCertificate(sampleCertId, "Revoked test");
      const [isValidAfterRevoke, isRevokedAfterRevoke] = await registry.verifyCertificate(sampleCertId, sampleDocHash);
      expect(isValidAfterRevoke).to.be.false;
      expect(isRevokedAfterRevoke).to.be.true;
    });
  });
});
