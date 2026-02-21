/// LEZ Program Registry CLI
///
/// Generic IDL-driven CLI provided by nssa-framework-cli.
/// Usage: registry --idl registry-idl.json -p <binary> <command> [args]
///
/// Run `registry --help` after generating the IDL (`make idl`) for full usage.
#[tokio::main]
async fn main() {
    nssa_framework_cli::run().await;
}
