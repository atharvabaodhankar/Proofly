import app from './app';
import { env } from './config/env';
import { indexer } from './indexer/worker';

const server = app.listen(env.PORT, () => {
  console.log('==============================================');
  console.log(`🚀 Proofly API Server listening on port ${env.PORT}`);
  console.log(`🌐 Base URL: ${env.API_BASE_URL}`);
  console.log(`⛓️  Blockchain: ${env.NETWORK_NAME} (Chain ID: ${env.CHAIN_ID})`);
  console.log(`📦 Storage: ${env.STORAGE_PROVIDER}`);
  console.log('==============================================');

  // Start background indexer if contract address is provided
  if (env.CONTRACT_ADDRESS) {
    indexer.start();
  }
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  indexer.stop();
  server.close(() => {
    console.log('HTTP server closed');
  });
});
