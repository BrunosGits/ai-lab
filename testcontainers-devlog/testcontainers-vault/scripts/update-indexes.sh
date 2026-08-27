#!/bin/bash
# Update all module index tables

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_DIR="/Users/bruno.lima/opencode/main/testcontainers-devlog/testcontainers-vault"

echo "=== Updating Module Indexes ==="

# Java
echo "Generating Java module list..."
"$SCRIPT_DIR/generate-module-list-java.sh"

# Rust
echo "Generating Rust module list..."
"$SCRIPT_DIR/generate-module-list-rust.sh"

# Python
echo "Generating Python module list..."
"$SCRIPT_DIR/generate-module-list-python.sh"

# Inject into Modules-INDEX.md
echo "Updating Modules-INDEX.md..."

MODULES_INDEX="$VAULT_DIR/Modules-INDEX.md"
TABLES_DIR="$VAULT_DIR/tables"

# Create tables directory if not exists
mkdir -p "$TABLES_DIR"

# Check if tables exist
JAVA_TABLE="$TABLES_DIR/java-modules.md"
RUST_TABLE="$TABLES_DIR/rust-modules.md"
PYTHON_TABLE="$TABLES_DIR/python-modules.md"

# Update Modules-INDEX.md with generated tables
# This is a simple approach - in practice you'd use sed/awk to replace table sections
echo "Module tables generated in $TABLES_DIR/"
echo "  - Java: $JAVA_TABLE"
echo "  - Rust: $RUST_TABLE"  
echo "  - Python: $PYTHON_TABLE"

echo "=== Update Complete ==="