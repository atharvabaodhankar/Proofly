// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CertificateRegistry
 * @dev Anchors digital certificate issuance proofs and revocation states on Polygon.
 * Off-chain PDFs and recipient metadata are kept off-chain (AWS S3 & PostgreSQL).
 * Only the compact cryptographic document hash, issuer address, and timestamps are stored on-chain.
 */
contract CertificateRegistry is AccessControl, ReentrancyGuard {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct CertificateRecord {
        bytes32 certificateId;
        address issuer;
        bytes32 documentHash;
        uint64 issuedAt;
        uint64 revokedAt;
        bool revoked;
        string metadataURI;
    }

    // Mapping from certificateId (UUID / unique hash) to CertificateRecord
    mapping(bytes32 => CertificateRecord) private _certificates;

    // Events matching Proofly system design
    event CertificateIssued(
        bytes32 indexed certificateId,
        address indexed issuer,
        bytes32 documentHash,
        string metadataURI,
        uint64 issuedAt
    );

    event CertificateRevoked(
        bytes32 indexed certificateId,
        address indexed issuer,
        uint64 revokedAt,
        string reason
    );

    // Custom errors for gas efficiency
    error CertificateAlreadyExists(bytes32 certificateId);
    error CertificateNotFound(bytes32 certificateId);
    error CertificateAlreadyRevoked(bytes32 certificateId);
    error InvalidCertificateId();
    error InvalidDocumentHash();
    error UnauthorizedRevocation(bytes32 certificateId, address caller);

    /**
     * @dev Initializes the contract granting deployer the default admin and issuer role.
     */
    constructor(address initialAdmin) {
        address admin = initialAdmin == address(0) ? msg.sender : initialAdmin;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
    }

    /**
     * @notice Issues a new certificate on-chain with its document hash and optional metadata URI.
     * @param certificateId Unique 32-byte identifier for the certificate (e.g. hashed UUID or number)
     * @param documentHash SHA-256 hash of the generated certificate document (PDF/image)
     * @param metadataURI Optional URI pointing to public certificate metadata
     */
    function issueCertificate(
        bytes32 certificateId,
        bytes32 documentHash,
        string calldata metadataURI
    ) external onlyRole(ISSUER_ROLE) nonReentrant {
        if (certificateId == bytes32(0)) revert InvalidCertificateId();
        if (documentHash == bytes32(0)) revert InvalidDocumentHash();
        if (_certificates[certificateId].issuedAt != 0) {
            revert CertificateAlreadyExists(certificateId);
        }

        uint64 currentTime = uint64(block.timestamp);

        _certificates[certificateId] = CertificateRecord({
            certificateId: certificateId,
            issuer: msg.sender,
            documentHash: documentHash,
            issuedAt: currentTime,
            revokedAt: 0,
            revoked: false,
            metadataURI: metadataURI
        });

        emit CertificateIssued(
            certificateId,
            msg.sender,
            documentHash,
            metadataURI,
            currentTime
        );
    }

    /**
     * @notice Revokes an existing certificate.
     * @param certificateId Unique 32-byte identifier of the certificate to revoke
     * @param reason Optional human-readable reason for revocation
     */
    function revokeCertificate(
        bytes32 certificateId,
        string calldata reason
    ) external nonReentrant {
        CertificateRecord storage cert = _certificates[certificateId];

        if (cert.issuedAt == 0) revert CertificateNotFound(certificateId);
        if (cert.revoked) revert CertificateAlreadyRevoked(certificateId);

        // Caller must be the original issuer or have DEFAULT_ADMIN_ROLE
        if (cert.issuer != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedRevocation(certificateId, msg.sender);
        }

        uint64 currentTime = uint64(block.timestamp);
        cert.revoked = true;
        cert.revokedAt = currentTime;

        emit CertificateRevoked(certificateId, msg.sender, currentTime, reason);
    }

    /**
     * @notice Retrieves the on-chain certificate record by its ID.
     * @param certificateId Unique 32-byte identifier of the certificate
     */
    function getCertificate(
        bytes32 certificateId
    )
        external
        view
        returns (
            bytes32 id,
            address issuer,
            bytes32 documentHash,
            uint64 issuedAt,
            uint64 revokedAt,
            bool revoked,
            string memory metadataURI
        )
    {
        CertificateRecord storage cert = _certificates[certificateId];
        if (cert.issuedAt == 0) revert CertificateNotFound(certificateId);

        return (
            cert.certificateId,
            cert.issuer,
            cert.documentHash,
            cert.issuedAt,
            cert.revokedAt,
            cert.revoked,
            cert.metadataURI
        );
    }

    /**
     * @notice Quick check to verify if a certificate is valid and not revoked.
     * @param certificateId Unique 32-byte identifier of the certificate
     * @param documentHash SHA-256 hash of the document to compare
     */
    function verifyCertificate(
        bytes32 certificateId,
        bytes32 documentHash
    ) external view returns (bool isValid, bool isRevoked, address issuer, uint64 issuedAt) {
        CertificateRecord storage cert = _certificates[certificateId];
        if (cert.issuedAt == 0) {
            return (false, false, address(0), 0);
        }
        if (cert.revoked) {
            return (false, true, cert.issuer, cert.issuedAt);
        }
        bool hashMatches = (cert.documentHash == documentHash);
        return (hashMatches, false, cert.issuer, cert.issuedAt);
    }

    /**
     * @notice Helper to convert a string ID into bytes32 identifier.
     * @param stringId The string format ID (e.g. UUID)
     */
    function hashStringId(string calldata stringId) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(stringId));
    }
}
