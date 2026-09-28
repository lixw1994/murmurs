#!/usr/bin/env bash
# Fails when contract/openapi.json differs from what the server code generates.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
committed="$root/contract/openapi.json"
fresh="$(mktemp "${TMPDIR:-/tmp}/openapi.XXXXXX")"
trap 'rm -f "$fresh"' EXIT

pnpm --silent --dir "$root/web" contract:generate --out "$fresh" >/dev/null

if ! diff -u "$committed" "$fresh"; then
  echo >&2
  echo "contract/openapi.json is out of date with the /api/v1 route definitions." >&2
  echo "Regenerate it with: pnpm --dir web contract:generate" >&2
  exit 1
fi
echo "contract/openapi.json is up to date."
