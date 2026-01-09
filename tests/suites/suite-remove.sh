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

# Test: dry-run does not modify file and reports removal
f1="$TMPDIR/acme-dry.json"; sample_acme "$f1"
before="$(jq -S . "$f1")"
out="$("$ACMECTL" remove "$f1" --domains b.example.org --dry-run 2>&1)" || { echo "$out"; fail "acmectl remove --dry-run failed"; }
if ! grep -Fq "Will remove the following entries" <<<"$out"; then
  echo "DEBUG: output:"
  printf '%s\n' "$out"
  fail "--dry-run did not report removal"
fi
[ "$(jq -S . "$f1")" = "$before" ] || fail "--dry-run modified the file"
ok "--dry-run preserved file and reported removals"

# Test: non-interactive remove removes entry and creates backup
f2="$TMPDIR/acme-remove.json"; sample_acme "$f2"
cwd="$(pwd)"; cd "$TMPDIR"
# run removal
"$ACMECTL" remove "$f2" --domains b.example.org >/dev/null 2>&1 || fail "non-interactive remove failed"
# backup exists (prefix bak.)
bakfile="$(ls bak.*.acme-remove.json 2>/dev/null || true)"
[ -n "$bakfile" ] || fail "backup not created"
# ensure b.example.org not present
if jq -e '.resolverA.Certificates[] | select(.domain.main=="b.example.org")' "$f2" >/dev/null 2>&1; then
  fail "b.example.org still present after removal"
fi
ok "non-interactive remove created backup and removed domain"
cd "$cwd"

# Test: idempotent removal (no error when removing again)
f3="$TMPDIR/acme-idempotent.json"; sample_acme "$f3"
"$ACMECTL" remove "$f3" --domains c.example.org >/dev/null 2>&1 || fail "first remove failed"
# second remove should exit 0 (no crash)
"$ACMECTL" remove "$f3" --domains c.example.org >/dev/null 2>&1 || fail "second remove failed (should be idempotent)"
ok "idempotent remove"

echo "All remove-suite tests passed."