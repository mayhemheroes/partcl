#!/usr/bin/env bash
#
# mayhem/test.sh — RUN partcl's own upstream test suite (tcl_test.c, built by mayhem/build.sh).
# The suite runs test_lexer/test_subst/test_flow/test_math; each check prints "OK: ..." on pass
# and "FAILED: ..." on failure, and the runner exits non-zero iff anything failed.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

RUNNER=/mayhem/tcl_test
if [ ! -x "$RUNNER" ]; then
  echo "FATAL: $RUNNER missing — mayhem/build.sh must build the test suite" >&2
  emit_ctrf "partcl-tcl_test" 0 1
  exit 1
fi

out="$("$RUNNER" 2>&1)"; rc=$?
printf '%s\n' "$out"

passed=$(printf '%s\n' "$out" | grep -c '^OK:')
failed=$(printf '%s\n' "$out" | grep -c '^FAILED:')
# The runner exits non-zero iff a check failed; if it crashed or reported failure without a
# parseable FAILED line, count that as a failure so a broken suite can never look green.
if [ "$rc" -ne 0 ] && [ "$failed" -eq 0 ]; then failed=1; fi

emit_ctrf "partcl-tcl_test" "$passed" "$failed"
