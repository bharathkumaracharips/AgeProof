// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TrustedIssuerRegistry} from "../src/TrustedIssuerRegistry.sol";
import {VerifierRegistry} from "../src/VerifierRegistry.sol";
import {CredentialCommitmentRegistry} from "../src/CredentialCommitmentRegistry.sol";
import {CredentialStatusRegistry} from "../src/CredentialStatusRegistry.sol";
import {Groth16Verifier} from "../src/Groth16Verifier.sol";
import {AgeVerifier} from "../src/AgeVerifier.sol";
import {ITrustedIssuerRegistry} from "../src/interfaces/ITrustedIssuerRegistry.sol";

contract DeployScript {
    struct DeploymentResult {
        address issuerRegistry;
        address verifierRegistry;
        address commitmentRegistry;
        address statusRegistry;
        address groth16Verifier;
        address ageVerifier;
    }

    function run() external returns (DeploymentResult memory result) {
        address deployer = msg.sender;

        // 1. Deploy Registries
        TrustedIssuerRegistry issuerReg = new TrustedIssuerRegistry(deployer);
        VerifierRegistry verifierReg = new VerifierRegistry(deployer);

        // 2. Deploy Commitment & Status Registries
        CredentialCommitmentRegistry commitReg = new CredentialCommitmentRegistry(address(issuerReg), 0);
        CredentialStatusRegistry statusReg = new CredentialStatusRegistry(address(issuerReg));

        // 3. Deploy Groth16 Verifier & AgeVerifier
        Groth16Verifier groth16 = new Groth16Verifier();
        AgeVerifier ageVerifier = new AgeVerifier(
            address(groth16),
            address(commitReg),
            address(statusReg),
            address(verifierReg)
        );

        // 4. Seed initial trusted issuer (DMV / Identity Authority)
        issuerReg.registerIssuer("Department of Motor Vehicles Identity Bureau", 123456789, 987654321);
        issuerReg.setIssuerStatus(deployer, ITrustedIssuerRegistry.IssuerStatus.Active);

        // 5. Seed initial verifier organization (Age-Restricted Entertainment Portal)
        bytes32 verifierScope = verifierReg.registerVerifier("Apex Nightlife & Gaming", "apex.gaming.network", 21);
        verifierReg.setVerifierApproval(verifierScope, true);

        result = DeploymentResult({
            issuerRegistry: address(issuerReg),
            verifierRegistry: address(verifierReg),
            commitmentRegistry: address(commitReg),
            statusRegistry: address(statusReg),
            groth16Verifier: address(groth16),
            ageVerifier: address(ageVerifier)
        });
    }
}
