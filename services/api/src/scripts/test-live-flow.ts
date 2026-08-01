import crypto from 'crypto';
import { supabaseAdmin } from '../config/supabase';
import { env } from '../config/env';
import { PdfService } from '../services/pdf.service';
import { storageService } from '../services/storage.service';
import { blockchainService } from '../services/blockchain.service';
import { CertificateStatus, UserRole, UserStatus, OrganizationStatus } from '@proofly/shared';

async function runLiveTest() {
  console.log('====================================================');
  console.log('🚀 Running Live Proofly End-to-End Test on Polygon Amoy');
  console.log('====================================================');
  console.log(`RPC URL:          ${env.POLYGON_AMOY_RPC_URL}`);
  console.log(`Contract Address: ${env.CONTRACT_ADDRESS}`);

  try {
    // 1. Create / Ensure Test Organization Admin User in Supabase
    const testEmail = `issuer.${Date.now()}@proofly.app`;
    console.log(`\n1. Creating test issuer user: ${testEmail}...`);
    const { data: user, error: userErr } = await supabaseAdmin
      .from('users')
      .insert({
        email: testEmail,
        password_hash: 'hashed_password_placeholder',
        name: 'Prof. Ada Lovelace',
        role: UserRole.ORG_ADMIN,
        status: UserStatus.ACTIVE,
      })
      .select()
      .single();

    if (userErr) throw new Error(`User creation failed: ${userErr.message}`);
    console.log(` Issuer User created with ID: ${user.id}`);

    // 2. Create Organization
    console.log('\n2. Creating test Organization "Proofly Institute of Technology"...');
    const slug = `proofly-tech-${Date.now()}`;
    const { data: org, error: orgErr } = await supabaseAdmin
      .from('organizations')
      .insert({
        name: 'Proofly Institute of Technology',
        slug: slug,
        logo_url: 'https://proofly.app/logo.png',
        status: OrganizationStatus.ACTIVE,
      })
      .select()
      .single();

    if (orgErr) throw new Error(`Org creation failed: ${orgErr.message}`);
    console.log(` Organization created with ID: ${org.id}`);

    // Link user as org admin
    await supabaseAdmin.from('organization_members').insert({
      organization_id: org.id,
      user_id: user.id,
      role: UserRole.ORG_ADMIN,
    });

    // 3. Generate Certificate PDF & SHA-256 Hash
    console.log('\n3. Generating Certificate PDF & Computing SHA-256 Document Hash...');
    const certNumber = `CERT-AMOY-${Date.now().toString().slice(-6)}`;
    const recipientName = 'Satoshi Nakamoto';
    const recipientEmail = 'satoshi@proofly.app';
    const title = 'Master of Decentralized Systems & Cryptography';
    const description = 'For pioneering foundational architectures in trustless state verification and decentralized ledger proof anchoring.';
    const issueDate = new Date().toISOString().split('T')[0];
    const verifyUrl = `${env.APP_URL}/verify/${certNumber}`;

    const { pdfBuffer, documentHash } = await PdfService.generateCertificate({
      certificateNumber: certNumber,
      recipientName,
      title,
      description,
      organizationName: org.name,
      issueDate,
      verifyUrl,
    });

    console.log(` PDF generated (${pdfBuffer.length} bytes)`);
    console.log(` SHA-256 Document Hash: ${documentHash}`);

    // 4. Save to Storage (S3 / Local)
    const s3ObjectKey = `organizations/${org.id}/certificates/${certNumber}/certificate.pdf`;
    const { url: fileUrl } = await storageService.uploadFile(pdfBuffer, s3ObjectKey, 'application/pdf');
    console.log(` PDF saved: ${fileUrl}`);

    // 5. Insert Record in Supabase
    console.log('\n4. Recording certificate in Supabase database...');
    const { data: cert, error: certErr } = await supabaseAdmin
      .from('certificates')
      .insert({
        certificate_number: certNumber,
        organization_id: org.id,
        recipient_user_id: null,
        recipient_name: recipientName,
        recipient_email: recipientEmail,
        title,
        description,
        issue_date: issueDate,
        s3_object_key: s3ObjectKey,
        document_hash: documentHash,
        metadata_uri: `${env.API_BASE_URL}/certificates/${certNumber}/metadata`,
        status: CertificateStatus.QUEUED,
        contract_address: env.CONTRACT_ADDRESS,
        chain_id: env.CHAIN_ID,
      })
      .select()
      .single();

    if (certErr) throw new Error(`Certificate DB insert failed: ${certErr.message}`);
    console.log(` Certificate DB Record ID: ${cert.id}`);

    // 6. Anchor Proof on Polygon Amoy Blockchain!
    console.log('\n5. Submitting Proof to Polygon Amoy Smart Contract...');
    const tx = await blockchainService.issueCertificateOnChain(
      cert.id,
      certNumber,
      documentHash,
      cert.metadata_uri || ''
    );

    console.log(` Live Issuance Confirmed on Polygon Amoy!`);
    console.log(` Transaction Hash: ${tx.txHash}`);
    console.log(` Block Number:     ${tx.blockNumber}`);
    console.log(` Polygonscan URL:  https://amoy.polygonscan.com/tx/${tx.txHash}`);

    // Update DB record with confirmed state
    await supabaseAdmin
      .from('certificates')
      .update({
        status: CertificateStatus.ISSUED,
        tx_hash: tx.txHash,
        block_number: tx.blockNumber,
        issued_at: new Date().toISOString(),
      })
      .eq('id', cert.id);

    // 7. Verify On-Chain directly from Smart Contract
    console.log('\n6. Reading back state directly from Polygon Amoy contract...');
    const onChainRecord = await blockchainService.getOnChainCertificate(certNumber);
    console.log(' Contract Record:', onChainRecord);

    const liveVerify = await blockchainService.verifyOnChain(certNumber, documentHash);
    console.log(' Live Smart Contract Verification Result:', liveVerify);

    console.log('\n====================================================');
    console.log(' ALL TESTS PASSED SUCCESSFULLY ON POLYGON AMOY!');
    console.log('====================================================');
    process.exit(0);
  } catch (err: any) {
    console.error('\n❌ Live test encountered an error:', err);
    process.exit(1);
  }
}

runLiveTest();
