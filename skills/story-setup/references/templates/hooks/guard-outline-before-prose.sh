#!/bin/bash
# guard-outline-before-prose.sh — PreToolUse(Write|Edit|MultiEdit) flow guard
# Writing "prose" requires the corresponding outline first, otherwise block
# (exit 2, BLOCKING).
#
# Only intercepts "first creation of a prose file without its outline":
#   - long-form prose/chapter_N_*.md : requires outline/outline_chapter_N.md in the same book
#   - short-form prose.md            : requires section-outline.md in the same directory
# Existing prose (continuation / de-AI / revision) always passes; non-prose targets
# and unresolvable paths pass silently. Design principle: miss rather than
# false-hit — any uncertainty exits 0.
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone throughout: bash globs/sed/case on book paths (issue #164 class).
export LC_ALL=C

HOOK_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [ -z "$HOOK_INPUT" ] && [ ! -t 0 ]; then
  HOOK_INPUT="$(cat)"
fi
# Deliberately not exported: Write/Edit/MultiEdit payloads carry whole chapters
# (MultiEdit also old_string+new_string); exporting stuffs it into every child
# process's envp and a big payload hits E2BIG on execve — the guard would die
# before exit 2 and degrade to a non-blocking error, the opposite of the BLOCKING
# contract. Only the node call that needs the payload gets it via stdin pipe
# (story_hook_cli.js extract-target reads stdin when HOOK_INPUT is unset); the
# extract_target_bash fallback below uses the printf builtin, no export needed.

# Extract the target file path: prefer the node shared core (same implementation as
# every other CLI); when node is absent, or node is present but extraction fails,
# fall back to pure bash. This is a blocking guard and must not fail open — the
# official install now recommends the native binary (only npm install ships Node),
# and an old node that doesn't know the node: prefix, or a corrupted deployed core,
# passes the probe but throws on extraction. As long as one path resolves, judge
# normally; only when both fail to extract, pass (miss rather than false-hit).
CLI="$(dirname "$0")/story_hook_cli.js"

# Pure-bash JSON extraction fallback: dig-priority first file_path/path/filePath
# string value. Claude (node app) hook payloads go through JSON.stringify — non-ASCII
# paths are raw UTF-8 (not \uXXXX-escaped), Windows drive paths are \\-escaped; both
# restore in bash (the drive branch below normalizes \ to /). Used when node is
# absent, or present but extraction failed.
extract_target_bash() {
  local key val
  for key in file_path path filePath; do
    val="$(printf '%s' "$HOOK_INPUT" \
      | grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
      | head -n1 \
      | sed -E "s/^\"$key\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//")"
    if [ -n "$val" ]; then
      val="${val//\\\"/\"}"   # \" -> "
      val="${val//\\\\/\\}"   # \\ -> \
      printf '%s' "$val"
      return 0
    fi
  done
  return 1
}

TARGET=""
if node -e "" >/dev/null 2>&1 && [ -f "$CLI" ]; then
  TARGET="$(printf '%s' "$HOOK_INPUT" | node "$CLI" extract-target 2>/dev/null || true)"
fi
# node present but extracted empty (old node without node: prefix / corrupted core
# passing the probe but throwing on extraction) also falls back to pure bash;
# otherwise it would fail open. Pass only when both fail to resolve.
[ -z "$TARGET" ] && TARGET="$(extract_target_bash 2>/dev/null || true)"
[ -z "$TARGET" ] && exit 0

ROOT=$(project_root)
# Absolute paths used as-is; relative paths join the project root.
# Windows + Git Bash may pass drive-absolute paths (F:/work/... or F:\work\...);
# treating them as relative would compose $ROOT/F:/work/... and misjudge the
# outline directory (issue #184). [A-Za-z]:[/\\]* hits drive-absolute paths and
# normalizes backslashes to forward slashes (aligned with plugin.ts isAbsolute).
case "$TARGET" in
  /*) ABS="$TARGET" ;;
  [A-Za-z]:[/\\]*) ABS="${TARGET//\\//}" ;;
  *)  ABS="$ROOT/$TARGET" ;;
esac

BASE="$(basename "$ABS")"
PARENT="$(basename "$(dirname "$ABS")")"

case "$BASE" in
  prose.md)
    # Short-form single-file prose: existing passes (continuation/revision)
    [ -f "$ABS" ] && exit 0
    BOOK_DIR="$(dirname "$ABS")"
    # story-import migration: when teardown-lib/{BookName}/ analysis source exists,
    # prose migrating before section-outline is the normal flow (the outline is
    # reverse-derived from the teardown), so pass
    [ -d "$ROOT/teardown-lib/$(basename "$BOOK_DIR")" ] && exit 0
    # Block only when this is truly a short-form project (setting.md signal —
    # story-short-write/import both produce setting.md first), so docs/prose.md
    # and similar non-fiction files are not false-hit
    [ -f "$BOOK_DIR/setting.md" ] || exit 0
    if [ ! -f "$BOOK_DIR/section-outline.md" ]; then
      printf '%s\n' "⛔ Prose blocked: ${TARGET} is missing section-outline.md in the same directory." >&2
      printf '%s\n' "   Finish \"section-outline.md\" per story-short-write first (no skipping the outline to write prose)." >&2
      printf '%s\n' "   If you truly need to draft first, create section-outline.md first." >&2
      exit 2
    fi
    ;;
  *)
    # Long-form chaptered prose: parent dir must be "prose", file named chapterN...
    [ "$PARENT" = "prose" ] || exit 0
    case "$BASE" in
      chapter*.md) ;;
      *) exit 0 ;;
    esac
    # Existing passes (continuation/revision)
    [ -f "$ABS" ] && exit 0
    # Chapter number (leading zeros stripped)
    NUM="$(printf '%s' "$BASE" | sed -nE 's/^[Cc]hapter[_ -]?0*([0-9][0-9]*).*/\1/p')"
    [ -z "$NUM" ] && exit 0
    BOOK_DIR="$(dirname "$(dirname "$ABS")")"
    # story-import migration: teardown-lib/{BookName}/ analysis source passes
    # (chapter outlines are reverse-derived from chapter summaries, later than
    # the prose migration)
    [ -d "$ROOT/teardown-lib/$(basename "$BOOK_DIR")" ] && exit 0
    OUTLINE_DIR="$BOOK_DIR/outline"
    FOUND=""
    if [ -d "$OUTLINE_DIR" ]; then
      # Tolerate zero-padding differences and title suffixes: match
      # outline/outline_chapter_N*.md by integer chapter number
      for f in "$OUTLINE_DIR"/outline_chapter_*.md; do
        [ -e "$f" ] || continue
        fnum="$(basename "$f" | sed -nE 's/^[Oo]utline_chapter_0*([0-9][0-9]*).*/\1/p')"
        if [ "$fnum" = "$NUM" ]; then FOUND="$f"; break; fi
      done
    fi
    if [ -z "$FOUND" ]; then
      printf '%s\n' "⛔ Prose blocked: chapter ${NUM} has no chapter outline (${OUTLINE_DIR#$ROOT/}/outline_chapter_${NUM}.md)." >&2
      printf '%s\n' "   Build the chapter outline per story-long-write first (no skipping the outline to write prose)." >&2
      printf '%s\n' "   If you truly need to draft first, create the matching outline file first." >&2
      exit 2
    fi
    # Debt gate (stateless): before first-writing chapter N, if the previous
    # chapter has uncleared toxic patterns and no "deslop:skip" exemption, clear
    # them first. The toxic scan runs on the shared core's prose-toxic subcommand
    # (same rules as the after-write net); a missing node/core or a failed scan
    # passes (miss rather than false-hit) — the after-write net and the SKILL's
    # same-turn rule still backstop. The criterion is computed from the previous
    # chapter file itself; no state files.
    PREV=$((NUM - 1))
    if [ "$PREV" -ge 1 ] && node -e "" >/dev/null 2>&1 && [ -f "$CLI" ]; then
      PROSE_DIR="$(dirname "$ABS")"
      PREV_FILE=""
      for f in "$PROSE_DIR"/chapter*.md; do
        [ -e "$f" ] || continue
        pnum="$(basename "$f" | sed -nE 's/^[Cc]hapter[_ -]?0*([0-9][0-9]*).*/\1/p')"
        if [ "$pnum" = "$PREV" ]; then PREV_FILE="$f"; break; fi
      done
      if [ -n "$PREV_FILE" ] && ! head -n 6 "$PREV_FILE" | grep -qiE 'deslop[[:space:]]*:[[:space:]]*skip'; then
        TOXIC="$(node "$CLI" prose-toxic "$PREV_FILE" 2>/dev/null || true)"
        if [ -n "$TOXIC" ]; then
          printf '%s\n' "⛔ Prose blocked: the previous chapter ($(basename "$PREV_FILE")) still has uncleared toxic patterns; clear them before writing chapter ${NUM}. To exempt explicitly, add <!-- deslop:skip --> under the previous chapter's title line and retry." >&2
          # List only the first 8. Don't write `printf … | head -n 8`: when there
          # are many debts head exits first, printf gets SIGPIPE, the pipeline
          # returns 141 under pipefail, and set -e kills the script — exit 2 is
          # never reached and the block degrades to a non-blocking error. Feed head
          # via here-string (no pipe, no SIGPIPE) with a || true belt to guarantee
          # exit 2 is reached.
          head -n 8 <<< "$TOXIC" >&2 || true
          exit 2
        fi
      fi
    fi
    ;;
esac

exit 0
