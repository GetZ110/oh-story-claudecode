#!/bin/bash
# check-python-invocation.sh — guard: skill docs must not bare-call `python3`
#
# On Windows, after a python.org install `python3` lands on the Microsoft Store
# stub and silently fails with exit 49 (issue #121). Every invocation must probe
# a working interpreter as python3 -> python -> py:
#   for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
#   "$PYBIN" -c "..."
#
# This guard intercepts every "bare call" form: python3 followed by whitespace
# and any argument (-c / -m / << / script path / quotes etc.), plus the no-space
# redirection forms (python3<<'PY' / python3<script) — the latter are valid shell
# but still land on the Store stub. The probe list `python3 python py` and prose
# mentioning python3 directly followed by a backslash-quote, dash, arrow etc.
# (no whitespace) are not affected.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository"
  exit 1
fi

# Bare-call forms: python3 + whitespace + any non-space argument (covers
# -c / -m / << / script paths / quotes), or python3 immediately followed by `<`
# (heredoc `python3<<'PY'` and input redirection `python3<script`, no whitespace).
# Immediately-following forms other than `<` (backslash-quote / dash / arrow /
# slash) are still prose and stay exempt.
PATTERN='python3([[:space:]]+[^[:space:]]|<)'
# The probe list `... in python3 python py ...` is an allowed form; remove it
# from hits (compatible with PYBIN/c variable names).
ALLOW='python3 python py'

echo "Python Invocation Guard"
echo "======================="

# skills/ docs + deployed template hooks (the CI scripts themselves may use any
# form and are not scanned)
hits="$(grep -rnE "$PATTERN" "$REPO_ROOT/skills" 2>/dev/null | grep -vF "$ALLOW" || true)"

if [ -n "$hits" ]; then
  echo "FAIL: bare python3 call found (exits 49 on Windows):"
  echo "$hits"
  echo
  echo "Use the interpreter-probe form instead:"
  echo '  for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done'
  echo '  "$PYBIN" -c "..."'
  exit 1
fi

echo "OK: no bare python3 calls"
echo

# Second guard: embedded python in deployed hooks must not write to stdout in
# text mode (print(/sys.stdout.write). On a Chinese Windows system python's text
# stdout defaults to cp936, encoding paths to GBK — bytes that don't match the
# script's UTF-8 literals, silently disabling the guard (issue #164). Values
# handed to the shell must go out as raw UTF-8 bytes:
#   sys.stdout.buffer.write(value.encode("utf-8"))
# `print(` cannot false-hit `printf ` (no parens); `sys.stdout.write(` cannot hit
# the allowed `sys.stdout.buffer.write(` (the extra .buffer).
HOOKS_DIR="$REPO_ROOT/skills/story-setup/references/templates/hooks"
TEXT_STDOUT='print\(|sys\.stdout\.write\('

echo "Hook stdout-encoding Guard"
echo "=========================="
if [ -d "$HOOKS_DIR" ]; then
  enc_hits="$(grep -rnE "$TEXT_STDOUT" "$HOOKS_DIR" --include='*.sh' 2>/dev/null || true)"
else
  enc_hits=""
fi

if [ -n "$enc_hits" ]; then
  echo "FAIL: embedded python uses text-mode stdout output (encoded to GBK on Chinese Windows, silently disabling the guard):"
  echo "$enc_hits"
  echo
  echo "Write values handed to the shell as raw UTF-8 bytes:"
  echo '  sys.stdout.buffer.write(value.encode("utf-8"))'
  exit 1
fi

echo "OK: no text-mode stdout output in embedded hook python"
