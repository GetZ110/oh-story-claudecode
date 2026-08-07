#!/bin/bash
# check-prose-after-write.sh — PostToolUse(Write|Edit|MultiEdit) prose backstop
# Runs the "lightweight deterministic net" after prose lands and injects findings
# as reminders — a model-independent backstop layer: even if the main session
# misses the "deterministic finish" step (compression / weak model / distraction),
# these hard signals still get caught.
#
# Covers only "hard signals" (worst when missed, and a degenerating model can't
# self-report): truncation, generation refusal / AI self-reference, engineering
# words in prose, back-to-back verbatim lines, toxic patterns (deterministic AI
# sentence fingerprints), failed/truncated landing, word-count debt.
# Advisory items (period stutter / long paragraphs / em dashes) and the full
# repetition scan / tier2 ambiguous words are still run in full by the workflow
# finish steps' check-ai-patterns / check-degeneration — this hook neither deploys
# nor depends on those two detectors; it is an independent lightweight net (the
# toxic-pattern rules share the same spec as the same-name rules in
# check-ai-patterns.js).
#
# Coverage: triggers only on PostToolUse Write|Edit|MultiEdit. Bash-tool prose
# writes (cat>/tee/cp/mv) bypass this hook (Claude/OpenCode side Bash only has the
# pre-guard, no post-write backstop); those paths are covered by Codex's Stop
# turn-end git-change-set scan. Known boundary, not a defect.
#
# The net and word-count logic run on the node shared core story_hook_core.js (the
# same one as OpenCode/ZCode), leaving bash only event routing and file-type
# judgment. node writes UTF-8 stdout natively, dropping the old embedded-python
# cp936 dance.
#
# Non-blocking (exit 0, advisory reminder, never blocks writing); fully silent when
# clean (never pollutes context); silently passes when node is unavailable (a
# backstop must not bite the flow).
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone for bash globs/basename/case on paths (issue #164 class). node
# runs as its own process on UTF-8 and is unaffected by LC_ALL=C.
export LC_ALL=C

HOOK_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [ -z "$HOOK_INPUT" ] && [ ! -t 0 ]; then
  HOOK_INPUT="$(cat)"
fi
# Deliberately not exported: Write/Edit payloads carry whole chapters; exporting
# stuffs them into every child process's envp and a big payload hits E2BIG,
# silently disabling the backstop. Only the node call that needs the payload gets
# it via stdin pipe (story_hook_cli.js extract-target reads stdin when HOOK_INPUT
# is unset).

# Detect node (the official install now recommends the native binary; only npm
# install ships Node — a native install may have no node. If not detected, pass
# silently: the backstop degrades off, session-start.sh reminds once).
node -e "" >/dev/null 2>&1 || exit 0
CLI="$(dirname "$0")/story_hook_cli.js"
[ -f "$CLI" ] || exit 0

# Extract the target file path (payload fed to node's stdin via pipe; path written
# back as UTF-8).
TARGET="$(printf '%s' "$HOOK_INPUT" | node "$CLI" extract-target 2>/dev/null || true)"
[ -z "$TARGET" ] && exit 0

ROOT=$(project_root)
# Drive-absolute path normalization (aligned with guard-outline-before-prose.sh /
# plugin.ts, issue #184).
case "$TARGET" in
  /*) ABS="$TARGET" ;;
  [A-Za-z]:[/\\]*) ABS="${TARGET//\\//}" ;;
  *)  ABS="$ROOT/$TARGET" ;;
esac

BASE="$(basename "$ABS")"
PARENT="$(basename "$(dirname "$ABS")")"

# Only backstop "prose" files — never code/outlines/setting/outline etc.:
#   - short-form: {book}/prose.md with setting.md alongside (the real short-form
#     project signal; excludes docs/prose.md etc.)
#   - long-form: {book}/prose/chapter_N*.md (parent dir must be "prose") with the
#     book having outline/tracking/setting (real book structure)
# case patterns anchor the first char: outline_chapter_N.md, volume_outline_N.md,
# check-ai-patterns.js, setting.md, outline.md etc. naturally don't match
# `prose.md`/`chapter*.md`, so they are never captured.
IS_PROSE=false
case "$BASE" in
  prose.md)
    [ -f "$(dirname "$ABS")/setting.md" ] && IS_PROSE=true
    ;;
  chapter*.md)
    if [ "$PARENT" = "prose" ]; then
      BOOK="$(dirname "$(dirname "$ABS")")"
      if [ -d "$BOOK/outline" ] || [ -d "$BOOK/tracking" ] || [ -d "$BOOK/setting" ] || [ -f "$BOOK/setting.md" ]; then
        IS_PROSE=true
      fi
    fi
    ;;
esac
[ "$IS_PROSE" = true ] || exit 0
[ -f "$ABS" ] || exit 0

# Join report lines with real newlines (NL), not literal `\n` placeholders:
# the end must use printf '%s' (see the trailing comment).
NL=$'\n'
OUT=""

# Landing check: extremely short prose (<200 bytes) is usually unfinished or a
# failed write (quota/timeout interruption). Uses bytes (wc -c) rather than words:
# under LC_ALL=C, a byte threshold is enough to judge "almost empty".
BYTES=$(wc -c < "$ABS" 2>/dev/null | tr -d ' ' || echo 0)
case "$BYTES" in ''|*[!0-9]*) BYTES=0 ;; esac
if [ "$BYTES" -lt 200 ]; then
  OUT+="[LANDED] prose is only ${BYTES} bytes — possibly unfinished or failed to write (quota/timeout?), verify and finish it.${NL}"
fi

# Content net + word count: the node shared core. The net catches
# truncation/refusal/AI self-reference/engineering tier1/adjacent repeat/toxic
# patterns (hard signals a degenerating model can't self-report); the word count
# compares prose against the "Target words:" of outline/outline_chapter_N*.md and
# hints when actual < 90%. Best-effort: silently skips when the outline/target is
# missing, no false reports.
NET_MSG="$(node "$CLI" prose-net "$ABS" 2>/dev/null || true)"
[ -n "$NET_MSG" ] && OUT+="[DEGRADATION/ENGINEERING/TOXIC/WORDCOUNT] (hard signals: truncation/refusal/engineering/toxic → rewrite; handle on hit, don't leave for the next chapter)${NL}${NET_MSG}${NL}"

[ -z "$OUT" ] && exit 0

# Must be %s not %b: ${OUT} embeds author-prose slices (truncation/repeat/
# engineering excerpts). %b would expand `\n`/`\b`/`\t` as escapes, rewriting the
# excerpts into content that doesn't exist in the file; `\c` (Windows paths like
# C:\code) would terminate the whole printf, silently dropping every hard signal
# after it (exit 0, empty stderr). This hook's own separator newlines are carried
# by the real ${NL} joined above; no reliance on %b expansion.
printf '%s\n' "=== Prose backstop check (${BASE}) ===" "Lightweight deterministic net auto-rescan (model-independent; catches final cleanup the main session might miss). Handle by type, then rescan to clean:"
printf '%s' "$OUT"
exit 0
