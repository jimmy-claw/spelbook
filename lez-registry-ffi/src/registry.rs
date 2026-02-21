//! Registry operation implementations.
//! Each function takes a JSON args string and returns a JSON result string.
//! TODO: implement actual sequencer calls via nssa_core + registry_core.

use serde_json::{json, Value};

/// Parse args JSON, returning an error string on failure.
fn parse_args(args: &str) -> Result<Value, String> {
    serde_json::from_str(args).map_err(|e| format!("invalid JSON: {}", e))
}

fn get_str<'a>(v: &'a Value, key: &str) -> Result<&'a str, String> {
    v[key].as_str().ok_or_else(|| format!("missing field '{}'", key))
}

pub fn register(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    // Validate required fields
    for field in &[
        "sequencer_url",
        "wallet_path",
        "program_id",
        "name",
        "version",
        "idl_cid",
    ] {
        if let Err(e) = get_str(&v, field) {
            return json!({"success": false, "error": e}).to_string();
        }
    }

    // TODO: Build and submit Register transaction via nssa_core
    // 1. Load wallet from wallet_path
    // 2. Compute registry_state PDA
    // 3. Compute program_entry PDA from program_id
    // 4. Build RegisterArgs from JSON
    // 5. Serialize instruction + submit via sequencer_url
    // 6. Return tx_hash

    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn update(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    for field in &["sequencer_url", "wallet_path", "program_id"] {
        if let Err(e) = get_str(&v, field) {
            return json!({"success": false, "error": e}).to_string();
        }
    }

    // TODO: Build and submit Update transaction
    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn list(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    let _sequencer_url = match get_str(&v, "sequencer_url") {
        Ok(u) => u,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    // TODO: Query registry_state PDA to get program_count,
    // then fetch each program_entry PDA by index.
    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn get_by_name(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    for field in &["sequencer_url", "name"] {
        if let Err(e) = get_str(&v, field) {
            return json!({"success": false, "error": e}).to_string();
        }
    }

    // TODO: Scan registry PDAs for matching name field
    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn get_by_id(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    for field in &["sequencer_url", "program_id"] {
        if let Err(e) = get_str(&v, field) {
            return json!({"success": false, "error": e}).to_string();
        }
    }

    // TODO: Derive program_entry PDA from program_id, fetch from sequencer
    json!({"success": false, "error": "not yet implemented"}).to_string()
}
