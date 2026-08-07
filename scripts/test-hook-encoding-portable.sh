#!/bin/bash
# test-hook-encoding-portable.sh — encoding-robustness regression for the
# deployed hooks in the English edition.
#
# The hooks must stay byte-safe when the user's environment is not UTF-8:
#   1) Tool stdout: hooks delegate to node (story_hook_cli.js) / python that read
#      UTF-8 explicitly and write raw UTF-8 bytes — never locale-decoded text.
#   2) When the user exports a GBK/GB2312 locale, gawk/GNU sed/GNU grep/bash
#      globbing decode UTF-8 content/paths as multi-byte garbage. Fix: hooks
#      `export LC_ALL=C` for byte matching (issue #164 class).
#
# Even in the English edition, user content is not guaranteed ASCII: book names
# may carry accents ("Káel's Óath") or CJK characters. This test proves the hooks
# handle such UTF-8 names byte-safely, both under the C locale and under a real
# non-UTF-8 locale:
#   Part 1: guard-outline-before-prose.sh on the English project structure under
#           the default environment and under LC_ALL=C.
#   Part 1b: Windows drive-letter absolute path classification (issue #184;
#            runs on any platform).
#   Part 1c: real Windows drive-letter path via cygpath (Windows/MSYS only).
#   Part 2: end-to-end under a real GBK locale (when available) with UTF-8 book
#           names — an accented English title and a CJK title.
#
# Usage: bash scripts/test-hook-encoding-portable.sh
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository"
  exit 1
fi
HOOKS_DIR="$REPO_ROOT/skills/story-setup/references/templates/hooks"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Probe a working interpreter (Windows python3 may be the Store stub, exit 49)
for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done

fail=0
pass() { echo "  PASS $1"; }
bad()  { echo "  FAIL $1"; fail=1; }

deploy() { # $1 = project root
  mkdir -p "$1/.claude"
  cp -R "$HOOKS_DIR" "$1/.claude/hooks"
  chmod +x "$1/.claude/hooks"/*.sh "$1/.claude/hooks/lib"/*.sh 2>/dev/null || true
}

echo "Hook encoding portability test (issue #164 class)"
echo "================================================="
echo "interpreter: $PYBIN"

# ===== Part 1: outline guard on the English structure (default vs LC_ALL=C) =====
echo "--- Part 1: guard-outline-before-prose.sh, English structure (default vs LC_ALL=C) ---"
P1="$WORK/p1"; deploy "$P1"
mkdir -p "$P1/book/prose" "$P1/book/outline" "$P1/short"
run_guard() { # $1 mode(default|C)  $2 file_path -> exit code
  local mode="$1" fp="$2" ec=0
  local -a envp=()
  [ "$mode" = "C" ] && envp=(env LC_ALL=C LANG=C)
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$fp" \
    | CLAUDE_PROJECT_DIR="$P1" ${envp[@]+"${envp[@]}"} bash "$P1/.claude/hooks/guard-outline-before-prose.sh" \
      >/dev/null 2>&1 || ec=$?
  printf '%s' "$ec"
}
for MODE in default C; do
  rm -f "$P1/book/outline/outline_chapter_001.md"
  [ "$(run_guard "$MODE" 'book/prose/chapter_001_beginning.md')" = 2 ] && pass "[$MODE] long blocked, chapter outline missing" || bad "[$MODE] long should block when the chapter outline is missing"
  : > "$P1/book/outline/outline_chapter_001.md"
  [ "$(run_guard "$MODE" 'book/prose/chapter_001_beginning.md')" = 0 ] && pass "[$MODE] long allowed, chapter outline present" || bad "[$MODE] long should allow when the chapter outline is present"
  : > "$P1/short/setting.md"; rm -f "$P1/short/section-outline.md"
  [ "$(run_guard "$MODE" 'short/prose.md')" = 2 ] && pass "[$MODE] short blocked, section-outline missing" || bad "[$MODE] short should block when section-outline.md is missing"
  : > "$P1/short/section-outline.md"
  [ "$(run_guard "$MODE" 'short/prose.md')" = 0 ] && pass "[$MODE] short allowed, section-outline present" || bad "[$MODE] short should allow when section-outline.md is present"
done

# ===== Part 1b: Windows drive-letter absolute path classification (issue #184, any platform) =====
# Under Windows + Git Bash, Claude Code passes drive-letter absolute paths
# (F:/... or F:\...). The old case branch only recognized /*, joined the path as
# $ROOT/F:/..., looked in the wrong outline/ directory and falsely reported a
# missing chapter outline. Fixed: drive-letter paths are treated as absolute.
# POSIX runners have no real drive letters: prove by contradiction — the fixture
# sits only under the "$ROOT/C:/<book>" path the OLD code would compose.
#   Fixed: guard treats C:/<book> as absolute (-> filesystem root /C:/<book>,
#          does not exist) -> finds no fixture -> block(2)
#   Old:   composes $ROOT/C:/<book>, hits the fixture -> allow(0)
# block(2) proves drive paths are classified as absolute. (On real Windows the
# same absolute handling hits the real drive's real outline and allows; here we
# only verify the "classified as absolute" fix.)
echo "--- Part 1b: Windows drive-letter absolute path classification (issue #184) ---"
if mkdir -p "$P1/C:/book184/outline" 2>/dev/null && : > "$P1/C:/book184/outline/outline_chapter_002.md" 2>/dev/null; then
  run_guard_drive() { # $1 file_path(JSON-escaped) -> exit code
    local ec=0
    printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1" \
      | CLAUDE_PROJECT_DIR="$P1" bash "$P1/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?
    printf '%s' "$ec"
  }
  [ "$(run_guard_drive 'C:/book184/prose/chapter_002_x.md')" = 2 ] \
    && pass "[win] forward-slash drive path treated as absolute (not root-joined)" \
    || bad  "[win] forward-slash drive path was root-joined — issue #184 regression"
  # Backslash paths arrive JSON-escaped (\\); json.loads yields single backslashes,
  # which the case branch then normalizes.
  [ "$(run_guard_drive 'C:\\book184\\prose\\chapter_002_x.md')" = 2 ] \
    && pass "[win] backslash drive path treated as absolute (separators normalized)" \
    || bad  "[win] backslash drive path mishandled — issue #184 regression"
  rm -rf "$P1/C:"
else
  echo "  SKIP: filesystem does not support ':' in directory names (cannot build the drive fixture)"
fi

# ===== Part 1c: real Windows drive-letter path (cygpath, Windows/MSYS only) =====
# 1b is the POSIX proof by contradiction; here on a real Windows/MSYS runner we
# map $P1 to a C:/... drive path with cygpath and verify user-visible behavior
# directly: outline present -> allow, outline missing -> block. POSIX without
# cygpath -> SKIP.
echo "--- Part 1c: real Windows drive-letter path via cygpath (issue #184) ---"
if command -v cygpath >/dev/null 2>&1; then
  WINROOT="$(cygpath -m "$P1" 2>/dev/null || true)"
  case "$WINROOT" in
    [A-Za-z]:/*)
      mkdir -p "$P1/winbook/prose" "$P1/winbook/outline"
      run_guard_win() { local ec=0; printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1" \
        | CLAUDE_PROJECT_DIR="$P1" bash "$P1/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?; printf '%s' "$ec"; }
      : > "$P1/winbook/outline/outline_chapter_003.md"
      [ "$(run_guard_win "$WINROOT/winbook/prose/chapter_003_x.md")" = 0 ] \
        && pass "[win] real drive path allowed when the chapter outline is present" \
        || bad  "[win] real drive path should allow when the chapter outline is present"
      rm -f "$P1/winbook/outline/outline_chapter_003.md"
      [ "$(run_guard_win "$WINROOT/winbook/prose/chapter_003_x.md")" = 2 ] \
        && pass "[win] real drive path blocked when the chapter outline is missing" \
        || bad  "[win] real drive path should block when the chapter outline is missing"
      rm -rf "$P1/winbook"
      ;;
    *)
      echo "  SKIP: cygpath present but did not yield a drive-letter path ($WINROOT)"
      ;;
  esac
else
  echo "  SKIP: cygpath not available (not a Windows/MSYS runner)"
fi

# ===== Part 2: end-to-end under a real non-UTF-8 locale with UTF-8 book names =====
echo "--- Part 2: real GBK locale (LANG/LC_ALL=zh_CN.GBK), UTF-8 book names ---"
# Detect a *usable* GBK-class locale: don't trust the `locale -a` list (Cygwin/
# MSYS2 synthesize locales on demand without listing them), actually try setting
# one and check `locale charmap` returns a GB-class encoding. This covers Linux
# (generated by localedef in CI), macOS (built-in), and Windows Git Bash
# (Cygwin-synthesized).
detect_gbk_locale() {
  local cand cm
  for cand in zh_CN.GBK zh_CN.gbk zh_CN.GB18030 zh_CN.gb18030 zh_CN.GB2312 zh_CN.gb2312; do
    cm="$(LC_ALL="$cand" locale charmap 2>/dev/null | tr 'a-z' 'A-Z' | tr -d '-')"
    case "$cm" in GBK|GB18030|GB2312) printf '%s' "$cand"; return 0 ;; esac
  done
  return 1
}
GBK_LOCALE="$(detect_gbk_locale || true)"
if [ -z "$GBK_LOCALE" ]; then
  echo "  SKIP: no usable zh_CN.GBK-class locale (Part 2 needs a real non-UTF-8 locale)"
else
  echo "  using locale: $GBK_LOCALE"
  GBK() { LANG="$GBK_LOCALE" LC_ALL="$GBK_LOCALE" env "$@"; }
  P2="$WORK/p2"; deploy "$P2"
  git -C "$P2" init -q; git -C "$P2" config user.email t@t.t; git -C "$P2" config user.name t
  # CJK book name as an intermediate directory — exactly the case where bash
  # globbing mis-decodes UTF-8 under GBK without the hooks' LC_ALL=C exports.
  BOOK="$P2/凯尔的誓约"; mkdir -p "$BOOK/prose" "$BOOK/outline" "$BOOK/tracking" "$BOOK/setting"
  printf '凯尔的誓约\n' > "$P2/.active-book"

  # 2a guard-outline: CJK book-name intermediate dir + CJK glob
  rg() { local ec=0; printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1" \
    | GBK CLAUDE_PROJECT_DIR="$P2" bash "$P2/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?; printf '%s' "$ec"; }
  [ "$(rg '凯尔的誓约/prose/chapter_001_beginning.md')" = 2 ] && pass "[GBK] guard blocks missing chapter outline" || bad "[GBK] guard should block missing chapter outline"
  : > "$BOOK/outline/outline_chapter_001.md"
  [ "$(rg '凯尔的誓约/prose/chapter_001_beginning.md')" = 0 ] && pass "[GBK] guard allows present chapter outline (CJK glob)" || bad "[GBK] guard should allow present chapter outline under GBK"
  [ "$(rg '凯尔的誓约/prose/chapter_0001_beginning.md')" = 0 ] && pass "[GBK] guard tolerates zero-padded chapter numbers" || bad "[GBK] guard should tolerate zero-padded chapter numbers under GBK"

  # 2b detect-story-gaps: a normal foreshadowing table must not warn; this also
  # proves the CJK book is discovered. F001's status is padded with full-width
  # space U+3000 (　planted　) to pin the trim that keeps recognizing the
  # full-width space under LC_ALL=C.
  cat > "$BOOK/tracking/foreshadowing.md" <<'EOF'
| ID | Foreshadowing | Planted chapter | Expected collection | Status{unplanted/planted/recovered/expired} | Importance{high/mid/low} |
|----|---------|---------|-------------|-----------------------------|----------------|
| F001 | jade pendant's origin | Chapter 1 | Chapter 20 |　planted　| high |
| F002 | master's past | Chapter 3 | Chapter 25 | recovered | mid |
EOF
  out="$(cd "$P2" && GBK CLAUDE_PROJECT_DIR="$P2" bash .claude/hooks/detect-story-gaps.sh 2>&1 || true)"
  echo "$out" | grep -q 'foreshadowing' && bad "[GBK] detect-story-gaps spuriously warns on a normal foreshadowing table" || pass "[GBK] detect-story-gaps silent on a normal foreshadowing table"
  # Manufacture a real gap (prose > 10, setting < 3) to prove the CJK book is
  # actually traversed (otherwise the silence above would be a false positive).
  i=1; while [ "$i" -le 11 ]; do : > "$BOOK/prose/chapter_${i}_x.md"; i=$((i+1)); done
  out2="$(cd "$P2" && GBK CLAUDE_PROJECT_DIR="$P2" bash .claude/hooks/detect-story-gaps.sh 2>&1 || true)"
  echo "$out2" | grep -q '凯尔的誓约' && pass "[GBK] detect-story-gaps discovers the CJK book + warns on a real gap" || bad "[GBK] detect-story-gaps failed to discover the CJK book under GBK"
  rm -f "$BOOK"/prose/chapter_*_x.md

  # 2c validate-story-commit: catch a hardcoded attribute under the GBK locale.
  # The attribute uses ASCII punctuation ("age : 18") — the regex's [[:space:]]
  # branch matches it. (A full-width-space variant "age　: 18" is not asserted
  # here: on Windows MSYS bash the hook's non-ASCII regex literal is converted
  # to the system ANSI codepage when spawning native grep, so that branch can
  # only be verified on UTF-8-locale runners; the ASCII form proves the byte
  # matching itself is locale-safe.)
  printf 'age : 18\n' > "$BOOK/prose/chapter_001_beginning.md"
  git -C "$P2" add -A >/dev/null 2>&1
  cout="$(cd "$P2" && GBK CLAUDE_PROJECT_DIR="$P2" STORY_COMMIT_COMMAND='git commit -m x' bash .claude/hooks/validate-story-commit.sh 2>&1 || true)"
  echo "$cout" | grep -q 'prose hardcodes character attributes' && pass "[GBK] validate-commit catches hardcoded attribute under GBK" || bad "[GBK] validate-commit missed the hardcoded attribute under GBK"

  # 2d lib/common.sh discover_active_book: when .active-book points at a short
  # non-ASCII book name, the LC_ALL=C trim in common.sh must not report an
  # illegal byte sequence and swallow the active book (which would fall back to
  # find's first book). Deterministic construction: the active book has setting/
  # but no tracking/prose (the fallback cannot find it), the decoy book has
  # tracking/ (the fallback would only hit the decoy) — before the fix it
  # resolves to the decoy, after it resolves to .active-book. The name carries
  # an accent and an apostrophe to stress byte handling.
  P2D="$WORK/p2d"; deploy "$P2D"
  mkdir -p "$P2D/Káel's Óath/setting" "$P2D/decoy-novel/tracking"
  printf "Káel's Óath \n" > "$P2D/.active-book"  # trailing space exercises the trim
  active_path="$(cd "$P2D" && GBK CLAUDE_PROJECT_DIR="$P2D" bash -c 'source ".claude/hooks/lib/common.sh"; discover_active_book' 2>/dev/null)"
  # Byte-safe assertion: the active book has setting/, the decoy has tracking/;
  # use [ -d ] to stat the byte path directly, avoiding basename rewriting
  # multi-byte names on some runners under GBK. Before the fix this resolves to
  # the decoy (no setting/), after the fix to the active book.
  if [ -d "$active_path/setting" ]; then
    pass "[GBK] common.sh discover_active_book honors the accented .active-book name"
  else
    bad "[GBK] common.sh discover_active_book dropped the accented .active-book name (resolved [$active_path])"
  fi
fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "PASS: hooks behave correctly under the C locale and a real non-UTF-8 locale with UTF-8 book names"
else
  echo "FAIL: a hook misbehaved under some encoding/locale mode (encoding regression)"
fi
exit "$fail"
