# lez-registry — Make Targets
#
# Prerequisites:
#   - Rust stable toolchain installed
#   - risc0 toolchain installed (for `make build`)
#   - wallet CLI installed (for `make deploy`)
#   - Sequencer running locally (for e2e tests)
#
# Quick start:
#   make check      # verify compilation
#   make build      # build the guest zkVM binary
#   make test       # run unit tests

SHELL := /bin/bash
PROGRAMS_DIR := target/riscv32im-risc0-zkvm-elf/docker

REGISTRY_BIN := $(PROGRAMS_DIR)/registry.bin

# ── Targets ──────────────────────────────────────────────────────────────────

.PHONY: help build build-cli check test idl deploy clean

help: ## Show this help
	@echo "lez-registry — Make Targets"
	@echo ""
	@echo "  make check          Check that all crates compile (no risc0 toolchain needed)"
	@echo "  make build          Build the registry zkVM guest binary"
	@echo "  make build-cli      Build the registry CLI"
	@echo "  make test           Run unit tests (registry_core, registry_program)"
	@echo "  make idl            Pretty-print the registry IDL"
	@echo "  make deploy         Deploy registry program to sequencer"
	@echo "  make clean          Remove build artifacts"

check: ## Verify all crates compile (skips guest binary build)
	cargo check -p registry_core -p registry_program -p registry-cli
	@echo ""
	@echo "✅ cargo check passed"

build: ## Build the registry zkVM guest binary
	cargo risczero build --manifest-path methods/guest/Cargo.toml
	@echo ""
	@echo "✅ Guest binary built: $(REGISTRY_BIN)"
	@ls -la $(REGISTRY_BIN)

build-cli: ## Build the standalone registry CLI
	cargo build --bin registry -p registry-cli
	@echo ""
	@echo "✅ CLI built: target/debug/registry"

test: ## Run unit tests
	cargo test -p registry_core -p registry_program
	@echo ""
	@echo "✅ Unit tests passed"

idl: ## Display the registry IDL
	@cat registry-idl.json | python3 -m json.tool 2>/dev/null || cat registry-idl.json

deploy: ## Deploy registry program to sequencer (requires make build first)
	@test -f "$(REGISTRY_BIN)" || (echo "ERROR: Registry binary not found. Run 'make build' first."; exit 1)
	wallet deploy-program $(REGISTRY_BIN)
	@echo ""
	@echo "✅ Registry program deployed"

clean: ## Remove build artifacts
	cargo clean
	@echo "✅ Build artifacts cleaned"
