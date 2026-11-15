pragma circom 2.1.6;

include "./DateComparison.circom";
include "./PoseidonMerkle.circom";

/**
 * @title AgeVerification
 * @notice Proves that a credential holder satisfies `birthDate <= Cutoff(currentDate, minAge)`
 * without disclosing their exact birthDate or identity attributes.
 */
template AgeVerification(merkleDepth) {
    // ------------------------------------------------------------------------
    // 1. PUBLIC SIGNALS
    // ------------------------------------------------------------------------
    signal input currentDate;       // YYYYMMDD (e.g. 20261116)
    signal input minAge;            // Threshold age (e.g. 18, 21)
    signal input merkleRoot;        // Merkle root of valid credential commitments
    signal input nullifierHash;     // Scoped nullifier for replay protection
    signal input verifierScope;     // Relying party domain/contract hash
    signal input challengeNonce;    // Ephemeral verifier nonce

    // ------------------------------------------------------------------------
    // 2. PRIVATE SIGNALS (WITNESS)
    // ------------------------------------------------------------------------
    signal input birthDate;         // YYYYMMDD (e.g. 20040512)
    signal input holderSecret;      // Holder's private random salt
    signal input issuerPubKey;      // Issuer's public key
    signal input pathElements[merkleDepth]; // Merkle sibling elements
    signal input pathIndices[merkleDepth];  // Merkle path 0/1 bits

    // ------------------------------------------------------------------------
    // 3. DATE VALIDATION & CUTOFF ARITHMETIC
    // ------------------------------------------------------------------------
    // Validate that birthDate is well-formed
    component validBirth = ValidateDate();
    validBirth.date <== birthDate;

    // Validate that currentDate is well-formed
    component validCurrent = ValidateDate();
    validCurrent.date <== currentDate;

    // Calculate cutoff date = (currentYear - minAge) * 10000 + currentMonth * 100 + currentDay
    signal currentYear <-- currentDate \ 10000;
    signal currentRemainder <-- currentDate % 10000;
    signal currentMonth <-- currentRemainder \ 100;
    signal currentDay <-- currentRemainder % 100;

    currentDate === currentYear * 10000 + currentMonth * 100 + currentDay;

    signal cutoffYear <== currentYear - minAge;
    signal cutoffDate <== cutoffYear * 10000 + currentMonth * 100 + currentDay;

    // Enforce birthDate <= cutoffDate (32-bit integer comparison)
    component ageCheck = LessEqThan(32);
    ageCheck.in[0] <== birthDate;
    ageCheck.in[1] <== cutoffDate;
    ageCheck.out === 1;

    // ------------------------------------------------------------------------
    // 4. CREDENTIAL COMMITMENT & MERKLE MEMBERSHIP
    // ------------------------------------------------------------------------
    // Leaf = Poseidon(birthDate, holderSecret, issuerPubKey)
    component leafHasher = MockPoseidon3();
    leafHasher.in[0] <== birthDate;
    leafHasher.in[1] <== holderSecret;
    leafHasher.in[2] <== issuerPubKey;

    signal leaf <== leafHasher.out;

    // Verify Merkle tree inclusion
    component merkleCheck = MerkleInclusionProof(merkleDepth);
    merkleCheck.leaf <== leaf;
    merkleCheck.root <== merkleRoot;
    for (var i = 0; i < merkleDepth; i++) {
        merkleCheck.pathElements[i] <== pathElements[i];
        merkleCheck.pathIndices[i] <== pathIndices[i];
    }

    // ------------------------------------------------------------------------
    // 5. SCOPED NULLIFIER CALCULATION
    // ------------------------------------------------------------------------
    // Nullifier = Poseidon(holderSecret, verifierScope, challengeNonce)
    component nullifierHasher = MockPoseidon3();
    nullifierHasher.in[0] <== holderSecret;
    nullifierHasher.in[1] <== verifierScope;
    nullifierHasher.in[2] <== challengeNonce;

    nullifierHash === nullifierHasher.out;
}

// Instantiate with tree depth of 16 (supports up to 65,536 issued credentials per tree)
component main {public [currentDate, minAge, merkleRoot, nullifierHash, verifierScope, challengeNonce]} = AgeVerification(16);
