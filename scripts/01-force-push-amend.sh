#!/usr/bin/env bash
# Route 1: git commit --amend, then git push --force.
# The pre-amend commit is already on GitHub. Amending does not remove it.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

payload 01-amend > config.env
git add config.env
git commit -q -m "Add service config"
git push -q origin main            # <-- GitHub now owns this commit object

ORPHAN="$(git rev-parse HEAD)"

# The developer notices the fake secret and rewrites the commit.
sed -i.bak "s/$FAKE_SECRET/REDACTED_BY_AMEND/" config.env && rm -f config.env.bak
git add config.env
git commit -q --amend -m "Add service config"
git push -q --force origin main    # <-- zero-commit PushEvent, before=$ORPHAN

record 01-amend "$ORPHAN" "force-push --amend" "Pre-amend commit on main. Still holds the fake secret."
