// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVerifierRegistry {
    struct VerifierProfile {
        bytes32 verifierScope;     // keccak256(domain)
        string verifierName;
        string domain;
        uint8 minAllowedAge;       // Minimum age threshold verifier is allowed to request
        bool approved;
        uint64 registeredAt;
    }

    event VerifierRegistered(bytes32 indexed verifierScope, string verifierName, string domain, uint8 minAllowedAge);
    event VerifierApprovalUpdated(bytes32 indexed verifierScope, bool approved);

    error VerifierAlreadyRegistered(bytes32 verifierScope);
    error VerifierNotFound(bytes32 verifierScope);
    error VerifierNotApproved(bytes32 verifierScope);

    function registerVerifier(string calldata verifierName, string calldata domain, uint8 minAllowedAge) external returns (bytes32 verifierScope);
    function setVerifierApproval(bytes32 verifierScope, bool approved) external;
    function getVerifier(bytes32 verifierScope) external view returns (VerifierProfile memory);
    function isApprovedVerifier(bytes32 verifierScope) external view returns (bool);
}
