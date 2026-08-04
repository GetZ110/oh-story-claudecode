#!/bin/bash
# test-charcount-portable.sh — verify that the "cross-platform character count"
# command counts Unicode code points correctly on all three platforms, including
# the Windows Microsoft Store stub scenario.
#
# Background: skill docs tell the model to count words with the probe command
# below. On Windows, after a python.org install `python3` lands on the Microsoft
# Store stub and silently fails with exit 49, so a working interpreter must be
# probed as python3 -> python -> py. GitHub windows-latest ships a working
# python3, so `--stub` mode inserts a fake exit-49 python3 to reproduce the real
# failure.
#
# Usage:
#   bash scripts/test-charcount-portable.sh           # with the real interpreter
#   bash scripts/test-charcount-portable.sh --stub     # simulate the Store stub (exit 49)
#
# Note: the PROBE/COUNT lines below must stay verbatim with the skill docs
# (story-short-write, story-long-write, narrative-writer, style-profile-generator).
# check-python-invocation.sh guards the docs from regressing to a bare python3
# call; this script guards that the command actually yields the right result.
set -euo pipefail

STUB=0
[ "${1:-}" = "--stub" ] && STUB=1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Accented directory + UTF-8 file name, reproducing the issue #121 path scenario.
BOOK_DIR="$WORK/café-project/volume-one"
mkdir -p "$BOOK_DIR"
# 18 code points: héllo wörld — test (é/ö are one code point each, the em dash
# one; 19 UTF-8 bytes — the count must be code points, not bytes). No trailing
# newline.
printf '%s' 'héllo wörld — test' > "$BOOK_DIR/prose.md"
EXPECT=18

# Remember a genuinely working interpreter first. The stub must be
# self-sufficient and not assume the current machine also installs python3 and
# python/py (some macOS environments only have python3).
REAL_PYTHON=""
for candidate in python3 python py; do
  if "$candidate" -c "" >/dev/null 2>&1; then
    REAL_PYTHON="$(command -v "$candidate")"
    break
  fi
done
[ -n "$REAL_PYTHON" ] || { echo "FAIL: no working Python interpreter" >&2; exit 1; }

if [ "$STUB" -eq 1 ]; then
  # Insert a fake python3 that always exits 49 at the front of PATH to reproduce
  # the Windows Store stub.
  FAKEBIN="$WORK/fakebin"
  mkdir -p "$FAKEBIN"
  printf '#!/bin/sh\nexit 49\n' > "$FAKEBIN/python3"
  printf '#!/bin/sh\nexec "%s" "$@"\n' "$REAL_PYTHON" > "$FAKEBIN/python"
  chmod +x "$FAKEBIN/python3"
  chmod +x "$FAKEBIN/python"
  PATH="$FAKEBIN:$PATH"
  export PATH
  echo "[stub] python3 now always exits 49 (simulating the Microsoft Store stub)"
fi

# === Probe + count commands, verbatim with the skill docs ===
# Count with a relative path (cd into the book dir first, then pass the file
# name) — exactly how the skill's model uses it: cd into the project/prose
# directory first, then use relative paths. On Windows Git Bash, feeding an
# absolute POSIX path (/tmp/..., /c/...) to a native Windows python resolves to
# C:\tmp\... and the file is not found; a relative path resolves against the
# child process's real cwd, consistently on all three platforms.
for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
GOT="$(cd "$BOOK_DIR" && "$PYBIN" -c "from pathlib import Path; print(len(Path('prose.md').read_text(encoding='utf-8')))")"
# === command ends ===

echo "selected interpreter: $PYBIN"
echo "char count: $GOT (expect $EXPECT)"

fail=0
if [ "$GOT" != "$EXPECT" ]; then
  echo "FAIL: character count mismatch (accented path or interpreter issue)"
  fail=1
fi
if [ "$STUB" -eq 1 ] && [ "$PYBIN" = "python3" ]; then
  echo "FAIL: stub mode still selected the broken python3; the fallback chain did not work"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS"
fi
exit "$fail"
