#!/usr/bin/env bash
# Proves contract/openapi.json is accepted by the client generators the apps use.
#
#   check-generators.sh           # both
#   check-generators.sh swift     # swift-openapi-generator via apple/Packages/MurmursAPI (needs Swift)
#   check-generators.sh kotlin    # openapi-generator (Kotlin) via Docker
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
which="${1:-all}"
KOTLIN_GENERATOR_IMAGE="openapitools/openapi-generator-cli:v7.25.0"

check_swift() {
  echo "== swift-openapi-generator"
  swift build --package-path "$root/apple/Packages/MurmursAPI"
}

check_kotlin() {
  echo "== openapi-generator (kotlin)"
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "Docker is required for the Kotlin generator check and is not running." >&2
    exit 1
  fi
  docker run --rm -v "$root/contract:/contract:ro" "$KOTLIN_GENERATOR_IMAGE" \
    generate -i /contract/openapi.json -g kotlin -o /tmp/kotlin-client
}

case "$which" in
  swift) check_swift ;;
  kotlin) check_kotlin ;;
  all) check_swift; check_kotlin ;;
  *) echo "Usage: $0 [swift|kotlin]" >&2; exit 2 ;;
esac
echo "Contract is consumable by: $which"
