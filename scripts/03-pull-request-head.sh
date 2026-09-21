#!/usr/bin/env bash
# Route 3: a pull request head. GitHub keeps every PR head under refs/pull/N/head.
# Closing the pull request and deleting the branch does not remove it.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

BRANCH="demo/pull-request-head"
git checkout -q -b "$BRANCH"
payload 03-pr > pr-secret.txt
git add pr-secret.txt
git commit -q -m "Add feature flag config"
git push -q origin "$BRANCH"
FIRST="$(git rev-parse HEAD)"

PR_URL="$(gh pr create --repo "$SLUG" --base main --head "$BRANCH" \
  --title "Demo: pull request head retention" \
  --body "This pull request exists to prove that its head commit survives closure and branch deletion.")"
PR_NUM="${PR_URL##*/}"

# Force-push inside the open pull request. GitHub keeps the superseded head too.
sed -i.bak "s/$FAKE_SECRET/REDACTED_IN_REVIEW/" pr-secret.txt && rm -f pr-secret.txt.bak
git add pr-secret.txt
git commit -q --amend -m "Add feature flag config"
git push -q --force origin "$BRANCH"
SECOND="$(git rev-parse HEAD)"

gh pr close "$PR_NUM" --repo "$SLUG" --delete-branch
git checkout -q main
git branch -q -D "$BRANCH"

record 03-pr-first "$FIRST" "pull request head" "First head of PR #$PR_NUM. Superseded by a force-push, then the PR closed and the branch deleted."
record 03-pr-final "$SECOND" "pull request head" "Final head of PR #$PR_NUM. Kept under refs/pull/$PR_NUM/head after branch deletion."
echo "$PR_NUM" > "$ROOT/evidence/pr-number.txt"
