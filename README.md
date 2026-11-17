# AgeProof: Zero-Knowledge Age Eligibility Verification

![Groth16 BN254](https://img.shields.io/badge/ZK--SNARK-Groth16%20%7C%20BN254-purple?style=for-the-badge)
![Circom](https://img.shields.io/badge/Circuit-Circom%202.1-yellow?style=for-the-badge)
![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=for-the-badge&logo=solidity)
![Foundry](https://img.shields.io/badge/Foundry-Framework-orange?style=for-the-badge)
![Rust](https://img.shields.io/badge/Rust-Axum%20Backend-black?style=for-the-badge&logo=rust)
![Next.js](https://img.shields.io/badge/Next.js-14%20App%20Router-black?style=for-the-badge&logo=next.js)

Prove eligibility for age-restricted services ($\ge 13, 16, 18, 21$) **without revealing an exact birth date**, identity attributes, or personal identifiers.

---

## 1. System Overview & Architecture

```
                                +-----------------------------------------------+
                                |          ON-CHAIN REGISTRIES & VERIFIER       |
                                |  TrustedIssuerRegistry   |  VerifierRegistry  |
                                |  CommitmentRegistry      |  AgeVerifier.sol   |
                                +-----------------------------------------------+
                                           ^                             ^
                                           | 1. Anchors Commitments      | 4. Submits Proof
                                           |    into Merkle Tree         |    & Nullifier
                 +-------------------------+                             +-----------------------+
                 |                                                                               |
       +---------v---------+                                                           +---------v---------+
       |  TRUSTED ISSUER   |                                                           | AGE VERIFIER      |
       | (Gov, Bank, DMV)  |                                                           | (Relying Party)   |
       +---------+---------+                                                           +---------+---------+
                 |                                                                               ^
                 | 2. Issues Signed Credential                                                   | 3. Verifier Challenge
                 |    Witness: birthDate, salt                                                   |    (Scope + Nonce)
                 v                                                                               |
       +-----------------------------------------------------------------------------------------+---------+
       |                                      IDENTITY HOLDER                                              |
       |                   Client-Side Prover (Browser snarkjs / Web Worker)                               |
       |                   Encrypted Local Storage: birthDate, holderSecret                                |
       |                   Computes: birthDate <= CutoffDate(currentDate, minAge)                          |
       |                   Generates: Scoped Nullifier = Poseidon(secret, scope, nonce)                    |
       +---------------------------------------------------------------------------------------------------+
```

---

## 2. Directory Structure

```
AgeProof/
├── circuits/                   # Circom ZK circuits & R1CS templates
│   ├── AgeVerification.circom  # Master Groth16 circuit for age verification
│   ├── DateComparison.circom   # Calendar arithmetic & integer range comparison
│   └── PoseidonMerkle.circom   # Merkle tree inclusion proof template
├── contracts/                  # Foundry Solidity smart contracts
│   ├── src/
│   │   ├── interfaces/         # Standard interfaces
│   │   ├── TrustedIssuerRegistry.sol        # Issuer whitelist & public keys
│   │   ├── VerifierRegistry.sol             # Relying party domain approval
│   │   ├── CredentialCommitmentRegistry.sol # Incremental Merkle tree
│   │   ├── CredentialStatusRegistry.sol     # Credential revocation tracking
│   │   ├── Groth16Verifier.sol              # BN254 pairing check
│   │   └── AgeVerifier.sol                  # Master verification contract
│   ├── test/                   # Unit & invariant test suites
│   ├── script/Deploy.s.sol     # Automated deployment script
│   └── foundry.toml
├── backend/                    # Rust backend workspace (Axum + Tokio)
│   ├── Cargo.toml
│   └── crates/
│       ├── zk-core/            # Date logic, Poseidon hashing, witness builder
│       └── server/             # REST API for issuance, challenges, verification
├── packages/sdk-ts/            # TypeScript SDK (@zk-age/sdk)
├── frontend/                   # Next.js 14 App Router interactive UI
└── specs/                      # Cryptographic specifications & threat models
    ├── cryptographic-spec.md   # BN254 Groth16, Poseidon hash, circuit inputs
    ├── architecture.md         # System design and protocol trust boundaries
    └── threat-model.md         # Invariants, anti-replay, and boundary security
```

---

## 3. Cryptographic Specification

### 3.1 Date Arithmetic
Date representation encodes year, month, and day into integer `YYYYMMDD`:
$$\text{CutoffDate} = (\text{currentYear} - \text{minAge}) \times 10000 + \text{currentMonth} \times 100 + \text{currentDay}$$
The circuit enforces:
$$\text{birthDate} \le \text{CutoffDate}$$

### 3.2 Scoped Nullifier (Anti-Replay & Unlinkability)
$$\text{Nullifier} = \text{Poseidon}(\text{holderSecret}, \text{verifierScope}, \text{challengeNonce})$$
- **Unlinkability:** Unique per verifier domain and challenge; prevents cross-service tracking.
- **Anti-Replay:** Submitting the proof twice within the same challenge context yields an identical nullifier, which the smart contract rejects.

---

## 4. Quickstart Guide

### 4.1 Smart Contracts (Foundry)
```bash
cd contracts
forge test
forge script script/Deploy.s.sol --broadcast
```

### 4.2 Rust Backend API
```bash
cd backend
cargo run -p server
# API available at http://localhost:8081
```

### 4.3 Next.js Frontend
```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000 to launch the ZK Prover and Verifier Portal
```

---

## 5. Critical Invariants
- `INV-1`: The holder's exact `birthDate` is **never** revealed as a public proof input.
- `INV-2`: A proof is valid if and only if $\text{birthDate} \le \text{CutoffDate}$.
- `INV-3`: Credential commitments must be anchored in an accepted Merkle root.
- `INV-4`: Nullifiers can only be consumed once per `(verifierScope, challengeNonce)`.
- `INV-5`: Revoked credentials fail validation via `CredentialStatusRegistry.sol`.
