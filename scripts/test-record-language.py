#!/usr/bin/env python3
"""Regression tests for the book record-language gate."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "skills/story-long-write/scripts/check-record-language.py"


class RecordLanguageTests(unittest.TestCase):
    def run_tool(self, project: Path, *extra: str, expect: int = 0) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [sys.executable, str(TOOL), "--project", str(project), *extra],
            text=True,
            capture_output=True,
            encoding="utf-8",
            check=False,
        )
        self.assertEqual(
            result.returncode,
            expect,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        return result

    def make_project(self, language: str) -> Path:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        project = Path(temporary.name) / "The Wrong Bride"
        project.mkdir()
        (project / "AGENTS.md").write_text(
            "# The Wrong Bride\n\n"
            f"- Prose language: en\n- Record language: {language}\n"
            "- English variant: en-US\n- Target platform: Wattpad\n"
            "- Protagonist: Claire Morgan\n",
            encoding="utf-8",
        )
        (project / "outline").mkdir()
        return project

    def test_chinese_records_allow_canonical_title_and_names(self) -> None:
        project = self.make_project("zh-CN")
        (project / "outline/outline_chapter_001.md").write_text(
            "# 第一章：The Wrong Bride\n"
            "- 核心事件：Claire Morgan 在 Wattpad 连载中进入婚姻危机。\n",
            encoding="utf-8",
        )

        self.run_tool(project)

    def test_chinese_records_reject_clear_english_block(self) -> None:
        project = self.make_project("zh-CN")
        (project / "outline/outline_chapter_001.md").write_text(
            "# Chapter One\n"
            "The heroine discovers the altered marriage contract.\n",
            encoding="utf-8",
        )

        result = self.run_tool(project, expect=2)

        self.assertIn("strong English record-language drift", result.stderr)
        self.assertIn("outline", result.stderr)

    def test_english_records_reject_clear_chinese_block(self) -> None:
        project = self.make_project("en")
        (project / "setting/characters.md").parent.mkdir()
        (project / "setting/characters.md").write_text(
            "## Character\n女主角必须夺回企业谈判主动权，并保留最终选择权。\n",
            encoding="utf-8",
        )

        result = self.run_tool(project, expect=2)

        self.assertIn("strong Chinese record-language drift", result.stderr)

    def test_missing_contract_is_a_hard_failure(self) -> None:
        project = self.make_project("zh-CN")
        (project / "AGENTS.md").unlink()

        result = self.run_tool(project, expect=2)

        self.assertIn("book language contract is required", result.stderr)


if __name__ == "__main__":
    unittest.main()
