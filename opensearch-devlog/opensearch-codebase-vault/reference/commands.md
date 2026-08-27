---
type: reference
tags: [opensearch, commands, gradle, git, gh]
---

# Useful Commands

## Gradle

```bash
# Build the project
./gradlew build

# Run a single test class
./gradlew :server:test --tests "org.opensearch.package.ClassName"

# Run a single test method
./gradlew :server:test --tests "org.opensearch.package.ClassName.methodName"

# Run integration tests
./gradlew :qa:randomized-testing:integrationTest

# Run sandbox tests
./gradlew :sandbox:qa:analytics-engine-coordinator:internalClusterTest

# Run REST tests
./gradlew :qa:rest:integrationTest

# Generate coverage report
./gradlew jacocoTestReport

# Check for compilation errors
./gradlew assemble
```

## Git

```bash
# Create a feature branch
git checkout -b fix/issue-number-description

# Amend a commit with sign-off
git commit --amend -s

# Fix DCO sign-off on last commit
git commit --amend -s --no-edit

# Rebase on main
git rebase main

# Force push after rebase (on your own branch only)
git push origin fix/issue-number-description --force-with-lease
```

## GitHub CLI

```bash
# Check PR status
gh pr checks <number>

# View PR details
gh pr view <number>

# Create a PR
gh pr create --head BrunosGits:branch-name

# Comment on a PR
gh pr comment <number> --body "your comment"

# Check CI status
gh run list --repo opensearch-project/OpenSearch --limit 5
```

## Running Tests

From [[testing-patterns]], the test command depends on the test type:

| Test Type | Command |
|-----------|---------|
| Unit test | `./gradlew :module:test --tests "FQCN"` |
| Integration test | `./gradlew :module:integrationTest` |
| REST test | `./gradlew :qa:rest:integrationTest` |
| Sandbox test | `./gradlew :sandbox:qa:module:internalClusterTest` |
