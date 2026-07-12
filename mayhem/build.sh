#!/usr/bin/env bash
#
# mayhem/build.sh — build partcl's libFuzzer harness + standalone reproducer + upstream test suite.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}"
: "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "$SRC"

# 1) Fuzz harness — tcl.c is compiled in-line (#include "../tcl.c" under -DTEST). The fuzzed
#    library code is instrumented with $SANITIZER_FLAGS so ASan/UBSan see the parser itself.
$CC $SANITIZER_FLAGS $DEBUG_FLAGS $LIB_FUZZING_ENGINE -std=c99 \
    "$SRC/mayhem/fuzz_tcl_harness.c" -o /mayhem/tcl

# 2) Standalone (non-fuzzer) reproducer over the same harness / code path.
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -std=c99 "$STANDALONE_FUZZ_MAIN" \
    "$SRC/mayhem/fuzz_tcl_harness.c" -o /mayhem/tcl-standalone

# 3) Upstream test suite (tcl_test.c) with the project's NORMAL flags — a clean, un-sanitized
#    build so mayhem/test.sh only RUNS it. COVERAGE_FLAGS (empty by default) instruments it.
$CC -O0 -g -std=c11 $COVERAGE_FLAGS "$SRC/tcl_test.c" -o /mayhem/tcl_test
