// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICredentialCommitmentRegistry {
    event CommitmentInserted(uint256 indexed index, uint256 commitment, uint256 newRoot);
    event RootInvalidated(uint256 root);

    error UnauthorizedIssuer();
    error TreeIsFull();
    error InvalidRoot(uint256 root);
    error CommitmentAlreadyExists(uint256 commitment);

    function insertCommitment(uint256 commitment) external returns (uint256 index, uint256 newRoot);
    function isKnownRoot(uint256 root) external view returns (bool);
    function currentRoot() external view returns (uint256);
}

interface ICredentialStatusRegistry {
    event CredentialRevoked(uint256 indexed commitmentHash, uint256 timestamp);
    event CredentialUnrevoked(uint256 indexed commitmentHash, uint256 timestamp);

    error AlreadyRevoked(uint256 commitmentHash);
    error NotRevoked(uint256 commitmentHash);
    error UnauthorizedStatusModifier();

    function revokeCredential(uint256 commitmentHash) external;
    function isRevoked(uint256 commitmentHash) external view returns (bool);
}

interface IAgeVerifier {
    struct ProofData {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    struct PublicInputs {
        uint256 currentDate;    // YYYYMMDD
        uint256 minAge;         // 13, 16, 18, 21
        uint256 merkleRoot;
        uint256 nullifierHash;
        uint256 verifierScope;
        uint256 challengeNonce;
    }

    event AgeVerified(
        bytes32 indexed verifierScope,
        uint256 indexed nullifierHash,
        uint256 minAge,
        uint256 timestamp
    );

    error InvalidProof();
    error NullifierAlreadyConsumed(uint256 nullifierHash);
    error UnknownMerkleRoot(uint256 merkleRoot);
    error StaleOrFutureDate(uint256 currentDate);
    error VerifierNotAuthorized(uint256 verifierScope);

    function verifyAgeEligibility(
        ProofData calldata proof,
        PublicInputs calldata inputs
    ) external returns (bool);

    function isNullifierConsumed(uint256 nullifierHash) external view returns (bool);
}
