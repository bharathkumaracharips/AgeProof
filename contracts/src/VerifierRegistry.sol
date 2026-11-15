// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IVerifierRegistry} from "./interfaces/IVerifierRegistry.sol";

contract VerifierRegistry is IVerifierRegistry {
    address public admin;

    mapping(bytes32 => VerifierProfile) private _verifiers;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address initialAdmin) {
        admin = initialAdmin == address(0) ? msg.sender : initialAdmin;
    }

    function registerVerifier(
        string calldata verifierName,
        string calldata domain,
        uint8 minAllowedAge
    ) external override returns (bytes32 verifierScope) {
        verifierScope = keccak256(abi.encodePacked(domain));
        if (_verifiers[verifierScope].registeredAt != 0) {
            revert VerifierAlreadyRegistered(verifierScope);
        }

        _verifiers[verifierScope] = VerifierProfile({
            verifierScope: verifierScope,
            verifierName: verifierName,
            domain: domain,
            minAllowedAge: minAllowedAge,
            approved: false, // Requires admin approval
            registeredAt: uint64(block.timestamp)
        });

        emit VerifierRegistered(verifierScope, verifierName, domain, minAllowedAge);
    }

    function setVerifierApproval(bytes32 verifierScope, bool approved) external override onlyAdmin {
        if (_verifiers[verifierScope].registeredAt == 0) revert VerifierNotFound(verifierScope);
        _verifiers[verifierScope].approved = approved;

        emit VerifierApprovalUpdated(verifierScope, approved);
    }

    function getVerifier(bytes32 verifierScope) external view override returns (VerifierProfile memory) {
        VerifierProfile memory profile = _verifiers[verifierScope];
        if (profile.registeredAt == 0) revert VerifierNotFound(verifierScope);
        return profile;
    }

    function isApprovedVerifier(bytes32 verifierScope) external view override returns (bool) {
        return _verifiers[verifierScope].approved;
    }
}
