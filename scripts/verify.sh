#!/usr/bin/env bash
# Prove the claim. For every recorded commit, check three things:
#   1. a full clone does not contain it            -> it really is unreachable
#   2. the REST API still returns it               -> GitHub still stores it
#   3. the .patch URL still returns the fake secret -> the content is still readable
# Run it with no arguments. It needs curl, git and jq.
set -uo pipefail

OWNER="${OWNER:-chrisns}"
REPO="${REPO:-example-orphaned-commit-repo}"
SLUG="$OWNER/$REPO"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE="$ROOT/evidence/orphans.tsv"
FAKE_SECRET="EXAMPLE_NOT_A_REAL_SECRET_0000"
AUTH=()
[ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "Cloning every branch and tag of $SLUG into a scratch directory."
git clone -q "https://github.com/$SLUG.git" "$WORK/clone"
git -C "$WORK/clone" fetch -q --tags origin

FAIL=0
printf '\n| id | commit | in a full clone | REST API | patch holds the string |\n'
printf '|----|--------|-----------------|----------|------------------------|\n'

while IFS=$'\t' read -r id sha route desc; do
  [ -z "$sha" ] && continue

  if git -C "$WORK/clone" cat-file -e "$sha^{commit}" 2>/dev/null; then
    REACHABLE="present"          # unexpected
  else
    REACHABLE="absent"           # expected
  fi

  CODE="$(curl -s -o "$WORK/api.json" -w '%{http_code}' "${AUTH[@]}" \
    "https://api.github.com/repos/$SLUG/commits/$sha")"

  if curl -sfL "${AUTH[@]}" "https://github.com/$SLUG/commit/$sha.patch" | grep -q "$FAKE_SECRET"; then
    PATCHED="yes"
  else
    PATCHED="no"
  fi

  printf '| `%s` | [`%s`](https://github.com/%s/commit/%s) | %s | %s | %s |\n' \
    "$id" "${sha:0:10}" "$SLUG" "$sha" "$REACHABLE" "$CODE" "$PATCHED"

  if [ "$REACHABLE" != "absent" ] || [ "$CODE" != "200" ]; then
    echo "CHECK FAILED: $id" >&2
    FAIL=1
  fi
done < <(tail -n +2 "$EVIDENCE")

printf '\nA row that reads "absent | 200" is the whole point.\n'
printf 'Git says the commit is gone. GitHub hands it back.\n'

exit "$FAIL"
