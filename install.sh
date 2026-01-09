#!/usr/bin/env bash
set -euo pipefail
REPO="XavierDupuis/acmectl"
RAW="https://raw.githubusercontent.com/$REPO/main/src/acmectl"
DEST="/usr/local/bin/acmectl"

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo "curl or wget required"; exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$RAW" -o "$tmp"
else
  wget -qO "$tmp" "$RAW"
fi

# quick sanity check
head -n1 "$tmp" | grep -q '^#!' || { echo "Downloaded file invalid"; exit 1; }

sudo install -m 0755 "$tmp" "$DEST"
echo "Installed to $DEST"