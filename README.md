# Brain EXE Contracts

> Solidity smart contracts for Brain EXE — post-quantum ERC-20 token with modular mint gate.

## Contracts

### BrainEXE.sol
Main ERC-20 token contract with fair-launch minting and deflationary burn tax.

| Parameter | Value |
|-----------|-------|
| Token Name | Brain EXE |
| Symbol | $EXE |
| Decimals | 18 |
| Max Supply | 1,000,000,000 EXE |
| Public Mint | 650,000,000 EXE (65%) |
| Liquidity Pool | 350,000,000 EXE (35%) |
| Mint Rate | 0.001 ETH = 50,000 EXE |
| Max Mint per Wallet | 500,000 EXE |
| Transfer Burn Fee | 1% (100 bps) |
| Max Burn Fee | 5% (500 bps) |
| Solidity | 0.8.28 |

**Key Functions:**
- `mint()` — Public mint with ETH at fixed rate
- `mintWithProof()` — Post-quantum gated mint via Merkle proof
- `setBurnFee()` — Owner: update burn fee (max 5%)
- `toggleMint()` — Owner: enable/disable minting
- `withdraw()` — Owner: withdraw collected ETH

### BrainAccount.sol
Simplified account abstraction wallet (EIP-4337-inspired).

**Features:**
- Arbitrary call execution (`execute`, `executeBatch`)
- EIP-1271 signature validation
- Delayed ownership change with 2-day timelock (social recovery)

### MintGate.sol
Modular Merkle-proof verifier for the Post-Quantum Mint Gate.

**Features:**
- Epoch-based Merkle root storage
- Owner publishes roots off-chain
- On-chain proof verification via OpenZeppelin MerkleProof

### IMintGate.sol
Interface for modular mint gate verification.

## Project Structure

```
contracts/
├── BrainEXE.sol       # Main ERC-20 token
├── BrainAccount.sol   # Smart contract wallet (AA)
├── MintGate.sol       # Merkle verifier
└── IMintGate.sol      # Interface
hardhat.config.js
```

## Getting Started

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia
```

## Networks

| Network | Chain ID | Config |
|---------|----------|--------|
| Hardhat | 1337 | Local testing |
| Sepolia | 11155111 | Testnet |
| Mainnet | 1 | Production |

## Environment Variables

Create `.env`:

```env
PRIVATE_KEY=your_private_key
SEPOLIA_RPC=https://rpc.sepolia.org
MAINNET_RPC=https://eth.llamarpc.com
ETHERSCAN_API_KEY=your_etherscan_key
```

## License

MIT
