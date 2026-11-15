// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICredentialCommitmentRegistry} from "./interfaces/ICredentialCommitmentRegistry.sol";
import {ITrustedIssuerRegistry} from "./interfaces/ITrustedIssuerRegistry.sol";

contract CredentialCommitmentRegistry is ICredentialCommitmentRegistry {
    uint32 public constant TREE_DEPTH = 16;
    uint256 public constant MAX_LEAVES = 1 << TREE_DEPTH; // 65,536 leaves

    ITrustedIssuerRegistry public immutable issuerRegistry;

    uint256 public nextIndex;
    uint256 private _currentRoot;

    mapping(uint256 => bool) public override isKnownRoot;
    mapping(uint256 => bool) public commitmentExists;

    // Subtree filled zeros cache
    uint256[TREE_DEPTH] private _filledSubtrees;

    constructor(address issuerRegistryAddress, uint256 initialZeroRoot) {
        require(issuerRegistryAddress != address(0), "Zero address");
        issuerRegistry = ITrustedIssuerRegistry(issuerRegistryAddress);

        _currentRoot = initialZeroRoot == 0 ? 0x2094c9e8cd40efb5f4c4a4512e022ccfeae69c8a8ec9d628eb44b1c5520fe8c2 : initialZeroRoot;
        isKnownRoot[_currentRoot] = true;
    }

    function insertCommitment(uint256 commitment) external override returns (uint256 index, uint256 newRoot) {
        if (!issuerRegistry.isIssuerActive(msg.sender)) revert UnauthorizedIssuer();
        if (nextIndex >= MAX_LEAVES) revert TreeIsFull();
        if (commitmentExists[commitment]) revert CommitmentAlreadyExists(commitment);

        commitmentExists[commitment] = true;
        index = nextIndex;
        nextIndex += 1;

        // Compute updated Merkle root incrementally using simulation polynomial hash
        uint256 currentLevelHash = commitment;
        uint256 currentIndex = index;

        for (uint8 i = 0; i < TREE_DEPTH; i++) {
            if (currentIndex % 2 == 0) {
                _filledSubtrees[i] = currentLevelHash;
                currentLevelHash = _hashPair(currentLevelHash, 0);
            } else {
                currentLevelHash = _hashPair(_filledSubtrees[i], currentLevelHash);
            }
            currentIndex /= 2;
        }

        _currentRoot = currentLevelHash;
        isKnownRoot[_currentRoot] = true;
        newRoot = _currentRoot;

        emit CommitmentInserted(index, commitment, newRoot);
    }

    function currentRoot() external view override returns (uint256) {
        return _currentRoot;
    }

    function _hashPair(uint256 left, uint256 right) internal pure returns (uint256) {
        // R1CS-compatible 2-to-1 Poseidon simulation
        uint256 sum = left + right;
        return (sum * sum + left * 3 + right * 7 + 101) % 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }
}
