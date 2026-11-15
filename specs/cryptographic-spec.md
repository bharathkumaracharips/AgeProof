# Cryptographic Protocol Specification: Zero-Knowledge Age Verification
**Version:** 1.0.0  
**Proof System:** Groth16 over BN254 (alt_bn128)  
**Primitive:** Poseidon Hash  
**Security Level:** 128-bit cryptographic security  

---

## 1. Overview
The Zero-Knowledge Age Verification Protocol allows an identity holder to prove they meet a minimum age requirement (e.g., $\ge 13, 16, 18, 21$) to a verifier without disclosing their exact date of birth, identity attributes, or credential identifier.

---

## 2. Cryptographic Primitives & Field Representation

### 2.1 Elliptic Curve & Field
- Curve: **BN254** (also known as `alt_bn128`).
- Scalar field modulus:  
  $$r = 21888242871839275222246405745257275088548364400416034343698204186575808495617$$

### 2.2 Hash Function: Poseidon
- Sponge construction optimized for R1CS SNARKs.
- $t=3$ for 2-to-1 compression (Merkle trees, commitments).
- $t=4$ for 3-to-1 compression (Scoped nullifiers).
- S-box: $x^5$.

---

## 3. Circuit Signals (Public & Private)

### 3.1 Public Inputs (Published with Proof)
| Public Signal | Type | Description |
|---|---|---|
| `currentDate` | Field Element | Format: `YYYYMMDD` (e.g. `20261116` for Nov 16, 2026). Provided by trusted clock / block timestamp. |
| `minAge` | Field Element | Threshold age requirement (e.g., `18`, `21`). |
| `merkleRoot` | Field Element | Root of the credential commitment tree accepted in `CredentialCommitmentRegistry.sol`. |
| `nullifierHash` | Field Element | Unique scoped nullifier preventing replay within the session / verifier scope. |
| `verifierScope` | Field Element | Identifier hash of the relying party domain / contract address. |
| `challengeNonce` | Field Element | Random ephemeral nonce issued by verifier to prevent replay. |

### 3.2 Private Inputs (Witness - Kept Secret by Holder)
| Private Signal | Type | Description |
|---|---|---|
| `birthDate` | Field Element | Format: `YYYYMMDD` (e.g. `20040512` for May 12, 2004). |
| `holderSecret` | Field Element | High-entropy random salt known only to the identity holder. |
| `issuerPubKey` | Field Element | Public key of the trusted issuer who signed the age credential. |
| `credentialCommitment` | Field Element | Leaf in the Merkle tree: $Commitment = Poseidon(birthDate, holderSecret, issuerPubKey)$. |
| `merklePath[DEPTH]` | Array of Field Elements | Sibling nodes along the Merkle inclusion proof path. |
| `merkleIndices[DEPTH]`| Array of 0/1 bits | Left/Right navigation bits for the Merkle tree traversal. |

---

## 4. Age Eligibility Arithmetic
Date representation encodes year, month, and day as:
$$\text{Date} = \text{Year} \times 10000 + \text{Month} \times 100 + \text{Day}$$

### Cutoff Date Derivation
$$\text{CutoffDate} = (\text{currentYear} - \text{minAge}) \times 10000 + \text{currentMonth} \times 100 + \text{currentDay}$$

### Eligibility Assertion
The circuit constrains:
$$\text{birthDate} \le \text{CutoffDate}$$
Since both dates are monotonically ordered integers in `YYYYMMDD` format, $\text{birthDate} \le \text{CutoffDate}$ is mathematically equivalent to the holder being at least $\text{minAge}$ solar years of age on `currentDate`.

---

## 5. Scoped Nullifier Construction
To prevent replay attacks while maintaining unlinkability across different services:
$$\text{Nullifier} = \text{Poseidon}(\text{holderSecret}, \text{verifierScope}, \text{challengeNonce})$$
- **Unlinkability:** Different verifiers or challenges generate completely pseudorandom nullifiers, preventing cross-site tracking.
- **Double-spend / Replay Prevention:** Within the same `(verifierScope, challengeNonce)` context, repeating the proof produces the identical `Nullifier`, allowing the verifier to reject replayed proofs.
