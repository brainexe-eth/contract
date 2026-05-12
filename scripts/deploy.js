const hre = require('hardhat');

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log('Deploying with account:', deployer.address);
  console.log('Network:', hre.network.name);
  console.log('');

  // Deploy MintGate (PQ verifier)
  console.log('📦 Deploying MintGate...');
  const MintGate = await hre.ethers.getContractFactory('MintGate');
  const mintGate = await MintGate.deploy();
  await mintGate.waitForDeployment();
  const mintGateAddress = await mintGate.getAddress();
  console.log('✅ MintGate deployed to:', mintGateAddress);

  // Deploy BrainEXE Token (with MintGate address)
  console.log('');
  console.log('📦 Deploying BrainEXE...');
  const BrainEXE = await hre.ethers.getContractFactory('BrainEXE');
  const token = await BrainEXE.deploy(mintGateAddress);
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log('✅ BrainEXE deployed to:', tokenAddress);

  // Deploy BrainAccount (AA Wallet) with deployer as owner
  console.log('');
  console.log('📦 Deploying BrainAccount...');
  const BrainAccount = await hre.ethers.getContractFactory('BrainAccount');
  const account = await BrainAccount.deploy(deployer.address);
  await account.waitForDeployment();
  const accountAddress = await account.getAddress();
  console.log('✅ BrainAccount deployed to:', accountAddress);

  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Deployment Summary');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('MintGate (PQ Verifier):', mintGateAddress);
  console.log('BrainEXE (Token):      ', tokenAddress);
  console.log('BrainAccount (AA):     ', accountAddress);
  console.log('Deployer:              ', deployer.address);
  console.log('Network:               ', hre.network.name);
  console.log('');
  console.log('Next steps:');
  console.log('1. Update CONTRACT_ADDRESS in frontend if token address changed');
  console.log('2. Verify contracts: npx hardhat verify --network sepolia <address> [args]');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
