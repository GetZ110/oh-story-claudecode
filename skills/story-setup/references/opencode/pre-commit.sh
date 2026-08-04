#!/bin/sh
### story-hooks: BEGIN ###
# story project commit validation
# Managed by story-setup -- do not edit this block manually
# Checks for hardcoded character attributes in story files (advisory only, never blocks)
#
# Per the SKILL.md deployment rules this block is inserted verbatim into the user's
# existing .git/hooks/pre-commit; the block carries no shebang and runs under the
# host interpreter. Host shebangs are commonly #!/bin/sh (git's own sample,
# lefthook, husky), and on Debian/Ubuntu /bin/sh is dash. So the whole block is
# POSIX-sh only: no set -o pipefail, no read -r -d '', no process substitution
# `< <(...)`, no $'\n' — under dash the first errors out and the last two are
# syntax errors, making every git commit fail (exit 1, no commit), the exact
# opposite of this block's "advisory only, never blocks" contract. The file's own
# shebang is /bin/sh too: in create mode the whole file is copied into the hook,
# and hosts without /bin/bash (Alpine/busybox, NixOS) would make git fatal instead
# of skipping. The trailing `|| true` is the last belt: even under a host set -e,
# this block can never block a commit.
(
set -eu
# LC_ALL=C: the full-width space/colon in the patterns is multi-byte UTF-8; under
# a GBK locale grep treats it as an invalid sequence, exits 2, and the ! negation
# false-reports every setting file as missing a field. Force the C locale for byte
# matching (same as validate-story-commit.sh, issue #164 convention:
# LC_ALL=C + alternation instead of character classes).
export LC_ALL=C
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WARNINGS=""
# POSIX sh has no $'\n'; this is the only way to write a newline constant.
NL='
'

# Fetch the staged md list at once: POSIX sh has no read -d '', so the -z NUL
# stream can't be consumed — newline-separated instead (only filenames containing
# newlines would mis-split, extremely rare and advisory-copy-only). Also can't write
# `git … | while`: the pipe puts while in a subshell and the accumulated WARNINGS
# never come out. Store in a variable first, then feed the while loop via here-doc
# so it still runs in the current shell.
STAGED=$(git -c core.quotepath=false diff --cached --relative --name-only --diff-filter=ACM -- . 2>/dev/null || true)

while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in
    *.md) ;;
    *) continue ;;
  esac

  FULL_PATH="$ROOT/$file"
  [ -f "$FULL_PATH" ] || continue

  # Match semantics and warning copy aligned with the JS core (story_hook_core.js
  # stagedMarkdownWarnings): colons/whitespace use alternation rather than
  # full-width-containing character classes (under C/GBK locales a class is split
  # into single bytes and misses); the name field uses grep -i case-insensitive.
  case "$file" in
    prose.md|*/prose.md|prose/*|*/prose/*)
      HARDCODED=$(grep -nEi "(height|weight|age)([[:space:]]|　)*(:)([[:space:]]|　)*[0-9]+" "$FULL_PATH" 2>/dev/null || true)
      if [ -n "$HARDCODED" ]; then
        WARNINGS="$WARNINGS$NL⚠ $file: prose hardcodes character attributes; reference the setting file instead:$NL$HARDCODED"
      fi
      ;;
  esac

  # Only character sheets are checked: setting/ also hosts project-level files like
  # relationships.md, genre-positioning.md, style.md, worldview/*, factions/* which
  # have no name field; one-shot over the whole tree would flood every commit with
  # false warnings and bury the real hardcoded-attribute warning above (same
  # judgment as validate-story-commit.sh).
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
  if [ "$IS_CHARACTER_SHEET" = true ] &&
    ! grep -qiE "^([[:space:]]|　)*(name)([[:space:]]|　)*(：|:)" "$FULL_PATH" 2>/dev/null; then
    WARNINGS="$WARNINGS$NL⚠ $file: setting file is missing the required name field."
  fi
done <<STORY_STAGED_EOF
$STAGED
STORY_STAGED_EOF

if [ -n "$WARNINGS" ]; then
  echo "=== Story Commit Warnings（advisory only）==="
  # printf '%s' not '%b'/echo -e: $WARNINGS embeds grep -n excerpts of the author's
  # prose, whose `\c` (Windows paths like C:\code) would terminate output and
  # swallow every warning after it.
  printf '%s\n' "$WARNINGS"
  echo "=== End Warnings ==="
fi

) || true
### story-hooks: END ###
