// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IMintGate.sol";

/**
 * @title MintGate
 * @dev Modular Merkle-proof verifier for the Brain EXE Post-Quantum Mint Gate.
 *      Stores Merkle roots per epoch. Owner publishes new roots off-chain.
 */
contract MintGate is IMintGate, Ownable {
    mapping(uint256 => bytes32) public merkleRoots;

    event MerkleRootUpdated(uint256 indexed epoch, bytes32 root);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Publish or update a Merkle root for a given epoch.
     * @param epoch The epoch / round number.
     * @param root The new Merkle root.
     */
    function updateMerkleRoot(uint256 epoch, bytes32 root) external onlyOwner {
        merkleRoots[epoch] = root;
        emit MerkleRootUpdated(epoch, root);
    }

    /**
     * @notice Verify a Merkle proof against the stored root for an epoch.
     * @param epoch The epoch to verify against.
     * @param leaf The leaf hash.
     * @param merkleProof The Merkle proof path.
     * @return valid True if the proof verifies against the stored root.
     */
    function verifyProof(
        uint256 epoch,
        bytes32 leaf,
        bytes32[] calldata merkleProof
    ) external view returns (bool valid) {
        bytes32 root = merkleRoots[epoch];
        if (root == bytes32(0)) return false;
        return MerkleProof.verify(merkleProof, root, leaf);
    }
}
