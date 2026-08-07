#!/bin/bash
# validate-story-commit.sh — check format issues at git commit time (WARNING only, no BLOCKING)
set -euo pipefail

source "$(dirname "$0")/lib/common.sh"

HOOK_INPUT="${CLAUDE_TOOL_INPUT:-}"
if [ -z "$HOOK_INPUT" ] && [ ! -t 0 ]; then
  HOOK_INPUT="$(cat)"
fi
# Deliberately not exported: exporting stuffs the payload into every child
# process's envp (git/grep/basename all count), and a big payload hits E2BIG on
# execve. Only the one node call that truly reads it gets a single-command
# assignment (is-git-commit only reads the HOOK_INPUT env var, not stdin), keeping
# the exposure to one spot. This hook hangs on the Bash tool, so payloads are just
# command strings and actually small; tightened to match the other hooks' convention.

is_git_commit_command() {
  # The node shared core isGitCommitCommand: the command prefers
  # STORY_COMMIT_COMMAND and digs command/cmd/script out of HOOK_INPUT otherwise.
  # js word-splitting semantics, consistent with OpenCode/ZCode; the documented
  # advisory-only differences from the old python shlex on "in-quote separators"
  # don't affect this hook's exit-0 non-blocking semantics. When node is not
  # detected, treat as "not a commit" and pass silently below (the backstop must
  # not bite the commit flow; a native install may have no node, session-start.sh
  # reminds once).
  node -e "" >/dev/null 2>&1 || return 1
  local CLI; CLI="$(dirname "$0")/story_hook_cli.js"
  [ -f "$CLI" ] || return 1
  HOOK_INPUT="$HOOK_INPUT" node "$CLI" is-git-commit >/dev/null 2>&1
}

# The PreToolUse matcher may be too wide or the target CLI may not support the if
# field; the script must self-check. Exit fully silently when there is no explicit
# git commit command, so echo/grep invocations never false-trigger.
if ! is_git_commit_command; then
  exit 0
fi

# Byte-stable zone for the case + grep matching below (issue #164 class).
# Placed after is_git_commit_command (which has its own decoding) so it can't
# affect the input decoding.
export LC_ALL=C

ROOT=$(project_root)
GIT_ROOT=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$ROOT")
# Join warning strings with real newlines (NL), not literal `\n` placeholders:
# the output end must use printf '%s' (see the trailing comment).
NL=$'\n'
WARNINGS=""

# Get the files about to be committed (-z null separator avoids space-in-path issues)
while IFS= read -r -d '' file; do
  # Skip non-md files
  case "$file" in
    *.md) ;;
    *) continue ;;
  esac

  FULL_PATH="$ROOT/$file"
  if [ ! -f "$FULL_PATH" ]; then
    FULL_PATH="$GIT_ROOT/$file"
  fi

  # Check prose files for hardcoded character attributes
  # Match semantics and warning copy aligned with the JS core (story_hook_core.js
  # stagedMarkdownWarnings, the cross-CLI authoritative implementation; py↔js
  # locked by scripts/test-prose-net-parity.sh Part E).
  case "$file" in
    prose.md|*/prose.md|prose/*|*/prose/*)
      HARDCODED=$(grep -nEi "\b(height|weight|age)\b([[:space:]]|　)*(:)([[:space:]]|　)*[0-9]+" "$FULL_PATH" 2>/dev/null || true)
      if [ -n "$HARDCODED" ]; then
        WARNINGS="$WARNINGS${NL}⚠ $file: prose hardcodes character attributes; reference the setting file instead:${NL}$HARDCODED"
      fi
      ;;
  esac

  # Check the required field of character sheets (structured match: key:value).
  # grep -i aligns with the JS core's /i: case-insensitive name/NAME/Name.
  #
  # Only character sheets are checked: setting/ also hosts project-level setting
  # files — artifact-protocols.md defines relationships.md (body is
  # "# Character Relationship Map"), genre-positioning.md, plus style.md,
  # genre-prose-card.md, worldview/*, factions/* etc., which have no name field by
  # design. Scanning the whole setting/ tree would flood every commit touching
  # setting/ with false warnings and bury the real "hardcoded attributes" warnings.
  # Judgment: files inside setting/characters|people subdirectories + flat
  # character sheets directly under setting/ (character.md/protagonist.md/
  # side-character.md/villain.md etc. custom names) are checked; other
  # subdirectories and known project-level files are skipped.
  # Four-end same scope: this script (Claude), OpenCode's .git/hooks/pre-commit,
  # the JS core's isCharacterSheetPath / stagedMarkdownWarnings, and codex's
  # _is_character_sheet_path / staged_markdown_warnings are all narrowed to the
  # same judgment. Change all four ends together, otherwise the same commit warns
  # differently across CLIs (parity test Part E locks py↔js).
  IS_CHARACTER_SHEET=false
  case "$file" in
    setting/characters/*|*/setting/characters/*|setting/people/*|*/setting/people/*)
      IS_CHARACTER_SHEET=true
      ;;
    setting/*/*|*/setting/*/*)
      # Non-character subdirectories (worldview/factions/reports/principles/
      # relationships etc.): skip the whole directory
      ;;
    setting/*|*/setting/*)
      case "${file##*/}" in
        relationships.md|genre-positioning.md|genre-prose-card.md|style.md|world-rules.md|worldview.md|cheat.md|background.md) ;;
        *) IS_CHARACTER_SHEET=true ;;
      esac
      ;;
  esac
  if [ "$IS_CHARACTER_SHEET" = true ] \
    && ! grep -qiE "^([[:space:]]|　)*(name)([[:space:]]|　)*(：|:)" "$FULL_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS${NL}⚠ $file: setting file is missing the required name field."
  fi
done < <(git -C "$ROOT" -c core.quotepath=false diff --cached --relative --name-only --diff-filter=ACM -z -- . 2>/dev/null || true)

if [ -n "$WARNINGS" ]; then
  echo "=== Story Commit Warnings（advisory only）==="
  # Must be %s not %b: $WARNINGS embeds grep -n excerpts of the author's prose. %b
  # would expand `\n`/`\b` as escapes and `\c` (Windows paths like C:\code) would
  # terminate printf, swallowing every file's warning together with the closing
  # frame. Separator newlines are carried by the real ${NL} joined above.
  printf '%s\n' "$WARNINGS"
  echo "=== End Warnings ==="
fi

# Always exit 0 — the writing flow must never be blocked by this hook
exit 0
