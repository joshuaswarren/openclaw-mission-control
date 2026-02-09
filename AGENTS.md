# Agent Guide: OpenClaw Mission Control

> **For AI Agents:** This document explains how this repository is organized and how to work with it safely.

## Repository Overview

This is a **fork** of `abhi1693/openclaw-mission-control` with local customizations for self-hosted deployment.

**Key Remotes:**
- `upstream` → `https://github.com/abhi1693/openclaw-mission-control.git` (original repo)
- `fork` → `https://github.com/joshuaswarren/openclaw-mission-control.git` (your fork)
- `origin` → Same as `upstream` (may vary)

## Branch Strategy (CRITICAL)

```
upstream/master ──────────────────────────────────────────
                       \
                        \
fork/master ────────────┬──────┬──────┬────────────────
                        │      │      │
                        ▼      ▼      ▼
                  feat/auth  feat/x  feat/y  (PR branches)
                        │      │      │
                        └──────┼──────┘
                               ▼
                        fork/local ←── YOU ARE HERE (deployment)
```

### Branch Purposes

| Branch | Purpose | Do Not... |
|--------|---------|-----------|
| `master` | Sync with upstream | Commit local changes here |
| `feat/*` | Individual feature PRs | Merge other features into these |
| `local` | **Active deployment** | Force push, delete, or rebase |

### Golden Rules

1. **Never commit to `master`** - It's only for syncing with upstream
2. **Never force-push `local`** - It's your running deployment state
3. **One feature = One `feat/` branch** - Keep PRs clean and focused
4. **Always rebase `feat/` on `master` before PR** - Keeps history clean

## Quick Reference

### Deploy Current Local Branch
```bash
cd ~/src/openclaw-mission-control
git checkout local
docker compose -f compose.yml --env-file .env up -d --build
```

### Update to Latest Upstream
```bash
./scripts/update-local.sh
```

### Check Current State
```bash
git branch -vv                    # See all branches and tracking
git log --oneline --graph -10     # See recent history
docker compose ps                 # Check container status
```

## Workflows

### Workflow 1: Update from Upstream

```bash
# Step 1: Update master from upstream
git checkout master
git fetch upstream
git rebase upstream/master
git push fork master

# Step 2: Rebase your feature branch
git checkout feat/pluggable-auth
git rebase master
# Resolve any conflicts
git push fork feat/pluggable-auth --force-with-lease

# Step 3: Update local deployment branch
git checkout local
git rebase master
git merge feat/pluggable-auth --no-edit

# Step 4: Deploy
docker compose -f compose.yml --env-file .env up -d --build
```

### Workflow 2: Create New Feature for PR

```bash
# Step 1: Start from clean master
git checkout master
git pull upstream master

# Step 2: Create feature branch
git checkout -b feat/my-new-feature

# Step 3: Make changes, commit
git add -A
git commit -m "feat: description of feature"

# Step 4: Push and create PR
git push -u fork feat/my-new-feature
gh pr create --repo abhi1693/openclaw-mission-control --base master

# Step 5: Also merge to local for immediate use
git checkout local
git merge feat/my-new-feature --no-edit
docker compose up -d --build
```

### Workflow 3: Fix Merge Conflicts on PR Branch

```bash
git checkout feat/pluggable-auth
git fetch upstream
git rebase upstream/master

# Fix conflicts in files...
git add -A
git rebase --continue

git push fork feat/pluggable-auth --force-with-lease
```

## Common Tasks

### Check What Features Are in Local Branch
```bash
git log --oneline local --not master
```

### See Which Feature Branches Are Merged
```bash
git branch --merged local | grep feat/
```

### Temporarily Test Upstream Version
```bash
# Save current state
git checkout -b local-backup

# Test upstream
git checkout master
docker compose up -d --build

# Go back to your version
git checkout local
docker compose up -d --build
```

## Troubleshooting

### "Already up to date" but you know there are changes
```bash
git fetch upstream
git log master..upstream/master --oneline  # See what's missing
git checkout master
git rebase upstream/master
```

### Merge conflicts in local branch
```bash
# Abort current merge
git merge --abort

# Hard reset to last known good state
git reflog  # Find last good commit
git reset --hard abc1234

# Then recreate local properly
git checkout master
git pull upstream master
git branch -D local
git checkout -b local
# Re-merge features
```

### Docker issues after update
```bash
# Clean build
docker compose down -v  # WARNING: deletes DB data!
docker compose up -d --build

# Or just restart containers
docker compose restart
```

## Environment Configuration

Your `.env` file contains local settings:

```bash
# Location: ~/src/openclaw-mission-control/.env (NOT committed)
# Key settings:
AUTH_MODE=local_bearer
LOCAL_AUTH_TOKEN=9ff9f9c1867c76d71efd57877bc032af
NEXT_PUBLIC_API_URL=http://100.83.54.18:8333
```

**Never commit .env files** - They contain secrets and host-specific config.

## Architecture Notes

### Authentication Flow (Local)

1. User visits http://100.83.54.18:3333
2. Frontend checks `NEXT_PUBLIC_AUTH_MODE`
3. If `local_bearer` and no token stored → Show `LocalAuthLogin` form
4. User enters token → Stored in `sessionStorage`
5. API calls include `Authorization: Bearer <token>` header
6. Backend validates token against `LOCAL_AUTH_TOKEN` env var

### Gateway Connection

- Gateway URL in DB must use `host.docker.internal` (not `127.0.0.1`)
- Gateway token must match `~/.openclaw/openclaw.json` auth token

## When to Ask for Help

Stop and ask the user if:
1. You see force-push warnings on `local` branch
2. There are uncommitted changes you don't understand
3. Multiple feature branches have conflicts with each other
4. The Docker environment won't start after updates

---

# Repository Guidelines (Original)

## Project Structure & Module Organization
- `backend/`: FastAPI service.
  - App code: `backend/app/` (routes `backend/app/api/`, models `backend/app/models/`, schemas `backend/app/schemas/`, workers `backend/app/workers/`).
  - DB migrations: `backend/migrations/` (generated versions in `backend/migrations/versions/`).
  - Tests: `backend/tests/`.
- `frontend/`: Next.js app.
  - Routes: `frontend/src/app/`; shared UI: `frontend/src/components/`; utilities: `frontend/src/lib/`.
  - Generated API client: `frontend/src/api/generated/` (do not edit by hand).
  - Tests: colocated `*.test.ts(x)` (example: `frontend/src/lib/backoff.test.ts`).
- `templates/`: shared templates packaged into the backend image (used by gateway integrations).
- `docs/`: protocol/architecture notes (see `docs/openclaw_gateway_ws.md`).

## Build, Test, and Development Commands
From repo root:
- `make setup`: install/sync backend + frontend dependencies.
- `make check`: CI-equivalent suite (lint, typecheck, tests/coverage, frontend build).
- `docker compose -f compose.yml --env-file .env up -d --build`: run full stack (Postgres + Redis included).

Fast local dev:
- `docker compose -f compose.yml --env-file .env up -d db redis`
- Backend: `cd backend && uv sync --extra dev && uv run uvicorn app.main:app --reload --port 8000`
- Frontend: `cd frontend && npm install && npm run dev`
- API client: `make api-gen` (backend must be running on `127.0.0.1:8000`).

## Coding Style & Naming Conventions
- Python: Black + isort (line length 100), flake8 (`backend/.flake8`), strict mypy (`backend/pyproject.toml`). Use `snake_case`.
- TypeScript/React: ESLint (Next.js) + Prettier (`make frontend-format`). Components `PascalCase`, variables `camelCase`. Prefix intentionally-unused destructured props with `_` (see `frontend/eslint.config.mjs`).
- Optional: `pre-commit install` to run format/lint hooks locally.

## Testing Guidelines
- Backend: pytest (`backend/tests/`, files `test_*.py`). Run `make backend-test` or `make backend-coverage` (writes `backend/coverage.xml`).
- Frontend: vitest + testing-library. Run `make frontend-test` (writes `frontend/coverage/`).

## Commit & Pull Request Guidelines
- Commits: Conventional Commits (e.g., `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`, `refactor: ...`; optional scope like `feat(chat): ...`).
- PRs: include what/why, how to test (ideally `make check`), linked issue (if any), and screenshots for UI changes.

## Security & Configuration Tips
- Never commit secrets. Use `.env.example` as the template and keep real values in `.env`.
