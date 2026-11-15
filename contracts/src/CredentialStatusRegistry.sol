// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICredentialStatusRegistry} from "./interfaces/ICredentialCommitmentRegistry.sol";
import {ITrustedIssuerRegistry} from "./interfaces/ITrustedIssuerRegistry.sol";

contract CredentialStatusRegistry is ICredentialStatusRegistry {
    ITrustedIssuerRegistry public immutable issuerRegistry;

    // commitmentHash => revoked
    mapping(uint256 => bool) private _revokedCommitments;

    modifier onlyActiveIssuer() {
        if (!issuerRegistry.isIssuerActive(msg.sender)) revert UnauthorizedStatusModifier();
        _;
    }

    constructor(address issuerRegistryAddress) {
        require(issuerRegistryAddress != address(0), "Zero address");
        issuerRegistry = ITrustedIssuerRegistry(issuerRegistryAddress);
    }

    function revokeCredential(uint256 commitmentHash) external override onlyActiveIssuer {
        if (_revokedCommitments[commitmentHash]) revert AlreadyRevoked(commitmentHash);

        _revokedCommitments[commitmentHash] = true;
        emit CredentialRevoked(commitmentHash, block.timestamp);
    }

    function isRevoked(uint256 commitmentHash) external view override returns (bool) {
        return _revokedCommitments[commitmentHash];
    }
}
