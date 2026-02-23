/// IDL generator for lez-registry.
///
/// Reads the #[lez_program] annotations from the guest binary source and
/// emits a JSON IDL to stdout.
///
/// Run via: cargo run --bin generate_idl > registry-idl.json
/// Or:      make idl
fn main() {
    lez_framework::generate_idl!("../methods/guest/src/bin/registry.rs");
}
