# Makefile for setting up binstaller and ghcp

# Variables
BINSTALLER_VERSION := v0.10.2
BINSTALLER_URL := https://github.com/binary-install/binstaller/releases/download/$(BINSTALLER_VERSION)
GHCP_VERSION := v1.15.0
BIN_DIR := ./bin
BINSTALLER := $(BIN_DIR)/binst
CONFIG_FILE := .config/binstaller/ghcp.yml
RUNNER_SCRIPT := run-ghcp.sh

.PHONY: all
all: install-binstaller $(CONFIG_FILE) $(RUNNER_SCRIPT) ## Install binstaller and generate all files (default)

.PHONY: install-binstaller
install-binstaller: $(BINSTALLER) ## Install binstaller to ./bin

$(BINSTALLER): | $(BIN_DIR)
	@echo "Installing binstaller $(BINSTALLER_VERSION) to $(BIN_DIR)..."
	@if command -v cosign >/dev/null 2>&1; then \
		echo "Using cosign for verification..."; \
		curl -sL "$(BINSTALLER_URL)/install.sh" | \
			(tmpfile=$$(mktemp); cat > "$$tmpfile"; \
			 cosign verify-blob \
			   --certificate-identity-regexp '^https://github.com/actionutils/trusted-go-releaser/.github/workflows/trusted-release-workflow.yml@.*$$' \
			   --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
			   --certificate "$(BINSTALLER_URL)/install.sh.pem" \
			   --signature "$(BINSTALLER_URL)/install.sh.sig" \
			   "$$tmpfile" >/dev/null 2>&1 && \
			 sh "$$tmpfile" -b $(BIN_DIR); rm -f "$$tmpfile"); \
	elif command -v gh >/dev/null 2>&1; then \
		echo "Using gh attestation for verification..."; \
		curl -sL "$(BINSTALLER_URL)/install.sh" | \
			(tmpfile=$$(mktemp); cat > "$$tmpfile"; \
			 gh attestation verify --repo=binary-install/binstaller \
			   --signer-workflow='actionutils/trusted-go-releaser/.github/workflows/trusted-release-workflow.yml' \
			   "$$tmpfile" >/dev/null 2>&1 && \
			 sh "$$tmpfile" -b $(BIN_DIR); rm -f "$$tmpfile"); \
	else \
		echo "Warning: Neither cosign nor gh found, installing without verification..."; \
		curl -sL "$(BINSTALLER_URL)/install.sh" | sh -s -- -b $(BIN_DIR); \
	fi
	@echo "binstaller installed successfully!"

# Generate ghcp configuration
$(CONFIG_FILE): $(BINSTALLER)
	@echo "Generating ghcp configuration from aqua registry..."
	@mkdir -p .config/binstaller
	@$(BINSTALLER) init --source=aqua --repo=int128/ghcp -o $(CONFIG_FILE) --force
	@echo "Embedding checksums for $(GHCP_VERSION)..."
	@$(BINSTALLER) embed-checksums --config $(CONFIG_FILE) --version $(GHCP_VERSION) --mode calculate
	@echo "Configuration generated at $(CONFIG_FILE)"

# Generate runner script
$(RUNNER_SCRIPT): $(BINSTALLER) $(CONFIG_FILE)
	@echo "Generating runner script for version $(GHCP_VERSION)..."
	@$(BINSTALLER) gen --config $(CONFIG_FILE) --type=runner --target-version $(GHCP_VERSION) -o $(RUNNER_SCRIPT)
	@chmod +x $(RUNNER_SCRIPT)
	@echo "Runner script generated at $(RUNNER_SCRIPT)"

# Create bin directory if it doesn't exist
$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

.PHONY: clean
clean: ## Remove generated configuration and runner script
	@echo "Cleaning generated files..."
	@rm -f $(RUNNER_SCRIPT)
	@rm -f $(CONFIG_FILE)
	@echo "Clean complete"

.PHONY: clean-all
clean-all: clean ## Remove all generated files including binstaller
	@echo "Removing binstaller..."
	@rm -f $(BINSTALLER)
	@rmdir $(BIN_DIR) 2>/dev/null || true
	@echo "Full clean complete"

.PHONY: test-runner
test-runner: $(RUNNER_SCRIPT) ## Test runner script with --version
	@echo "Testing runner script..."
	@./$(RUNNER_SCRIPT) -- --version

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
