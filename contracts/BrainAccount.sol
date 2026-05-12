// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title BrainAccount
 * @dev Simplified Account Abstraction (EIP-4337-inspired) smart contract wallet.
 *  - Programmable ownership (not bound to a single private key)
 *  - Delayed ownership changes (social recovery pattern)
 *  - Arbitrary execution (wallet can interact with any dApp)
 *  - EIP-1271 signature validation
 * @custom:twitter https://x.com/brainexeth
 * @custom:github https://github.com/brainexe-eth
 */
contract BrainAccount {
    address public owner;
    address public pendingOwner;
    uint256 public ownershipChangeTime;
    uint256 public constant OWNERSHIP_DELAY = 2 days;

    // Nonce for replay protection on signed operations
    uint256 public nonce;

    event Executed(address indexed to, uint256 value, bytes data);
    event OwnershipChangeInitiated(address indexed newOwner, uint256 effectiveTime);
    event OwnershipChanged(address indexed newOwner);
    event Received(address indexed sender, uint256 amount);

    constructor(address _owner) {
        require(_owner != address(0), "Owner cannot be zero");
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BrainAccount: not owner");
        _;
    }

    /**
     * @notice Execute an arbitrary call. Core AA functionality.
     * @param to Target contract or EOA
     * @param value ETH to send
     * @param data Calldata payload
     */
    function execute(address to, uint256 value, bytes calldata data) external onlyOwner {
        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        emit Executed(to, value, data);
    }

    /**
     * @notice Execute a batch of calls in a single transaction.
     * @param to Array of targets
     * @param value Array of ETH amounts
     * @param data Array of calldata payloads
     */
    function executeBatch(
        address[] calldata to,
        uint256[] calldata value,
        bytes[] calldata data
    ) external onlyOwner {
        require(to.length == value.length && value.length == data.length, "Length mismatch");
        for (uint256 i = 0; i < to.length; i++) {
            (bool success, bytes memory result) = to[i].call{value: value[i]}(data[i]);
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
            emit Executed(to[i], value[i], data[i]);
        }
    }

    /**
     * @notice EIP-1271 signature validation.
     * @param hash The hash of the message signed
     * @param signature The signature bytes
     * @return magicValue 0x1626ba7e if valid
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
        if (_verifySignature(hash, signature)) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }

    function _verifySignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
        if (signature.length != 65) return false;
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // Prevent malleability
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }
        address signer = ecrecover(hash, v, r, s);
        return signer == owner;
    }

    /**
     * @notice Initiate a delayed ownership change (social recovery pattern).
     * @param newOwner The proposed new owner
     */
    function initiateOwnershipChange(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero");
        pendingOwner = newOwner;
        ownershipChangeTime = block.timestamp + OWNERSHIP_DELAY;
        emit OwnershipChangeInitiated(newOwner, ownershipChangeTime);
    }

    /**
     * @notice Confirm the ownership change after the delay has passed.
     *         Can only be called by the pending owner.
     */
    function confirmOwnershipChange() external {
        require(msg.sender == pendingOwner, "BrainAccount: not pending owner");
        require(block.timestamp >= ownershipChangeTime, "BrainAccount: delay not passed");
        owner = pendingOwner;
        pendingOwner = address(0);
        ownershipChangeTime = 0;
        emit OwnershipChanged(owner);
    }

    /**
     * @notice Cancel a pending ownership change.
     */
    function cancelOwnershipChange() external onlyOwner {
        pendingOwner = address(0);
        ownershipChangeTime = 0;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}
