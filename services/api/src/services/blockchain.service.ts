import { ethers } from 'ethers';
import { env } from '../config/env';
import { supabaseAdmin } from '../config/supabase';
import { BlockchainOperation, BlockchainTxStatus } from '@proofly/shared';

// CertificateRegistry ABI (minimal or full)
export const CERTIFICATE_REGISTRY_ABI = [
  'function issueCertificate(bytes32 certificateId, bytes32 documentHash, string calldata metadataURI) external',
  'function revokeCertificate(bytes32 certificateId, string calldata reason) external',
  'function getCertificate(bytes32 certificateId) external view returns (bytes32 id, address issuer, bytes32 documentHash, uint64 issuedAt, uint64 revokedAt, bool revoked, string memory metadataURI)',
  'function verifyCertificate(bytes32 certificateId, bytes32 documentHash) external view returns (bool isValid, bool isRevoked, address issuer, uint64 issuedAt)',
  'event CertificateIssued(bytes32 indexed certificateId, address indexed issuer, bytes32 documentHash, string metadataURI, uint64 issuedAt)',
  'event CertificateRevoked(bytes32 indexed certificateId, address indexed issuer, uint64 revokedAt, string reason)',
];

export class BlockchainService {
  private provider: ethers.JsonRpcProvider;
  private signer: ethers.Wallet | null = null;
  private contractAddress: string;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(env.POLYGON_AMOY_RPC_URL, {
      chainId: env.CHAIN_ID,
      name: env.NETWORK_NAME,
    });

    if (env.RELAYER_PRIVATE_KEY) {
      const privateKey = env.RELAYER_PRIVATE_KEY.startsWith('0x')
        ? env.RELAYER_PRIVATE_KEY
        : `0x${env.RELAYER_PRIVATE_KEY}`;
      this.signer = new ethers.Wallet(privateKey, this.provider);
    }

    this.contractAddress = env.CONTRACT_ADDRESS || ethers.ZeroAddress;
  }

  /**
   * Helper to format a string certificate identifier (e.g. UUID or 'CERT-2026-...') into a bytes32 hash.
   */
  public static toBytes32(str: string): string {
    return ethers.keccak256(ethers.toUtf8Bytes(str));
  }

  /**
   * Gets the read-only contract instance.
   */
  public getReadOnlyContract(): ethers.Contract {
    if (!this.contractAddress || this.contractAddress === ethers.ZeroAddress) {
      throw new Error('Contract address is not configured. Please set CONTRACT_ADDRESS in .env');
    }
    return new ethers.Contract(this.contractAddress, CERTIFICATE_REGISTRY_ABI, this.provider);
  }

  /**
   * Gets the writable contract instance with the relayer signer.
   */
  public getWriteContract(): ethers.Contract {
    if (!this.signer) {
      throw new Error('Relayer private key is not configured. Please set RELAYER_PRIVATE_KEY in .env');
    }
    if (!this.contractAddress || this.contractAddress === ethers.ZeroAddress) {
      throw new Error('Contract address is not configured. Please set CONTRACT_ADDRESS in .env');
    }
    return new ethers.Contract(this.contractAddress, CERTIFICATE_REGISTRY_ABI, this.signer);
  }

  /**
   * Submits an on-chain certificate issuance transaction to Polygon Amoy.
   */
  public async issueCertificateOnChain(
    certificateDbId: string,
    certificateNumber: string,
    documentHash: string,
    metadataURI = ''
  ): Promise<{ txHash: string; blockNumber: number }> {
    const certBytes32 = BlockchainService.toBytes32(certificateNumber);

    // 1. Record initial transaction state in Supabase
    const { data: txRecord, error: txInsertErr } = await supabaseAdmin
      .from('blockchain_transactions')
      .insert({
        certificate_id: certificateDbId,
        chain_id: env.CHAIN_ID,
        contract_address: this.contractAddress,
        operation: BlockchainOperation.ISSUE,
        status: BlockchainTxStatus.SUBMITTED,
        submitted_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (txInsertErr) {
      console.error('Error recording blockchain_transactions row:', txInsertErr);
    }

    try {
      const contract = this.getWriteContract();
      console.log(`Submitting issuance to Polygon Amoy for cert: ${certificateNumber} (${certBytes32})...`);

      const tx = await contract.issueCertificate(certBytes32, documentHash, metadataURI);
      console.log(`Issuance tx submitted: ${tx.hash}. Waiting for confirmation...`);

      // Update tx_hash in database
      if (txRecord) {
        await supabaseAdmin
          .from('blockchain_transactions')
          .update({ tx_hash: tx.hash })
          .eq('id', txRecord.id);
      }

      const receipt = await tx.wait(1); // Wait 1 block confirmation
      console.log(` Issuance confirmed in block ${receipt.blockNumber}! Gas used: ${receipt.gasUsed.toString()}`);

      // Update transaction status to CONFIRMED
      if (txRecord) {
        await supabaseAdmin
          .from('blockchain_transactions')
          .update({
            status: BlockchainTxStatus.CONFIRMED,
            tx_hash: tx.hash,
            confirmed_at: new Date().toISOString(),
            block_number: receipt.blockNumber,
          })
          .eq('id', txRecord.id);
      }

      return {
        txHash: tx.hash,
        blockNumber: receipt.blockNumber,
      };
    } catch (error: any) {
      console.error(`❌ Blockchain issuance failed:`, error.message);

      if (txRecord) {
        await supabaseAdmin
          .from('blockchain_transactions')
          .update({
            status: BlockchainTxStatus.FAILED,
            error_message: error.message,
          })
          .eq('id', txRecord.id);
      }

      throw error;
    }
  }

  /**
   * Submits an on-chain certificate revocation transaction to Polygon Amoy.
   */
  public async revokeCertificateOnChain(
    certificateDbId: string,
    certificateNumber: string,
    reason = ''
  ): Promise<{ txHash: string; blockNumber: number }> {
    const certBytes32 = BlockchainService.toBytes32(certificateNumber);

    const { data: txRecord } = await supabaseAdmin
      .from('blockchain_transactions')
      .insert({
        certificate_id: certificateDbId,
        chain_id: env.CHAIN_ID,
        contract_address: this.contractAddress,
        operation: BlockchainOperation.REVOKE,
        status: BlockchainTxStatus.SUBMITTED,
        submitted_at: new Date().toISOString(),
      })
      .select()
      .single();

    try {
      const contract = this.getWriteContract();
      console.log(`Submitting revocation to Polygon Amoy for cert: ${certificateNumber}...`);

      const tx = await contract.revokeCertificate(certBytes32, reason);
      const receipt = await tx.wait(1);

      if (txRecord) {
        await supabaseAdmin
          .from('blockchain_transactions')
          .update({
            status: BlockchainTxStatus.CONFIRMED,
            tx_hash: tx.hash,
            confirmed_at: new Date().toISOString(),
            block_number: receipt.blockNumber,
          })
          .eq('id', txRecord.id);
      }

      return {
        txHash: tx.hash,
        blockNumber: receipt.blockNumber,
      };
    } catch (error: any) {
      console.error(`❌ Blockchain revocation failed:`, error.message);
      if (txRecord) {
        await supabaseAdmin
          .from('blockchain_transactions')
          .update({
            status: BlockchainTxStatus.FAILED,
            error_message: error.message,
          })
          .eq('id', txRecord.id);
      }
      throw error;
    }
  }

  /**
   * Reads the on-chain certificate state directly from the smart contract.
   */
  public async getOnChainCertificate(certificateNumber: string) {
    const certBytes32 = BlockchainService.toBytes32(certificateNumber);
    const contract = this.getReadOnlyContract();

    try {
      const cert = await contract.getCertificate(certBytes32);
      return {
        id: cert.id,
        issuer: cert.issuer,
        documentHash: cert.documentHash,
        issuedAt: Number(cert.issuedAt),
        revokedAt: Number(cert.revokedAt),
        revoked: cert.revoked,
        metadataURI: cert.metadataURI,
      };
    } catch (error: any) {
      return null;
    }
  }

  /**
   * Live verification against the smart contract.
   */
  public async verifyOnChain(certificateNumber: string, documentHash: string) {
    const certBytes32 = BlockchainService.toBytes32(certificateNumber);
    const contract = this.getReadOnlyContract();

    try {
      const [isValid, isRevoked, issuer, issuedAt] = await contract.verifyCertificate(certBytes32, documentHash);
      return {
        isValid,
        isRevoked,
        issuer,
        issuedAt: Number(issuedAt),
      };
    } catch (error: any) {
      return {
        isValid: false,
        isRevoked: false,
        issuer: ethers.ZeroAddress,
        issuedAt: 0,
      };
    }
  }
}

export const blockchainService = new BlockchainService();
