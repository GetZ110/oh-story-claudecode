"""Regression checks for the English book-level language contract."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def main() -> None:
    contract = read("skills/story-setup/references/agent-references/english-book-contract.md")
    for field in (
        "Prose language: en",
        "Record language: en",
        "English variant: en-US",
        "Dialogue quotation: curly double quotes",
        "Content rating:",
        "Content warnings:",
        "Serialization:",
    ):
        assert field in contract, f"contract missing {field!r}"

    runtime_skills = (
        "story-cover",
        "story-deslop",
        "story-import",
        "story-long-analyze",
        "story-long-scan",
        "story-long-write",
        "story-review",
        "story-short-analyze",
        "story-short-scan",
        "story-short-write",
    )
    for skill in runtime_skills:
        text = read(f"skills/{skill}/SKILL.md")
        assert "user's language" not in text.lower(), f"{skill} still has chat-language fallback"
        assert "English book contract" in text, f"{skill} does not consume the book contract"

    for demo in (
        "demo/long-form/The-Shattered-Throne/AGENTS.md",
        "demo/teardown-lib/The-Last-Knight/AGENTS.md",
        "demo/teardown-lib/The-Secret-Keeper/AGENTS.md",
    ):
        text = read(demo)
        assert "Prose language: en" in text, f"{demo} missing prose language"
        assert "Record language: en" in text, f"{demo} missing record language"

    print(f"English book contract passed ({len(runtime_skills)} runtime skills, 3 demos).")


if __name__ == "__main__":
    main()
