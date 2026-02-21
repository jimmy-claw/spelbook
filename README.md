# lez-registry

**On-chain Program Registry for the LEZ ecosystem.**

`lez-registry` is a standalone LEZ program that provides an on-chain directory for LEZ programs. Developers register their deployed program IDs along with human-readable metadata and a Codex CID pointing to the program's IDL JSON stored on Logos Storage.

---

## What it does

- **Register** a new program: anyone can register their program. The signer becomes the author and only they may later update the entry.
- **Update** an existing entry: only the original author (signer) is allowed to update metadata.
- Metadata is stored on-chain in two PDA types:
  - `RegistryState` — singleton tracking global registry statistics (program count, authority)
  - `ProgramEntry` — per-program metadata (name, version, author, IDL CID, description, tags, registration timestamp)

## Crate structure

```
lez-registry/
├── registry_core/       # Shared types: Instructions, ProgramEntry, RegistryState, PDA helpers
├── registry_program/    # On-chain handlers: register.rs, update.rs
├── methods/             # risc0 build crate
│   └── guest/           # zkVM guest binary (registry.rs)
├── cli/                 # registry CLI — register, update, list, info, status
├── e2e_tests/           # End-to-end tests (runs against a local sequencer)
├── registry-idl.json    # IDL schema for the registry program itself
└── Makefile             # build, check, test, idl targets
```

## Relationship to lez-multisig

`lez-registry` is **standalone** — it has no dependency on `lez-multisig`. The multisig is a _consumer_ of the registry (it registers itself), not part of it.

## Quick start

```bash
# Check that everything compiles
make check

# Build the guest binary (requires risc0 toolchain)
make build

# Run unit tests
make test
```

## CLI usage

```bash
# Register a program
registry register \
  --account <your-account-id> \
  --program-id <64-hex-chars> \
  --name lez-multisig \
  --version 0.1.0 \
  --idl-cid <codex-cid> \
  --description "Multi-signature wallet program" \
  --tag governance --tag multisig

# Update an existing entry
registry update \
  --account <your-account-id> \
  --program-id <64-hex-chars> \
  --version 0.2.0

# Show registry status
registry status

# Generate shell completions
registry completions bash
```

## IDL

The `registry-idl.json` file describes the program's interface (instructions, accounts, argument types). Programs registered in the registry link to their own IDL via a Codex CID.

## Architecture

The registry uses the NSSA (Non-Sovereign Smart Account) framework:

- Instructions are serialized as `registry_core::Instruction` (serde JSON)
- The zkVM guest (`methods/guest/src/bin/registry.rs`) is the on-chain binary, verified by risc0
- PDA seeds ensure deterministic account addresses per program ID
- The CLI talks to the LEZ sequencer via the `nssa`/`wallet` client libraries

## License

See [LICENSE](LICENSE).
