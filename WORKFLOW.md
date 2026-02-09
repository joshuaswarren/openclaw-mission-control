# Local Development Workflow

> **For AI Agents:** Quick reference for updating and deploying. See `AGENTS.md` for full documentation.

## Quick Commands

```bash
# Deploy current local branch
docker compose -f compose.yml --env-file .env up -d --build

# Update from upstream (one command)
./scripts/update-local.sh

# Check status
git branch -vv && docker compose ps
```

## Branch Strategy

```
upstream/master ──────────────────────────────────────────
                       \
                        \
fork/master (sync) ───────┬──────┬──────┬────────────────
                          │      │      │
                          ▼      ▼      ▼
                    feat/auth  feat/x  feat/y
                          │      │      │
                          └──────┼──────┘
                                 ▼
                          fork/local (YOUR DEPLOYMENT)
```

- **fork/master**: Tracks upstream, never commit here (only sync)
- **feat/***: Individual feature branches for PRs
- **fork/local**: Integration branch combining upstream + your features (for deployment)

## Daily Workflow

### Update to latest upstream + your changes:
```bash
# 1. Sync your fork's master with upstream
git checkout master
git fetch upstream
git rebase upstream/master
git push fork master

# 2. Rebase your feature branch on latest master
git checkout feat/pluggable-auth
git rebase master

# 3. Update your local deployment branch
git checkout local
git rebase master
git merge feat/pluggable-auth --no-edit

# 4. Deploy
docker compose up -d --build
```

### Add a new feature:
```bash
git checkout master
git pull upstream master
git checkout -b feat/my-new-feature
# ... make changes ...
git commit -m "feat: my new feature"
git push fork feat/my-new-feature
# Create PR

# Then merge into local for immediate use
git checkout local
git merge feat/my-new-feature --no-edit
```

## Deployment Commands

```bash
# Rebuild with latest code
docker compose -f compose.yml --env-file .env up -d --build

# Just restart containers (no rebuild)
docker compose -f compose.yml --env-file .env restart

# View logs
docker compose -f compose.yml --env-file .env logs -f --tail=100
```
