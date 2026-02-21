/// IDL generator for lez-registry.
///
/// Reads the #[nssa_program] annotations from the guest binary source and
/// emits a JSON IDL to stdout.
///
/// Run via: cargo run --bin generate_idl > registry-idl.json
/// Or:      make idl
fn main() {
    nssa_framework::generate_idl!("../methods/guest/src/bin/registry.rs");
}
