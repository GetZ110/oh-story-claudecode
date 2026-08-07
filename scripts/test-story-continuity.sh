#!/bin/bash
# test-story-continuity.sh — cross-batch continuity backstop regression for
# detect-story-gaps.sh. Guarantees: ① tracking staleness (prose advanced to
# chapter N but tracking/context.md is older) → warns that continuing would lose
# continuity; ② duplicate chapter titles (two chapters with the same name) →
# suggests renaming; ③ a clean project (context newer than prose, unique titles)
# stays silent. Same trigger conditions as codex story_codex_hook.py's
# continuity_findings (the codex side is covered by test-codex-hooks.sh).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && { echo "Error: not in a git repository" >&2; exit 1; }
HOOK="$REPO_ROOT/skills/story-setup/references/templates/hooks/detect-story-gaps.sh"
[ -f "$HOOK" ] || { echo "FAIL: hook not found: $HOOK" >&2; exit 1; }
bash -n "$HOOK" || { echo "FAIL: hook has syntax errors" >&2; exit 1; }

# The continuity scan goes through the node shared core (story_hook_cli.js);
# skip if no node interpreter (the hook itself degrades silently then, and the
# clean-project assertions below would otherwise false-green).
if ! node -e "" >/dev/null 2>&1; then
  echo "test-story-continuity: no node interpreter, skipped."
  exit 0
fi

fails=0
run() { CLAUDE_PROJECT_DIR="$1" bash "$HOOK"; }

# Real book structure (3 setting files, avoiding the "lots of prose, little
# setting" gap warning so only continuity is exercised).
make_book() {
  local root="$1"
  mkdir -p "$root/the-book/prose" "$root/the-book/outline" "$root/the-book/tracking" "$root/the-book/setting"
  printf 'a\n' > "$root/the-book/setting/characters.md"
  printf 'b\n' > "$root/the-book/setting/world.md"
  printf 'c\n' > "$root/the-book/setting/power.md"
  printf 'outline\n' > "$root/the-book/outline/volume_outline_1.md"
}

# ① tracking staleness + ② duplicate titles
T1="$(mktemp -d)"; make_book "$T1"
printf 'old context\n' > "$T1/the-book/tracking/context.md"
sleep 1
printf '# Chapter 1 Final Battle\nprose.\n' > "$T1/the-book/prose/chapter_001_final_battle.md"
printf '# Chapter 2 Final Battle\nprose.\n' > "$T1/the-book/prose/chapter_002_final_battle.md"
out="$(run "$T1")"
printf '%s' "$out" | grep -q 'prose is ahead of tracking' || { echo "FAIL: tracking staleness not triggered"; echo "$out" >&2; fails=$((fails+1)); }
printf '%s' "$out" | grep -q '2 chapters share the title' || { echo "FAIL: duplicate-title warning not triggered"; echo "$out" >&2; fails=$((fails+1)); }
rm -rf "$T1"

# ③ clean project: context newer than prose, unique titles -> silent
T2="$(mktemp -d)"; make_book "$T2"
printf '# Chapter 1 Beginning\nprose.\n' > "$T2/the-book/prose/chapter_001_beginning.md"
printf '# Chapter 2 Turning Point\nprose.\n' > "$T2/the-book/prose/chapter_002_turning_point.md"
sleep 1
printf 'new context, caught up to chapter 2\n' > "$T2/the-book/tracking/context.md"
out="$(run "$T2")"
[ -z "$out" ] || { echo "FAIL: clean project should be silent, but got:"; echo "$out" >&2; fails=$((fails+1)); }
rm -rf "$T2"

# ④ short-form project (no tracking/): no staleness check (no context.md), no
# false positive
T3="$(mktemp -d)"
mkdir -p "$T3/short-book/prose" "$T3/short-book/setting" "$T3/short-book/outline"
printf 'a\n' > "$T3/short-book/setting/characters.md"; printf 'b\n' > "$T3/short-book/setting/world.md"; printf 'c\n' > "$T3/short-book/setting/power.md"
printf '# Chapter 1 Start\nprose.\n' > "$T3/short-book/prose/chapter_001_start.md"
printf 'outline\n' > "$T3/short-book/outline/volume_outline_1.md"
out="$(run "$T3")"
printf '%s' "$out" | grep -q 'prose is ahead of tracking' && { echo "FAIL: short-form project without tracking must not report staleness"; echo "$out" >&2; fails=$((fails+1)); } || true
rm -rf "$T3"

if [ "$fails" -ne 0 ]; then
  echo "Story continuity tests FAILED ($fails)." >&2
  exit 1
fi
echo "Story continuity regression tests passed."
