#!/usr/bin/env bash
# Route 6: a commit that was born orphaned.
# The Git Data API writes blob, tree and commit objects without touching any ref.
# No push happens. No branch ever points at it. GitHub serves it anyway.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT"

PARENT="$(git rev-parse origin/main)"
BASE_TREE="$(gh api "repos/$SLUG/git/commits/$PARENT" --jq .tree.sha)"

BLOB="$(payload 06-api | gh api "repos/$SLUG/git/blobs" -f encoding=utf-8 -f content=@- --jq .sha)"

TREE="$(gh api "repos/$SLUG/git/trees" \
  -f base_tree="$BASE_TREE" \
  -f 'tree[][path]=api-only-secret.txt' \
  -f 'tree[][mode]=100644' \
  -f 'tree[][type]=blob' \
  -f "tree[][sha]=$BLOB" --jq .sha)"

ORPHAN="$(gh api "repos/$SLUG/git/commits" \
  -f message='Commit created through the API with no ref' \
  -f tree="$TREE" \
  -f "parents[]=$PARENT" --jq .sha)"

record 06-api "$ORPHAN" "API, no ref" "Written by the Git Data API. It never had a ref, so nothing had to be deleted."
