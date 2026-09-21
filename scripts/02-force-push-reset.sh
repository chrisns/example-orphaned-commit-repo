#!/usr/bin/env bash
# Route 2: git reset --hard HEAD~1, then git push --force.
# This is the classic "oops commit". The commit leaves the local branch and stays on GitHub.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

payload 02-reset > credentials.txt
git add credentials.txt
git commit -q -m "Oops: commit credentials by mistake"
git push -q origin main            # <-- GitHub now owns this commit object

ORPHAN="$(git rev-parse HEAD)"

# The developer panics and drops the commit.
git reset -q --hard HEAD~1
git push -q --force origin main    # <-- zero-commit PushEvent, before=$ORPHAN

record 02-reset "$ORPHAN" "force-push --reset" "Dropped commit. Never reachable from any branch again."
