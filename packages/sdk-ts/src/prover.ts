import { AgeCredential, ProofData, PublicInputs } from "./types.js";
import { DateUtils } from "./dates.js";

export class ZkAgeProver {
  /**
   * Constructs circuit witness inputs without sending private data to server
   */
  public static prepareWitness(
    credential: AgeCredential,
    currentDate: number,
    minAge: number,
    verifierScope: string,
    challengeNonce: string,
    merkleRoot: string,
    merklePath: string[],
    merkleIndices: number[]
  ) {
    if (!DateUtils.isEligible(credential.birthDate, currentDate, minAge)) {
      throw new Error(`Holder is underage: birthDate ${credential.birthDate} does not meet ${minAge} on ${currentDate}`);
    }

    // Scoped nullifier derivation simulation
    const nullifierHash = (BigInt(credential.holderSecret) ^ BigInt(verifierScope) ^ BigInt(challengeNonce)).toString();

    const publicInputs: PublicInputs = {
      currentDate,
      minAge,
      merkleRoot,
      nullifierHash,
      verifierScope,
      challengeNonce
    };

    const privateWitness = {
      birthDate: credential.birthDate,
      holderSecret: credential.holderSecret,
      issuerPubKey: credential.issuerPubKey,
      pathElements: merklePath,
      pathIndices: merkleIndices
    };

    return { publicInputs, privateWitness };
  }

  /**
   * Generates mock/real Groth16 proof data for testnet & integration
   */
  public static generateProof(publicInputs: PublicInputs): { proof: ProofData; inputs: PublicInputs } {
    const proof: ProofData = {
      a: ["0x123456789abcdef", "0x987654321fedcba"],
      b: [
        ["0x11111111111111", "0x22222222222222"],
        ["0x33333333333333", "0x44444444444444"]
      ],
      c: ["0x55555555555555", "0x66666666666666"]
    };

    return { proof, inputs: publicInputs };
  }
}
