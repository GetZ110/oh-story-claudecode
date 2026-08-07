#!/usr/bin/env python3
"""Codex hook adapter for oh-story writing projects.

This script intentionally has no third-party dependencies. It adapts the core
story guardrails to Codex hook stdin/stdout JSON contracts.
"""
from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any


HOOK_CWD: Path | None = None


def read_hook_input() -> dict[str, Any]:
    global HOOK_CWD
    # Read raw UTF-8 bytes, not the locale-decoded text stream: tool payloads can
    # carry non-ASCII filenames, and Windows Python defaults stdin to the ANSI code
    # page (cp1252/cp936), which mojibakes them so the prose guard never matches and
    # silently allows (same fix as the bash hooks).
    raw = sys.stdin.buffer.read().decode("utf-8", "replace")
    if not raw.strip():
        return {}
    try:
        obj = json.loads(raw)
        if not isinstance(obj, dict):
            return {}
        cwd = obj.get("cwd")
        if isinstance(cwd, str) and Path(cwd).is_dir():
            HOOK_CWD = Path(cwd).resolve()
        return obj
    except Exception:
        return {}


def emit(obj: dict[str, Any] | None) -> None:
    if obj:
        # Write UTF-8 bytes directly: Windows Python stdout defaults to the ANSI code
        # page and would garble/raise on deny reasons and additionalContext.
        sys.stdout.buffer.write(json.dumps(obj, ensure_ascii=False).encode("utf-8"))


def _deployed_root_from_file() -> Path | None:
    """Self-locate the project root from this script's deployed path.

    story-setup deploys this hook to <root>/.codex/hooks/story_codex_hook.py, so the
    project root is __file__'s great-grandparent. This is the most reliable resolver on
    Windows: the launcher computes the root in (Git Bash) shell as an MSYS path like
    /c/proj, which does NOT survive as a native-Python env var or cwd — but __file__ is
    always a native path. So a non-git project launched from a nested cwd still resolves.
    """
    try:
        here = Path(__file__).resolve()
    except Exception:
        return None
    if here.parent.name == "hooks" and here.parent.parent.name == ".codex":
        root = here.parent.parent.parent
        if root.is_dir():
            return root
    return None


def project_root() -> Path:
    for env_name in ("CODEX_PROJECT_DIR", "CLAUDE_PROJECT_DIR"):
        value = os.environ.get(env_name)
        if not value:
            continue
        try:
            candidate = Path(value)
            if candidate.is_dir():
                return candidate.resolve()
        except Exception:
            pass
    deployed = _deployed_root_from_file()
    if deployed is not None:
        return deployed
    start = HOOK_CWD if HOOK_CWD and HOOK_CWD.is_dir() else Path.cwd()
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=str(start),
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        if out:
            return Path(out).resolve()
    except Exception:
        pass
    return start.resolve()


def safe_rel(root: Path, path: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except Exception:
        return str(path)


def read_active_book(root: Path) -> Path | None:
    active_file = root / ".active-book"
    if active_file.exists():
        lines = active_file.read_text(encoding="utf-8", errors="ignore").splitlines()
        # A blank/whitespace first line must fall through to discovery, not resolve to
        # root/"" == root (mirrors the bash oracle common.sh discover_active_book, which
        # trims then requires non-empty, and the JS hook's firstLine()+truthy guard).
        declared = lines[0].strip() if lines else ""
        if declared:
            candidate = (root / declared).resolve()
            try:
                candidate.relative_to(root.resolve())
            except Exception:
                candidate = None  # type: ignore[assignment]
            if candidate and candidate.exists():
                return candidate
    for track in root.glob("**/tracking"):
        if any(part.startswith(".") for part in track.relative_to(root).parts):
            continue
        return track.parent
    for body in root.glob("**/prose"):
        if any(part.startswith(".") for part in body.relative_to(root).parts):
            continue
        return body.parent
    for body_file in root.glob("**/prose.md"):
        if any(part.startswith(".") for part in body_file.relative_to(root).parts):
            continue
        return body_file.parent
    return None


def hook_context(event: str, text: str) -> dict[str, Any]:
    return {"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}}


# ── lightweight deterministic net (same implementation as the python embedded in
# templates/hooks/check-prose-after-write.sh, keeping parity) ──
# Only "hard signals" (worst when missed, and a degenerating model can't self-report):
# truncation / generation refusal·AI self-reference / engineering words in prose /
# back-to-back verbatim lines. Independent of check-degeneration.js.
# The terminal set is aligned with check-degeneration.js findTruncation ([.!?…”"'’])}~—"]):
# ASCII " is the legal closing quote from normalize-punctuation.js --quote-mode ascii.
_NET_TERMINAL = set(".!?…”’”])}~—\"")
_NET_QUOTE_OPENERS = ("“", "‘", '"', "'")
_NET_SOFT_PATTERNS = [
    # Model-typed suffixes (language model / AI assistant / chatbot) must be consumed
    # optionally, otherwise the lookahead sees the next word and misses the classic
    # degenerate opening entirely.
    (re.compile(r"\b(?:as an?|being an?)\s+(?:AI|language model|artificial intelligence|chatbot|assistant)(?=\b|[.,;:!?\"')\]]|I(?:'m| am)|can't|cannot|won't|will not|would|shall|must|$)", re.I), "AI self-reference"),
    (re.compile(r"^(Sure|Certainly|Here'?s|As an AI|I (?:cannot|can't|am unable|apologize))"), "AI chatbot voice"),
    (re.compile(r"\b(?:I|we)(?:'m|'re| am| are)? (?:sorry|apologize|unable|not able|can't|cannot) (?:to )?(?:continue|write|generate|finish|complete|help|assist|provide|produce)\b", re.I), "generation refusal"),
]
_NET_HARD_PATTERNS = [
    (re.compile(r"\b(?:TODO|TBD|placeholder|to be continued)\b|\[INSERT[^\]]{0,20}\]", re.I), "placeholder"),
    (re.compile(r"\b(?:chapter outline|volume outline|master outline|story unit|plot point|target words?|word count target|hook note|payoff note|foreshadowing note)\b", re.I), "engineering-word leakage"),
    (re.compile("�"), "mojibake (replacement char)"),
]


def _net_is_skippable(stripped: str) -> bool:
    if not stripped:
        return True
    if stripped[0] == "#":
        return True
    if stripped == "---":
        return True
    if re.match(r"^[-—=*·•\s]+$", stripped):
        return True
    return False


# ── toxic patterns (deterministic AI sentence fingerprints, isomorphic to the JS
# core toxicPhraseFindings; messages canonical in the JS core) ──
# Same spec as the same-name rules in check-ai-patterns.js: only deterministic,
# low-false-positive patterns; density/advisory checks belong to the deep scan.
# All regexes scan linearly with bounded quantifiers. Dialogue/chat/system text
# doesn't count: paired-quote spans become equal-length '?' placeholders (see
# _toxic_mask_quoted for why '?' not '.'), and lines still containing quote chars
# after masking (cross-line dialogue / unclosed quotes) are skipped whole.
# js↔py parity is locked by scripts/check-hook-regex-sync.sh (verbatim canonical
# strings) and scripts/test-prose-net-parity.sh (fixture diffs).
_TOXIC_QUOTE_SPANS = [re.compile(r"“[^”]*”"), re.compile(r"‘[^’]*’"), re.compile(r'"[^"]*"'), re.compile(r"'[^']*'")]
_TOXIC_QUOTE_CHARS = set("“”‘’\"'")
# Clause-start boundary (a preceding char in this set admits the "wasn't X. It was Y"
# second clause opener).
_TOXIC_CLAUSE_BOUNDARY = set(" ,.!?;:…—~ \t")
_TOXIC_TRAILER_WINDOW_WORDS = 250
_TOXIC_SENTENCE_PATTERNS = [
    (re.compile(r"\b(?:his|her|their|the (?:man'?s|woman'?s|boy'?s|girl'?s)) voice\s+(?:was|were|sounded|stayed|remained|dropped)\s+(?:quiet|soft|low|calm|even|level|steady|gentle|barely (?:audible|a whisper))[^.!?\n]{0,30}?\b(?:but|yet|still|though)\b", re.I), "voice-contrast", "Cut the 'voice was quiet/soft... but/yet...' contrast setup; write the concrete effect the voice lands on the room."),
    (re.compile(r"(?:\bno\s+[a-z][a-z0-9' -]{1,24}(?:,|\.)\s*){2}\bno\s+[a-z][a-z0-9' -]{1,24}\b", re.I), "negation-parade", "Cut the 'No X. No Y...' denial list to one or none; write what is actually present."),
    (re.compile(r"\b(it|that|this) wasn't (?:just|merely|simply)\s+[^.!?\n,]{1,20}[,.]\s*\b(?:it|that|this) (?:was|is)\b", re.I), "not-was-comparison", "Cut the negated setup; write the positive term directly, or show it through action/detail."),
]
_TOXIC_TRAILER = re.compile(r"\blittle did (?:he|she|they|we|i|anyone|everyone) know\b|\bunbeknownst to (?:him|her|them|us|everyone)\b|\bno (?:one|body) knew (?:that|what|how|why|where|who)\b|\bnone of them knew\b|\bwhat (?:happened|came) next would\b|\bthis (?:was|is|would be) only the beginning\b|\bthe (?:night|day|battle|war|real (?:battle|war|test|challenge)) (?:was|is|had) (?:just|only) (?:beginning|starting)\b|\b(?:their|his|her|the) (?:lives|life|world|story) (?:was|were|is|are) about to change\b|\bfate had other plans\b", re.I)
# Chapter-end state summary: shares the end window with trailer-ending; seals the
# past where trailer-ending previews the future. All branches are banned forms by
# name; "in that moment, he finally understood" is NOT collected (normal human beat).
_TOXIC_TRAILER_SUMMARY = re.compile(r"\bit was (?:a|the) (?:night|day|morning|moment) that would (?:change|alter|end) everything\b|\b(?:nothing|everything) would (?:ever )?be the same (?:again)?\b|\beverything was about to change\b|\bthe world would never be the same\b|\b(?:his|her|their|the) (?:life|world|story) (?:would|was) (?:be )?(?:forever|permanently) changed\b|\bthe wheels? of fate\b", re.I)


def _toxic_mask_quoted(line: str) -> str:
    # The placeholder is "?" rather than ".": it must truncate the rules' [^.!?\n]
    # negative classes (? is equivalent to a period in every rule's class) without
    # landing on any rule's acceptance position. A period placeholder would forge a
    # terminator for the end-window rules. Length is preserved, so the window cut
    # doesn't drift. The placeholder length counts UTF-16 code units (an emoji in
    # dialogue counts 2), aligned with the JS core "?".repeat(m.length).
    out = line
    for rx in _TOXIC_QUOTE_SPANS:
        out = rx.sub(lambda m: "?" * (len(m.group(0).encode("utf-16-le")) // 2), out)
    return out


def _toxic_not_was_excluded(line: str, matched: str, start: int) -> bool:
    """"Wasn't it obvious?" — a question opener is not the "wasn't just X... was Y"
    contrast (the regex already requires a following "it/that/this was", but a
    question form "Wasn't it just X?" would otherwise slip past the comma clause)."""
    before = line[max(0, start - 12):start]
    if re.search(r"wasn't it$", before, re.I):
        return True
    return False


def _toxic_match_sentence(line: str) -> tuple[str, str, str] | None:
    """Each line reports only the first matching sentence rule (rescan-to-clean
    philosophy: fix one spot, rescan for the next)."""
    for rx, label, fix in _TOXIC_SENTENCE_PATTERNS:
        for m in rx.finditer(line):
            if label == "not-was-comparison" and _toxic_not_was_excluded(line, m.group(0), m.start()):
                continue
            return (label, fix, m.group(0))
    return None


def _word_count(text: str) -> int:
    return len(re.findall(r"[A-Za-z0-9]+(?:['’][A-Za-z]+)?", text))


def toxic_phrase_findings(text: str) -> list[str]:
    findings: list[str] = []
    content: list[tuple[int, str]] = []
    for i, raw in enumerate(text.split("\n"), 1):
        s = raw.strip()
        if _net_is_skippable(s):
            continue
        masked = _toxic_mask_quoted(s)
        if any(ch in _TOXIC_QUOTE_CHARS for ch in masked):
            continue
        content.append((i, masked))
    for line_no, masked in content:
        hit = _toxic_match_sentence(masked)
        if hit:
            findings.append(f"Line {line_no} toxic pattern [{hit[0]}]: \"{hit[2][:20]}\" — {hit[1]}")
    # trailer-ending / trailer-summary scan only the end window (word count after
    # quote masking, boundary line counted in full).
    acc = 0
    cut = len(content)
    while cut > 0 and acc < _TOXIC_TRAILER_WINDOW_WORDS:
        cut -= 1
        acc += _word_count(content[cut][1])
    for line_no, masked in content[cut:]:
        m = _TOXIC_TRAILER.search(masked)
        if m:
            findings.append(f"Line {line_no} toxic pattern [trailer-ending]: \"{m.group(0)[:20]}\" — cut the chapter-end preview; end on an action or image that is happening now.")
        ms = _TOXIC_TRAILER_SUMMARY.search(masked)
        if ms:
            findings.append(f"Line {line_no} toxic pattern [trailer-summary]: \"{ms.group(0)[:20]}\" — cut the chapter-end state verdict; the ending state is outline planning language — land the chapter on a concrete action, image, or line.")
    if findings:
        findings.append("Toxic patterns are deterministic AI fingerprints: clear this chapter before continuing. Full scan: node <skill>/scripts/check-ai-patterns.js --check <prose file>")
    return findings


def prose_net_findings(text: str) -> list[str]:
    findings: list[str] = []
    content: list[tuple[int, str]] = []
    for i, raw in enumerate(text.split("\n"), 1):
        s = raw.strip()
        if _net_is_skippable(s):
            continue
        content.append((i, s))
        is_dialogue = s[0] in _NET_QUOTE_OPENERS
        hit = False
        if not is_dialogue:
            for rx, label in _NET_SOFT_PATTERNS:
                m = rx.search(s)
                if m:
                    findings.append(f"Line {i} meta leakage ({label}): \"{m.group(0)[:20]}\"")
                    hit = True
                    break
        if hit:
            continue
        for rx, label in _NET_HARD_PATTERNS:
            m = rx.search(s)
            if m:
                findings.append(f"Line {i} {label}: \"{m.group(0)[:20]}\"")
                break
    for (la, sa), (lb, sb) in zip(content, content[1:]):
        if sa == sb and len(sa) >= 8:
            findings.append(f"Line {lb} verbatim repeat: line identical to the previous line \"{sa[:20]}\"")
    if content:
        ln, last = content[-1]
        if last and last[-1] not in _NET_TERMINAL:
            findings.append(f"Line {ln} suspected truncation: ending \"...{last[-12:]}\" does not end with terminal punctuation")
    # The "deslop:skip" exemption shares the debt-gate criterion (first 6 lines of the
    # file): when the marker is present, skip the toxic-pattern push-back only — the
    # rest of the net (meta/placeholder/repeat/truncation) still runs.
    if not re.search(r"deslop\s*:\s*skip", "\n".join(re.split(r"\r?\n", text)[:6]), re.I):
        findings.extend(toxic_phrase_findings(text))
    return findings


def _is_prose_path(root: Path, abs_path: Path) -> bool:
    """Prose file detection (same over-capture gate as check-prose-after-write.sh):
    short-form {book}/prose.md with setting.md alongside; long-form
    {book}/prose/chapter_N*.md with {book} having outline/tracking/setting."""
    base = abs_path.name
    parent = abs_path.parent.name
    if base == "prose.md":
        return (abs_path.parent / "setting.md").exists()
    if parent == "prose" and re.match(r"^chapter.*\.md$", base, re.I):
        book = abs_path.parent.parent
        return (book / "outline").is_dir() or (book / "tracking").is_dir() or (book / "setting").is_dir() or (book / "setting.md").exists()
    return False


def find_changed_prose_files(root: Path) -> list[Path]:
    """Prose files changed this turn (git diff + untracked), used by the Stop
    backstop — Codex has no PostToolUse, so the content net rescan runs on git's
    change set at the Stop event. Non-git repos or no changes return empty
    (best-effort)."""
    # Both diff invocations must carry --relative (and -- .): without it git emits
    # repo-root-relative paths, and when the project root is a subdirectory of the
    # repo (.git above), root/rel composes a non-existent <root>/<proj>/<proj>/…
    # path that exists() drops entirely — committed chapters' revisions would be
    # missed wholesale, and Codex has no PostToolUse, so this Stop net is its only
    # content net. --relative also narrows scope to the -C subtree, matching
    # ls-files (already cwd-relative); same for staged_markdown_warnings and the
    # JS core stagedMarkdownWarnings.
    out: list[Path] = []
    seen: set[str] = set()
    for args in (
        ["git", "-C", str(root), "-c", "core.quotepath=false", "diff", "--relative", "--name-only", "-z", "--diff-filter=ACM", "--", "."],
        ["git", "-C", str(root), "-c", "core.quotepath=false", "diff", "--relative", "--name-only", "--cached", "-z", "--diff-filter=ACM", "--", "."],
        ["git", "-C", str(root), "-c", "core.quotepath=false", "ls-files", "--others", "--exclude-standard", "-z"],
    ):
        try:
            raw = subprocess.check_output(args, stderr=subprocess.DEVNULL)
        except Exception:
            continue
        for chunk in raw.split(b"\0"):
            if not chunk:
                continue
            rel = chunk.decode("utf-8", errors="ignore")
            if not rel.endswith(".md"):
                continue
            abs_path = (root / rel).resolve()
            key = str(abs_path)
            if key in seen or not abs_path.exists():
                continue
            if _is_prose_path(root, abs_path):
                seen.add(key)
                out.append(abs_path)
    return out


def _wordcount_finding(abs_path: Path, text: str) -> str | None:
    """Word-count debt (long-form chaptered prose only): read "Target words:" from
    outline/outline_chapter_N*.md; actual < 90% is a hint. Same implementation as the
    python embedded in check-prose-after-write.sh / opencode wordcountFinding."""
    base = abs_path.name
    if abs_path.parent.name != "prose":
        return None
    m = re.match(r"^chapter[_ ]?0*(\d+)", base, re.I)
    if not m:
        return None
    num = m.group(1)
    target = None
    for f in (abs_path.parent.parent / "outline").glob("outline_chapter_*.md"):
        fm = re.search(r"outline_chapter_0*(\d+)", f.name, re.I)
        if not fm or fm.group(1) != num:
            continue
        try:
            txt = f.read_text(encoding="utf-8")
        except Exception:
            continue
        tm = re.search(r"[Tt]arget words?:?\s*(\d{3,6})", txt)
        if tm:
            target = int(tm.group(1))
        break
    if not target:
        return None
    actual = _word_count(text)
    if actual < target * 0.9:
        return (f"Word count: chapter {num} is {actual} words < 90% of the target {target} ({int(target*0.9)}). "
                f"Locate the thin dense/light spots against the outline budget and rewrite once to quota — don't squeeze in piecemeal fixes.")
    return None


def _discover_all_books(root: Path) -> list[Path]:
    books: list[Path] = []
    seen: set[str] = set()
    for pattern in ("**/tracking", "**/prose", "**/prose.md"):
        for hit in root.glob(pattern):
            if any(part.startswith(".") for part in hit.relative_to(root).parts):
                continue
            book = hit.parent
            key = str(book.resolve())
            if key not in seen:
                seen.add(key)
                books.append(book)
    return books


def continuity_findings(root: Path) -> list[str]:
    """Cross-batch continuity backstop: ① tracking staleness (chapters written but
    context.md not updated → continuation loses continuity); ② duplicate chapter
    titles (two chapters with the same name are usually a mistaken copy). Model-
    independent reminders at turn/session boundaries; silent when clean.
    Scans repo-wide (same as gap detection) — inactive books are flagged on purpose,
    not narrowed by .active-book; staleness uses mtime +1s tolerance, a heuristic
    advisory (checkout / -p copies can skew)."""
    msgs: list[str] = []
    for book in _discover_all_books(root):
        body_dir = book / "prose"
        chapters = sorted(body_dir.glob("chapter*.md")) if body_dir.is_dir() else []
        # ① tracking staleness (long-form only: has tracking/context.md)
        ctx = book / "tracking" / "context.md"
        if chapters and ctx.exists():
            newest = max((c.stat().st_mtime for c in chapters), default=0)
            try:
                ctx_m = ctx.stat().st_mtime
            except Exception:
                ctx_m = 0
            if newest > ctx_m + 1:
                latest = max(chapters, key=lambda c: c.stat().st_mtime).name
                msgs.append(f"[continuity] {safe_rel(root, book)}: prose is ahead of tracking — latest is \"{latest}\" but tracking/context.md is older; continuation will lose continuity. Update tracking/context.md and tracking/foreshadowing.md before continuing.")
        # ② title dedup (by the title part of chapter_N_Title)
        titles: dict[str, list[str]] = {}
        for c in chapters:
            mt = re.match(r"^chapter[_ ]?0*\d+[_\- ]+(.+)$", c.stem, re.I)
            if not mt:
                continue
            key = mt.group(1).strip()
            if key:
                titles.setdefault(key, []).append(c.name)
        for title, files in titles.items():
            if len(files) > 1:
                msgs.append(f"[continuity] {safe_rel(root, book)}: {len(files)} chapters share the title \"{title}\" ({('，'.join(files))[:60]}), consider renaming.")
    return msgs


def session_start() -> None:
    root = project_root()
    messages: list[str] = []
    sentinel = root / ".story-deployed"
    if sentinel.exists():
        sent_text = sentinel.read_text(encoding="utf-8", errors="ignore")
        if "target_cli:" not in sent_text:
            messages.append("[story-setup] .story-deployed is missing the target_cli field; re-run $story-setup.")
        elif "codex" not in re.search(r"target_cli:\s*(.*)", sent_text).group(1):  # type: ignore[union-attr]
            messages.append("[story-setup] the deployment marker does not include codex; re-run $story-setup and choose Codex to enable Codex hooks/agents.")
    book = read_active_book(root)
    if book:
        ctx = book / "tracking" / "context.md"
        if ctx.exists():
            messages.append(f"[story context] Active book: {safe_rel(root, book)}. Read {safe_rel(root, ctx)} before continuing long-form writing.")
        else:
            messages.append(f"[story context] Active story project detected: {safe_rel(root, book)}.")
    messages.extend(continuity_findings(root))
    if messages:
        emit(hook_context("SessionStart", "\n".join(messages)))


def resolve_target(root: Path, target: str, base: Path | None = None) -> Path:
    normalized = target.replace("\\", "/")
    p = Path(normalized)
    return p if p.is_absolute() else ((base or root) / p).resolve()


def _shell_words(segment: str) -> list[str]:
    """Quote-aware linear word splitter (isomorphic to the JS core shellWords,
    char-by-char aligned): quoted spans copied verbatim (paired quotes stripped,
    unclosed runs to segment end), ASCII whitespace (space/Tab/CR/LF) splits —
    U+3000 is not a shell word splitter, so it does not split. No \\ unescaping:
    resolve_target treats \\ as a path separator (Windows paths)."""
    words: list[str] = []
    current = ""
    started = False
    quote = ""
    for ch in segment:
        if quote:
            if ch == quote:
                quote = ""
            else:
                current += ch
            continue
        if ch in ('"', "'"):
            quote = ch
            started = True
            continue
        if ch in (" ", "\t", "\r", "\n"):
            if started:
                words.append(current)
            current = ""
            started = False
            continue
        started = True
        current += ch
    if started:
        words.append(current)
    return words


def _shell_segments(command: str) -> list[str]:
    """Split on shell control chars outside quotes only; quotes are kept for
    _shell_words to remove."""
    segments: list[str] = []
    current = ""
    quote = ""
    for ch in command:
        if quote:
            current += ch
            if ch == quote:
                quote = ""
            continue
        if ch in ('"', "'"):
            quote = ch
            current += ch
            continue
        if ch in (";", "&", "|", "\n"):
            if current:
                segments.append(current)
            current = ""
            continue
        current += ch
    if current:
        segments.append(current)
    return segments


def _before_shell_redirection(segment: str) -> str:
    """Drop the first outside-quote redirection and everything after it; the fd
    digits of 2> are dropped too."""
    current = ""
    quote = ""
    for ch in segment:
        if quote:
            current += ch
            if ch == quote:
                quote = ""
            continue
        if ch in ('"', "'"):
            quote = ch
            current += ch
            continue
        if ch in ("<", ">"):
            return re.sub(r"\d+$", "", current)
        current += ch
    return current


def extract_prose_targets_from_command(command: str) -> list[str]:
    # Only treat a prose path as a write target when it is the destination of an actual
    # write op (redirection / tee / touch / cp|mv dest). Scanning the whole command would
    # flag any heredoc body, doc string, or grep pattern that merely *mentions*
    # prose/chapter_N.md and wrongly deny the edit.
    # Target tokens come in three shapes (quoted spans win): double-quoted / single-quoted /
    # bare word. The bare class only excludes ASCII whitespace (space/Tab/CR/LF, the shell's
    # real word splitters): \s in both python and js includes U+3000, and a full-width space
    # does not split shell words. Backslash-escaped spaces are still not supported —
    # resolve_target normalizes \ to path separators (Windows paths).
    bare = "[^ \t\r\n\"'<>|;&()]"
    token = "\"([^\"]*prose[^\"]*)\"|'([^']*prose[^']*)'|['\"]?(" + bare + "*prose" + bare + "*)['\"]?"
    targets: list[str] = []
    for m in re.finditer(r">>?\s*(?:" + token + ")", command):  # > dest, >> dest, cat >dest
        targets.append(m.group(1) or m.group(2) or m.group(3))
    # Use an explicit start/separator class, not \b: \b is Unicode-aware in Python re but ASCII-only
    # in JS, so an ASCII boundary keeps this identical to opencode plugin.ts (parity).
    for m in re.finditer(r"(?:^|[\s;&|(){}<>])(?:tee(?:\s+-a)?|touch)\s+(?:" + token + ")", command):
        targets.append(m.group(1) or m.group(2) or m.group(3))
    # cp/mv: the write destination is the last positional arg of the segment. Parse it (regex can't
    # tell a prose source from a prose dest, and a trailing 2>/dev/null / >log / || breaks end-anchoring).
    for raw_segment in _shell_segments(command):
        seg = _before_shell_redirection(raw_segment)
        # Quote-aware splitting (same as the JS core shellWords): str.split() would chop
        # targets on U+3000 and spaces inside quotes, taking the last piece and judging
        # it against another book (one that has the outline and passes).
        words = _shell_words(seg)
        if len(words) >= 2 and words[0] in ("cp", "mv"):
            positionals = [w for w in words[1:] if not w.startswith("-")]
            if positionals and "prose" in positionals[-1]:
                targets.append(positionals[-1])
    return [t for t in targets if t]


def extract_apply_patch_targets(command: str) -> list[str]:
    # Char-by-char isomorphic with the JS shared core extractPatchTargets (parity locked
    # by test-prose-net-parity.sh command-function fixtures). Only Add/Update would miss
    # `*** Move to:` — a sub-directive of the Update File section (apply_patch's
    # rename/move form) whose written path is the *destination*; the source no longer
    # exists after the move: a draft without an outline once moved straight into
    # prose/ via `Update File: draft.md` + `Move to: book/prose/chapter_9.md` (the
    # outline gate passed and the after-write net scanned a source that no longer
    # exists). So Move *replaces* the same section's source target.
    # Delete File never enters the table: deletion is not a write, prose_block_reason
    # already passes for existing prose and there is nothing to scan after deletion;
    # but a Delete section can still carry Move to (move then delete source), so Delete
    # only clears the source slot pending replacement.
    targets: list[str] = []
    source_index = -1
    for line in command.splitlines():
        # Control lines must start at column 0; a leading space is apply_patch's
        # context marker and must not be stripped.
        m = re.match(r"^\*\*\* (Add|Update|Delete) File: (.+)$", line)
        if m:
            if m.group(1) == "Delete":
                source_index = -1
                continue
            targets.append(m.group(2).strip())
            source_index = len(targets) - 1
            continue
        m = re.match(r"^\*\*\* Move to: (.+)$", line)
        if m:
            destination = m.group(1).strip()
            if not destination:
                continue
            if source_index >= 0:
                targets[source_index] = destination
            else:
                targets.append(destination)
            source_index = -1
    return targets


def target_paths_from_hook(obj: dict[str, Any]) -> list[Path]:
    root = project_root()
    base = root
    if HOOK_CWD and HOOK_CWD.is_dir():
        try:
            HOOK_CWD.relative_to(root)
            base = HOOK_CWD
        except ValueError:
            pass
    tool_name = str(obj.get("tool_name") or "")
    tool_input = obj.get("tool_input") if isinstance(obj.get("tool_input"), dict) else {}
    assert isinstance(tool_input, dict)
    raw_targets: list[str] = []
    for key in ("file_path", "filePath", "path", "target", "filename"):
        value = tool_input.get(key)
        if isinstance(value, str):
            raw_targets.append(value)
    command = tool_input.get("command")
    if isinstance(command, str):
        if tool_name == "Bash":
            raw_targets.extend(extract_prose_targets_from_command(command))
        else:
            raw_targets.extend(extract_apply_patch_targets(command))
            raw_targets.extend(extract_prose_targets_from_command(command))
    return [resolve_target(root, t, base) for t in raw_targets if t]


def prose_block_reason(root: Path, abs_path: Path) -> str | None:
    base = abs_path.name
    parent = abs_path.parent.name
    if base == "prose.md":
        if abs_path.exists():
            return None
        book_dir = abs_path.parent
        if (root / "teardown-lib" / book_dir.name).exists():
            return None
        if not (book_dir / "setting.md").exists():
            return None
        if not (book_dir / "section-outline.md").exists():
            # copy aligned with the JS core proseBlockReason (py↔js locked by
            # test-prose-net-parity.sh Part E)
            return f"⛔ Prose blocked: {safe_rel(root, abs_path)} is missing section-outline.md in the same directory. Finish \"section-outline.md\" per story-short-write before writing prose."
        return None
    if parent != "prose":
        return None
    if not re.match(r"^chapter.*\.md$", base, re.I):
        return None
    if abs_path.exists():
        return None
    m = re.match(r"^chapter[_ ]?0*(\d+)", base, re.I)
    if not m:
        return None
    num = m.group(1)
    book_dir = abs_path.parent.parent
    # A new book may first-build prose before any outline/tracking/setting scaffolding
    # exists; the core guard must fail closed. Relative paths are resolved by
    # HOOK_CWD — don't weaken this canonical guard to mask cwd semantics.
    if (root / "teardown-lib" / book_dir.name).exists():
        return None
    outline_dir = book_dir / "outline"
    found = False
    if outline_dir.is_dir():
        for candidate in outline_dir.iterdir():
            fm = re.match(r"^outline_chapter_0*(\d+).*\.md$", candidate.name, re.I)
            if fm and fm.group(1) == num:
                found = True
                break
    if not found:
        return f"⛔ Prose blocked: chapter {num} has no chapter outline ({safe_rel(root, outline_dir)}/outline_chapter_{num}.md). Build the chapter outline per story-long-write before writing prose."
    # Debt gate (stateless): before first-writing chapter N, if the previous chapter
    # has uncleared toxic patterns and no "deslop:skip" exemption, clear them first.
    # The check is computed from the previous chapter file itself; a missing/unreadable
    # previous chapter passes (miss over false-hit).
    # js↔py copy is locked by check-hook-regex-sync.sh; judgment by
    # test-prose-net-parity.sh Part E.
    prev_num = int(num) - 1
    if prev_num >= 1:
        prev_file = None
        try:
            for candidate in abs_path.parent.iterdir():
                pm = re.match(r"^chapter[_ ]?0*(\d+).*\.md$", candidate.name, re.I)
                if pm and int(pm.group(1)) == prev_num:
                    prev_file = candidate
                    break
        except OSError:
            prev_file = None
        if prev_file is not None:
            prev_text = None
            try:
                prev_text = prev_file.read_text(encoding="utf-8", errors="replace")
            except OSError:
                prev_text = None
            if prev_text is not None and not re.search(r"deslop\s*:\s*skip", "\n".join(re.split(r"\r?\n", prev_text)[:6]), re.I):
                hits = [ln for ln in toxic_phrase_findings(prev_text) if ln.startswith("Line ")]
                if hits:
                    shown = hits[:6]
                    more = len(hits) - len(shown)
                    reason = (
                        f"⛔ Prose blocked: the previous chapter ({prev_file.name}) still has {len(hits)} uncleared toxic patterns; "
                        f"clear them before writing chapter {num}. To exempt explicitly, add <!-- deslop:skip --> under the previous chapter's title line and retry.\n"
                        + "\n".join(shown)
                    )
                    if more > 0:
                        reason += f"\n({more} more; full scan: node <skill>/scripts/check-ai-patterns.js --check <previous chapter file>)"
                    return reason
    return None


def pre_tool_prose_guard(obj: dict[str, Any]) -> None:
    root = project_root()
    for path in target_paths_from_hook(obj):
        reason = prose_block_reason(root, path)
        if reason:
            emit({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            })
            return


def find_command(value: Any) -> str:
    if isinstance(value, dict):
        for key in ("command", "cmd", "script"):
            if isinstance(value.get(key), str):
                return value[key]
        for key in ("tool_input", "input", "parameters", "args"):
            found = find_command(value.get(key))
            if found:
                return found
    return ""


def is_git_commit_command(raw: str) -> bool:
    raw = raw.replace("\r\n", "\n").replace("\r", "\n").replace("\n", " ; ")
    try:
        lexer = shlex.shlex(raw, posix=True, punctuation_chars="();|&{}")
        lexer.whitespace_split = True
        tokens = list(lexer)
    except TypeError:
        try:
            tokens = shlex.split(raw, posix=True)
        except Exception:
            tokens = raw.split()
    except Exception:
        tokens = raw.split()
    assignment = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
    separators = {";", "&&", "||", "|", "|&", "&"}
    openers = {"(", "{"}
    closers = {")",
        "}",
    }
    control_words = {"then", "do", "else", "elif"}
    wrappers = {"command", "noglob"}
    git_options_with_value = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix", "--config-env"}

    def skip_shell_wrappers(i: int) -> int:
        while i < len(tokens):
            tok = tokens[i]
            if tok in openers or assignment.match(tok) or tok in wrappers:
                i += 1
                continue
            if tok == "env":
                i += 1
                while i < len(tokens):
                    if assignment.match(tokens[i]) or tokens[i] in {"-i", "--ignore-environment"}:
                        i += 1
                        continue
                    break
                continue
            break
        return i

    def is_git_commit_at(i: int) -> bool:
        if i >= len(tokens) or tokens[i] != "git":
            return False
        i += 1
        while i < len(tokens):
            tok = tokens[i]
            if tok in closers or tok in separators:
                return False
            if tok == "commit":
                return True
            if tok == "--":
                i += 1
                continue
            if tok in git_options_with_value:
                i += 2
                continue
            if any(tok.startswith(prefix + "=") for prefix in git_options_with_value if prefix.startswith("--")):
                i += 1
                continue
            if tok.startswith("-c") and tok != "-c":
                i += 1
                continue
            if tok.startswith("-"):
                i += 1
                continue
            return False
        return False

    segment_start = True
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok in separators or tok in control_words:
            segment_start = True
            i += 1
            continue
        if segment_start or tok in openers:
            start = skip_shell_wrappers(i)
            if is_git_commit_at(start):
                return True
            segment_start = False
        i += 1
    return False


# Project-level setting files directly under setting/: artifact-protocols.md defines
# relationships.md (body is "# Character Relationship Map"), genre-positioning.md,
# style.md, genre-prose-card.md — these have no name field by design.
_SETTING_NON_CHARACTER_FILES = {"relationships.md", "genre-positioning.md", "genre-prose-card.md", "style.md", "world-rules.md", "worldview.md", "cheat.md", "background.md"}


def _is_character_sheet_path(rel: str) -> bool:
    """Only character sheets are checked: scanning the whole setting/ tree would
    flood every commit touching setting/ with false warnings and bury real
    "hardcoded character attributes in prose" warnings. Matches the case branches
    in validate-story-commit.sh / opencode pre-commit.sh (bash↔js↔py four-end
    parity, don't unilaterally revert to one-shot):
    ① files inside a setting/characters|people subdirectory → character sheet;
    ② anything else under a setting/<subdir>/ → whole directory skipped
       (worldview/factions/reports/principles/relationships etc.);
    ③ flat files directly under setting/ → character sheets except the known
       project-level files (protagonist.md/side-character.md/villain.md etc.).
    bash's `*` matches across `/`, so `setting/characters/*|*/setting/characters/*`
    means "some setting segment satisfies the branch" — hence two passes (first find
    branch ① across the path, then branch ②) rather than judging by the first
    setting segment, which would diverge from bash on nested paths like
    setting/other/setting/characters/x.md.
    Same implementation as the JS core isCharacterSheetPath; py↔js locked by
    scripts/test-prose-net-parity.sh Part E."""
    segments = rel.split("/")
    last = len(segments) - 1
    # Branch ①: some setting segment is followed by characters/people with a file under it
    for i in range(last - 1):
        if segments[i] == "setting" and segments[i + 1] in ("characters", "people"):
            return True
    # Branch ②: some setting segment has >=2 segments after it, i.e. a non-character subdir
    for i in range(last - 1):
        if segments[i] == "setting":
            return False
    # Branch ③: flat files directly under setting/ (branch ② already excluded deeper
    # paths, so the setting segment can only be the second-to-last)
    return last >= 1 and segments[last - 1] == "setting" and segments[last] not in _SETTING_NON_CHARACTER_FILES


def staged_markdown_warnings(root: Path) -> str:
    try:
        proc = subprocess.run(
            ["git", "-C", str(root), "-c", "core.quotepath=false", "diff", "--cached", "--relative", "--name-only", "--diff-filter=ACM", "-z", "--", "."],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        return ""
    warnings: list[str] = []
    for raw in proc.stdout.split(b"\0"):
        if not raw:
            continue
        file = raw.decode("utf-8", errors="ignore")
        if not file.endswith(".md"):
            continue
        full = root / file
        if not full.exists():
            continue
        text = full.read_text(encoding="utf-8", errors="ignore")
        # Match semantics and warning copy aligned with the JS core
        # (story_hook_core.js stagedMarkdownWarnings, the cross-CLI authoritative
        # implementation): name field re.I case-insensitive. py↔js locked by
        # scripts/test-prose-net-parity.sh Part E.
        if file == "prose.md" or "/prose.md" in file or file.startswith("prose/") or "/prose/" in file:
            hits = []
            for idx, line in enumerate(text.splitlines(), 1):
                if re.search(r"\b(height|weight|age)\b(\s)*(:)(\s)*[0-9]+", line, re.I):
                    hits.append(f"{idx}:{line}")
            if hits:
                warnings.append(f"⚠ {file}: prose hardcodes character attributes; reference the setting file instead:\n" + "\n".join(hits))
        if _is_character_sheet_path(file):
            if not re.search(r"^(\s)*(name)(\s)*(:)", text, re.M | re.I):
                warnings.append(f"⚠ {file}: setting file is missing the required name field.")
    if not warnings:
        return ""
    return "=== Story Commit Warnings（advisory only）===\n" + "\n".join(warnings) + "\n=== End Warnings ==="


def pre_tool_commit_advisory(obj: dict[str, Any]) -> None:
    command = find_command(obj)
    if not command or not is_git_commit_command(command):
        return
    warnings = staged_markdown_warnings(project_root())
    if warnings:
        emit(hook_context("PreToolUse", warnings))


def compact_summary(event: str) -> None:
    root = project_root()
    lines = ["=== Story Compact Summary ==="]
    book = read_active_book(root)
    if book:
        ctx = book / "tracking" / "context.md"
        if ctx.exists():
            line_count = len(ctx.read_text(encoding="utf-8", errors="ignore").splitlines())
            lines.append(f"Writing context: {safe_rel(root, ctx)} ({line_count} lines)")
        else:
            lines.append(f"Active story project: {safe_rel(root, book)}")
    else:
        lines.append("Active state: not found")
    try:
        # -z + bytes so a non-ASCII filename under a user-global core.quotepath=false
        # can't raise UnicodeDecodeError on a Windows ANSI code page (counts only).
        # --relative -- . narrows counts to the project subtree: when the project root
        # is a subdirectory of the repo, omitting it would count the whole upper repo
        # (same stance as find_changed_prose_files / staged_markdown_warnings).
        changed = subprocess.check_output(["git", "-C", str(root), "-c", "core.quotepath=false", "diff", "--relative", "--name-only", "-z", "--", "."], stderr=subprocess.DEVNULL)
        staged = subprocess.check_output(["git", "-C", str(root), "-c", "core.quotepath=false", "diff", "--relative", "--name-only", "--cached", "-z", "--", "."], stderr=subprocess.DEVNULL)
        n_changed = len([x for x in changed.split(b"\0") if x])
        n_staged = len([x for x in staged.split(b"\0") if x])
        lines.append(f"Git: {n_changed} unstaged, {n_staged} staged")
    except Exception:
        pass
    emit({"systemMessage": "\n".join(lines)})


def stop_event() -> None:
    # Codex has no PostToolUse; the prose content net runs at the turn-ending Stop
    # event, rescanning hard signals (truncation/refusal/engineering words/repeat)
    # on this turn's git-changed prose. Non-blocking, silent when clean; parse
    # failures always {continue:True}. Stop hooks require JSON on stdout.
    try:
        root = project_root()
        blocks: list[str] = []
        for abs_path in find_changed_prose_files(root):
            try:
                text = abs_path.read_text(encoding="utf-8")
            except Exception:
                continue
            findings = prose_net_findings(text)
            wc = _wordcount_finding(abs_path, text)
            if wc:
                findings.append(wc)
            if findings:
                blocks.append(f"=== {safe_rel(root, abs_path)} ===\n" + "\n".join(findings))
        if blocks:
            emit({
                "continue": True,
                "systemMessage": "=== Prose backstop check (turn-end rescan, model-independent) ===\nHard signals: fix them in the prose and rescan to clean:\n"
                + "\n".join(blocks),
            })
            return
    except Exception:
        pass
    emit({"continue": True})


def main() -> int:
    event = sys.argv[1] if len(sys.argv) > 1 else ""
    obj = read_hook_input()
    if event == "session-start":
        session_start()
    elif event == "pre-tool-prose-guard":
        pre_tool_prose_guard(obj)
    elif event == "pre-tool-commit-advisory":
        pre_tool_commit_advisory(obj)
    elif event == "pre-compact":
        compact_summary("PreCompact")
    elif event == "post-compact":
        compact_summary("PostCompact")
    elif event == "stop":
        stop_event()
    else:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
