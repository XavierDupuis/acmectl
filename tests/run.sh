#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TESTDIR="$ROOT/tests/suites"

# Colors (only if stdout is a TTY)
if [ -t 1 ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

echo "${BOLD}Running test suites in:${RESET} $TESTDIR"
echo

if [ ! -d "$TESTDIR" ]; then
  echo "${RED}Tests directory not found:${RESET} $TESTDIR" >&2
  exit 2
fi

suites=()
while IFS= read -r -d '' f; do suites+=("$f"); done < <(find "$TESTDIR" -maxdepth 1 -type f -name 'suite-*.sh' -print0 | sort -z)

if [ "${#suites[@]}" -eq 0 ]; then
  echo "${YELLOW}No test suites found (expected files matching tests/suite-*.sh)${RESET}"
  exit 2
fi

total=0; passed=0; failed=0
echo

for suite in "${suites[@]}"; do
  total=$((total+1))
  name="$(basename "$suite")"
  printf "${BLUE}▶ ${BOLD}%s${RESET}\n" "$name"
  start_ts=$(date +%s)
  if (cd "$ROOT" && bash "$suite"); then
    elapsed=$(( $(date +%s) - start_ts ))
    printf "  ${GREEN}✔ %s${RESET} ${YELLOW}(%ds)${RESET}\n\n" "OK" "$elapsed"
    passed=$((passed+1))
  else
    elapsed=$(( $(date +%s) - start_ts ))
    printf "  ${RED}✖ %s${RESET} ${YELLOW}(%ds)${RESET}\n\n" "FAILED" "$elapsed"
    failed=$((failed+1))
  fi
done

echo "${BOLD}Summary:${RESET}"
printf "  Total: %d, ${GREEN}Passed: %d${RESET}, ${RED}Failed: %d${RESET}\n\n" "$total" "$passed" "$failed"

if [ "$failed" -ne 0 ]; then
  echo "${RED}Some test suites failed.${RESET}" >&2
  exit 1
fi

echo "${GREEN}All test suites passed.${RESET}"
exit 0
