#!/bin/bash
# detect-story-gaps.sh — detect the 5 gaps in writing projects
# Design principle: fully silent when there are no gaps, never pollute context
set -euo pipefail

# Load shared libraries (project_root + discover_all_books)
source "$(dirname "$0")/lib/common.sh"

# Byte-stable zone: awk parses the foreshadowing table and find/grep touch paths.
# Under a GBK locale, multi-byte decoding of UTF-8 breaks trims and == comparisons.
# Force the C locale for byte matching (issue #164 class). The continuity scan at
# the end embeds python, but it reads files with encoding='utf-8' explicitly and
# writes UTF-8 bytes via stdout.buffer, so it is unaffected by LC_ALL=C — exporting
# at the top is safe.
export LC_ALL=C

ROOT=$(project_root)
# Join report lines with real newlines (NL), not literal `\n` placeholders:
# the output end must use printf '%s' (see the trailing comment).
NL=$'\n'
OUTPUT=""
HAS_WARNINGS=false

# 1. New-project detection: no book directory (long-form and short-form projects)
# bash 3.2 compatible: no assoc arrays; discover_all_books dedupes in order.
declare -a BOOK_DIRS=()
while IFS= read -r dir; do
  [ -n "$dir" ] && BOOK_DIRS+=("$dir")
done < <(discover_all_books)

if [ "${#BOOK_DIRS[@]}" -eq 0 ]; then
  # Brand-new project, no directory structure — exit silently
  exit 0
fi

for BOOK_DIR in "${BOOK_DIRS[@]}"; do
  BOOK_NAME=$(basename "$BOOK_DIR")
  BOOK_OUTPUT=""

  # 2. Lots of prose but little setting
  CHAPTER_COUNT=0
  SETTING_COUNT=0
  # `|| true` + numeric fallback is required: find exits 1 on unreadable
  # subdirectories, pipefail turns it into the pipeline's exit code, and set -e
  # would kill the script — OUTPUT only flushes at the end, losing every warning.
  if [ -d "$BOOK_DIR/prose" ]; then
    CHAPTER_COUNT=$(find "$BOOK_DIR/prose" -name "*.md" 2>/dev/null | wc -l | tr -d ' ' || true)
    case "$CHAPTER_COUNT" in ''|*[!0-9]*) CHAPTER_COUNT=0 ;; esac
  elif [ -f "$BOOK_DIR/prose.md" ]; then
    CHAPTER_COUNT=1
  fi
  if [ -d "$BOOK_DIR/setting" ]; then
    SETTING_COUNT=$(find "$BOOK_DIR/setting" -name "*.md" 2>/dev/null | wc -l | tr -d ' ' || true)
    case "$SETTING_COUNT" in ''|*[!0-9]*) SETTING_COUNT=0 ;; esac
  fi
  if [ "$CHAPTER_COUNT" -gt 10 ] && [ "$SETTING_COUNT" -lt 3 ]; then
    BOOK_OUTPUT+="[WARN] ${BOOK_NAME}: ${CHAPTER_COUNT} chapters of prose but only ${SETTING_COUNT} setting files — consider adding setting material.${NL}"
  fi

  # 4. Expired or abnormal foreshadowing threads
  if [ -f "$BOOK_DIR/tracking/foreshadowing.md" ]; then
    # Check only the status column of table data rows. Normal open statuses
    # (unplanted/planted) don't warn — otherwise every long-form project would
    # trigger a full foreshadowing audit on every SessionStart.
    # Behavior regression script: scripts/check-hook-regex-sync.sh (locale
    # robustness guaranteed by export LC_ALL=C)
    ABNORMAL_FORESHADOW=$(awk -F'|' '
      # Cells may pad with full-width space U+3000; under LC_ALL=C [[:space:]] only
      # matches ASCII whitespace, so pad cells would keep it in the status and be
      # misjudged abnormal; alternate the full-width space explicitly (no character
      # classes for non-ASCII, which triggers the cross-locale bug).
      function trim(s) { gsub(/^([[:space:]]|　)+|([[:space:]]|　)+$/, "", s); return s }
      # The separator row class must include `:`: markdown alignment rows like
      # |:---|:---:|---:| are also separators; without it they would be treated as data
      # rows with ":---" as the status, falsely warning on every SessionStart.
      /^\|/ && $0 !~ /^\|[-:[:space:]|]+$/ {
        status=trim($6)
        if (status == "" || status == "Status" || status ~ /^Status\{/) next
        if (status == "expired" || (status != "unplanted" && status != "planted" && status != "recovered")) print
      }
    ' "$BOOK_DIR/tracking/foreshadowing.md" 2>/dev/null || true)
    if [ -n "$ABNORMAL_FORESHADOW" ]; then
      BOOK_OUTPUT+="[WARN] ${BOOK_NAME}: tracking/foreshadowing.md contains expired or abnormal entries — run /story-review lean or do a foreshadowing audit.${NL}"
    fi
  fi

  # 5. Missing outline (judged by project type)
  if [ -d "$BOOK_DIR/prose" ] || [ -f "$BOOK_DIR/prose.md" ]; then
    # Long-form judgment: tracking/ exists → outline/ directory required
    if [ -d "$BOOK_DIR/tracking" ] && [ ! -d "$BOOK_DIR/outline" ]; then
      BOOK_OUTPUT+="[WARN] ${BOOK_NAME}: has prose/ but no outline/ — build the outline first.${NL}"
    # Short-form judgment: no tracking/ → section-outline.md single file required
    elif [ ! -d "$BOOK_DIR/tracking" ] && [ ! -f "$BOOK_DIR/section-outline.md" ]; then
      BOOK_OUTPUT+="[WARN] ${BOOK_NAME}: has prose but no section-outline.md — build the outline first.${NL}"
    fi
  fi

  # Only report the book when it has issues
  if [ -n "$BOOK_OUTPUT" ]; then
    OUTPUT+="Checked: $BOOK_NAME${NL}$BOOK_OUTPUT"
    HAS_WARNINGS=true
  fi
done

# 3. Global unfinished-teardown detection (project-level, not book-level)
GLOBAL_PROGRESS_OUTPUT=""
if [ -d "$ROOT/teardown-lib" ]; then
  # Same as session-start: filter by "Final status"; finished teardowns no longer
  # report (raw counting would report them unfinished forever).
  while IFS= read -r progress_file; do
    [ -n "$progress_file" ] || continue
    GLOBAL_PROGRESS_OUTPUT+="[WARN] Teardown unfinished: ${progress_file#$ROOT/}, run /story-long-analyze to continue.${NL}"
  done < <(discover_incomplete_analyses "$ROOT")
fi
if [ -n "$GLOBAL_PROGRESS_OUTPUT" ]; then
  OUTPUT+="$GLOBAL_PROGRESS_OUTPUT"
  HAS_WARNINGS=true
fi

# 6. Cross-batch continuity backstop (tracking staleness + duplicate chapter
# titles) — the node shared core continuityFindings, the same implementation as
# Codex/OpenCode/ZCode. Session-start reminder: "wrote chapters but context.md
# didn't keep up" or "two chapters share a title". Messages match the old
# implementation verbatim; dedup ordering for multiple books follows js semantics
# (documented; only affects advisory order, not whether it reports). Scan scope is
# repo-wide (same as the gap detection above) — inactive books in multi-book
# projects are also reminded, deliberately (you want to know about disconnects
# before switching books), not narrowed by .active-book. Staleness uses mtime
# comparison (+1s tolerance against same-second false positives), a heuristic
# advisory: git checkout / -p copies that change mtime may skew it — reminder only,
# never blocking. Silent skip when node is absent (a native install may have no
# node; session-start.sh reminds once; core.js is loaded by story_hook_cli.js in
# the hook directory).
if node -e "" >/dev/null 2>&1; then
  CONT_CLI="$(dirname "$0")/story_hook_cli.js"
  if [ -f "$CONT_CLI" ]; then
    CONTINUITY_OUTPUT="$(node "$CONT_CLI" continuity "$ROOT" 2>/dev/null || true)"
    if [ -n "$CONTINUITY_OUTPUT" ]; then
      OUTPUT+="$CONTINUITY_OUTPUT"
      HAS_WARNINGS=true
    fi
  fi
fi

# Only output when there are warnings
# Must be %s not %b: $OUTPUT embeds book directory names and node continuity output
# (chapter titles read from files). %b would expand `\n`/`\b` as escapes and `\c`
# would terminate printf, swallowing the [WARN]s. Separator newlines are carried by
# the real ${NL} joined above.
if [ "$HAS_WARNINGS" = true ]; then
  printf '%s\n' "=== Writing Gap Detection ===" "$OUTPUT"
fi
