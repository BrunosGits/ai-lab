#!/bin/bash
# Generate Java module list from testcontainers-java modules
# Outputs markdown table for Modules-INDEX.md

set -e

MODULES_DIR="/home/bruno/ai-lab/testcontainers-java/modules"
OUTPUT_FILE="/Users/bruno.lima/opencode/main/testcontainers-devlog/testcontainers-vault/tables/java-modules.md"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "| Module | Category | Description | Status |" > "$OUTPUT_FILE"
echo "|--------|----------|-------------|--------|" >> "$OUTPUT_FILE"

for module_dir in "$MODULES_DIR"/*/; do
    [ -d "$module_dir" ] || continue
    module_name=$(basename "$module_dir")
    
    # Skip build.gradle and non-module directories
    [ -f "$module_dir/build.gradle" ] || continue
    
    # Extract description from build.gradle
    desc=$(grep -E "description\s*=" "$module_dir/build.gradle" | head -1 | sed -E 's/.*description\s*=\s*"([^"]*)".*/\1/' || echo "")
    
    # Determine category from directory structure
    category="Other"
    case "$module_name" in
        *postgres*|*mysql*|*maria*|*oracle*|*sqlserver*|*cockroach*|*clickhouse*|*cratedb*|*db2*|*databend*|*presto*|*trino*|*tidb*|*yugabyte*|*oceanbase*) category="Databases (SQL)" ;;
        *mongo*|*redis*|*cassandra*|*couchbase*|*couchdb*|*influx*|*neo4j*|*orient*|*scylla*|*elasticsearch*|*opensearch*|*typesense*|*pinecone*|*qdrant*|*milvus*|*weaviate*) category="Databases (NoSQL)" ;;
        *kafka*|*rabbit*|*pulsar*|*redpanda*|*solace*|*activemq*|*artemis*) category="Message Queues" ;;
        *localstack*|*gcloud*|*azure*|*vault*|*consul*|*k3s*|*ollama*|*openfga*) category="Cloud/Infra" ;;
        *elasticsearch*|*opensearch*|*clickhouse*|*questdb*|*presto*|*trino*|*timeplus*|*influx*|*grafana*) category="Search/Analytics" ;;
        *selenium*|*webdriver*|*vnc*) category="Web/UI" ;;
        *) category="Specialized" ;;
    esac
    
    # Status
    if [ -f "$module_dir/src/main/java/org/testcontainers/containers/${module_name^}Container.java" ] || [ -f "$module_dir/src/main/java/org/testcontainers/containers/${module_name}Container.java" ]; then
        status="✅"
    else
        status="🔄"
    fi
    
    echo "| $module_name | $category | $desc | $status |" >> "$OUTPUT_FILE"
done

echo "Generated $OUTPUT_FILE with $(grep -c '^|' "$OUTPUT_FILE") modules"