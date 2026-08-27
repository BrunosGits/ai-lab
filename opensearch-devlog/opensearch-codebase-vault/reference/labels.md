---
type: reference
tags: [opensearch, labels, github]
---

# Issue and PR Labels

Common labels on OpenSearch issues and PRs.

## Priority Labels

| Label | Meaning |
|-------|---------|
| `>breaking` | Breaking change |
| `>enhancement` | New feature or improvement |
| `>bug` | Bug fix |
| `>flaky-test` | Flaky test |
| `>tech-debt` | Technical debt |

## Status Labels

| Label | Meaning |
|-------|---------|
| `v2.19.0` | Target version |
| `v3.0.0` | Target version |
| `untriaged` | Not yet triaged |
| `discuss` | Needs discussion |

## Area Labels

| Label | Meaning |
|-------|---------|
| `distributed` | Distributed systems |
| `Indexing` | Indexing |
| `Search` | Search |
| `Plugins` | Plugins |
| `Build` | Build system |
| `Analytics` | Analytics engine |

## Contributor Labels

| Label | Meaning |
|-------|---------|
| `backport` | Needs backport to release branch |
| `backport 2.x` | Backport to 2.x |
| `skip-changelog` | Skip changelog entry |
| `CI` | CI related |

## How We Use Labels

- Look for `v2.x` or `v3.x` labels to know target versions
- `>breaking` means it needs special attention
- `backport` means it needs to be cherry-picked to release branches
- `skip-changelog` means no changelog entry needed
