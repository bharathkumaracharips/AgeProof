# Threat Model & Security Invariants

## 1. Threat Vectors and Mitigations

| Threat Vector | Attack Scenario | Protocol Mitigation |
|---|---|---|
| **Birthday Boundary Bypass** | User turns 21 tomorrow and attempts to prove eligibility today | Monotonic arithmetic date comparison `YYYYMMDD <= CutoffDate` guarantees exact day-level precision; boundary dates fail the inequality constraint. |
| **Leap-Year Edge Cases** | Born on Feb 29; year increment arithmetic causes overflows or invalid dates | Integer `YYYYMMDD` ordering avoids calendar math traps in circuit. Feb 29, 2004 (`20040229`) compares correctly against Feb 28 (`20250228`) and March 1 (`20250301`). |
| **Proof Replay Attack** | Malicious party intercepts Alice's ZK proof and submits it to another verifier | The proof binds `verifierScope` and `challengeNonce`. Any replayed proof to another verifier or session fails either the domain check or the consumed nullifier check. |
| **Cross-Service Tracking** | Two verifiers collude to match proof submissions and identify the same user across platforms | The nullifier is scoped with `verifierScope`. Because `verifierScope` differs per verifier, the resulting nullifiers are computationally indistinguishable from random field elements. |
| **Credential Forgery** | Attacker invents a fake birth date and secret | The circuit verifies Merkle inclusion of `commitment = Poseidon(birthDate, holderSecret, issuerPubKey)` against the on-chain registry's accepted roots. |
| **Revoked Credential Usage** | User's age credential was revoked due to DMV fraud or identity theft | On-chain and off-chain verifiers check the commitment against `CredentialStatusRegistry.sol`; revoked commitments are removed or flagged in the accumulator. |
| **Unconstrained Witness Attack** | Malicious prover manipulates intermediate circuit signals | Every intermediate variable in the Circom circuit is strictly constrained with quadratic rank-1 constraints ($R1CS$). |

---

## 2. Protocol Invariants
1. `INV-1`: The holder's exact `birthDate` is **never** revealed as a public signal in any proof.
2. `INV-2`: A proof is valid if and only if the underlying `birthDate` satisfies $\text{Age} \ge \text{minAge}$ on the specified `currentDate`.
3. `INV-3`: Credential commitments can only be accepted if anchored in a valid, unrevoked Merkle root in `CredentialCommitmentRegistry.sol`.
4. `INV-4`: Each nullifier can only be consumed once per `(verifierScope, challengeNonce)`.
5. `INV-5`: No private key, plaintext birth date, or holder secret is ever written to the blockchain or sent to backend servers.
