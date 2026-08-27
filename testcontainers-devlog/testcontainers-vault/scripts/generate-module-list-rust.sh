#!/bin/bash
# Generate Rust module list from testcontainers-rs core crate
# Outputs markdown table for Modules-INDEX.md

set -e

CRATE_DIR="/home/bruno/ai-lab/testcontainers-rs/testcontainers/src"
OUTPUT_FILE="/Users/bruno.lima/opencode/main/testcontainers-devlog/testcontainers-vault/tables/rust-modules.md"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "| Module | Category | Description | Status |" > "$OUTPUT_FILE"
echo "|--------|----------|-------------|--------|" >> "$OUTPUT_FILE"

# Scan images directory for module files
for module_file in "$CRATE_DIR/images"/*.rs; do
    [ -f "$module_file" ] || continue
    
    module_name=$(basename "$module_file" .rs)
    
    # Skip core files
    case "$module_name" in
        generic|mod) continue ;;
    esac
    
    # Extract description from file
    desc=$(grep -E "^//!|^///" "$module_file" | head -3 | sed 's|^//! ||; s|^/// ||' | tr '\n' ' ' | sed 's/|/\\|/g' | head -c 80)
    [ -z "$desc" ] && desc="Core module"
    
    # Determine category
    category="Other"
    case "$module_name" in
        postgres|mysql|redis|sqlite) category="Databases (SQL)" ;;
        mongo|cassandra|redis) category="Databases (NoSQL)" ;;
        kafka|rabbitmq|pulsar) category="Message Queues" ;;
        localstack|gcloud|azure) category="Cloud/Infra" ;;
        elasticsearch|clickhouse|prometheus) category="Search/Analytics" ;;
        selenium|webdriver) category="Web/UI" ;;
        *) category="Specialized" ;;
    esac
    
    status="✅"
    
    echo "| $module_name | $category | $desc | $status |" >> "$OUTPUT_FILE"
done

# Also check for modules in testcontainers-modules-community if available
COMMUNITY_DIR="/home/bruno/ai-lab/testcontainers-rs-modules-community"
if [ -d "$COMMUNITY_DIR/modules" ]; then
    echo "" >> "$OUTPUT_FILE"
    echo "| Module | Category | Description | Status |" >> "$OUTPUT_FILE"
    echo "|--------|----------|-------------|--------|" >> "$OUTPUT_FILE"
    
    for module_dir in "$COMMUNITY_DIR/modules"/*/; do
        [ -d "$module_dir" ] || continue
        module_name=$(basename "$module_dir")
        
        desc=$(grep -E "description\s*=" "$module_dir/Cargo.toml" 2>/dev/null | head -1 | sed -E 's/.*description\s*=\s*"([^"]*)".*/\1/' || echo "Community module")
        
        echo "| $module_name (community) | Community | $desc | 📦 |" >> "$OUTPUT_FILE"
    done
fi

echo "Generated $OUTPUT_FILE"