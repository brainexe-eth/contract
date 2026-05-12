const hre = require('hardhat');

/**
 * Owner-only script to update deployed contract state.
 * Run: npx hardhat run scripts/update-contract.js --network sepolia
 */
async function main() {
  const [owner] = await hre.ethers.getSigners();
  console.log('Updating with owner:', owner.address);

  // ─── CONFIG: paste your deployed addresses here ───
  const MINTGATE_ADDRESS = '0x0cC079203B0cEF078Cc1bf9b321362F8678b22FB';
  const BRAINEXE_ADDRESS = '0x222d7cBc17Ef9f6778DA1A1Ecf40d5B3ff484719';

  const MintGate = await hre.ethers.getContractAt('MintGate', MINTGATE_ADDRESS);
  const BrainEXE = await hre.ethers.getContractAt('BrainEXE', BRAINEXE_ADDRESS);

  // ─── 1. Update Merkle Root on MintGate ───
  // Replace with your computed Merkle root (bytes32 hex)
  const EPOCH = 0;
  const MERKLE_ROOT = '0x0000000000000000000000000000000000000000000000000000000000000000';

  if (MERKLE_ROOT !== '0x0000000000000000000000000000000000000000000000000000000000000000') {
    console.log(`\n📦 Updating Merkle Root for epoch ${EPOCH}...`);
    const tx1 = await MintGate.updateMerkleRoot(EPOCH, MERKLE_ROOT);
    await tx1.wait();
    console.log('✅ Merkle root updated:', MERKLE_ROOT);
  } else {
    console.log('\n⚠️ Skipped Merkle root update (placeholder detected).');
    console.log('   Set MERKLE_ROOT to your actual root before running this script.');
  }

  // ─── 2. Update BrainEXE Settings ───
  // Uncomment and modify as needed:

  // const BURN_FEE = 100; // 1% = 100 basis points
  // console.log(`\n📦 Setting burn fee to ${BURN_FEE} bps...`);
  // const tx2 = await BrainEXE.setBurnFee(BURN_FEE);
  // await tx2.wait();
  // console.log('✅ Burn fee updated');

  // const MAX_MINT = hre.ethers.parseEther('500000'); // 500k EXE
  // console.log('\n📦 Setting max mint per wallet...');
  // const tx3 = await BrainEXE.setMaxMintPerWallet(MAX_MINT);
  // await tx3.wait();
  // console.log('✅ Max mint per wallet updated');

  // const MINT_ENABLED = true;
  // console.log('\n📦 Toggling mint...');
  // const tx4 = await BrainEXE.toggleMint(MINT_ENABLED);
  // await tx4.wait();
  // console.log('✅ Mint toggled:', MINT_ENABLED);

  // ─── Read current state ───
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Current Contract State');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('MintGate merkleRoots(0):', await MintGate.merkleRoots(0));
  console.log('BrainEXE mintEnabled:  ', await BrainEXE.mintEnabled());
  console.log('BrainEXE burnFee:      ', (await BrainEXE.burnFee()).toString(), 'bps');
  console.log('BrainEXE maxMint:      ', hre.ethers.formatEther(await BrainEXE.maxMintPerWallet()), 'EXE');
  console.log('BrainEXE totalMinted:  ', hre.ethers.formatEther(await BrainEXE.totalMinted()), 'EXE');
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
