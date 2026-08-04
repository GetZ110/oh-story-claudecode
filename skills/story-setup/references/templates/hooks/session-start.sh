#!/bin/bash
# session-start.sh — show project status and writing-context summary
# Design principle: fully silent when there is nothing useful, never pollute context
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# Join injected strings with real newlines (NL), not literal `\n` placeholders:
# the output end must use printf '%s' (see the trailing comment).
NL=$'\n'
OUTPUT=""
HAS_CONTENT=false

# Minimal preflight before sourcing; otherwise a missing lib can't print a fixable hint.
if [ ! -f "$HOOK_DIR/lib/common.sh" ] || [ ! -f "$HOOK_DIR/lib/sentinel.sh" ]; then
  printf '%s\n' "[WARN] story hook library is missing. Re-run /story-setup to restore .claude/hooks/lib/."
  exit 0
fi

# Load shared libraries
source "$HOOK_DIR/lib/common.sh"
source "$HOOK_DIR/lib/sentinel.sh"

# Byte-stable zone: this hook handles book paths via discover_active_book; under a
# GBK locale, locale-sensitive operations mis-decode UTF-8. Force the C locale for
# byte processing (issue #164 class). No embedded python here, so export is safe.
export LC_ALL=C

ROOT=$(project_root)

# One-shot restart confirmation after story-setup deployment. Custom agents are only
# registered as subagent_type at session start; story-setup leaves
# .claude/.agents-pending-restart as a marker. Reaching here means this is a fresh
# session where agents have reloaded — confirm and clear the marker (one-shot).
if [ -f "$ROOT/.claude/.agents-pending-restart" ]; then
  OUTPUT+="[INFO] story-setup just deployed/updated agents and this session has reloaded them — story-architect, prose-writer and other custom agents are now registered.${NL}"
  OUTPUT+="  If a writing skill still reports spawn failure / solo fallback, you are still in the pre-deployment session; open a new Claude Code session.${NL}${NL}"
  HAS_CONTENT=true
  rm -f "$ROOT/.claude/.agents-pending-restart" 2>/dev/null || true
fi

# Deployment self-check: .story-deployed exists but hook files were deleted
# story_hook_cli.js/story_hook_core.js are the load-bearing node shared core — if
# deleted, check-prose-after-write / validate-story-commit / detect-story-gaps all
# silently degrade, so they must be on the list.
if sentinel_exists "$ROOT/.story-deployed"; then
  MISSING_HOOKS=""
  for hook in session-start.sh session-end.sh detect-story-gaps.sh pre-compact.sh post-compact.sh validate-story-commit.sh guard-outline-before-prose.sh check-prose-after-write.sh story_hook_cli.js story_hook_core.js lib/common.sh lib/sentinel.sh; do
    if [ ! -f "$ROOT/.claude/hooks/$hook" ]; then
      MISSING_HOOKS+="$hook "
    fi
  done
  if [ -n "$MISSING_HOOKS" ]; then
    OUTPUT+="[WARN] .story-deployed exists but hooks are missing: $MISSING_HOOKS${NL}"
    OUTPUT+="  Fix: re-run /story-setup to restore the missing hooks.${NL}${NL}"
    HAS_CONTENT=true
  fi

  # node runtime check: the prose backstop net / commit-format hints / continuity
  # checks run on the node shared core. The official install now recommends the
  # native binary; only the npm install ships Node — a native install may have no
  # node and those three degrade silently (the outline guard keeps its pure-bash
  # backstop). Remind once at session start so it isn't mistaken for still active.
  if ! node -e "" >/dev/null 2>&1; then
    OUTPUT+="[WARN] node runtime not found: prose backstop net / commit-format hints / continuity checks are disabled (the outline guard still has its pure-bash backstop).${NL}"
    OUTPUT+="  Fix: install Node.js (https://nodejs.org, or nvm / brew install node) and open a new session to restore.${NL}${NL}"
    HAS_CONTENT=true
  fi

  AGENTS_VERSION=$(read_sentinel_field agents_version "$ROOT/.story-deployed")
  case "$AGENTS_VERSION" in
    ''|*[!0-9]*)
      OUTPUT+="[WARN] .story-deployed is missing a numeric agents_version. Re-run /story-setup.${NL}${NL}"
      HAS_CONTENT=true
      ;;
    *)
      if [ "$AGENTS_VERSION" -lt 23 ]; then
        OUTPUT+="[WARN] story-setup agents_version=$AGENTS_VERSION is below v23. Re-run /story-setup to refresh hooks, agents and references (open a new session after deploying).${NL}${NL}"
        HAS_CONTENT=true
      elif [ "$AGENTS_VERSION" -gt 23 ]; then
        OUTPUT+="[WARN] story-setup agents_version=$AGENTS_VERSION is above the v23 this hook supports. Don't downgrade over it; update oh-story-claudecode first.${NL}${NL}"
        HAS_CONTENT=true
      fi
      ;;
  esac

  # agents_version (above) is the only runtime staleness authority, bumped only when
  # deployed artifact behavior changes; setup_skill_version is a skill-content anchor
  # that moves on its own rhythm — existence check only, no version comparison, so
  # content changes don't false-report "needs redeploy".
  for field in setup_skill_version target_cli resolver_strategy references_dir; do
    if [ -z "$(read_sentinel_field "$field" "$ROOT/.story-deployed")" ]; then
      OUTPUT+="[WARN] .story-deployed is missing the $field field. Re-run /story-setup to refresh deployment metadata.${NL}${NL}"
      HAS_CONTENT=true
    fi
  done

  REFERENCES_DIR=$(read_sentinel_field references_dir "$ROOT/.story-deployed")
  if [ -n "$REFERENCES_DIR" ]; then
    REFERENCES_PATH=$(resolve_project_path "$REFERENCES_DIR")
    if [ ! -d "$REFERENCES_PATH" ] || ! find "$REFERENCES_PATH" -maxdepth 1 -type f -name "*.md" -print -quit 2>/dev/null | grep -q .; then
      OUTPUT+="[WARN] story-setup reference package is missing or empty: ${REFERENCES_DIR}. Re-run /story-setup.${NL}${NL}"
      HAS_CONTENT=true
    fi
  fi
else
  OUTPUT+="[WARN] Writing environment is not deployed. Run /story-setup to initialize.${NL}${NL}"
  HAS_CONTENT=true
fi

# Show branch and recent commits (only when git history exists)
BRANCH=$(git -C "$ROOT" branch --show-current 2>/dev/null || echo "")
if [ -n "$BRANCH" ]; then
  OUTPUT+="=== Writing Progress ===${NL}"
  OUTPUT+="Branch: $BRANCH${NL}"
  RECENT=$(git -C "$ROOT" log --oneline -5 2>/dev/null || true)
  if [ -n "$RECENT" ]; then
    OUTPUT+="$RECENT${NL}"
  fi
  OUTPUT+="${NL}"
  HAS_CONTENT=true
fi

# context.md snapshot (current-position section only, first 10 lines)
BOOK_DIR=$(discover_active_book)
if [ -n "$BOOK_DIR" ] && [ -f "$BOOK_DIR/tracking/context.md" ]; then
  OUTPUT+="--- Current Position ---${NL}"
  # `2>/dev/null || true` is required: [ -f ] is true for "exists but unreadable",
  # where head exits non-zero and set -e would kill the script before OUTPUT flushes.
  SNAPSHOT=$(head -10 "$BOOK_DIR/tracking/context.md" 2>/dev/null || true)
  OUTPUT+="${SNAPSHOT}${NL}---${NL}${NL}"
  HAS_CONTENT=true
fi

# Unfinished teardowns (report only when count > 0)
if [ -d "$ROOT/teardown-lib" ]; then
  # Same: when a subdirectory is unreadable find exits 1 and pipefail turns it into
  # the pipeline's exit code — set -e would kill the script before printing a byte.
  # `|| true` + numeric fallback keeps only this item degraded; the rest still land.
  # Count only teardowns whose "Final status" is not completed: counting raw
  # _progress.md files would report finished books as unfinished forever.
  PROGRESS_COUNT=$(discover_incomplete_analyses "$ROOT" | wc -l | tr -d ' ' || true)
  case "$PROGRESS_COUNT" in ''|*[!0-9]*) PROGRESS_COUNT=0 ;; esac
  if [ "$PROGRESS_COUNT" -gt 0 ]; then
    OUTPUT+="[INFO] teardown-lib/ has $PROGRESS_COUNT unfinished teardowns. Run /story-long-analyze or /story-short-analyze.${NL}"
    HAS_CONTENT=true
  fi
fi

# Version update check (passive reminder: at most once per 24h, fully silent
# fallback, failure never affects the session; disable with export STORY_NO_UPDATE_CHECK=1)
story_update_check() {
  [ -n "${STORY_NO_UPDATE_CHECK:-}" ] && return 0
  command -v curl >/dev/null 2>&1 || return 0
  local vfile=""
  [ -f "$ROOT/.claude/skills/story/VERSION" ] && vfile="$ROOT/.claude/skills/story/VERSION"
  [ -z "$vfile" ] && [ -f "$HOME/.claude/skills/story/VERSION" ] && vfile="$HOME/.claude/skills/story/VERSION"
  [ -n "$vfile" ] || return 0
  local cur; cur=$(tr -dc '0-9.' < "$vfile" 2>/dev/null) || return 0
  [ -n "$cur" ] || return 0
  local cache="${HOME:-$ROOT}/.claude/.story-update-cache"
  local now; now=$(date +%s 2>/dev/null) || return 0
  local last=0 latest=""
  if [ -f "$cache" ]; then
    last=$(sed -n '1p' "$cache" 2>/dev/null || echo 0)
    latest=$(sed -n '2p' "$cache" 2>/dev/null || echo "")
  fi
  case "$last" in ''|*[!0-9]*) last=0;; esac
  local checked=0
  if [ "$((now - last))" -ge 86400 ]; then
    checked=1
    latest=$(curl -fsS --max-time 5 "https://api.github.com/repos/worldwonderer/oh-story-claudecode/releases/latest" 2>/dev/null \
      | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '[0-9][0-9.]*' | head -1) || latest=""
    # Write the timestamp on success or failure: on failure latest stays empty as a
    # negative cache, otherwise environments that can't reach GitHub would wait a
    # full 5s curl on every session start and never get a reminder.
    printf '%s\n%s\n' "$now" "$latest" > "$cache" 2>/dev/null || true
  fi
  # The reminder itself is throttled too: the cached latest stays populated, so
  # without checking `checked` the same version would remind on every session start.
  [ "$checked" -eq 1 ] || return 0
  [ -n "$latest" ] || return 0
  if [ "$latest" != "$cur" ] && [ "$(printf '%s\n%s\n' "$cur" "$latest" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$latest" ]; then
    OUTPUT+="[INFO] The story writing toolkit has a new version v${latest} (current v${cur}). Update: npx skills add worldwonderer/oh-story-claudecode -y -g then re-run /story-setup; or tell /story \"check for updates\". Disable reminders: export STORY_NO_UPDATE_CHECK=1${NL}"
    HAS_CONTENT=true
  fi
}
story_update_check || true

# Output only when there is actual content; otherwise stay fully silent
# Must be %s not %b: $OUTPUT embeds the tracking/context.md snapshot and git log
# commit titles. %b would expand `\b`/`\n` inside them as escapes (rewriting backup
# paths and stuffing raw 0x08 into context), and `\c` (commit titles with C:\code)
# would terminate printf outright, silently dropping the trailing markers. Separator
# newlines are carried by the real ${NL} joined above.
if [ "$HAS_CONTENT" = true ]; then
  printf '%s' "$OUTPUT"
fi
