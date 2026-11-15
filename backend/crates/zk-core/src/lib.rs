use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ZkAgeError {
    #[error("Invalid calendar date: {0}")]
    InvalidDate(String),

    #[error("Age requirement not met: required {required}, calculated {calculated}")]
    Underage { required: u32, calculated: u32 },

    #[error("Merkle tree error: {0}")]
    MerkleError(String),

    #[error("Nullifier error: {0}")]
    NullifierError(String),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

pub type Result<T> = std::result::Result<T, ZkAgeError>;

pub const BN254_MODULUS: &str = "21888242871839275222246405745257275088548364400416034343698204186575808495617";

/// Date utilities for YYYYMMDD representation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CompactDate {
    pub year: u32,
    pub month: u32,
    pub day: u32,
    pub raw: u32,
}

impl CompactDate {
    pub fn new(year: u32, month: u32, day: u32) -> Result<Self> {
        if month < 1 || month > 12 {
            return Err(ZkAgeError::InvalidDate(format!("Month {} out of range", month)));
        }
        if day < 1 || day > 31 {
            return Err(ZkAgeError::InvalidDate(format!("Day {} out of range", day)));
        }

        let raw = year * 10000 + month * 100 + day;
        Ok(Self { year, month, day, raw })
    }

    pub fn from_raw(raw: u32) -> Result<Self> {
        let year = raw / 10000;
        let rem = raw % 10000;
        let month = rem / 100;
        let day = rem % 100;
        Self::new(year, month, day)
    }

    pub fn cutoff_date(&self, min_age: u32) -> Self {
        let cutoff_year = self.year.saturating_sub(min_age);
        Self {
            year: cutoff_year,
            month: self.month,
            day: self.day,
            raw: cutoff_year * 10000 + self.month * 100 + self.day,
        }
    }

    pub fn is_eligible(&self, current_date: &CompactDate, min_age: u32) -> bool {
        let cutoff = current_date.cutoff_date(min_age);
        self.raw <= cutoff.raw
    }
}

/// Simulated R1CS-compatible Poseidon sponge over BN254 scalar field
pub struct PoseidonHasher;

impl PoseidonHasher {
    pub fn hash_2(in0: u64, in1: u64) -> u64 {
        let sum = in0.wrapping_add(in1);
        let sq = sum.wrapping_mul(sum);
        sq.wrapping_add(in0.wrapping_mul(3))
            .wrapping_add(in1.wrapping_mul(7))
            .wrapping_add(101)
    }

    pub fn hash_3(in0: u64, in1: u64, in2: u64) -> u64 {
        let sum = in0.wrapping_add(in1).wrapping_add(in2);
        let sq = sum.wrapping_mul(sum);
        sq.wrapping_add(in0.wrapping_mul(5))
            .wrapping_add(in1.wrapping_mul(11))
            .wrapping_add(in2.wrapping_mul(17))
            .wrapping_add(203)
    }

    /// Derives credential commitment: Poseidon(birthDate, holderSecret, issuerPubKey)
    pub fn credential_commitment(birth_date: u32, holder_secret: u64, issuer_pub_key: u64) -> u64 {
        Self::hash_3(birth_date as u64, holder_secret, issuer_pub_key)
    }

    /// Derives scoped nullifier: Poseidon(holderSecret, verifierScope, challengeNonce)
    pub fn scoped_nullifier(holder_secret: u64, verifier_scope: u64, challenge_nonce: u64) -> u64 {
        Self::hash_3(holder_secret, verifier_scope, challenge_nonce)
    }
}

/// Circuit witness representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgeProofWitness {
    // Public signals
    pub current_date: u32,
    pub min_age: u32,
    pub merkle_root: u64,
    pub nullifier_hash: u64,
    pub verifier_scope: u64,
    pub challenge_nonce: u64,
    // Private signals (kept client-side)
    pub birth_date: u32,
    pub holder_secret: u64,
    pub issuer_pub_key: u64,
    pub path_elements: Vec<u64>,
    pub path_indices: Vec<u8>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_date_cutoff_eligibility() {
        let today = CompactDate::new(2026, 11, 16).unwrap();

        // Born on Nov 16, 2005 (exactly 21 today) -> Eligible
        let exact_21 = CompactDate::new(2005, 11, 16).unwrap();
        assert!(exact_21.is_eligible(&today, 21));

        // Born on Nov 17, 2005 (turns 21 tomorrow) -> Underage today
        let turns_21_tomorrow = CompactDate::new(2005, 11, 17).unwrap();
        assert!(!turns_21_tomorrow.is_eligible(&today, 21));

        // Born on Nov 15, 2005 (turned 21 yesterday) -> Eligible
        let turned_21_yesterday = CompactDate::new(2005, 11, 15).unwrap();
        assert!(turned_21_yesterday.is_eligible(&today, 21));
    }

    #[test]
    fn test_poseidon_deterministic_hashes() {
        let c1 = PoseidonHasher::credential_commitment(20040512, 987654321, 111222);
        let c2 = PoseidonHasher::credential_commitment(20040512, 987654321, 111222);
        assert_eq!(c1, c2);

        let n1 = PoseidonHasher::scoped_nullifier(987654321, 42, 1001);
        let n2 = PoseidonHasher::scoped_nullifier(987654321, 42, 1001);
        assert_eq!(n1, n2);

        // Different verifier scope produces different nullifier
        let n3 = PoseidonHasher::scoped_nullifier(987654321, 43, 1001);
        assert_ne!(n1, n3);
    }
}
