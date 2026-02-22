{
  description = "lez-registry-ffi — C FFI shared library for the LEZ Program Registry";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crane, rust-overlay, ... }:
    let
      lib = nixpkgs.lib;

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = lib.genAttrs systems;

      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };
    in
    {
      packages = forAll (system:
        let
          pkgs = mkPkgs system;

          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" ];
          };

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          # Fetch pre-built circuit files needed by logos-blockchain-pol build.rs
          # These are platform-specific (contain native binaries)
          circuitsArchName = {
            "x86_64-linux"  = "x86_64-linux";
            "aarch64-linux" = "x86_64-linux";  # TODO: add aarch64 circuits
            "x86_64-darwin" = "x86_64-linux";   # TODO: add darwin circuits
            "aarch64-darwin" = "x86_64-linux";   # TODO: add darwin circuits
          }.${system};

          logosBlockchainCircuits = pkgs.fetchurl {
            url = "https://github.com/jimmy-claw/lez-registry/releases/download/circuits-v0.1.0/logos-blockchain-circuits-${circuitsArchName}.tar.gz";
            sha256 = "59fd9275e5afdaf2d94408787f23fdeb12ea6a53a52a328da6ce14ea2cd76692";
          };

          circuitsDir = pkgs.runCommand "logos-blockchain-circuits" {} ''
            mkdir -p $out
            tar xzf ${logosBlockchainCircuits} -C $out
          '';

          # Filter source to only include Rust/Cargo files and the include/ dir
          src = lib.cleanSourceWith {
            src = ./..;  # workspace root (lez-registry/)
            filter = path: type:
              (craneLib.filterCargoSources path type)
              || (lib.hasInfix "/include/" path)
              || (lib.hasSuffix ".h" path);
          };

          commonArgs = {
            inherit src;
            pname = "lez-registry-ffi";
            version = "0.1.0";

            # Build only the FFI crate
            cargoExtraArgs = "-p lez-registry-ffi";

            nativeBuildInputs = with pkgs; [
              pkg-config
              protobuf
            ];

            buildInputs = with pkgs; [
              openssl
            ] ++ lib.optionals stdenv.isDarwin [
              libiconv
              darwin.apple_sdk.frameworks.Security
              darwin.apple_sdk.frameworks.SystemConfiguration
            ];

            # risc0 guest builds need this
            RISC0_SKIP_BUILD = "1";

            # logos-blockchain-pol build.rs needs circuits directory
            LOGOS_BLOCKCHAIN_CIRCUITS = "${circuitsDir}";
          };

          # Build deps first (for caching)
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          # Build the actual FFI crate
          lezRegistryFfi = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;

            # Install the .so/.dylib and header
            postInstall = ''
              mkdir -p $out/lib $out/include

              # Find and copy the shared library
              find target -name "liblez_registry_ffi.so" -o -name "liblez_registry_ffi.dylib" | head -1 | while read f; do
                cp "$f" $out/lib/
              done

              # Also copy the static lib if present
              find target -name "liblez_registry_ffi.a" | head -1 | while read f; do
                cp "$f" $out/lib/
              done

              # Copy the C header
              cp lez-registry-ffi/include/*.h $out/include/ 2>/dev/null || true
            '';
          });
        in
        {
          default = lezRegistryFfi;
          lib = lezRegistryFfi;
        }
      );

      devShells = forAll (system:
        let
          pkgs = mkPkgs system;
          pkg = self.packages.${system}.default;
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ pkg ];
            packages = with pkgs; [ rust-analyzer ];
          };
        }
      );
    };
}
