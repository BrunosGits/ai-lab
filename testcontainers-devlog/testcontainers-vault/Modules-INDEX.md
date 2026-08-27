# Modules Index — Cross-Language Comparison

> Module catalog comparison across Java, Rust, and Python testcontainers implementations.

---

## 1. Module Count Summary

| Category | Java | Rust (Core) | Python |
|----------|------|-------------|--------|
| **Databases (SQL)** | 15+ | 5+ | 10+ |
| **Databases (NoSQL)** | 8+ | 3+ | 5+ |
| **Message Queues** | 6+ | 3+ | 4+ |
| **Cloud / Infrastructure** | 8+ | 2+ | 4+ |
| **Search / Analytics** | 5+ | 2+ | 3+ |
| **Web / UI** | 3+ | 1+ | 2+ |
| **Specialized / Other** | 10+ | 3+ | 5+ |
| **Total** | **60+** | **19+** | **30+** |

> **Note:** Rust count reflects core crate only (`testcontainers/src/`). Community modules are in separate repo.

---

## 2. Databases (SQL)

| Module | Java | Rust | Python |
|--------|------|------|--------|
| PostgreSQL | ✅ | ✅ | ✅ |
| MySQL | ✅ | ✅ | ✅ |
| MariaDB | ✅ | ✅ | ✅ |
| Oracle (Free/XE) | ✅ | ❌ | ❌ |
| SQL Server | ✅ | ❌ | ✅ |
| CockroachDB | ✅ | ❌ | ✅ |
| ClickHouse | ✅ | ❌ | ✅ |
| CrateDB | ✅ | ❌ | ✅ |
| DB2 | ✅ | ❌ | ❌ |
| Oracle Free | ✅ | ❌ | ❌ |
| Oracle XE | ✅ | ❌ | ❌ |
| OceanBase | ✅ | ❌ | ❌ |
| TiDB | ✅ | ❌ | ✅ |
| YugabyteDB | ✅ | ❌ | ✅ |
| Databend | ✅ | ❌ | ❌ |
| Presto/Trino | ✅ | ❌ | ❌ |

---

## 3. Databases (NoSQL)

| Module | Java | Rust | Python |
|--------|------|------|--------|
| MongoDB | ✅ | ✅ | ✅ |
| Redis | ✅ | ✅ | ✅ |
| Cassandra | ✅ | ❌ | ✅ |
| Couchbase | ✅ | ❌ | ✅ |
| CouchDB | ✅ | ❌ | ❌ |
| InfluxDB | ✅ | ❌ | ❌ |
| Neo4j | ✅ | ❌ | ❌ |
| OrientDB | ✅ | ❌ | ❌ |
| ScyllaDB | ✅ | ❌ | ❌ |
| Elasticsearch | ✅ | ❌ | ✅ |
| OpenSearch | ✅ | ❌ | ✅ |
| Typesense | ✅ | ❌ | ❌ |
| Pinecone | ✅ | ❌ | ❌ |
| Qdrant | ✅ | ❌ | ❌ |
| Milvus | ✅ | ❌ | ❌ |
| Weaviate | ✅ | ❌ | ❌ |

---

## 4. Message Queues

| Module | Java | Rust | Python |
|--------|------|------|--------|
| Kafka | ✅ | ✅ | ✅ |
| RabbitMQ | ✅ | ✅ | ✅ |
| Pulsar | ✅ | ❌ | ✅ |
| Redpanda | ✅ | ❌ | ❌ |
| Solace | ✅ | ❌ | ❌ |
| ActiveMQ | ✅ | ❌ | ❌ |
| Artemis | ✅ | ❌ | ❌ |
| RabbitMQ Streams | ✅ | ❌ | ❌ |
| Redis (as queue) | ✅ | ✅ | ✅ |

---

## 4. Cloud / Infrastructure

| Module | Java | Rust | Python |
|--------|------|------|--------|
| LocalStack | ✅ | ✅ | ✅ |
| GCloud | ✅ | ❌ | ✅ |
| Azure | ✅ | ❌ | ✅ |
| LocalStack Pro | ✅ | ❌ | ❌ |
| Vault | ✅ | ❌ | ✅ |
| Consul | ✅ | ❌ | ❌ |
| K3s | ✅ | ❌ | ❌ |
| Ollama | ✅ | ❌ | ✅ |
| OpenFGA | ✅ | ❌ | ❌ |

---

## 4. Search & Analytics

| Module | Java | Rust | Python |
|--------|------|------|--------|
| Elasticsearch | ✅ | ❌ | ✅ |
| OpenSearch | ✅ | ❌ | ❌ |
| ClickHouse | ✅ | ❌ | ✅ |
| QuestDB | ✅ | ❌ | ❌ |
| Presto | ✅ | ❌ | ❌ |
| Trino | ✅ | ❌ | ❌ |
| Timeplus | ✅ | ❌ | ❌ |
| InfluxDB | ✅ | ❌ | ❌ |
| Grafana | ✅ | ❌ | ❌ |
| Prometheus | ❌ | ❌ | ❌ |

---

## 4. Web / UI

| Module | Java | Rust | Python |
|--------|------|------|--------|
| Selenium | ✅ | ❌ | ✅ |
| Webdriver | ✅ | ❌ | ❌ |
| VncRecording | ✅ | ❌ | ❌ |
| Playwright | ❌ | ❌ | ❌ |

---

## 4. Specialized / Other

| Module | Java | Rust | Python |
|--------|------|------|--------|
| Toxiproxy | ✅ | ❌ | ✅ |
| MockServer | ✅ | ❌ | ❌ |
| WireMock | ✅ | ❌ | ❌ |
| Testcontainers MCP Gateway | ✅ | ❌ | ❌ |
| Docker Model Runner | ✅ | ❌ | ❌ |
| Toxiproxy | ✅ | ❌ | ✅ |
| Vault | ✅ | ❌ | ✅ |
| MinIO | ✅ | ❌ | ✅ |
| Nginx | ✅ | ❌ | ❌ |
| Solr | ✅ | ❌ | ❌ |
| Solace | ✅ | ❌ | ❌ |
| Pulsar | ✅ | ❌ | ❌ |
| Redpanda | ✅ | ❌ | ❌ |
| K3s | ✅ | ❌ | ❌ |
| k6 | ✅ | ❌ | ❌ |
| HiveMQ | ✅ | ❌ | ❌ |
| ActiveMQ | ✅ | ❌ | ❌ |
| Camel | ✅ | ❌ | ❌ |

---

## 5. Module Status Legend

| Status | Meaning |
|--------|---------|
| ✅ | Available in core/modules |
| ❌ | Not available in core |
| 🔄 | In development / incubating |
| 📦 | Community module (separate repo) |

---

## 6. Automation

### Generate Module Lists

Run the automation scripts to update this table:

```bash
# Java: scans modules/*/build.gradle
./scripts/generate-module-list-java.sh

# Rust: scans testcontainers/src/ Cargo.toml files
./scripts/generate-module-list-rust.sh

# Python: parses pyproject.toml for module definitions
./scripts/generate-module-list-python.sh

# Update all
./scripts/update-indexes.sh
```

### Script Outputs

| Script | Output |
|--------|--------|
| `generate-module-list-java.sh` | `tables/java-modules.md` |
| `generate-module-list-rust.sh` | `tables/rust-modules.md` |
| `generate-module-list-python.sh` | `tables/python-modules.md` |