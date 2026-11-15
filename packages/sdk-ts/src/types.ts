export interface ProofData {
  a: [string, string];
  b: [[string, string], [string, string]];
  c: [string, string];
}

export interface PublicInputs {
  currentDate: number;      // YYYYMMDD
  minAge: number;           // 13, 16, 18, 21
  merkleRoot: string;
  nullifierHash: string;
  verifierScope: string;
  challengeNonce: string;
}

export interface AgeCredential {
  credentialId: string;
  birthDate: number;        // YYYYMMDD (private)
  holderSecret: string;     // private salt
  issuerPubKey: string;     // issuer public key
  commitment: string;       // Poseidon(birthDate, holderSecret, issuerPubKey)
  issuedAt: string;
}

export interface VerificationRequest {
  verifierScope: string;
  verifierName: string;
  domain: string;
  requiredMinAge: number;
  challengeNonce: string;
  expiresAt: string;
}

export interface VerificationResult {
  valid: boolean;
  minAge: number;
  nullifierHash: string;
  error?: string;
}
