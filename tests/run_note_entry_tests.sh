#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
set -eu
cd "$(dirname "$0")/.."
sh tests/run_scale_lights_tests.sh
CC="${CC:-cc}"
OUT=build/note-entry
mkdir -p "$OUT"
for test in note_entry_test note_entry_settings_test project_test; do
    "$CC" -O2 -w -Ibuild/gen -Ifirmware/src -Ifirmware/hal "tests/$test.c" -lm -o "$OUT/$test"
    if ! "$OUT/$test" "$OUT" > "$OUT/$test.log" 2>&1; then
        cat "$OUT/$test.log"
        exit 1
    fi
    tail -n 1 "$OUT/$test.log"
done
echo "NOTE_ENTRY_HOST_SUITE_OK"
