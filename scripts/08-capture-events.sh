#!/usr/bin/env bash
# Capture the public event trail that makes these commits findable.
# A force-push that removes commits emits a PushEvent with no "commits" array.
# The "before" field of that event holds the hash of the abandoned commit.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

gh api "repos/$SLUG/events" --paginate > "$ROOT/evidence/events.json"

gh api "repos/$SLUG/events" --paginate --jq \
  '.[] | select(.type=="PushEvent") | {created_at, ref: .payload.ref, before: .payload.before, head: .payload.head, size: .payload.size, has_commits: (.payload | has("commits"))}' \
  > "$ROOT/evidence/push-events.jsonl"

echo "force-push events, which carry no commits array:"
grep '"has_commits":false' "$ROOT/evidence/push-events.jsonl" || echo "none yet, the events API lags by several minutes"
