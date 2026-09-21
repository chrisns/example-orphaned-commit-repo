#!/usr/bin/env bash
# Route 7: a custom ref namespace. GitHub accepts refs outside refs/heads and refs/tags.
# Such a ref shows in git ls-remote but not in the branch or tag lists of the web UI.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

payload 07-hidden > hidden-secret.txt
git add hidden-secret.txt
git commit -q -m "Commit parked in a custom ref namespace"
ORPHAN="$(git rev-parse HEAD)"
git reset -q --hard HEAD~1

ACCEPTED=""
for NS in refs/hidden/stash refs/notes/orphan-demo refs/meta/orphan-demo; do
  if git push -q origin "$ORPHAN:$NS" 2>/dev/null; then ACCEPTED="$NS"; break; fi
done

if [ -z "$ACCEPTED" ]; then
  echo "GitHub refused every custom namespace that was tried."
  exit 1
fi
echo "accepted namespace: $ACCEPTED"
git push -q origin ":$ACCEPTED"     # delete the ref again

record 07-hidden "$ORPHAN" "custom ref namespace" "Pushed to $ACCEPTED, which the web UI does not list, then the ref was deleted."
echo "$ACCEPTED" > "$ROOT/evidence/hidden-ref.txt"
