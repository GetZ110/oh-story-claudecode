#!/usr/bin/env python3
"""Validate a book contract and catch strong record-language drift.

The scanner is deliberately conservative.  Book titles, proper nouns, stable
identifiers, and language/platform codes may remain canonical.  It fails only
on lines that contain a clear natural-language block in the opposite script,
so it is useful as a workflow gate without pretending that language detection
can reliably classify every name or genre term.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


LANGUAGE_RE = re.compile(r"(?im)^\s*(?:[-*]\s*)?Record language\s*:\s*([A-Za-z0-9_-]+)\s*$")
TITLE_RE = re.compile(r"(?im)^\s*[-*]\s*Title\s*:\s*(.+?)\s*$")
PROTAGONIST_RE = re.compile(r"(?im)^\s*[-*]\s*Protagonist\s*:\s*(.+?)\s*$")
WORD_RE = re.compile(r"[A-Za-z][A-Za-z'-]*")
CJK_RE = re.compile(r"[\u3400-\u9fff]")
TEXT_SUFFIXES = {".md", ".txt", ".json", ".yaml", ".yml"}
SCAN_DIRS = ("outline", "setting", "tracking")
CANONICAL_WORDS = {
    "en",
    "en-us",
    "en-gb",
    "en-au",
    "en-ca",
    "zh",
    "zh-cn",
    "zh-hans",
    "us",
    "uk",
    "wattpad",
    "webnovel",
    "royal",
    "road",
    "amazon",
    "kindle",
    "inkitt",
    "radish",
    "galatea",
    "goodnovel",
    "tapas",
    "chapter",
    "outline",
}


class LanguageCheckError(Exception):
    """A contract or record-language validation failure."""


def read_contract(project: Path) -> tuple[str, set[str]]:
    profile = project.resolve() / "AGENTS.md"
    if not profile.is_file():
        raise LanguageCheckError(
            f"book language contract is required before writing records: {profile}"
        )
    try:
        text = profile.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise LanguageCheckError(f"unable to read book language contract {profile}: {exc}") from exc

    match = LANGUAGE_RE.search(text)
    if match is None:
        raise LanguageCheckError("book AGENTS.md is missing a complete Record language field")
    value = match.group(1).lower()
    if value in {"zh", "zh-cn", "zh-hans"}:
        language = "zh-CN"
    elif value in {"en", "en-us", "en-gb", "en-au", "en-ca"}:
        language = "en"
    else:
        raise LanguageCheckError(f"unsupported Record language in book AGENTS.md: {match.group(1)}")

    allowed = set(CANONICAL_WORDS)
    for pattern in (TITLE_RE, PROTAGONIST_RE):
        for match in pattern.finditer(text):
            allowed.update(word.lower() for word in WORD_RE.findall(match.group(1)))
    return language, allowed


def text_files(project: Path) -> list[Path]:
    files: list[Path] = []
    for directory in SCAN_DIRS:
        root = project / directory
        if not root.is_dir():
            continue
        files.extend(
            path
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES
        )
    return sorted(files)


def violations(project: Path, language: str, allowed: set[str]) -> list[str]:
    findings: list[str] = []
    for path in text_files(project):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            findings.append(f"{path}: unable to read UTF-8 record file: {exc}")
            continue
        for line_number, line in enumerate(text.splitlines(), start=1):
            cjk_count = len(CJK_RE.findall(line))
            words = [word.lower() for word in WORD_RE.findall(line)]
            unknown_english = [word for word in words if word not in allowed]
            if language == "zh-CN" and (
                (cjk_count == 0 and len(unknown_english) >= 4)
                or (cjk_count > 0 and len(unknown_english) >= 8)
            ):
                findings.append(
                    f"{path.relative_to(project)}:{line_number}: strong English record-language drift"
                )
            elif language == "en" and cjk_count >= 8:
                findings.append(
                    f"{path.relative_to(project)}:{line_number}: strong Chinese record-language drift"
                )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True, help="book project root")
    parser.add_argument(
        "--contract-only",
        action="store_true",
        help="validate AGENTS.md without scanning outline/setting/tracking",
    )
    args = parser.parse_args()
    try:
        language, allowed = read_contract(args.project)
        findings = [] if args.contract_only else violations(args.project, language, allowed)
    except LanguageCheckError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if findings:
        print(f"ERROR: {len(findings)} record-language issue(s) found", file=sys.stderr)
        for finding in findings:
            print(f"- {finding}", file=sys.stderr)
        return 2
    print(f"OK: book contract and {language} record language validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
