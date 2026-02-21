//! Logos Storage (Codex) operation implementations.
//! Uses the Codex HTTP REST API: POST /api/codex/v1/data, GET /api/codex/v1/data/{cid}/...

use serde_json::{json, Value};

fn parse_args(args: &str) -> Result<Value, String> {
    serde_json::from_str(args).map_err(|e| format!("invalid JSON: {}", e))
}

fn get_str<'a>(v: &'a Value, key: &str) -> Result<&'a str, String> {
    v[key]
        .as_str()
        .ok_or_else(|| format!("missing field '{}'", key))
}

pub fn upload(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    let _logos_storage_url = match get_str(&v, "logos_storage_url") {
        Ok(u) => u,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };
    let _file_path = match get_str(&v, "file_path") {
        Ok(p) => p,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    // TODO: POST multipart/form-data to {logos_storage_url}/api/codex/v1/data
    // Read file_path, send as form field, parse response CID
    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn download(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    let _logos_storage_url = match get_str(&v, "logos_storage_url") {
        Ok(u) => u,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };
    let _cid = match get_str(&v, "cid") {
        Ok(c) => c,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    // TODO: GET {logos_storage_url}/api/codex/v1/data/{cid}/network/stream
    // Return base64-encoded content
    json!({"success": false, "error": "not yet implemented"}).to_string()
}

pub fn fetch_idl(args: &str) -> String {
    let v = match parse_args(args) {
        Ok(v) => v,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    let _logos_storage_url = match get_str(&v, "logos_storage_url") {
        Ok(u) => u,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };
    let _cid = match get_str(&v, "cid") {
        Ok(c) => c,
        Err(e) => return json!({"success": false, "error": e}).to_string(),
    };

    // TODO: download() + base64 decode + parse JSON as IDL + return
    json!({"success": false, "error": "not yet implemented"}).to_string()
}
