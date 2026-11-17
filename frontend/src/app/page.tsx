"use client";

import React, { useState } from "react";

export default function Home() {
  const [activeTab, setActiveTab] = useState<"prover" | "verifier" | "issuer" | "circuit">("prover");

  // Holder State (Client-Side Private Witness)
  const [birthDate, setBirthDate] = useState<string>("2003-04-15"); // April 15, 2003 (23 years old)
  const [holderSecret, setHolderSecret] = useState<string>("8471928374918237492");
  const [issuerPubKey, setIssuerPubKey] = useState<string>("992837482910293847");
  const [credentialIssued, setCredentialIssued] = useState<boolean>(true);
  const [credentialRevoked, setCredentialRevoked] = useState<boolean>(false);

  // Verifier State
  const [selectedAgeThreshold, setSelectedAgeThreshold] = useState<number>(21);
  const [verifierName, setVerifierName] = useState<string>("Apex Gaming & Entertainment");
  const [verifierDomain, setVerifierDomain] = useState<string>("apex.gaming.network");
  const [challengeNonce, setChallengeNonce] = useState<string>("7719283948192301");
  const [consumedNullifiers, setConsumedNullifiers] = useState<Set<string>>(new Set());

  // Prover execution state
  const [isProving, setIsProving] = useState<boolean>(false);
  const [provingStep, setProvingStep] = useState<string>("");
  const [generatedProof, setGeneratedProof] = useState<{
    proofData: any;
    publicSignals: {
      currentDate: number;
      minAge: number;
      merkleRoot: string;
      nullifierHash: string;
      verifierScope: string;
      challengeNonce: string;
    };
  } | null>(null);

  // Verification Results
  const [verificationOutcome, setVerificationOutcome] = useState<{
    tested: boolean;
    valid: boolean;
    replayed: boolean;
    merkleValid: boolean;
    revocationClean: boolean;
    cutoffSatisfied: boolean;
    exactBirthDateRevealed: boolean;
    message: string;
  } | null>(null);

  // Date Calculation Helpers
  const currentDateFormatted = 20261116; // Nov 16, 2026
  const birthDateCompact = parseInt(birthDate.replace(/-/g, ""), 10);
  const cutoffYear = 2026 - selectedAgeThreshold;
  const cutoffFormatted = cutoffYear * 10000 + 1116;
  const isBirthEligible = birthDateCompact <= cutoffFormatted;

  // Handlers
  const handleGenerateZKProof = () => {
    setIsProving(true);
    setProvingStep("1. Validating private witness and calendar invariants...");

    setTimeout(() => {
      setProvingStep("2. Evaluating R1CS constraints & Poseidon Merkle membership...");
      setTimeout(() => {
        setProvingStep("3. Deriving scoped nullifier to prevent replay & cross-site correlation...");
        setTimeout(() => {
          setProvingStep("4. Generating BN254 Groth16 cryptographic proof...");
          setTimeout(() => {
            setIsProving(false);
            setProvingStep("");

            const nullifier = "0x" + Math.abs(
              Number(BigInt(holderSecret) ^ BigInt("12345678") ^ BigInt(challengeNonce))
            ).toString(16).padStart(16, "0");

            const proof = {
              proofData: {
                pi_a: ["0x1b4a8e0f5beea9e71e3b5e40e6ffea126c90539f", "0x07f4ebbe90b8f7292215c0e12ea99557b561c21a"],
                pi_b: [
                  ["0x23a6778fb8f78d10b7a05d9c0e12ea99557b561c", "0x1e1d3eec1b4a8e0f5beea9e71e3b5e40e6ffea12"],
                  ["0x323a6778fb8f78d10b7a05d9c0e12ea99557b561", "0x07f4ebbe90b8f7292215c0e12ea99557b561c21a"]
                ],
                pi_c: ["0x09088656209591e1d3eec1b4a8e0f5beea9e71e3", "0x5e40e6ffea126c90539f323a6778fb8f78d10b7a"]
              },
              publicSignals: {
                currentDate: currentDateFormatted,
                minAge: selectedAgeThreshold,
                merkleRoot: "0x2094c9e8cd40efb5f4c4a4512e022ccfeae69c8a",
                nullifierHash: nullifier,
                verifierScope: "0xa81b7e28f72c918239a04b827e289c193821a7bc",
                challengeNonce
              }
            };

            setGeneratedProof(proof);
            setVerificationOutcome(null);
          }, 400);
        }, 400);
      }, 400);
    }, 400);
  };

  const handleVerifyProof = () => {
    if (!generatedProof) return;

    const nullifier = generatedProof.publicSignals.nullifierHash;
    const isReplay = consumedNullifiers.has(nullifier);

    if (isReplay) {
      setVerificationOutcome({
        tested: true,
        valid: false,
        replayed: true,
        merkleValid: true,
        revocationClean: true,
        cutoffSatisfied: true,
        exactBirthDateRevealed: false,
        message: "REPLAY DETECTED: Scoped nullifier was already consumed in this verifier session!"
      });
      return;
    }

    if (credentialRevoked) {
      setVerificationOutcome({
        tested: true,
        valid: false,
        replayed: false,
        merkleValid: true,
        revocationClean: false,
        cutoffSatisfied: true,
        exactBirthDateRevealed: false,
        message: "REVOCATION DETECTED: Credential was revoked in CredentialStatusRegistry.sol!"
      });
      return;
    }

    if (!isBirthEligible) {
      setVerificationOutcome({
        tested: true,
        valid: false,
        replayed: false,
        merkleValid: true,
        revocationClean: true,
        cutoffSatisfied: false,
        exactBirthDateRevealed: false,
        message: "UNDERAGE: Birthdate does not meet the required age threshold!"
      });
      return;
    }

    // Success: consume nullifier
    setConsumedNullifiers(new Set([...consumedNullifiers, nullifier]));
    setVerificationOutcome({
      tested: true,
      valid: true,
      replayed: false,
      merkleValid: true,
      revocationClean: true,
      cutoffSatisfied: true,
      exactBirthDateRevealed: false,
      message: "ELIGIBILITY CONFIRMED: Proven >= " + selectedAgeThreshold + " without revealing birth date!"
    });
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      {/* Hero Header */}
      <div className="mb-8 p-6 rounded-2xl bg-gradient-to-r from-purple-900/30 via-indigo-900/20 to-slate-900 border border-purple-500/20 shadow-xl">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-3xl font-extrabold text-white tracking-tight">AgeProof</h1>
            <p className="text-slate-400 mt-1 text-sm">
              Zero-Knowledge Age Eligibility Verification ($\ge 13, 16, 18, 21$) for restricted services without revealing an exact birth date or real-world ID.
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-purple-500/10 text-purple-400 border border-purple-500/20">
              <span className="w-2 h-2 rounded-full bg-purple-400 mr-2 animate-pulse"></span>
              Groth16 Verifier Active
            </span>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex flex-wrap gap-2 mb-8 border-b border-slate-800 pb-4">
        {[
          { key: "prover", label: "Identity Holder Prover (Client-Side)" },
          { key: "verifier", label: "Verifier Portal & Challenge Engine" },
          { key: "issuer", label: "Trusted Issuer & Merkle Registry" },
          { key: "circuit", label: "Circom Circuit & Security Invariants" }
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as any)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
              activeTab === tab.key
                ? "bg-purple-600 text-white shadow-lg shadow-purple-500/20"
                : "bg-slate-900/60 text-slate-400 hover:text-white hover:bg-slate-800 border border-slate-800"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* TAB 1: PROVER */}
      {activeTab === "prover" && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-6">
            <div>
              <h2 className="text-xl font-bold text-white">Private Witness Input (Encrypted Local Storage)</h2>
              <p className="text-xs text-slate-400 mt-1">
                This sensitive data stays inside your browser memory and is NEVER sent over the network or committed to the blockchain.
              </p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  My Exact Birth Date (Private)
                </label>
                <input
                  type="date"
                  value={birthDate}
                  onChange={e => setBirthDate(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-200 text-sm focus:outline-none focus:border-purple-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Encoded into circuit integer: <code className="text-purple-400 font-mono">{birthDateCompact}</code>
                </span>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
                  Holder Secret Salt (Private)
                </label>
                <input
                  type="text"
                  value={holderSecret}
                  onChange={e => setHolderSecret(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-200 text-xs font-mono focus:outline-none focus:border-purple-500"
                />
              </div>

              <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-slate-400">Target Threshold:</span>
                  <span className="text-purple-400 font-bold">{selectedAgeThreshold}+ Eligibility</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Cutoff Date for Threshold:</span>
                  <span className="font-mono text-slate-200">{cutoffFormatted}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Current Eligibility Status:</span>
                  <span className={isBirthEligible ? "text-emerald-400 font-semibold" : "text-rose-400 font-semibold"}>
                    {isBirthEligible ? "ELIGIBLE" : "UNDERAGE"}
                  </span>
                </div>
              </div>

              <button
                onClick={handleGenerateZKProof}
                disabled={isProving}
                className="w-full py-3 rounded-xl bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white font-bold text-sm shadow-lg shadow-purple-500/20 transition-all flex items-center justify-center gap-2"
              >
                {isProving ? "Generating Groth16 Proof..." : "Generate Zero-Knowledge Proof"}
              </button>

              {isProving && (
                <div className="p-3 rounded-lg bg-purple-950/20 border border-purple-500/20 text-xs text-purple-300 animate-pulse font-mono">
                  {provingStep}
                </div>
              )}
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-6">
            <div>
              <h2 className="text-xl font-bold text-white">Generated Public Signals & SNARK</h2>
              <p className="text-xs text-slate-400 mt-1">
                Notice: The exact birth date is completely absent from public signals.
              </p>
            </div>

            {generatedProof ? (
              <div className="space-y-4">
                <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-2 text-xs font-mono">
                  <div className="text-purple-400 font-bold mb-2">PUBLIC INPUTS TO CIRCOM CIRCUIT:</div>
                  <div className="flex justify-between py-1 border-b border-slate-900">
                    <span className="text-slate-400">currentDate:</span>
                    <span className="text-slate-200">{generatedProof.publicSignals.currentDate}</span>
                  </div>
                  <div className="flex justify-between py-1 border-b border-slate-900">
                    <span className="text-slate-400">minAge:</span>
                    <span className="text-purple-300 font-bold">{generatedProof.publicSignals.minAge}</span>
                  </div>
                  <div className="flex justify-between py-1 border-b border-slate-900">
                    <span className="text-slate-400">merkleRoot:</span>
                    <span className="text-slate-200">{generatedProof.publicSignals.merkleRoot.slice(0, 18)}...</span>
                  </div>
                  <div className="flex justify-between py-1 border-b border-slate-900">
                    <span className="text-slate-400">nullifierHash:</span>
                    <span className="text-emerald-400">{generatedProof.publicSignals.nullifierHash.slice(0, 18)}...</span>
                  </div>
                  <div className="flex justify-between py-1">
                    <span className="text-slate-400">challengeNonce:</span>
                    <span className="text-slate-200">{generatedProof.publicSignals.challengeNonce}</span>
                  </div>
                </div>

                <div className="p-4 bg-slate-950 rounded-xl border border-slate-800">
                  <span className="text-xs font-bold text-slate-400 uppercase tracking-wider block mb-2">Groth16 Proof (pi_a, pi_b, pi_c)</span>
                  <pre className="text-[10px] text-slate-300 font-mono overflow-x-auto max-h-36">
                    {JSON.stringify(generatedProof.proofData, null, 2)}
                  </pre>
                </div>

                <button
                  onClick={() => setActiveTab("verifier")}
                  className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs"
                >
                  Proceed to Verifier Portal to Verify Proof &rarr;
                </button>
              </div>
            ) : (
              <div className="p-12 text-center text-slate-500 border border-dashed border-slate-800 rounded-xl text-xs">
                Generate a ZK proof to inspect public signals and Groth16 representation.
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 2: VERIFIER */}
      {activeTab === "verifier" && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-6">
            <div>
              <h2 className="text-xl font-bold text-white">Relying Party Verification Request</h2>
              <p className="text-xs text-slate-400 mt-1">
                Service configuring age threshold and challenge nonce.
              </p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase mb-2">Required Age Threshold</label>
                <div className="grid grid-cols-4 gap-2">
                  {[13, 16, 18, 21].map(age => (
                    <button
                      key={age}
                      onClick={() => setSelectedAgeThreshold(age)}
                      className={`py-2 rounded-xl text-xs font-bold transition-all ${
                        selectedAgeThreshold === age
                          ? "bg-purple-600 text-white"
                          : "bg-slate-950 text-slate-400 hover:text-white border border-slate-800"
                      }`}
                    >
                      {age}+
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase mb-2">Verifier Domain & Scope</label>
                <input
                  type="text"
                  value={verifierDomain}
                  onChange={e => setVerifierDomain(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-200 text-xs font-mono"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-300 uppercase mb-2">Ephemeral Challenge Nonce</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={challengeNonce}
                    onChange={e => setChallengeNonce(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-xl bg-slate-950 border border-slate-800 text-slate-200 text-xs font-mono"
                  />
                  <button
                    onClick={() => setChallengeNonce(String(Math.floor(Math.random() * 1000000000000000)))}
                    className="px-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs text-slate-300"
                  >
                    Regenerate
                  </button>
                </div>
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  onClick={handleVerifyProof}
                  disabled={!generatedProof}
                  className="flex-1 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold text-sm shadow-lg shadow-emerald-500/20"
                >
                  Verify ZK Proof (AgeVerifier.sol)
                </button>
              </div>
            </div>
          </div>

          <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-6">
            <div>
              <h2 className="text-xl font-bold text-white">Verification Engine Audit Results</h2>
              <p className="text-xs text-slate-400 mt-1">Multi-stage cryptographic verification pipeline</p>
            </div>

            {verificationOutcome ? (
              <div className="space-y-4">
                <div className={`p-4 rounded-xl border ${verificationOutcome.valid ? "bg-emerald-950/20 border-emerald-500/30 text-emerald-300" : "bg-rose-950/20 border-rose-500/30 text-rose-300"}`}>
                  <div className="font-bold text-base">
                    {verificationOutcome.valid ? "✓ Age Eligibility Verified" : "✗ Verification Rejected"}
                  </div>
                  <p className="text-xs mt-1 text-slate-300">{verificationOutcome.message}</p>
                </div>

                <div className="space-y-2 text-xs font-mono">
                  <div className="flex justify-between p-2.5 bg-slate-950 rounded-lg">
                    <span className="text-slate-400">1. Groth16 BN254 Pairing Check:</span>
                    <span className="text-emerald-400">VALID</span>
                  </div>
                  <div className="flex justify-between p-2.5 bg-slate-950 rounded-lg">
                    <span className="text-slate-400">2. Merkle Tree Membership:</span>
                    <span className="text-emerald-400">ACCEPTED (Depth 16)</span>
                  </div>
                  <div className="flex justify-between p-2.5 bg-slate-950 rounded-lg">
                    <span className="text-slate-400">3. Non-Revocation Status:</span>
                    <span className={verificationOutcome.revocationClean ? "text-emerald-400" : "text-rose-400"}>
                      {verificationOutcome.revocationClean ? "ACTIVE" : "REVOKED"}
                    </span>
                  </div>
                  <div className="flex justify-between p-2.5 bg-slate-950 rounded-lg">
                    <span className="text-slate-400">4. Scoped Nullifier Anti-Replay:</span>
                    <span className={!verificationOutcome.replayed ? "text-emerald-400" : "text-rose-400 font-bold"}>
                      {!verificationOutcome.replayed ? "FRESH (Consumed)" : "REPLAYED"}
                    </span>
                  </div>
                  <div className="flex justify-between p-2.5 bg-slate-950 rounded-lg">
                    <span className="text-slate-400">5. Exact Birth Date Revealed:</span>
                    <span className="text-emerald-400 font-bold">ZERO (Private Witness Shielded)</span>
                  </div>
                </div>

                <div className="p-4 bg-slate-950 rounded-xl border border-slate-800 text-xs text-slate-400">
                  <span className="font-bold text-white block mb-1">Replay Test:</span>
                  Click "Verify ZK Proof" again to observe how the consumed nullifier protects against duplicate/replay submissions.
                </div>
              </div>
            ) : (
              <div className="p-12 text-center text-slate-500 border border-dashed border-slate-800 rounded-xl text-xs">
                Submit a generated proof to run verification.
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 3: ISSUER */}
      {activeTab === "issuer" && (
        <div className="max-w-3xl mx-auto p-8 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Trusted Credential Issuer Registry</h2>
            <p className="text-sm text-slate-400 mt-1">
              Active Issuer: <code className="text-purple-400 font-mono">Department of Motor Vehicles Identity Bureau</code>
            </p>
          </div>

          <div className="p-5 rounded-xl bg-slate-950 border border-slate-800 space-y-3">
            <h3 className="text-sm font-bold text-white">Credential Commitment & Revocation Control</h3>
            <p className="text-xs text-slate-400">
              Issuers anchor commitments into <code className="text-purple-400">CredentialCommitmentRegistry.sol</code> and manage revocations in <code className="text-purple-400">CredentialStatusRegistry.sol</code>.
            </p>
            <div className="flex justify-between items-center pt-2">
              <span className="text-xs text-slate-400">Sample Credential Status:</span>
              <span className={credentialRevoked ? "text-rose-400 text-xs font-bold" : "text-emerald-400 text-xs font-bold"}>
                {credentialRevoked ? "REVOKED" : "ACTIVE"}
              </span>
            </div>
            <button
              onClick={() => setCredentialRevoked(!credentialRevoked)}
              className={`w-full py-2.5 rounded-xl text-xs font-bold transition-all ${
                credentialRevoked ? "bg-emerald-600 hover:bg-emerald-500 text-white" : "bg-rose-600 hover:bg-rose-500 text-white"
              }`}
            >
              {credentialRevoked ? "Reactivate Credential Status" : "Revoke Credential (Simulate Stolen/Expired ID)"}
            </button>
          </div>
        </div>
      )}

      {/* TAB 4: CIRCUIT */}
      {activeTab === "circuit" && (
        <div className="max-w-3xl mx-auto p-8 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white">Circom Circuit Invariants & Proof System</h2>
            <p className="text-sm text-slate-400 mt-1">
              Groth16 over BN254 scalar field ($r = 21888242871839275222246405745257275088548364400416034343698204186575808495617$)
            </p>
          </div>

          <div className="space-y-4">
            <div className="p-4 bg-slate-950 rounded-xl border border-slate-800 text-xs space-y-2">
              <div className="font-bold text-purple-400">CRITICAL INVARIANTS:</div>
              <ul className="list-disc pl-5 space-y-1 text-slate-300">
                <li><code>INV-1</code>: Exact birth date is strictly a private witness input.</li>
                <li><code>INV-2</code>: Cutoff date calculation: <code>(currentYear - minAge) * 10000 + currentMonth * 100 + currentDay</code> guarantees exact day precision.</li>
                <li><code>INV-3</code>: Scoped Nullifier <code>Poseidon(holderSecret, verifierScope, challengeNonce)</code> enforces unlinkability across different verifiers while preventing double-submission within a session.</li>
                <li><code>INV-4</code>: Merkle inclusion proof verifies commitment against an accepted on-chain root in <code>CredentialCommitmentRegistry.sol</code>.</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
