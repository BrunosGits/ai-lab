# Branch Strategy

How branches are managed in the expandir fork.

## Branches

| Branch | Purpose | Tracks |
|--------|---------|--------|
| `dev` | Main development | upstream main |
| `feature/*` | Feature branches | dev |

## Syncing with Upstream

```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream into dev
git checkout dev
git merge upstream/dev

# Or rebase (cleaner history)
git checkout dev
git rebase upstream/dev
```

## Creating Feature Branches

```bash
# Create from dev
git checkout dev
git checkout -b feature/my-feature

# When done
git checkout dev
git merge feature/my-feature
git branch -d feature/my-feature
```

## Tags

- `expandir-0.1.0` — Fork point (identical to espanso v2.2.3)
- Future tags: `expandir-0.2.0`, etc.

## Upstream Management

- Upstream remote: `espanso/espanso`
- Sync monthly or when upstream has important changes
- Don't sync too often — keep changes small and manageable
