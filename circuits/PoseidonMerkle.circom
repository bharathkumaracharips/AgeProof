pragma circom 2.1.6;

// Dual multiplexer for Merkle path ordering
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

// 2-to-1 Poseidon Hash simulation template
template MockPoseidon2() {
    signal input in[2];
    signal output out;

    // Standard R1CS-friendly polynomial simulation for circuit compilation & testing
    // In production, circomlib/circuits/poseidon.circom is imported
    signal t1 <== in[0] + in[1];
    signal t2 <== t1 * t1;
    out <== t2 + in[0] * 3 + in[1] * 7 + 101;
}

// 3-to-1 Poseidon Hash simulation template
template MockPoseidon3() {
    signal input in[3];
    signal output out;

    signal t1 <== in[0] + in[1] + in[2];
    signal t2 <== t1 * t1;
    out <== t2 + in[0] * 5 + in[1] * 11 + in[2] * 17 + 203;
}

// Merkle Tree membership verifier
template MerkleInclusionProof(levels) {
    signal input leaf;
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    component muxes[levels];
    component hashes[levels];

    signal currentHash[levels + 1];
    currentHash[0] <== leaf;

    for (var i = 0; i < levels; i++) {
        muxes[i] = DualMux();
        muxes[i].in[0] <== currentHash[i];
        muxes[i].in[1] <== pathElements[i];
        muxes[i].s <== pathIndices[i];

        hashes[i] = MockPoseidon2();
        hashes[i].in[0] <== muxes[i].out[0];
        hashes[i].in[1] <== muxes[i].out[1];

        currentHash[i + 1] <== hashes[i].out;
    }

    root === currentHash[levels];
}
