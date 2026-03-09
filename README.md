# SPELbook — On-Chain Program Registry

> **SPELbook** = the registry where all **SPEL** programs are listed.
>
> Just like a spellbook catalogues spells, SPELbook catalogues on-chain programs — their IDs, versions, authors, and IDLs. If you deployed it on LEZ, it belongs in the book.

Built with [SPEL](https://github.com/logos-co/spel) — the Anchor-inspired developer framework for LEZ programs.

---

## What it does

- **Register** a program: anyone can register their deployed program ID along with metadata and a Logos Storage CID pointing to the IDL.
- **Update** an existing entry: only the original author may update.
- **Discover** programs: query by name, author, or program ID.

On-chain state:
- `RegistryState` — global stats (program count, authority)
- `ProgramEntry` — per-program metadata (name, version, author, IDL CID, description, tags, timestamp)

## Quick Start

```bash
make check        # Compile host crates (no risc0 needed)
make build        # Build zkVM guest binary
make idl          # Generate IDL
make cli ARGS="--help"
```

## CLI Usage

```bash
# Register a program
registry -p registry.bin register \
  --name my-program \
  --version 0.1.0 \
  --idl-path ./my-program.json        # auto-uploads to Logos Storage \
  --description "My LEZ program" \
  --program-id 1673032724,3536244476,...

# Update an entry
registry -p registry.bin update \
  --program-id 1673032724,... \
  --version 0.2.0
```

## Crate structure

```
spelbook/
├── registry_core/       # Shared types: Instructions, ProgramEntry, RegistryState
├── registry_program/    # On-chain handlers: register.rs, update.rs
├── methods/guest/       # zkVM guest binary
├── cli/                 # 3-line CLI wrapper (IDL-driven)
└── Makefile
```

## Relationship to SPEL ecosystem

SPELbook is a standalone LEZ program. The multisig is a consumer of SPELbook (it registers itself), not part of it. Both are built using SPEL framework.

## v0.1.0

Tagged [v0.1.0](https://github.com/logos-co/spelbook/releases/tag/v0.1.0).

## License

MIT
