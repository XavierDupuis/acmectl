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
      {"domain":{"main":"b.example.org"},"certificate":"...","key":"..."},
      {"domain":{"main":"d.example.org"},"certificate":"...","key":"..."}
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

f="$TMPDIR/acme-interactive.json"
sample_acme "$f"

# We need to run acmectl interactively simulation:
# Select item number 2 (resolverA:b.example.org) then confirm 'y'
# Provide input lines: "2" then "y"
# Use printf to feed stdin; since acmectl disables colors when not a TTY, this should work.

printf "2\ny\n" | "$ACMECTL" remove "$f" >/dev/null 2>&1 || fail "interactive removal command failed"

# Verify that b.example.org was removed
if jq -e '.resolverA.Certificates[] | select(.domain.main=="b.example.org")' "$f" >/dev/null 2>&1; then
  fail "interactive remove did not remove b.example.org"
fi

# Ensure other domains remain
for remain in a.example.org d.example.org c.example.org; do
  if ! jq -e --arg d "$remain" '.[]? | .. | objects | select(has("domain") and (.domain.main == $d))' "$f" >/dev/null 2>&1; then
    fail "expected domain still present in file: $remain"
  fi
done

ok "interactive remove removed selected entry and preserved others"