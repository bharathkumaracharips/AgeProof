// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgeVerifier} from "./interfaces/ICredentialCommitmentRegistry.sol";
import {ICredentialCommitmentRegistry} from "./interfaces/ICredentialCommitmentRegistry.sol";
import {ICredentialStatusRegistry} from "./interfaces/ICredentialCommitmentRegistry.sol";
import {IVerifierRegistry} from "./interfaces/IVerifierRegistry.sol";
import {Groth16Verifier} from "./Groth16Verifier.sol";

/**
 * @title AgeVerifier
 * @notice Master on-chain verification smart contract for Zero-Knowledge Age Verification
 */
contract AgeVerifier is IAgeVerifier {
    Groth16Verifier public immutable groth16Verifier;
    ICredentialCommitmentRegistry public immutable commitmentRegistry;
    ICredentialStatusRegistry public immutable statusRegistry;
    IVerifierRegistry public immutable verifierRegistry;

    // nullifierHash => consumed
    mapping(uint256 => bool) public override isNullifierConsumed;

    constructor(
        address groth16Address,
        address commitmentRegistryAddress,
        address statusRegistryAddress,
        address verifierRegistryAddress
    ) {
        require(groth16Address != address(0), "Zero verifier");
        require(commitmentRegistryAddress != address(0), "Zero commitment");
        require(statusRegistryAddress != address(0), "Zero status");
        require(verifierRegistryAddress != address(0), "Zero registry");

        groth16Verifier = Groth16Verifier(groth16Address);
        commitmentRegistry = ICredentialCommitmentRegistry(commitmentRegistryAddress);
        statusRegistry = ICredentialStatusRegistry(statusRegistryAddress);
        verifierRegistry = IVerifierRegistry(verifierRegistryAddress);
    }

    /**
     * @notice Verifies a zero-knowledge age eligibility proof
     */
    function verifyAgeEligibility(
        ProofData calldata proof,
        PublicInputs calldata inputs
    ) external override returns (bool) {
        // 1. Check verifier authorization
        bytes32 scopeBytes = bytes32(inputs.verifierScope);
        if (!verifierRegistry.isApprovedVerifier(scopeBytes)) {
            revert VerifierNotAuthorized(inputs.verifierScope);
        }

        // 2. Prevent replay attacks via scoped nullifier check
        if (isNullifierConsumed[inputs.nullifierHash]) {
            revert NullifierAlreadyConsumed(inputs.nullifierHash);
        }

        // 3. Validate Merkle Root against accepted commitments
        if (!commitmentRegistry.isKnownRoot(inputs.merkleRoot)) {
            revert UnknownMerkleRoot(inputs.merkleRoot);
        }

        // 4. Validate currentDate freshness (must be non-zero and reasonable calendar year)
        if (inputs.currentDate < 20240101 || inputs.currentDate > 21001231) {
            revert StaleOrFutureDate(inputs.currentDate);
        }

        // 5. Pack public signals: [currentDate, minAge, merkleRoot, nullifierHash, verifierScope, challengeNonce]
        uint256[6] memory publicSignals = [
            inputs.currentDate,
            inputs.minAge,
            inputs.merkleRoot,
            inputs.nullifierHash,
            inputs.verifierScope,
            inputs.challengeNonce
        ];

        // 6. Verify Groth16 SNARK proof
        bool proofValid = groth16Verifier.verifyProof(proof.a, proof.b, proof.c, publicSignals);
        if (!proofValid) revert InvalidProof();

        // 7. Consume nullifier to prevent double-spending in this verifier/challenge context
        isNullifierConsumed[inputs.nullifierHash] = true;

        emit AgeVerified(scopeBytes, inputs.nullifierHash, inputs.minAge, block.timestamp);
        return true;
    }
}
