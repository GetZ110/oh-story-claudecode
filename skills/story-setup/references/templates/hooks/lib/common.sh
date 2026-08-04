#!/bin/bash
# common.sh — shared function library, sourced by each hook file
# Note: no `set -euo pipefail` here — sourcing must not override the caller's shell options

# project_root — resolve the project root deterministically
# Prefers Claude Code's injected CLAUDE_PROJECT_DIR; falls back to git root; finally cwd.
# Prints an absolute path so hooks run from a nested cwd can't misread/miswrite.
project_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    (cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P) && return
  fi
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ] && [ -d "$git_root" ]; then
    (cd "$git_root" 2>/dev/null && pwd -P) && return
  fi
  pwd -P
}

# resolve_project_path <path> — resolve a relative path against the project root.
resolve_project_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$(project_root)" "$path" ;;
  esac
}

# discover_active_book — single-book query (the active book)
# Prefers root/.active-book; otherwise find the first tracking/ (long-form) or
# prose/ / prose.md (short-form). Used by session-start / session-end /
# pre-compact / post-compact — a session cares about the active book only.
discover_active_book() {
  local root
  root=$(project_root)

  if [ -f "$root/.active-book" ]; then
    local active
    # LC_ALL=C: process bytes, not locale-decoded text, so a leading/trailing
    # space trim can't mangle UTF-8 book names under a GBK locale (per-command
    # fallback here; this library is sourced by hooks that don't export it).
    active=$(LC_ALL=C sed -n '1p' "$root/.active-book" | LC_ALL=C sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
    if [ -n "$active" ]; then
      resolve_project_path "$active"
      return
    fi
  fi

  # Long-form first (tracking/ directory exists)
  local first
  first=$(find "$root" -maxdepth 4 -type d -name "tracking" -print -quit 2>/dev/null || true)
  if [ -n "$first" ]; then
    dirname "$first"
    return
  fi

  # Short-form fallback: prose/ directory or prose.md (maxdepth 4 covers
  # recommend/short/book/prose structures)
  local story_path
  story_path=$(find "$root" -maxdepth 4 \( -type d -name "prose" -o -type f -name "prose.md" \) -print -quit 2>/dev/null || true)
  if [ -n "$story_path" ]; then
    dirname "$story_path"
  fi
}

# analysis_incomplete <_progress.md path> — is a teardown still unfinished (exit 0 = unfinished)
# Criterion is the "Final status" field: completed / completed_with_errors count as
# done; anything else (pending / paused_after_stage1), a missing field, an empty
# file, or a read failure counts as unfinished — better to remind once too often
# than let a teardown truly abandoned mid-pipeline go silent (an empty file is
# exactly the shape of a pipeline interrupted right after starting).
analysis_incomplete() {
  local value
  # Match only the status value after the colon: substring-matching the whole line
  # against *completed* would misjudge template placeholders like
  # `{pending/paused_after_stage1/completed/completed_with_errors}` and parentheticals
  # like `pending (re-run after a previous completed)` as done.
  value=$(LC_ALL=C grep -m1 -oiE 'final status[[:space:]]*(：|:)[[:space:]]*[A-Za-z_]+' "$1" 2>/dev/null \
    | LC_ALL=C grep -oiE '[A-Za-z_]+$' || true)
  [ -n "$value" ] || return 0
  case "$value" in
    completed|completed_with_errors) return 1 ;;
    *) return 0 ;;
  esac
}

# discover_incomplete_analyses <project root> — list unfinished _progress.md under teardown-lib/
# Output: newline-separated absolute paths (same scope as discover_all_books). Empty when teardown-lib/ doesn't exist.
discover_incomplete_analyses() {
  local root="$1"
  [ -d "$root/teardown-lib" ] || return 0
  { find "$root/teardown-lib" -name "_progress.md" -print 2>/dev/null || true; } | while IFS= read -r progress_file; do
    [ -n "$progress_file" ] || continue
    if analysis_incomplete "$progress_file"; then printf '%s\n' "$progress_file"; fi
  done
  # Explicitly return 0: if the loop's last judgment lands on "completed", while
  # would carry 1 out, and a caller with pipefail + set -e would die right here.
  return 0
}

# discover_all_books — multi-book query (every book in the project)
# Output: newline-separated unique absolute directory paths.
# Used by detect-story-gaps — it walks every book for gap detection.
discover_all_books() {
  local root
  root=$(project_root)
  # awk dedupes while preserving insertion order (bash 3.2 compatible, no assoc arrays)
  {
    # Long-form: parent of tracking/
    find "$root" -maxdepth 4 -type d -name "tracking" -print 2>/dev/null | while IFS= read -r d; do dirname "$d"; done
    # Short-form: parent of prose/ or prose.md
    find "$root" -maxdepth 4 \( -type d -name "prose" -o -type f -name "prose.md" \) -print 2>/dev/null | while IFS= read -r d; do dirname "$d"; done
  } | awk 'NF && !seen[$0]++'
}
