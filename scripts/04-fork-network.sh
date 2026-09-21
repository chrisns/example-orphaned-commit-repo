#!/usr/bin/env bash
# Route 4: the fork network. A fork and its parent share one object store.
# A commit pushed to the fork is readable through the parent repository URL.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

WORK="$(mktemp -d)"
gh repo fork "$SLUG" --org "$FORK_OWNER" --fork-name "$REPO" --clone=false || true
sleep 5
gh repo clone "$FORK_OWNER/$REPO" "$WORK/fork" -- -q
cd "$WORK/fork"
git checkout -q -b demo/fork-leak
source "$ROOT/scripts/lib.sh"
payload 04-fork > fork-secret.txt
git add fork-secret.txt
git commit -q -m "Commit made only in the fork"
git push -q origin demo/fork-leak
ORPHAN="$(git rev-parse HEAD)"

# Delete the branch in the fork. The object stays in the shared network.
git push -q origin --delete demo/fork-leak

cd "$ROOT"
rm -rf "$WORK"
record 04-fork "$ORPHAN" "fork network" "Pushed to the $FORK_OWNER fork only, then the fork branch was deleted. Readable through the parent repository."
