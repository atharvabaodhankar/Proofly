import { ethers } from 'ethers';
import { env } from '../config/env';
import { supabaseAdmin } from '../config/supabase';
import { CERTIFICATE_REGISTRY_ABI } from '../services/blockchain.service';
import { CertificateStatus } from '@proofly/shared';

export class BlockchainIndexer {
  private provider: ethers.JsonRpcProvider;
  private contract: ethers.Contract | null = null;
  private isRunning = false;
  private pollIntervalMs = 12000; // Poll every 12 seconds on Polygon Amoy

  constructor() {
    this.provider = new ethers.JsonRpcProvider(env.POLYGON_AMOY_RPC_URL);
    if (env.CONTRACT_ADDRESS && env.CONTRACT_ADDRESS !== ethers.ZeroAddress) {
      this.contract = new ethers.Contract(env.CONTRACT_ADDRESS, CERTIFICATE_REGISTRY_ABI, this.provider);
    }
  }

  public async start() {
    if (this.isRunning) return;
    if (!this.contract) {
      console.log('ℹ️ Indexer: CONTRACT_ADDRESS not configured. Skipping event indexer worker.');
      return;
    }

    this.isRunning = true;
    console.log(`📡 Proofly Blockchain Indexer started for contract: ${env.CONTRACT_ADDRESS} on Chain ${env.CHAIN_ID}`);

    this.pollLoop();
  }

  private async pollLoop() {
    while (this.isRunning) {
      try {
        await this.syncEvents();
      } catch (error: any) {
        console.error('❌ Indexer sync error:', error.message);
      }

      await new Promise((resolve) => setTimeout(resolve, this.pollIntervalMs));
    }
  }

  private async syncEvents() {
    if (!this.contract) return;

    const currentBlock = await this.provider.getBlockNumber();

    // Get last processed block from DB
    const { data: state } = await supabaseAdmin
      .from('indexer_state')
      .select('last_processed_block')
      .eq('chain_id', env.CHAIN_ID)
      .single();

    let fromBlock = state && Number(state.last_processed_block) > 0 
      ? Number(state.last_processed_block) + 1 
      : currentBlock - 5;
      
    if (fromBlock < 0) fromBlock = 0;
    if (fromBlock > currentBlock) return;

    // Alchemy Free tier restricts eth_getLogs to max 10 blocks per request
    const MAX_BLOCK_BATCH = 9; 
    const toBlock = Math.min(fromBlock + MAX_BLOCK_BATCH, currentBlock);

    console.log(`🔍 Indexer querying blocks ${fromBlock} to ${toBlock} (Latest: ${currentBlock})...`);

    // 1. Query CertificateIssued events
    const issuedFilter = this.contract.filters.CertificateIssued();
    const issuedEvents = await this.contract.queryFilter(issuedFilter, fromBlock, toBlock);

    for (const event of issuedEvents) {
      if ('args' in event) {
        const [certificateIdBytes, issuer, docHash, metadataURI, issuedAt] = event.args;
        console.log(` Event: CertificateIssued [certId: ${certificateIdBytes}, tx: ${event.transactionHash}]`);

        // Find certificate in Postgres with matching hash or queued status
        const { data: certs } = await supabaseAdmin
          .from('certificates')
          .select('id, certificate_number, status')
          .eq('document_hash', docHash)
          .limit(1);

        if (certs && certs.length > 0) {
          const cert = certs[0];
          await supabaseAdmin
            .from('certificates')
            .update({
              status: cert.status === CertificateStatus.CLAIMED ? CertificateStatus.CLAIMED : CertificateStatus.ISSUED,
              tx_hash: event.transactionHash,
              block_number: event.blockNumber,
              issued_at: new Date(Number(issuedAt) * 1000).toISOString(),
            })
            .eq('id', cert.id);
        }
      }
    }

    // 2. Query CertificateRevoked events
    const revokedFilter = this.contract.filters.CertificateRevoked();
    const revokedEvents = await this.contract.queryFilter(revokedFilter, fromBlock, toBlock);

    for (const event of revokedEvents) {
      if ('args' in event) {
        const [certificateIdBytes, issuer, revokedAt, reason] = event.args;
        console.log(` Event: CertificateRevoked [certId: ${certificateIdBytes}, reason: ${reason}]`);

        // Update status in DB
        await supabaseAdmin
          .from('certificates')
          .update({
            status: CertificateStatus.REVOKED,
            revoked_at: new Date(Number(revokedAt) * 1000).toISOString(),
          })
          .eq('tx_hash', event.transactionHash);
      }
    }

    // 3. Update last processed block
    await supabaseAdmin.from('indexer_state').upsert({
      chain_id: env.CHAIN_ID,
      last_processed_block: toBlock,
      contract_address: env.CONTRACT_ADDRESS || ethers.ZeroAddress,
      updated_at: new Date().toISOString(),
    });
  }

  public stop() {
    this.isRunning = false;
  }
}

export const indexer = new BlockchainIndexer();

if (require.main === module) {
  indexer.start();
}
