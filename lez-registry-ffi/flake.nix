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

          # Fetch pre-built circuit files from official logos-blockchain-circuits releases
          # See: https://github.com/logos-blockchain/logos-blockchain-circuits/releases
          circuitsVersion = "v0.4.1";
          circuitsPlatform = {
            "x86_64-linux"   = "linux-x86_64";
            "aarch64-linux"  = "linux-aarch64";
            "x86_64-darwin"  = "macos-x86_64";
            "aarch64-darwin" = "macos-aarch64";
          }.${system};

          logosBlockchainCircuits = pkgs.fetchurl {
            url = "https://github.com/logos-blockchain/logos-blockchain-circuits/releases/download/${circuitsVersion}/logos-blockchain-circuits-${circuitsVersion}-${circuitsPlatform}.tar.gz";
            hash = {
              "x86_64-linux"   = "sha256-Oi3xhqm5Sd4PaCSHWMvsJm2YPtSlm11BBG99xG30tiM=";
              "aarch64-linux"  = "";  # TODO: compute when needed
              "x86_64-darwin"  = "";  # TODO: compute when needed
              "aarch64-darwin" = "";  # TODO: compute when needed
            }.${system};
          };

          circuitsDir = pkgs.runCommand "logos-blockchain-circuits" {} ''
            mkdir -p $out
            tar xzf ${logosBlockchainCircuits} -C $out --strip-components=1
          '';

          # Pre-built NSSA program method binaries (needed by nssa build.rs)
          nssaProgramMethods = pkgs.fetchurl {
            url = "https://github.com/jimmy-claw/lez-registry/releases/download/circuits-v0.1.0/nssa-program-methods.tar.gz";
            sha256 = "a40ee19678cb44b07167dbe7ccc3e7279585d7fb6182831d792c03e6ad2b64d5";
          };

          artifactsDir = pkgs.runCommand "nssa-artifacts" {} ''
            mkdir -p $out/program_methods
            tar xzf ${nssaProgramMethods} -C $out
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

            # nssa build.rs expects ../artifacts/program_methods/ with .bin files
            # Symlink the pre-built artifacts into the source tree
            preConfigure = ''
              ln -sf ${artifactsDir} artifacts
            '';
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
