---
type: codebase
module: sandbox
tags: [opensearch, sandbox, experimental]
---

# Sandbox

Experimental features. Disabled by default. Enable with `-Dsandbox.enabled=true`.

Path: `sandbox/`

## Plugins (`sandbox/plugins/`)

| Plugin | Purpose |
|--------|---------|
| `analytics-engine` | Analytics query execution, stage management, transport |
| `analytics-backend-datafusion` | DataFusion backend (Rust) for analytics queries |
| `analytics-backend-lucene` | Lucene backend for analytics queries |
| `composite-engine` | Composite index engine |
| `dsl-query-executor` | DSL query execution |
| `block-cache-foyer` | Block cache (Rust) |
| `parquet-data-format` | Parquet file format support |
| `native-repository-s3` | S3 snapshot repository |
| `native-repository-gcs` | GCS snapshot repository |
| `native-repository-azure` | Azure snapshot repository |
| `native-repository-fs` | Filesystem snapshot repository |
| `test-ppl-frontend` | PPL (Piped Processing Language) frontend for testing |

## QA Modules (`sandbox/qa/`)

| Module | Purpose |
|--------|---------|
| `analytics-engine-coordinator` | Coordinator-side integration tests for analytics |
| `analytics-engine-rest` | REST-level integration tests for analytics |

## Key Files We Touched

- `AnalyticsSearchService.java` — query execution, fetch by row IDs
- `LateMaterializationStageExecution.java` — LM stage scatter/gather
- `StageTask.java` — per-stage task with metrics
- `QueryProfileBuilder.java` — profile output construction
- `FetchByRowIdsRequest.java` — wire format for fetch requests
- `AnalyticsQueryTaskCleanupIT.java` — flaky test (fixed in [[22750-flaky-test-fix]])

## Why Sandbox Exists

From [[00-contributing-guide]]:
> Significant core changes (search phases, codecs, specialized Lucene APIs) are more likely to merge if sandboxed. Sandbox is disabled by default.

Sandbox has no BWC guarantees. Wire formats can change freely between versions.

## Running Sandbox ITs (learned 2026-09-17)

Sandbox modules need JDK 25+ and are excluded from the build unless explicitly enabled — pass `-Dsandbox.enabled=true` **with `--no-daemon`**, otherwise a warm daemon can ignore the sysprop and the `:sandbox:*` projects stay invisible. The Rust native library (`sandbox/libs/dataformat-native`) needs `protoc` installed (`apt-get install protobuf-compiler`) or the `substrait` crate build fails.

On a ≤4G RAM box the release link of `opensearch-native-lib` OOMs (`lto=true, codegen-units=1` in `[profile.release]`). Workaround that keeps the fix test-only: `CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 CARGO_BUILD_JOBS=1` — deps rebuild once (~70 min cold, ~9 min warm), then the link fits. Full command:

```
./gradlew --no-daemon -Dsandbox.enabled=true :sandbox:qa:analytics-engine-coordinator:internalClusterTest --tests '<FQCN>'
```

## Related

- [[00-overview]] — top-level layout
- [[transport-layer]] — streaming transport used by analytics
- [[query-flow]] — analytics query flow
- [[22706-flaky-test]] — the flaky test we fixed
- [[22676-lm-profile]] — the profile metrics we reviewed
