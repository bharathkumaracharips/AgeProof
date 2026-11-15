# System Architecture: Privacy-Preserving Age Eligibility Protocol

## 1. System Participants & Interaction Model

```
       +-------------------------------------------------------------+
       |                  ON-CHAIN TRUST & REGISTRIES                |
       |  TrustedIssuerRegistry  |  CredentialCommitmentRegistry     |
       |  CredentialStatusReg    |  AgeVerifier (Groth16 + Logic)    |
       +-------------------------------------------------------------+
                 ^                                            ^
                 | 1. Registers Commitments                   | 4. Submits Proof
                 |                                            |    (On-chain)
       +---------+----------+                      +----------+----------+
       |  TRUSTED ISSUER    |                      | CREDENTIAL VERIFIER |
       | (Gov, Bank, DMV)   |                      | (e-Commerce, Game,  |
       +---------+----------+                      |  Nightclub, Social) |
                 |                                 +----------+----------+
                 | 2. Issues Signed                           ^
                 |    Credential Witness                      | 3. Verifier Challenge
                 v                                            |    & Age Policy
       +------------------------------------------------------+----------+
       |                       IDENTITY HOLDER                           |
       |     Client-Side Prover (Browser snarkjs / Web Worker)           |
       |     Private Storage: Encrypted birthDate, holderSecret          |
       |     Witness Calculation -> Groth16 Prover -> ZK Proof           |
       +-----------------------------------------------------------------+
```

### Steps in Protocol Flow:
1. **Issuer Registration & Key Publishing:** Trusted issuers are approved in `TrustedIssuerRegistry.sol`.
2. **Credential Issuance:** Holder verifies real-world age with Issuer (e.g. government ID). The Issuer constructs the Poseidon commitment:
   $$\text{commitment} = \text{Poseidon}(\text{birthDate}, \text{holderSecret}, \text{issuerPubKey})$$
   The commitment is inserted into `CredentialCommitmentRegistry.sol` (Merkle tree).
3. **Verification Request:** Relying party generates an ephemeral `challengeNonce` with a requested threshold (e.g., $\text{minAge} = 21$) and target `verifierScope`.
4. **ZK Proof Generation:** The holder's browser creates a Groth16 proof using the Circom WASM witness generator. The proof proves:
   - The holder knows `birthDate` and `holderSecret` such that `commitment` is in the Merkle tree with root `merkleRoot`.
   - `birthDate <= CutoffDate(currentDate, minAge)`.
   - `nullifierHash = Poseidon(holderSecret, verifierScope, challengeNonce)`.
   - **Crucially:** `birthDate` and `holderSecret` are private witness inputs and never leave the user's browser.
5. **Verification:** The verifier (either off-chain via Rust service or on-chain via `AgeVerifier.sol`) validates the proof against the verification key, checks the Merkle root is valid, and consumes the nullifier.
