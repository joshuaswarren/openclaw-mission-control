#!/bin/bash
# Update local deployment with latest upstream + your features
#
# For AI Agents: Run this when the user wants to "update from upstream"
# or "get latest changes" or "sync with main repo"
# This script: syncs master from upstream, rebases feat/pluggable-auth,
# merges into local branch, and redeploys Docker containers
#

set -e

echo "🔄 Updating local Mission Control..."

# 1. Save current branch
CURRENT_BRANCH=$(git branch --show-current)

# 2. Update master from upstream
echo "📥 Syncing master with upstream..."
git checkout master
git fetch upstream
git rebase upstream/master
git push fork master

# 3. Rebase feature branch on latest master
echo "🔀 Rebasing feature branch..."
git checkout feat/pluggable-auth
git rebase master || {
    echo "❌ Rebase failed. Resolve conflicts manually:"
    echo "   git status"
    echo "   # Fix files"
    echo "   git add -A"
    echo "   git rebase --continue"
    exit 1
}
git push fork feat/pluggable-auth --force-with-lease

# 4. Update local branch
echo "🔄 Updating local integration branch..."
git checkout local
git rebase master
git merge feat/pluggable-auth --no-edit || true

# 5. Deploy
echo "🚀 Rebuilding and deploying..."
docker compose -f compose.yml --env-file .env up -d --build

# 6. Restore original branch
git checkout "$CURRENT_BRANCH"

echo "✅ Done! Your local Mission Control is updated."
echo ""
echo "Check status with: docker compose -f compose.yml --env-file .env logs -f --tail=50"
