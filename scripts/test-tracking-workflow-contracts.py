#!/usr/bin/env python3
"""Lexical guards for the single-authority tracking workflow contracts."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_all(text: str, needles: tuple[str, ...], label: str) -> None:
    missing = [needle for needle in needles if needle not in text]
    require(not missing, f"{label} missing contract text: {missing}")


def test_transaction_is_the_only_tracking_writer() -> None:
    for path in (
        "skills/story-long-write/SKILL.md",
        "skills/story-long-write/references/workflow-daily.md",
        "skills/story-long-write/references/workflow-revision.md",
        "skills/story-import/SKILL.md",
        "skills/story-review/SKILL.md",
    ):
        require("tracking_commit.py" in read(path), f"{path} must route writes through tracking_commit.py")

    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        (
            "one structured authority state plus deterministic derived views",
            "not written separately",
            "_tracking-state.json",
            "only commit point",
            "directly rerun the same `commit`",
            "expected_state_revision",
            "complete continuity record",
            "not a concurrency lock",
        ),
        "tracking protocol",
    )


def test_authority_model_matches_the_implementation() -> None:
    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        (
            "imported cutoff chapter",
            "imported_through_chapter",
            "chapter records",
            "overlay records",
            "sole authority",
            "does not reverse-parse Markdown",
        ),
        "tracking authority model",
    )
    require("基线_截至第N章.md" not in protocol, "tracking protocol still creates a redundant baseline file")
    for path in (
        "skills/story-long-write/references/state-tracking.md",
        "skills/story-import/references/state-tracking.md",
        "skills/story-long-write/references/workflow-daily.md",
    ):
        require("core: true" not in read(path), f"{path} still instructs callers to use the removed core field")


def test_failed_commit_retries_the_same_external_transaction() -> None:
    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        (
            "事务 JSON 在成功前必须保留",
            "修正环境后直接重跑**同一份** `commit`",
            "不维护 `dirty/pending/repair` 状态机",
        ),
        "retry contract",
    )


def test_state_card_and_compact_delta_limits_are_explicit() -> None:
    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        (
            "目标 ≤1536 字节，硬上限 3072 字节",
            "目标 ≤4096 字节，超过警告；硬上限 8192 字节",
            "四个列表不限制条数",
            "≤12288 字节",
            "## Current Position",
            "## Long-Term Constraints",
            "## 核心character-state",
            "## Active Foreshadowing",
            "## Recent Chapters",
            "## Next-Chapter Commitments",
            "## Continuity Risks",
        ),
        "bounded tracking protocol",
    )


def test_import_records_a_cutoff_without_fabricated_old_deltas() -> None:
    text = read("skills/story-import/SKILL.md")
    require_all(
        text,
        (
            "imported_through_chapter=N",
            "do not fabricate per-chapter records for chapters 1..N",
            "_tracking-state.json",
            "character-state/{Character Name}.md",
            "timeline reader-knowledge view",
            "tracking_commit.py init",
        ),
        "story-import tracking",
    )
    # 迁移可以描述，但只能「存档旧结构后按当前协议重建」，不得声称解析/转换旧tracking文件。
    require("_retired-tracking-archive" in text, "story-import migration must archive the old tracking structure")
    require(
        "解析旧" not in text and "兼容层" not in text,
        "story-import must not claim to parse or convert old tracking structures",
    )


def test_reader_timeline_is_kept_separate_from_author_truth() -> None:
    explorer = read("skills/story-setup/references/templates/agents/story-explorer.md")
    require_all(
        explorer,
        (
            "defaults to `reader` when no audience is specified",
            "reader-knowledge timeline",
            "author-truth timeline",
            "reader results must not mix unrevealed `objective_fact` content into the `reader` view",
        ),
        "story-explorer timeline",
    )
    checker = read("skills/story-setup/references/templates/agents/consistency-checker.md")
    require_all(
        checker,
        (
            "Use the author-truth timeline to verify objective chronology",
            "the reader-knowledge timeline to verify that prose does not reveal information early",
            "tracking_commit.py check",
        ),
        "consistency timeline",
    )


def test_review_mutations_are_transactional_and_scoped() -> None:
    text = read("skills/story-review/SKILL.md")
    require_all(
        text,
        (
            "full / lean modes may modify `tracking/` only through `tracking_commit.py`",
            "solo mode reports findings and writes no files",
            "mode=revision",
            "the same ID `upsert` for current state",
            "keep chapter-records within its size contract",
            "tracking_commit.py check",
        ),
        "story-review tracking maintenance",
    )


def test_retired_tracking_architecture_is_absent() -> None:
    paths = (
        "README.md",
        "README_EN.md",
        "skills/story-long-write/SKILL.md",
        "skills/story-long-write/references/artifact-protocols.md",
        "skills/story-long-write/references/workflow-daily.md",
        "skills/story-long-write/references/workflow-revision.md",
        "skills/story-import/SKILL.md",
        "skills/story-import/references/structure-mapping-long.md",
        "skills/story-review/SKILL.md",
        "skills/story-setup/references/templates/CLAUDE.md.tmpl",
        "skills/story-setup/references/templates/agents/story-explorer.md",
        "skills/story-setup/references/templates/rules/story-consistency.md",
    )
    retired = (
        "tracking/阶段摘要.md",
        "tracking/摘要/",
        "## 逐章更新记录",
        "## 累计待处理项",
        "## 历史记录索引",
        "顶层区块恰好是下面 11 个",
        "迁移归档",
        "_tracking-meta.json",
        "事件库.json",
    )
    for path in paths:
        text = read(path)
        found = [term for term in retired if term in text]
        require(not found, f"{path} still contains retired tracking architecture: {found}")

    require(
        not (ROOT / "skills/story-setup/references/templates/context.md.tmpl").exists(),
        "manual context template must be deleted; the transaction tool renders the hot cache",
    )


def test_no_tracking_fallback_or_context_style_fingerprint_remains() -> None:
    long_write = read("skills/story-long-write/SKILL.md")
    for forbidden in (
        "character-state文件缺失** → 从角色设定文件和前文推断当前状态",
        "伏笔/timeline文件缺失** → 不检查",
    ):
        require(forbidden not in long_write, f"story-long-write still has tracking fallback: {forbidden}")
    require_all(
        long_write,
        (
            "treat the semantic checkpoint as corrupted",
            "existing book has prose and `tracking/` but `_tracking-state.json` is missing or invalid, treat the semantic checkpoint as corrupted and stop before writing; re-run `/story-import`",
        ),
        "fail-closed tracking reads",
    )
    writer = read("skills/story-setup/references/templates/agents/narrative-writer.md")
    require("`context.md` 文风指纹" not in writer, "narrative-writer still reads a removed context style fingerprint")
    require("tracking/context.md`「文风指纹」" not in writer, "narrative-writer still treats context as style storage")
    require("The continuation state card does not contain a style fingerprint" in writer, "narrative-writer must keep style out of tracking context")


def test_hooks_fail_closed_on_invalid_tracking_checkpoints() -> None:
    js = read("skills/story-setup/references/templates/hooks/story_hook_core.js")
    py = read("skills/story-setup/references/codex/hooks/story_codex_hook.py")
    for label, text in (("JS hook", js), ("Codex hook", py)):
        require_all(
            text,
            (
                "_tracking-state.json is missing",
                "schema_version=4",
                "state_revision",
                "mode=revision transaction to rebuild derived views",
                "re-run /story-import",
                "last_committed_chapter",
                "Tracking must be committed first",
            ),
            label,
        )


def test_daily_quality_repairs_close_tracking_before_batch_finish() -> None:
    text = read("skills/story-long-write/references/workflow-daily.md")
    revision = text.index("If a prose repair changes facts that affect later chapters")
    step_four = text.index("## Step 4: Progress summary")
    require(revision < step_four, "quality repair revision invariant must appear before Step 4")
    require_all(text[revision:step_four], ("mode=revision", "run `check` afterward", "Pure wording changes do not require a resubmission"), "daily quality repair closure")


def test_tracking_examples_use_the_demo_novel() -> None:
    paths = (
        "skills/story-long-write/references/tracking-transaction.md",
        "skills/story-import/SKILL.md",
        "skills/story-import/references/character-state-reverse.md",
        "skills/story-review/SKILL.md",
        "skills/story-setup/references/templates/rules/story-consistency.md",
    )
    for path in paths:
        text = read(path)
        found = [term for term in ("Lin Zhou", "Bell Tower", "Investigator") if term in text]
        require(not found, f"{path} still contains placeholder examples: {found}")


def test_context_retirement_must_be_declared_not_silent() -> None:
    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        (
            "delta.retired_context_items",
            "delta.retired_characters",
            "## Retired Entries This Chapter",
            "omission is not deletion",
        ),
        "explicit context retirement",
    )
    daily = read("skills/story-long-write/references/workflow-daily.md")
    require_all(
        daily,
        ("delta.retired_context_items", "delta.retired_characters", "submit the complete current context each chapter"),
        "daily workflow retirement rules",
    )


def test_init_archives_a_pre_protocol_tracking_directory() -> None:
    protocol = read("skills/story-long-write/references/tracking-transaction.md")
    require_all(
        protocol,
        ("tracking/_retired-tracking-archive/", "A failed `init` validation moves no files", "is not parsed"),
        "init archive contract",
    )
    require(
        "tracking/_retired-tracking-archive/" in read("skills/story-long-write/references/workflow-daily.md"),
        "workflow-daily must state where a pre-protocol tracking directory goes",
    )
    tool = read("skills/story-long-write/scripts/tracking_commit.py")
    require(
        'RETIRED_ARCHIVE_DIR = "_retired-tracking-archive"' in tool,
        "tracking_commit.py must define the archive directory used by the documented contract",
    )


def main() -> None:
    tests = [
        value
        for name, value in sorted(globals().items())
        if name.startswith("test_") and callable(value)
    ]
    for test in tests:
        test()
    print(f"Tracking workflow contract tests passed ({len(tests)} tests).")


if __name__ == "__main__":
    main()
