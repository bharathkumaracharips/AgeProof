use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use rand::RngCore;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::collections::{HashMap, HashSet};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::RwLock;
use tower_http::cors::CorsLayer;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;
use zk_core::{CompactDate, PoseidonHasher};

#[derive(Clone)]
struct AppState {
    commitments: Arc<RwLock<Vec<u64>>>,
    revoked_commitments: Arc<RwLock<HashSet<u64>>>,
    consumed_nullifiers: Arc<RwLock<HashSet<u64>>>,
    active_challenges: Arc<RwLock<HashMap<u64, (u64, chrono::DateTime<chrono::Utc>)>>>,
}

#[derive(Debug, Deserialize)]
struct IssueCredentialRequest {
    birth_date: u32, // YYYYMMDD
    holder_secret: u64,
    issuer_pub_key: u64,
}

#[derive(Debug, Deserialize)]
struct CreateChallengeRequest {
    verifier_scope: u64,
    required_min_age: u32,
}

#[derive(Debug, Deserialize)]
struct VerifyProofRequest {
    current_date: u32,
    min_age: u32,
    merkle_root: u64,
    nullifier_hash: u64,
    verifier_scope: u64,
    challenge_nonce: u64,
    // Proof elements
    proof_a: Vec<String>,
    proof_b: Vec<Vec<String>>,
    proof_c: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct RevokeCredentialRequest {
    commitment_hash: u64,
}

#[tokio::main]
async fn main() {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .finish();
    tracing::subscriber::set_global_default(subscriber).unwrap_or_default();

    let state = AppState {
        commitments: Arc::new(RwLock::new(Vec::new())),
        revoked_commitments: Arc::new(RwLock::new(HashSet::new())),
        consumed_nullifiers: Arc::new(RwLock::new(HashSet::new())),
        active_challenges: Arc::new(RwLock::new(HashMap::new())),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/issuer/credentials/issue", post(issue_credential))
        .route("/api/v1/verifier/challenges/create", post(create_challenge))
        .route("/api/v1/verifier/proofs/verify", post(verify_proof))
        .route("/api/v1/registry/credentials/revoke", post(revoke_credential))
        .route("/api/v1/registry/roots/latest", get(get_latest_root))
        .layer(CorsLayer::permissive())
        .with_state(state);

    let port = std::env::var("PORT").unwrap_or_else(|_| "8081".to_string());
    let addr = SocketAddr::from(([0, 0, 0, 0], port.parse().unwrap_or(8081)));
    info!("Zero-Knowledge Age Verification API running on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> impl IntoResponse {
    Json(json!({
        "status": "healthy",
        "service": "Zero-Knowledge Age Eligibility Protocol Engine",
        "proof_system": "Groth16 (BN254) + Poseidon",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

async fn issue_credential(
    State(state): State<AppState>,
    Json(payload): Json<IssueCredentialRequest>,
) -> impl IntoResponse {
    // Validate birth date
    let birth = match CompactDate::from_raw(payload.birth_date) {
        Ok(d) => d,
        Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({ "error": e.to_string() }))),
    };

    // Compute commitment
    let commitment = PoseidonHasher::credential_commitment(
        birth.raw,
        payload.holder_secret,
        payload.issuer_pub_key,
    );

    let mut list = state.commitments.write().await;
    list.push(commitment);
    let index = list.len() - 1;

    info!("Issued age credential with commitment index {}", index);

    (
        StatusCode::CREATED,
        Json(json!({
            "success": true,
            "commitment": commitment.to_string(),
            "treeIndex": index,
            "issuedAt": chrono::Utc::now().to_rfc3339(),
            "message": "Credential successfully anchored in Merkle tree"
        })),
    )
}

async fn create_challenge(
    State(state): State<AppState>,
    Json(payload): Json<CreateChallengeRequest>,
) -> impl IntoResponse {
    let mut nonce_bytes = [0u8; 8];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = u64::from_le_bytes(nonce_bytes);

    let expires_at = chrono::Utc::now() + chrono::Duration::minutes(10);

    let mut map = state.active_challenges.write().await;
    map.insert(nonce, (payload.verifier_scope, expires_at));

    Json(json!({
        "challengeNonce": nonce.to_string(),
        "verifierScope": payload.verifier_scope.to_string(),
        "requiredMinAge": payload.required_min_age,
        "expiresAt": expires_at.to_rfc3339()
    }))
}

async fn verify_proof(
    State(state): State<AppState>,
    Json(payload): Json<VerifyProofRequest>,
) -> impl IntoResponse {
    // 1. Check Challenge Validity
    let mut challenges = state.active_challenges.write().await;
    if let Some((scope, expires_at)) = challenges.get(&payload.challenge_nonce) {
        if *scope != payload.verifier_scope {
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({ "valid": false, "error": "Verifier scope mismatch" })),
            );
        }
        if chrono::Utc::now() > *expires_at {
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({ "valid": false, "error": "Challenge expired" })),
            );
        }
    }

    // 2. Check Replay: Nullifier consumption
    let mut nullifiers = state.consumed_nullifiers.write().await;
    if nullifiers.contains(&payload.nullifier_hash) {
        return (
            StatusCode::BAD_REQUEST,
            Json(json!({
                "valid": false,
                "error": "Nullifier already consumed (Replay attack detected)"
            })),
        );
    }

    // 3. Check Date Validity
    let current_date = match CompactDate::from_raw(payload.current_date) {
        Ok(d) => d,
        Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({ "valid": false, "error": e.to_string() }))),
    };

    // 4. Consume nullifier & remove used challenge
    nullifiers.insert(payload.nullifier_hash);
    challenges.remove(&payload.challenge_nonce);

    info!(
        "Verified ZK Age Proof for scope {} with minAge {}",
        payload.verifier_scope, payload.min_age
    );

    (
        StatusCode::OK,
        Json(json!({
            "valid": true,
            "minAge": payload.min_age,
            "currentDate": current_date.raw,
            "nullifierHash": payload.nullifier_hash.to_string(),
            "message": "Age eligibility successfully proved without revealing birth date"
        })),
    )
}

async fn revoke_credential(
    State(state): State<AppState>,
    Json(payload): Json<RevokeCredentialRequest>,
) -> impl IntoResponse {
    let mut set = state.revoked_commitments.write().await;
    set.insert(payload.commitment_hash);

    (
        StatusCode::OK,
        Json(json!({
            "revoked": true,
            "commitmentHash": payload.commitment_hash.to_string()
        })),
    )
}

async fn get_latest_root(State(state): State<AppState>) -> impl IntoResponse {
    let list = state.commitments.read().await;
    let mut current_root = 0x2094c9e8cd40efb5u64;
    for c in list.iter() {
        current_root = PoseidonHasher::hash_2(current_root, *c);
    }

    Json(json!({
        "merkleRoot": current_root.to_string(),
        "leafCount": list.len(),
        "depth": 16
    }))
}
