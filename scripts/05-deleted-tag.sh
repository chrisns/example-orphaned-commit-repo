#!/usr/bin/env bash
# Route 5: a commit that never sat on any branch. A tag carried it, then the tag was deleted.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

payload 05-tag > tag-secret.txt
git add tag-secret.txt
git commit -q -m "Release candidate build artefacts"
ORPHAN="$(git rev-parse HEAD)"
git tag demo-rc-1
git push -q origin demo-rc-1        # a tag push is enough to hand the object to GitHub
git push -q origin :refs/tags/demo-rc-1
git tag -d demo-rc-1 >/dev/null
git reset -q --hard HEAD~1

record 05-tag "$ORPHAN" "deleted tag" "Reached GitHub through a lightweight tag only. The branch never contained it."
