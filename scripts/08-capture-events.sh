#!/usr/bin/env bash
# Capture the public event trail that makes these commits findable.
# A force-push shows as a PushEvent with "size": 0 and a "before" SHA.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

gh api "repos/$SLUG/events" --paginate > "$ROOT/evidence/events.json"
gh api "repos/$SLUG/events" --paginate --jq \
  '.[] | select(.type=="PushEvent") | {created_at, ref: .payload.ref, size: .payload.size, before: .payload.before, head: .payload.head}' \
  > "$ROOT/evidence/push-events.jsonl"
echo "zero-size push events:"
grep '"size":0' "$ROOT/evidence/push-events.jsonl" || true
