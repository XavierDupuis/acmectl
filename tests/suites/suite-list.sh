#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ACMECTL="$ROOT/src/acmectl"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing $1; install and retry"; exit 2; }
}
require_cmd jq
require_cmd bash

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok - $*"; }

sample_acme() {
  cat >"$1" <<'JSON'
{
  "resolverA": {
    "Account": {"Email":"a@x"},
    "Certificates": [
      {"domain":{"main":"a.example.org"},"certificate":"...","key":"..."},
      {"domain":{"main":"b.example.org"},"certificate":"...","key":"..."}
    ]
  },
  "resolverB": {
    "Account": {"Email":"b@x"},
    "Certificates": [
      {"domain":{"main":"c.example.org"},"certificate":"...","key":"..."}
    ]
  }
}
JSON
}

[ -x "$ACMECTL" ] || { echo "Executable not found at $ACMECTL. Build/install src/acmectl and make it executable." >&2; exit 2; }

f="$TMPDIR/acme-list.json"
sample_acme "$f"

out="$("$ACMECTL" list "$f")" || { echo "acmectl list failed"; exit 2; }

# Strings to verify appear anywhere in output (implementation-agnostic)
required=(
  "resolverA:a.example.org"
  "resolverA:b.example.org"
  "resolverB:c.example.org"
)

for want in "${required[@]}"; do
  if ! grep -Fq "$want" <<<"$out"; then
    echo "DEBUG: acmectl list output:"
    printf '%s\n' "$out"
    fail "missing expected token: $want"
  fi
done

ok "list output contains expected tokens"