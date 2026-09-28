#!/usr/bin/env bash
# Fails when contract/openapi.json makes a backward-incompatible change to
# /api/v1 compared with the main branch (adr/0014).
#
#   check-breaking.sh                          # base: $BASE_REF (default origin/master)
#   check-breaking.sh --base A.json --revision B.json
#
# Uses a local `oasdiff` binary if present, otherwise the tufin/oasdiff image.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
base_ref="${BASE_REF:-origin/master}"
base=""
revision="$root/contract/openapi.json"

while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="$2"; shift 2 ;;
    --revision) revision="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

work="$(mktemp -d "${TMPDIR:-/tmp}/oasdiff.XXXXXX")"
trap 'rm -rf "$work"' EXIT

if [ -z "$base" ]; then
  if ! git -C "$root" show "$base_ref:contract/openapi.json" > "$work/base.json" 2>/dev/null; then
    echo "No baseline: $base_ref has no contract/openapi.json yet. Skipping breaking-change check."
    exit 0
  fi
else
  cp "$base" "$work/base.json"
fi
cp "$revision" "$work/revision.json"

if command -v oasdiff >/dev/null 2>&1; then
  run=(oasdiff)
  dir="$work"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  run=(docker run --rm -v "$work:/specs:ro" tufin/oasdiff)
  dir="/specs"
else
  echo "Neither oasdiff nor a running Docker daemon is available." >&2
  echo "Install oasdiff (brew install oasdiff) or start Docker." >&2
  exit 1
fi

if "${run[@]}" breaking "$dir/base.json" "$dir/revision.json" --fail-on ERR; then
  echo "No breaking changes to /api/v1."
else
  echo >&2
  echo "Breaking change to /api/v1 detected (see above). Keep v1 backward compatible:" >&2
  echo "add fields and endpoints instead, or introduce a new endpoint (adr/0014)." >&2
  exit 1
fi
