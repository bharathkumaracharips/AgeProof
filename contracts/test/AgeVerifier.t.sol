// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TrustedIssuerRegistry} from "../src/TrustedIssuerRegistry.sol";
import {VerifierRegistry} from "../src/VerifierRegistry.sol";
import {CredentialCommitmentRegistry} from "../src/CredentialCommitmentRegistry.sol";
import {CredentialStatusRegistry} from "../src/CredentialStatusRegistry.sol";
import {Groth16Verifier} from "../src/Groth16Verifier.sol";
import {AgeVerifier} from "../src/AgeVerifier.sol";
import {IAgeVerifier} from "../src/interfaces/ICredentialCommitmentRegistry.sol";
import {ITrustedIssuerRegistry} from "../src/interfaces/ITrustedIssuerRegistry.sol";

contract AgeVerifierTest {
    TrustedIssuerRegistry private issuerReg;
    VerifierRegistry private verifierReg;
    CredentialCommitmentRegistry private commitReg;
    CredentialStatusRegistry private statusReg;
    Groth16Verifier private groth16;
    AgeVerifier private ageVerifier;

    bytes32 private verifierScope;

    function setUp() public {
        issuerReg = new TrustedIssuerRegistry(address(this));
        verifierReg = new VerifierRegistry(address(this));
        commitReg = new CredentialCommitmentRegistry(address(issuerReg), 0);
        statusReg = new CredentialStatusRegistry(address(issuerReg));
        groth16 = new Groth16Verifier();

        ageVerifier = new AgeVerifier(
            address(groth16),
            address(commitReg),
            address(statusReg),
            address(verifierReg)
        );

        // Register and approve issuer
        issuerReg.registerIssuer("State Identity Authority", 111, 222);
        issuerReg.setIssuerStatus(address(this), ITrustedIssuerRegistry.IssuerStatus.Active);

        // Register and approve verifier
        verifierScope = verifierReg.registerVerifier("Test Service", "test.example.com", 18);
        verifierReg.setVerifierApproval(verifierScope, true);
    }

    function testSuccessfulVerificationAndNullifierConsumption() public {
        // Insert commitment
        uint256 commitment = 1234567890;
        (, uint256 root) = commitReg.insertCommitment(commitment);

        uint256 nullifier = 999888777;
        uint256 challenge = 555444333;

        IAgeVerifier.ProofData memory proof = IAgeVerifier.ProofData({
            a: [uint256(1), uint256(2)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(7), uint256(8)]
        });

        IAgeVerifier.PublicInputs memory inputs = IAgeVerifier.PublicInputs({
            currentDate: 20261116,
            minAge: 18,
            merkleRoot: root,
            nullifierHash: nullifier,
            verifierScope: uint256(verifierScope),
            challengeNonce: challenge
        });

        bool success = ageVerifier.verifyAgeEligibility(proof, inputs);
        require(success, "Verification must succeed");
        require(ageVerifier.isNullifierConsumed(nullifier), "Nullifier must be marked consumed");

        // Attempt replay with identical nullifier should revert
        bool replayedFailed = false;
        try ageVerifier.verifyAgeEligibility(proof, inputs) {
            // Should fail
        } catch {
            replayedFailed = true;
        }
        require(replayedFailed, "Replay attack must fail");
    }

    function testUnknownMerkleRootReverts() public {
        uint256 fakeRoot = 99999999999999999999999;

        IAgeVerifier.ProofData memory proof = IAgeVerifier.ProofData({
            a: [uint256(1), uint256(2)],
            b: [[uint256(3), uint256(4)], [uint256(5), uint256(6)]],
            c: [uint256(7), uint256(8)]
        });

        IAgeVerifier.PublicInputs memory inputs = IAgeVerifier.PublicInputs({
            currentDate: 20261116,
            minAge: 21,
            merkleRoot: fakeRoot,
            nullifierHash: 111222333,
            verifierScope: uint256(verifierScope),
            challengeNonce: 444555
        });

        bool failed = false;
        try ageVerifier.verifyAgeEligibility(proof, inputs) {
        } catch {
            failed = true;
        }
        require(failed, "Unknown Merkle root must revert");
    }
}
