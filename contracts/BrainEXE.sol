// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IMintGate.sol";

/**
 * @title BrainEXE
 * @dev ERC-20 token with modular Post-Quantum Mint Gate (via IMintGate).
 * 65% public mint / 35% liquidity allocation.
 * 1% burn tax on every transfer (excluding mints/burns).
 * @custom:twitter https://x.com/brainexeth
 * @custom:github https://github.com/brainexe-eth
 */
contract BrainEXE is ERC20, Ownable, ReentrancyGuard {
    // Supply allocation
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant MINTABLE_SUPPLY = 650_000_000 * 10 ** 18; // 65%
    uint256 public constant LIQUIDITY_SUPPLY = 350_000_000 * 10 ** 18; // 35%

    // Pricing: 0.001 ETH = 50,000 EXE
    uint256 public constant ETH_FOR_RATE = 0.001 ether;
    uint256 public constant TOKENS_FOR_RATE = 50_000 * 10 ** 18;

    // Mint state
    bool public mintEnabled = true;
    uint256 public totalMinted;
    uint256 public maxMintPerWallet = 500_000 * 10 ** 18; // 500k EXE
    mapping(address => uint256) public mintedByWallet;

    // Post-Quantum Mint Gate (modular)
    IMintGate public immutable mintGate;
    mapping(bytes32 => bool) public usedPkHash;

    // Burn tax state
    uint256 public burnFee = 100; // 1% = 100 basis points
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant MAX_BURN_FEE = 500; // 5% max

    // Events
    event Mint(address indexed to, uint256 tokenAmount, uint256 ethAmount, uint256 epoch, bytes32 pkHash);
    event BurnTaxApplied(address indexed from, address indexed to, uint256 burnAmount);
    event BurnFeeUpdated(uint256 newFee);

    constructor(address _mintGate) ERC20("Brain EXE", "EXE") Ownable(msg.sender) {
        require(_mintGate != address(0), "MintGate cannot be zero");
        mintGate = IMintGate(_mintGate);
        _mint(msg.sender, LIQUIDITY_SUPPLY);
    }

    /**
     * @notice Mint tokens by sending ETH. Rate: 0.001 ETH = 50,000 EXE.
     */
    function mint() external payable nonReentrant {
        require(mintEnabled, "Minting is disabled");
        require(msg.value > 0, "Send ETH");

        uint256 tokenAmount = getTokensForEth(msg.value);
        require(tokenAmount > 0, "Amount too small");
        require(totalMinted + tokenAmount <= MINTABLE_SUPPLY, "Mintable supply exceeded");
        require(mintedByWallet[msg.sender] + tokenAmount <= maxMintPerWallet, "Exceeds wallet cap");

        totalMinted += tokenAmount;
        mintedByWallet[msg.sender] += tokenAmount;

        _mint(msg.sender, tokenAmount);
        emit Mint(msg.sender, tokenAmount, msg.value, 0, bytes32(0));
    }

    /**
     * @notice Mint tokens by sending ETH through the Post-Quantum Mint Gate.
     *         Rate: 0.001 ETH = 50,000 EXE.
     * @param epoch The Merkle root epoch to verify against.
     * @param recipient The address to receive minted tokens.
     * @param pkHash Hash of the PQ public key (keccak256). Anti-replay key.
     * @param merkleProof Merkle proof showing pkHash is in the approved set.
     */
    function mintWithProof(
        uint256 epoch,
        address recipient,
        bytes32 pkHash,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant {
        require(mintEnabled, "Minting is disabled");
        require(msg.value > 0, "Send ETH");
        require(recipient != address(0), "Invalid recipient");

        // Verify Post-Quantum proof via modular MintGate
        require(mintGate.verifyProof(epoch, pkHash, merkleProof), "Invalid PQ proof");

        // Anti-replay: one pkHash = one mint event
        require(!usedPkHash[pkHash], "Already minted");
        usedPkHash[pkHash] = true;

        uint256 tokenAmount = getTokensForEth(msg.value);
        require(tokenAmount > 0, "Amount too small");
        require(totalMinted + tokenAmount <= MINTABLE_SUPPLY, "Mintable supply exceeded");
        require(mintedByWallet[recipient] + tokenAmount <= maxMintPerWallet, "Exceeds wallet cap");

        totalMinted += tokenAmount;
        mintedByWallet[recipient] += tokenAmount;

        _mint(recipient, tokenAmount);
        emit Mint(recipient, tokenAmount, msg.value, epoch, pkHash);
    }

    function getTokensForEth(uint256 ethAmount) public pure returns (uint256) {
        return (ethAmount * TOKENS_FOR_RATE) / ETH_FOR_RATE;
    }

    function getEthForTokens(uint256 tokenAmount) public pure returns (uint256) {
        return (tokenAmount * ETH_FOR_RATE) / TOKENS_FOR_RATE;
    }

    // --- Burn Tax Logic ---

    function _update(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0)) {
            uint256 burnAmount = (amount * burnFee) / FEE_DENOMINATOR;
            super._update(from, address(0), burnAmount);
            super._update(from, to, amount - burnAmount);
            if (burnAmount > 0) {
                emit BurnTaxApplied(from, to, burnAmount);
            }
        } else {
            super._update(from, to, amount);
        }
    }

    // --- Owner Controls ---

    function setBurnFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAX_BURN_FEE, "Fee exceeds 5% max");
        burnFee = _fee;
        emit BurnFeeUpdated(_fee);
    }

    function toggleMint(bool _enabled) external onlyOwner {
        mintEnabled = _enabled;
    }

    function setMaxMintPerWallet(uint256 _max) external onlyOwner {
        maxMintPerWallet = _max;
    }

    /**
     * @notice Withdraw all ETH collected from minting.
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH balance");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        revert("Direct deposits not allowed, use mint()");
    }
}
