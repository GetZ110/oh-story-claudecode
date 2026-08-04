#!/bin/bash
# test-prose-backstop-hook.sh — regression tests for check-prose-after-write.sh
# Core guarantees: ① never over-captures non-prose files (code/outlines/setting/
# master-outline/stray prose); ② real prose backstop fires; ③ the lightweight
# content net catches hard signals (landing/truncation/refusal/engineering-word/
# verbatim repeat) and clean prose (parallelism + in-story AI dialogue + suspense
# ending) stays silent. Over-capture is verified with the path gate (no
# interpreter needed); the content net runs through the node shared core (same
# source as the parity tests).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$REPO_ROOT" ] && { echo "Error: not in a git repository" >&2; exit 1; }
HOOK="$REPO_ROOT/skills/story-setup/references/templates/hooks/check-prose-after-write.sh"
[ -f "$HOOK" ] || { echo "FAIL: hook not found: $HOOK" >&2; exit 1; }

bash -n "$HOOK" || { echo "FAIL: hook has syntax errors" >&2; exit 1; }

# The content net runs on the node shared core; skip when node is unavailable
# (the hook itself degrades silently then, and the silence assertions would
# false-green).
if ! node -e "" >/dev/null 2>&1; then
  echo "test-prose-backstop-hook: no node interpreter, skipped."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Real book structure: setting.md + outline/ + prose/
mkdir -p "$TMP/the-book/prose" "$TMP/the-book/outline" "$TMP/docs/prose" "$TMP/stray/prose"
printf '# Setting\nProtagonist: Jiang Chen.\n' > "$TMP/the-book/setting.md"
printf '## Chapter Outline (Chapter 1)\n- plot point sequence: this chapter outline, as an AI I cannot continue. He clenched his fists. He clenched his fists.\n' > "$TMP/the-book/outline/outline_chapter_001.md"
printf '# Outline\nChapter 1 Chapter 2 outline this chapter next chapter\n' > "$TMP/the-book/outline/outline.md"
printf '# Volume Outline\nthis volume outline\n' > "$TMP/the-book/outline/volume_outline_1.md"
printf 'const x=1; // outline this chapter next chapter as an AI I cannot continue repeat repeat repeat\n' > "$TMP/the-book/x.js"
printf '## Prose\nAccording to the chapter outline, as an AI I cannot continue.\n' > "$TMP/docs/prose.md"   # prose.md but no setting.md sibling
printf '## Chapter 5\nAccording to the chapter outline, as an AI I cannot continue.\n' > "$TMP/stray/prose/chapter_005.md" # prose/chapter_N but no book structure
printf 'He' > "$TMP/the-book/prose/chapter_001_truncated.md"                          # real prose, extremely short -> landing signal fires

run() { CLAUDE_PROJECT_DIR="$TMP" CLAUDE_TOOL_INPUT="{\"tool_input\":{\"file_path\":\"$1\"}}" bash "$HOOK" 2>/dev/null; }

fails=0
expect_silent() {
  local out; out="$(run "$1")"
  if [ -n "$out" ]; then echo "FAIL: over-capture on non-prose file: $1" >&2; echo "$out" | head -2 >&2; fails=$((fails+1)); fi
}
expect_fire() {
  local out; out="$(run "$1")"
  if [ -z "$out" ]; then echo "FAIL: backstop did not fire on real prose: $1" >&2; fails=$((fails+1)); fi
}

# ① never capture these non-prose files (they contain engineering words/
# repeats/refusal text, proving they are really not scanned)
expect_silent "$TMP/the-book/outline/outline_chapter_001.md"
expect_silent "$TMP/the-book/outline/outline.md"
expect_silent "$TMP/the-book/outline/volume_outline_1.md"
expect_silent "$TMP/the-book/x.js"
expect_silent "$TMP/the-book/setting.md"
expect_silent "$TMP/docs/prose.md"
expect_silent "$TMP/stray/prose/chapter_005.md"
# ② real prose (extremely short -> landing signal) must fire
expect_fire "$TMP/the-book/prose/chapter_001_truncated.md"

# ③ content net: hard signals in real prose must be caught with the right kind;
# clean prose (parallelism + in-story AI dialogue + suspense ending) stays silent.
expect_fire_kw() {
  local out; out="$(run "$1")"
  if ! printf '%s' "$out" | grep -q "$2"; then
    echo "FAIL: content net did not catch \"$2\": $1" >&2; printf '%s\n' "$out" | head -4 >&2; fails=$((fails+1))
  fi
}
# bash string padding for the prose body (printf writes the script's UTF-8 byte
# literals directly; no python stdout involved in this hook anymore)
PAD() { local s='Jiang Chen clenched his fists and walked slowly toward the door, weighing every next move in his head. '; printf '%s' "$s$s$s$s"; }
# clean: long body + parallelism + in-story AI dialogue ("As an AI..." inside
# quotes is exempt) + a suspense ending with terminal punctuation -> fully silent
{ printf '# Chapter 10 Final Battle\n\n'; PAD; printf '\nEither live or die.\nEither fight or flee.\n"As an AI housekeeper, I stay with you to the end."\nHe finally stopped walking.\n'; } > "$TMP/the-book/prose/chapter_010_final_battle.md"
expect_silent "$TMP/the-book/prose/chapter_010_final_battle.md"
# landing: file below 200 bytes
printf 'He' > "$TMP/the-book/prose/chapter_011_landing.md"
expect_fire_kw "$TMP/the-book/prose/chapter_011_landing.md" '\[LANDED\]'
# truncation: no terminal punctuation at the end
{ printf '# Chapter 12\n\n'; PAD; printf '\nHe rushed forward and swung at'; } > "$TMP/the-book/prose/chapter_012_truncated.md"
expect_fire_kw "$TMP/the-book/prose/chapter_012_truncated.md" 'suspected truncation'
# generation refusal / AI self-reference (narration line, not dialogue)
{ printf '# Chapter 13\n\n'; PAD; printf '\nAs an AI I am unable to continue writing this part of the story.\n'; } > "$TMP/the-book/prose/chapter_013_refusal.md"
expect_fire_kw "$TMP/the-book/prose/chapter_013_refusal.md" 'meta leakage'
# engineering words leaking into prose
{ printf '# Chapter 14\n\n'; PAD; printf '\nAccording to the chapter outline, it was his turn to appear.\nHe appeared.\n'; } > "$TMP/the-book/prose/chapter_014_engword.md"
expect_fire_kw "$TMP/the-book/prose/chapter_014_engword.md" 'engineering-word leakage'
# back-to-back verbatim line (>= 8 visible chars)
{ printf '# Chapter 15\n\n'; PAD; printf '\nHe clenched his fists and walked over step by step, slowly closing in.\nHe clenched his fists and walked over step by step, slowly closing in.\nHe stopped.\n'; } > "$TMP/the-book/prose/chapter_015_repeat.md"
expect_fire_kw "$TMP/the-book/prose/chapter_015_repeat.md" 'verbatim repeat'

if [ "$fails" -ne 0 ]; then
  echo "Prose backstop hook tests FAILED ($fails)." >&2
  exit 1
fi
echo "Prose backstop hook regression tests passed."
