#!/bin/bash
# check-hook-locale-safety.sh — guard the deployed hooks' byte safety under
# non-UTF-8 locales (issue #164 class).
#
# Background: deployed hooks run in the user's Git Bash. If the user exports a
# GBK/GB2312 locale, gawk/GNU sed/GNU grep and bash globbing decode UTF-8
# content/paths as multi-byte garbage, silently breaking the guards (false
# blocks or missed detections). The fix is `export LC_ALL=C` in the hook so all
# matching is byte-based. In this English edition the shipped content is ASCII,
# but user content (book names, prose) can still be non-ASCII, so the hygiene
# rules remain.
#
# This guard is a locale-independent static check (runs on any CI), complementing
# the behavior-level regression scripts/test-hook-encoding-portable.sh (which
# runs hooks end-to-end under a real non-UTF-8 locale).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository"
  exit 1
fi
HOOKS_DIR="$REPO_ROOT/skills/story-setup/references/templates/hooks"

echo "Hook locale-safety Guard"
echo "========================"

fail=0

# Check 1: every deployed hook that processes user content/paths must export
# LC_ALL=C so matching is byte-based under a GBK locale. Hooks embedding python
# (guard-outline/validate-story-commit) place the export deliberately (see each
# file's comment) but must still have it.
# The list is not hand-copied: enumerate every top-level hooks/*.sh (lib/ is
# covered by Check 3's per-command LC_ALL=C), so a new hook is checked
# automatically. The floor list below keeps the "must exist" semantics: a hook
# that is deleted must not fake green because enumeration simply found nothing.
REQUIRED_LOCALE_HOOKS="check-prose-after-write detect-story-gaps guard-outline-before-prose validate-story-commit session-start session-end pre-compact post-compact"
for h in $REQUIRED_LOCALE_HOOKS; do
  if [ ! -f "$HOOKS_DIR/$h.sh" ]; then
    echo "FAIL: expected locale-sensitive hook missing: $h.sh"
    fail=1
  fi
done
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if ! grep -qE '^[[:space:]]*export[[:space:]]+LC_(ALL|CTYPE)=C\b' "$f"; then
    echo "FAIL: $(basename "$f") missing export LC_ALL=C (non-UTF-8 locales would garble byte matching, issue #164 class)"
    fail=1
  fi
done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -type f | sort)
[ "$fail" -eq 0 ] && echo "OK: locale-sensitive hooks all export LC_ALL=C"

# Check 2: no bracket character classes containing full-width punctuation in
# deployed-hook regexes (e.g. [：:]). Such classes only work under a UTF-8
# locale; under C/GBK they are decoded byte-wise and miss matches — use
# alternation (：|:) instead. Detect `[` immediately followed by a common
# full-width punctuation mark; whole-line comments are skipped.
# The directory is passed to -r (with --include) rather than "$HOOKS_DIR"/*.sh:
# the latter only expands top-level files and the -r becomes a no-op, so bracket
# classes in lib/common.sh, lib/sentinel.sh would never be scanned.
BRACKET_HITS="$(LC_ALL=C grep -rnE '\[[^]]*(：|；|，|。|！|？|、)' "$HOOKS_DIR" --include='*.sh' 2>/dev/null \
  | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
if [ -n "$BRACKET_HITS" ]; then
  echo "FAIL: deployed-hook regex contains a bracket class with full-width punctuation (misses under C/GBK; use alternation (A|B)):"
  echo "$BRACKET_HITS"
  fail=1
else
  echo "OK: no bracket classes with full-width punctuation"
fi

# Check 3: function libraries under hooks/lib/ do not export LC_ALL=C themselves
# (the caller decides the locale); their sed/grep that handle user book
# names/paths must carry a per-command LC_ALL=C, otherwise trims report illegal
# byte sequences under GBK, .active-book gets swallowed empty, and discovery
# misresolves to the first book found by find.
# Scan all of lib/ rather than hardcoding common.sh: sentinel.sh is also reused
# by session-start, and hardcoding a filename would auto-exempt new libraries.
if [ -d "$HOOKS_DIR/lib" ]; then
  # grep -n with filename prefix (-H); comment lines removed via :[0-9]+:[[:space:]]*#.
  BARE_TEXT_TOOL="$(grep -HnE '(^|[^=[:alnum:]_])(sed|grep)[[:space:]]' "$HOOKS_DIR/lib"/*.sh 2>/dev/null \
    | grep -vE 'LC_ALL=C' | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
  if [ -n "$BARE_TEXT_TOOL" ]; then
    echo "FAIL: hooks/lib has sed/grep without LC_ALL=C (non-UTF-8 locales garble user book names):"
    echo "$BARE_TEXT_TOOL"
    fail=1
  else
    echo "OK: hooks/lib sed/grep all carry LC_ALL=C"
  fi
fi

exit "$fail"
