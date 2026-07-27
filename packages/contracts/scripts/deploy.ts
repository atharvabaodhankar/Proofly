import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log("==========================================");
  console.log("Proofly Smart Contract Deployment");
  console.log("==========================================");
  console.log(`Network Name:  ${network.name}`);
  console.log(`Chain ID:      ${network.chainId}`);
  console.log(`Deployer:      ${deployer ? deployer.address : "None"}`);

  if (deployer) {
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log(`Deployer POL:  ${ethers.formatEther(balance)} POL`);
  }

  console.log("\nDeploying CertificateRegistry...");
  const CertificateRegistry = await ethers.getContractFactory("CertificateRegistry");
  const registry = await CertificateRegistry.deploy(deployer ? deployer.address : ethers.ZeroAddress);
  await registry.waitForDeployment();

  const contractAddress = await registry.getAddress();
  const deploymentTx = registry.deploymentTransaction();

  console.log("\n Contract Deployed Successfully!");
  console.log(`Contract Address: ${contractAddress}`);
  if (deploymentTx) {
    console.log(`Deployment Tx:    ${deploymentTx.hash}`);
  }

  // Export contract info for backend services
  const deploymentData = {
    network: network.name,
    chainId: Number(network.chainId),
    address: contractAddress,
    deployer: deployer ? deployer.address : "",
    deploymentTx: deploymentTx ? deploymentTx.hash : "",
    deployedAt: new Date().toISOString(),
  };

  const exportDir = path.resolve(__dirname, "../deployments");
  if (!fs.existsSync(exportDir)) {
    fs.mkdirSync(exportDir, { recursive: true });
  }

  const exportFile = path.join(exportDir, `${network.chainId === 80002n ? "amoy" : network.name}.json`);
  fs.writeFileSync(exportFile, JSON.stringify(deploymentData, null, 2));
  console.log(`Deployment data saved to: ${exportFile}`);

  // Also sync ABI to shared/api directory
  const artifactPath = path.resolve(__dirname, "../artifacts/contracts/CertificateRegistry.sol/CertificateRegistry.json");
  if (fs.existsSync(artifactPath)) {
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    const abiExportPath = path.resolve(__dirname, "../../../services/api/src/config/CertificateRegistryABI.json");
    const abiDir = path.dirname(abiExportPath);
    if (!fs.existsSync(abiDir)) {
      fs.mkdirSync(abiDir, { recursive: true });
    }
    fs.writeFileSync(abiExportPath, JSON.stringify(artifact.abi, null, 2));
    console.log(`ABI exported to backend: ${abiExportPath}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
