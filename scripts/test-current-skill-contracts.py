#!/usr/bin/env python3
"""Focused regressions for the structured current-contract validator."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
MODULE_PATH = SCRIPT_DIR / "check-current-skill-contracts.py"
SPEC = importlib.util.spec_from_file_location("current_contract_validator", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
VALIDATOR = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = VALIDATOR
SPEC.loader.exec_module(VALIDATOR)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def finding_codes(findings: list[object]) -> set[str]:
    return {finding.code for finding in findings}


def repository_manifest() -> object:
    manifest, findings = VALIDATOR.load_manifest(SCRIPT_DIR / "current-contract.json")
    require(not findings and manifest is not None, "repository manifest must load")
    return manifest


def manifest_with(**overrides: object) -> object:
    """Build an overridden current contract through the normal load path, to
    exercise a version bump."""
    raw = json.loads((SCRIPT_DIR / "current-contract.json").read_text(encoding="utf-8"))
    raw.update(overrides)
    with tempfile.TemporaryDirectory() as tmp:
        bumped_path = Path(tmp) / "bumped.json"
        bumped_path.write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
        manifest, findings = VALIDATOR.load_manifest(bumped_path)
    require(not findings and manifest is not None, "bumped manifest must stay well-formed")
    return manifest


def flagged_paths(manifest: object, code: str) -> set[str]:
    return {
        finding.path.relative_to(REPO_ROOT).as_posix()
        for finding in VALIDATOR.validate_repository(REPO_ROOT, manifest)
        if finding.code == code and finding.path is not None
    }


def test_manifest_contract() -> None:
    manifest_path = SCRIPT_DIR / "current-contract.json"
    manifest, findings = VALIDATOR.load_manifest(manifest_path)
    require(not findings, "repository manifest should validate: {}".format(findings))
    require(manifest is not None, "repository manifest should load")
    require(not VALIDATOR.validate_repository(REPO_ROOT, manifest), "manifest and repository must agree")

    raw = json.loads(manifest_path.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)

        wrong_type = dict(raw)
        wrong_type["agents_version"] = "18"
        wrong_type_path = tmpdir / "wrong-type.json"
        wrong_type_path.write_text(json.dumps(wrong_type, ensure_ascii=False), encoding="utf-8")
        _, wrong_type_findings = VALIDATOR.load_manifest(wrong_type_path)
        require(
            "manifest-value-type" in finding_codes(wrong_type_findings),
            "string agents_version must be rejected",
        )

        stale = dict(raw)
        stale["topic_decision_phase"] = 4
        stale_path = tmpdir / "stale.json"
        stale_path.write_text(json.dumps(stale, ensure_ascii=False), encoding="utf-8")
        stale_manifest, stale_findings = VALIDATOR.load_manifest(stale_path)
        require(
            not stale_findings and stale_manifest is not None,
            "a well-formed manifest remains the source of truth",
        )
        require(
            "topic-decision-phase" in finding_codes(
                VALIDATOR.validate_repository(REPO_ROOT, stale_manifest)
            ),
            "repository drift from the manifest must be rejected",
        )

        malformed_sections = dict(raw)
        malformed_sections["required_outline_sections"] = [{"rule": "Stage position"}]
        malformed_path = tmpdir / "malformed-sections.json"
        malformed_path.write_text(json.dumps(malformed_sections, ensure_ascii=False), encoding="utf-8")
        _, malformed_findings = VALIDATOR.load_manifest(malformed_path)
        require(
            "manifest-outline-type" in finding_codes(malformed_findings),
            "incomplete outline-section objects must be rejected",
        )

        duplicate_artifacts = dict(raw)
        duplicate_artifacts["primary_benchmark_artifacts"] = ["plot/pacing.md", "plot/pacing.md"]
        duplicate_path = tmpdir / "duplicate-artifacts.json"
        duplicate_path.write_text(json.dumps(duplicate_artifacts, ensure_ascii=False), encoding="utf-8")
        _, duplicate_findings = VALIDATOR.load_manifest(duplicate_path)
        require(
            "manifest-artifact-duplicate" in finding_codes(duplicate_findings),
            "duplicate primary artifacts must be rejected",
        )

        renamed_artifacts = dict(raw)
        renamed_artifacts["primary_benchmark_artifacts"] = [
            "benchmark/emotional-engine.md",
            "benchmark/rhythm-index.md",
        ]
        renamed_path = tmpdir / "renamed-artifacts.json"
        renamed_path.write_text(
            json.dumps(renamed_artifacts, ensure_ascii=False), encoding="utf-8"
        )
        renamed_manifest, renamed_findings = VALIDATOR.load_manifest(renamed_path)
        require(
            not renamed_findings and renamed_manifest is not None,
            "renamed current artifacts must remain manifest-driven",
        )
        renamed_semantic = semantic_findings(
            "- If `benchmark/rhythm-index.md` is missing, fall back to reading `teardown-report.md`.",
            renamed_manifest.primary_benchmark_artifacts,
        )
        require(
            "silent-primary-artifact-fallback" in finding_codes(renamed_semantic),
            "semantic guard must follow renamed manifest artifacts",
        )


def semantic_findings(
    text: str, primary_artifacts: tuple[str, ...] | None = None
) -> list[object]:
    if primary_artifacts is None:
        primary_artifacts = repository_manifest().primary_benchmark_artifacts
    return VALIDATOR.semantic_primary_fallback_findings(
        text,
        Path("fixture.md"),
        primary_artifacts,
    )


def test_bad_fallbacks_fail() -> None:
    bad_cases = {
        "inline report fallback": "- If `plot/emotional-beats.md` is missing, fall back to reading `teardown-report.md`.",
        "nested summary substitution": """
1. Check `plot/pacing.md`.
2. When any primary artifact is missing:
   - Use `chapters/chapter_5_summary.md` instead.
""",
        "structured gap story fallback": "- When `plot/pacing.md` is missing and `rhythm_missing: true`, switch to `storylines.md` to fill the rhythm.",
    }
    for label, text in bad_cases.items():
        findings = semantic_findings(text)
        require(
            "silent-primary-artifact-fallback" in finding_codes(findings),
            "{} should fail".format(label),
        )


def test_fail_fast_prose_passes() -> None:
    good_cases = {
        "explicit prohibition": "- When `plot/emotional-beats.md` is missing, stop; do not substitute `teardown-report.md`, chapter summaries, or storylines.",
        "explicit no fallback": "- When `rhythm_missing: true`, return `missing_primary_contract`; fallback to `storylines.md` is prohibited.",
        "normal complete branch": "- When both primary artifacts exist, read `teardown-report.md` as a human-readable overview.",
        "deep-dive fallback is not primary fallback": (
            "- First read `plot/emotional-beats.md` and `plot/pacing.md`; stop to repair when the module or rhythm file is missing. "
            "After matching `chapters/chapter_5_summary.md`, if the same chapter's deep dive does not exist, fall back to the golden-three-chapters deep dives."
        ),
    }
    for label, text in good_cases.items():
        findings = semantic_findings(text)
        require(not findings, "{} should pass, got {}".format(label, findings))


def test_sibling_bullets_do_not_lend_the_missing_condition() -> None:
    """Adjacent items are independent contracts: a fail-fast sibling must not
    lend its "primary artifact missing" condition to a correct reading item."""
    fail_fast = "- `plot/pacing.md` → when missing, stop the import; do not substitute `teardown-report.md`, chapter summaries, or storylines"
    good_neighbours = {
        "benign read after a fail-fast sibling": "- When both primary artifacts exist, read `teardown-report.md` as a human-readable overview.",
        "human-readable overview bullet": "- storylines (human-readable overview) → read from `storylines.md`; leave blank when missing",
        "prose block after a fail-fast bullet": "**lossless check** (when any fails, delete `_chapter-summary-index.md` and fall back to per-file scanning):",
    }
    for label, good in good_neighbours.items():
        findings = semantic_findings(fail_fast + "\n" + good + "\n")
        require(not findings, "{} should pass, got {}".format(label, findings))

    nested = (
        "When any primary artifact is missing:\n"
        "- record it in tracking first\n"
        "- then confirm the block state\n"
        "- then fall back to reading `teardown-report.md` to assemble the benchmark view\n"
    )
    require(
        "silent-primary-artifact-fallback" in finding_codes(semantic_findings(nested)),
        "a missing condition on a parent item must still block a downgraded child",
    )
    deep = "- When any primary artifact is missing:\n  - import branch:\n    - adopt `storylines.md` as a substitute.\n"
    require(
        "silent-primary-artifact-fallback" in finding_codes(semantic_findings(deep)),
        "a missing condition two levels up must still block a downgraded child",
    )
    wrapped = "- If `plot/pacing.md` is missing,\n  then switch to reading `chapters/chapter_2_summary.md` to fill the rhythm.\n"
    require(
        "silent-primary-artifact-fallback" in finding_codes(semantic_findings(wrapped)),
        "a continuation line still belongs to the same item as its condition",
    )
    table_rows = (
        "| Condition | Action |\n"
        "|---|---|\n"
        "| `plot/pacing.md` missing | stop Stage 6 and report `missing_primary_contract` |\n"
        "| `chapters/chapter_1-3_deep-dive.md` missing | dialogue subtext falls back to the teardown report |\n"
    )
    require(
        not semantic_findings(table_rows),
        "adjacent table rows are independent records; a deep-dive fallback is not a primary downgrade: {}".format(
            semantic_findings(table_rows)
        ),
    )
    bad_row = (
        "| Condition | Action |\n"
        "|---|---|\n"
        "| `plot/pacing.md` missing | fall back to reading `teardown-report.md` to fill the rhythm |\n"
    )
    require(
        "silent-primary-artifact-fallback" in finding_codes(semantic_findings(bad_row)),
        "a primary downgrade inside the same table row must be blocked",
    )


def test_undecodable_markdown_is_a_named_failure() -> None:
    """Non-UTF-8 text would silently pass every content rule; it must be a named
    failure. Binary assets are still skipped."""
    rule = next(
        r for r in VALIDATOR.LEGACY_RULES if r.code == "dotted-demo-workflow-label"
    )
    dotted = "# Process notes\n\nOld label \u2014 St\u00e9phane's note: Step 1.2: old label\n"
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        demo = root / "demo"
        demo.mkdir()
        target = demo / "process-notes.md"
        target.write_text(dotted, encoding="utf-8")
        require(
            VALIDATOR.check_absent_rule(root, rule),
            "a UTF-8 dotted label must be intercepted by the content rule",
        )
        target.write_bytes(dotted.encode("gb18030"))
        require(
            not VALIDATOR.check_absent_rule(root, rule),
            "the content rule cannot read a GBK file — exactly why a dedicated scan is needed",
        )
        require(
            "unreadable-source-file"
            in finding_codes(VALIDATOR.undecodable_source_findings([demo])),
            "non-UTF-8 contract text must be a named failure, not a silent skip",
        )
        target.write_text(dotted, encoding="utf-16")
        require(
            "unreadable-source-file"
            in finding_codes(VALIDATOR.undecodable_source_findings([demo])),
            "UTF-16 Markdown contains NUL but is still contract text; it must not masquerade as a binary asset",
        )
        target.write_text(dotted, encoding="utf-8")
        (demo / "cover.png").write_bytes(b"\x89PNG\r\n\x1a\n\xff\xfe")
        # Extension-less / non-whitelisted binaries (.DS_Store etc.) are
        # recognized by NUL bytes and must not be misreported.
        (demo / ".DS_Store").write_bytes(b"\x00\x00\x00\x01Bud1\xff\xfe")
        require(
            not VALIDATOR.undecodable_source_findings([demo]),
            "binary assets are not contract text and must stay silent: {}".format(
                VALIDATOR.undecodable_source_findings([demo])
            ),
        )


def test_progress_schema_pins_are_repo_wide() -> None:
    """Bumping progress_schema_version must name every literal anchor, not just
    pipeline-ops.md."""
    current = repository_manifest().progress_schema_version
    stale = flagged_paths(
        manifest_with(progress_schema_version=current + 1), "progress-schema-version"
    )
    for relative in (
        "skills/story-long-analyze/references/pipeline-ops.md",
        "skills/story-long-analyze/SKILL.md",
        "skills/story-import/SKILL.md",
        "skills/story-setup/UPGRADING.md",
        "demo/teardown-lib/The-Last-Knight/_progress.md",
    ):
        require(
            relative in stale,
            "{} schema_version anchor must follow the manifest; actual hits {}".format(
                relative, sorted(stale)
            ),
        )
    require(
        "CHANGELOG.md" not in stale,
        "CHANGELOG history is not constrained by the current value",
    )


def test_stale_scan_phase_reference_accepts_backticks() -> None:
    """Both backticked `story-long-scan` Phase N and bare-token forms must be
    caught by the stale reference scan."""
    current = repository_manifest().topic_decision_phase
    stale = flagged_paths(
        manifest_with(topic_decision_phase=current + 1),
        "stale-topic-decision-phase-reference",
    )
    for relative in (
        "skills/story-long-write/SKILL.md",
        "skills/story-long-analyze/SKILL.md",
    ):
        require(
            relative in stale,
            "{} topic-decision phase reference must be caught; actual hits {}".format(relative, sorted(stale)),
        )


def test_structured_sentinel_contract() -> None:
    manifest = repository_manifest()
    scattered = """
agents_version: {agents_version}
setup_skill_version: {setup_skill_version}
the surrounding prose also mentions target_cli, resolver_strategy and references_dir.
""".format(
        agents_version=manifest.agents_version,
        setup_skill_version=manifest.setup_skill_version,
    )
    require(
        VALIDATOR.extract_sentinel_fields(scattered) is None,
        "scattered sentinel tokens must not satisfy the deployment block",
    )
    require(
        "setup-sentinel-block"
        in finding_codes(
            VALIDATOR.sentinel_contract_findings(
                scattered, manifest, Path("fixture.md")
            )
        ),
        "missing structured sentinel block must fail",
    )

    structured = """
### Step 8: Create deployment marker

- Write the following fields:

```yaml
deployed_at: 2026-07-14T00:00:00Z
agents_version: {agents_version}
setup_skill_version: {setup_skill_version}
target_cli: codex
resolver_strategy: project-first
references_dir: .codex/skills/story-setup/references
```
""".format(
        agents_version=manifest.agents_version,
        setup_skill_version=manifest.setup_skill_version,
    )
    require(
        not VALIDATOR.sentinel_contract_findings(
            structured, manifest, Path("fixture.md")
        ),
        "well-formed structured sentinel must pass",
    )

    incomplete = structured.replace("target_cli: codex\n", "")
    require(
        "setup-sentinel-fields"
        in finding_codes(
            VALIDATOR.sentinel_contract_findings(
                incomplete, manifest, Path("fixture.md")
            )
        ),
        "missing generated sentinel fields must fail",
    )


def test_structured_outline_contract() -> None:
    manifest = repository_manifest()
    rule_names = [rule for rule, _ in manifest.required_outline_sections]
    demo_names = [demo for _, demo in manifest.required_outline_sections]

    scattered_rule = "2. **Required chapter-outline fields**\n\n" + " ".join(rule_names)
    require(
        "outline-rule-section"
        in finding_codes(
            VALIDATOR.outline_rule_contract_findings(
                scattered_rule, manifest, Path("rule.md")
            )
        ),
        "outline names scattered in prose must not satisfy structured rules",
    )
    structured_rule = (
        "2. **Required chapter-outline fields**\n"
        + "\n".join("- {}: required".format(name) for name in rule_names)
        + "\n3. **Next rule**\n"
    )
    require(
        not VALIDATOR.outline_rule_contract_findings(
            structured_rule, manifest, Path("rule.md")
        ),
        "structured outline rule fields must pass",
    )

    scattered_demo = "This chapter should contain: " + " ".join(demo_names)
    declared = VALIDATOR.extract_demo_outline_fields(scattered_demo)
    require(
        not set(demo_names).issubset(declared),
        "demo names scattered in prose must not count as declared sections",
    )
    structured_demo = "\n".join("## {}".format(name) for name in demo_names)
    require(
        set(demo_names).issubset(
            VALIDATOR.extract_demo_outline_fields(structured_demo)
        ),
        "structured demo headings must be recognized",
    )


def test_upgrading_version_contract() -> None:
    manifest = repository_manifest()
    structured = """
## Current Version

- `setup_skill_version: {setup_skill_version}`
- `agents_version: {agents_version}`

## Next Section
""".format(
        setup_skill_version=manifest.setup_skill_version,
        agents_version=manifest.agents_version,
    )
    require(
        not VALIDATOR.upgrading_version_findings(
            structured, manifest, Path("UPGRADING.md")
        ),
        "structured current-version bullets must pass",
    )
    scattered = (
        "The text mentions setup_skill_version: {} and agents_version: {}, but has no current-version section.".format(
            manifest.setup_skill_version, manifest.agents_version
        )
    )
    require(
        "upgrading-current-version"
        in finding_codes(
            VALIDATOR.upgrading_version_findings(
                scattered, manifest, Path("UPGRADING.md")
            )
        ),
        "version strings scattered in prose must not satisfy current-version bullets",
    )


def test_deeply_nested_fallback_keeps_all_governing_ancestors() -> None:
    text = (
        "- When `plot/pacing.md` is missing:\n"
        "  - import stage:\n"
        "    - sixth stage:\n"
        "      - benchmark view:\n"
        "        - fall back to reading `teardown-report.md` to assemble the rhythm.\n"
    )
    found = VALIDATOR.semantic_primary_fallback_findings(
        text,
        Path("deeply-nested.md"),
        ("plot/pacing.md",),
    )
    require(
        "silent-primary-artifact-fallback" in finding_codes(found),
        "a missing condition in a deep list must reach the fallback action, not get lost after three levels",
    )


def test_old_artifact_prose_silent_only() -> None:
    """keep C: explicitly-marked old-format outline tolerance passes; unmarked
    silent downgrades are still blocked (drop A/B unaffected)."""
    rule = next(r for r in VALIDATOR.LEGACY_RULES if r.code == "old-artifact-prose")
    require(rule.exempt_when is not None, "old-artifact-prose must narrow to silent-only")
    flagged = [
        "Old chapter outline format missing these fields does not block reading; unknown items are written as `[TODO]`.",
        "Old chapter outline format falls back to reading core event, plot point sequence, and target emotion.",
        "Old volume outline format missing the volume contract/story-unit card does not block the daily update; this round is recorded in `tracking/context.md`.",
        "Old chapter outline format only checks core event, target emotion, opening/closing hooks, and target words.",
    ]
    silent = [
        "legacy teardown format used directly, without conversion.",
        "The old outline format is taken as authoritative without notice.",
        "legacy structure accepted silently, continues writing.",
    ]
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        skills = root / "skills" / "story-long-write"
        skills.mkdir(parents=True)
        (skills / "keep-c.md").write_text("\n".join(flagged) + "\n", encoding="utf-8")
        require(
            not VALIDATOR.check_absent_rule(root, rule),
            "flagged old-outline tolerance (keep C) must pass, got {}".format(
                VALIDATOR.check_absent_rule(root, rule)
            ),
        )
        (skills / "keep-c.md").write_text("\n".join(silent) + "\n", encoding="utf-8")
        found = VALIDATOR.check_absent_rule(root, rule)
        require(
            len(found) == len(silent),
            "each silent old-format downgrade must fire, got {}".format(found),
        )


def main() -> int:
    test_manifest_contract()
    test_bad_fallbacks_fail()
    test_fail_fast_prose_passes()
    test_sibling_bullets_do_not_lend_the_missing_condition()
    test_undecodable_markdown_is_a_named_failure()
    test_progress_schema_pins_are_repo_wide()
    test_deeply_nested_fallback_keeps_all_governing_ancestors()
    test_stale_scan_phase_reference_accepts_backticks()
    test_old_artifact_prose_silent_only()
    test_structured_sentinel_contract()
    test_structured_outline_contract()
    test_upgrading_version_contract()
    print("OK: current-contract manifest, structure, and fallback regressions passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
