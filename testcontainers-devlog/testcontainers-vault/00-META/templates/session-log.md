# Session Log: YYYY-MM-DD

## Date
YYYY-MM-DD

## Issues Worked On
1. **<Repo> #<Issue>** - <Brief description>
2. ...

## Summary
...

## Commands Run (VPS)
```bash
# Java
cd /home/bruno/ai-lab/testcontainers-java
./gradlew --no-daemon :testcontainers:compileJava
./gradlew --no-daemon :testcontainers:test --tests '*GenericContainer*'

# Rust
cd /home/bruno/ai-lab/testcontainers-rs
cargo +nightly fmt --all -- --check
cargo clippy
cargo test --features blocking
```

## Next Steps
- ...