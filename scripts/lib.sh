#!/usr/bin/env bash
# Shared helpers for the orphaned-commit demonstrations.
set -euo pipefail

OWNER="${OWNER:-chrisns}"
REPO="${REPO:-example-orphaned-commit-repo}"
FORK_OWNER="${FORK_OWNER:-cnsdotme}"
SLUG="$OWNER/$REPO"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE="$ROOT/evidence/orphans.tsv"

# The payload is deliberately fake. It is not a credential and never was one.
FAKE_SECRET="EXAMPLE_NOT_A_REAL_SECRET_0000"

record() {
  # record <id> <sha> <route> <description>
  local id="$1" sha="$2" route="$3" desc="$4"
  mkdir -p "$(dirname "$EVIDENCE")"
  [ -f "$EVIDENCE" ] || printf 'id\tsha\troute\tdescription\n' > "$EVIDENCE"
  # Replace any earlier row that has the same id.
  awk -F'\t' -v id="$id" 'NR==1 || $1 != id' "$EVIDENCE" > "$EVIDENCE.tmp"
  printf '%s\t%s\t%s\t%s\n' "$id" "$sha" "$route" "$desc" >> "$EVIDENCE.tmp"
  mv "$EVIDENCE.tmp" "$EVIDENCE"
  echo "recorded: $id $sha ($route)"
}

payload() {
  # payload <id> -> a file body that names which demonstration produced it
  cat <<EOF
# This file only ever existed inside an orphaned commit.
# The value below is fake. It is not a credential.
ORPHAN_DEMO_ID=$1
API_TOKEN=$FAKE_SECRET
EOF
}
