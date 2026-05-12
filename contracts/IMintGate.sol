// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMintGate
 * @dev Interface for a modular Merkle-proof verification contract.
 *      Used by BrainEXE to enforce the Post-Quantum Mint Gate off-chain.
 */
interface IMintGate {
    /**
     * @notice Verify a Merkle proof against a stored root for a given epoch.
     * @param epoch The epoch / round number of the Merkle root.
     * @param leaf The leaf hash to prove inclusion of.
     * @param merkleProof Array of sibling hashes forming the proof path.
     * @return True if the proof is valid for the epoch's root.
     */
    function verifyProof(
        uint256 epoch,
        bytes32 leaf,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    /**
     * @notice Get the Merkle root for a specific epoch.
     * @param epoch The epoch number.
     * @return The stored Merkle root (bytes32(0) if not set).
     */
    function merkleRoots(uint256 epoch) external view returns (bytes32);
}
