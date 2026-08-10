"""Contract tests for the English prose word-count tokenization."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PATTERN = r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+|-[A-Za-z0-9]+)*"
SAMPLE = "The state-of-the-art ward didn't fail—it shifted."


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def main() -> None:
    assert len(re.findall(PATTERN, SAMPLE)) == 7

    js_pattern = PATTERN.replace("\\", "")
    executable_copies = [
        "skills/story-setup/references/templates/hooks/story_hook_core.js",
        "skills/story-setup/references/opencode/story_hook_core.js",
        "skills/story-setup/references/zcode/hooks/story_hook_core.js",
        "skills/story-deslop/scripts/check-ai-patterns.js",
        "skills/story-long-write/scripts/check-ai-patterns.js",
        "skills/story-short-write/scripts/check-ai-patterns.js",
        "skills/story-review/scripts/check-ai-patterns.js",
        "skills/story-deslop/scripts/check-degeneration.js",
        "skills/story-long-write/scripts/check-degeneration.js",
        "skills/story-short-write/scripts/check-degeneration.js",
        "skills/story-review/scripts/check-degeneration.js",
    ]
    for relative in executable_copies:
        assert js_pattern in read(relative), f"{relative} is out of sync"

    assert PATTERN in read("skills/story-setup/references/codex/hooks/story_codex_hook.py")
    short_skill = read("skills/story-short-write/SKILL.md")
    assert "Path('prose.md').read_text(encoding='utf-8').split()" not in short_skill
    assert "shared English word-count contract" in short_skill
    print(f"Word-count contract passed ({len(executable_copies) + 1} implementations).")


if __name__ == "__main__":
    main()
