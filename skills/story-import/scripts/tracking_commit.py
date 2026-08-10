#!/usr/bin/env python3
"""Maintain one structured story state and its deterministic Markdown views.

The language model supplies compact semantic JSON.  This tool validates and
merges that input in memory, renders every derived view, then atomically writes
``_tracking-state.json`` last as the single commit point.  One book project has
one serial writer; concurrent commits are intentionally unsupported.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import re
import stat
import sys
import tempfile
import unicodedata
from pathlib import Path
from typing import Any


INPUT_SCHEMA_VERSION = 1
TRACKING_SCHEMA_VERSION = 4
DELTA_TARGET_BYTES = 1536
DELTA_MAX_BYTES = 3072
CONTEXT_TARGET_BYTES = 8192
CONTEXT_MAX_BYTES = 12288
SNAPSHOT_TARGET_BYTES = 4096
SNAPSHOT_MAX_BYTES = 8192

CONTEXT_HEADINGS = (
    "## Current Position",
    "## Long-Term Constraints",
    "## Core Character States",
    "## Active Foreshadowing",
    "## Recent Chapters",
    "## Next-Chapter Commitments",
    "## Continuity Risks",
)
FORESHADOW_STATUSES = ("planted", "resolved", "expired", "abandoned")
FORESHADOW_IMPORTANCE = ("high", "medium", "low")
REVEAL_STATUSES = ("unrevealed", "partially_revealed", "revealed")
INVALID_FILE_CHARS = re.compile(r"[<>:\"/\\|?*\x00-\x1f]")
FORESHADOW_ID = re.compile(r"^F\d{3,}$")
EVENT_ID = re.compile(r"^E\d{3,}$")
WINDOWS_RESERVED_NAMES = {
    "CON",
    "PRN",
    "AUX",
    "NUL",
    *(f"COM{index}" for index in range(1, 10)),
    *(f"LPT{index}" for index in range(1, 10)),
}
RETIRED_TRACKING_PATHS = (
    "_tracking-meta.json",
    "stage-summary.md",
    "character-state.md",
    "timeline.md",
    "summaries",
    "timeline/event-library.json",
)
RETIRED_ARCHIVE_DIR = "_retired-tracking-archive"


class TrackingError(ValueError):
    """Expected validation or tracking-state error."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise TrackingError(message)


def as_mapping(value: object, label: str) -> dict[str, Any]:
    require(isinstance(value, dict), f"{label} must be a JSON object")
    return value


def as_list(value: object, label: str) -> list[Any]:
    require(isinstance(value, list), f"{label} must be a JSON array")
    return value


def as_int(value: object, label: str, *, minimum: int = 0) -> int:
    require(isinstance(value, int) and not isinstance(value, bool), f"{label} must be an integer")
    require(value >= minimum, f"{label} must be >= {minimum}")
    return value


def require_known_keys(mapping: dict[str, Any], allowed: set[str], label: str) -> None:
    unknown = set(mapping) - allowed
    require(not unknown, f"{label} contains unsupported fields: {', '.join(sorted(unknown))}")


def clean_text(value: object, label: str, *, allow_empty: bool = False, max_bytes: int = 768) -> str:
    require(isinstance(value, str), f"{label} must be a string")
    cleaned = " ".join(value.replace("|", "｜").split())
    require(allow_empty or bool(cleaned), f"{label} must not be empty")
    require(len(cleaned.encode("utf-8")) <= max_bytes, f"{label} exceeds {max_bytes} bytes")
    return cleaned


def clean_string_list(
    value: object,
    label: str,
    *,
    maximum: int | None = None,
    item_max_bytes: int = 384,
) -> list[str]:
    values = as_list(value, label)
    if maximum is not None:
        require(len(values) <= maximum, f"{label} may contain at most {maximum} items")
    return [clean_text(item, f"{label}[{index}]", max_bytes=item_max_bytes) for index, item in enumerate(values)]


def safe_file_component(value: object, label: str) -> str:
    name = unicodedata.normalize("NFC", clean_text(value, label, max_bytes=180))
    require(not INVALID_FILE_CHARS.search(name), f"{label} contains an invalid filename character")
    require(name not in {".", ".."} and not name.endswith((".", " ")), f"{label} is not a safe filename")
    require(name.split(".", 1)[0].upper() not in WINDOWS_RESERVED_NAMES, f"{label} is reserved on Windows")
    return name


def portable_name_key(name: str) -> str:
    return unicodedata.normalize("NFC", name).casefold()


def byte_size(text: str) -> int:
    return len(text.encode("utf-8"))


def emit(text: str, *, error: bool = False) -> None:
    """Write UTF-8 bytes directly so CLI output is stable across platforms."""
    stream = sys.stderr if error else sys.stdout
    stream.flush()
    stream.buffer.write((text + "\n").encode("utf-8"))
    stream.buffer.flush()


def read_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise TrackingError(f"unable to read JSON {path}: {exc}") from exc


def json_payload(document: object) -> str:
    return json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def atomic_write_text(path: Path, payload: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def write_if_changed(path: Path, payload: str) -> None:
    try:
        if path.read_text(encoding="utf-8") == payload:
            return
    except FileNotFoundError:
        pass
    atomic_write_text(path, payload)


def tracking_root(project: Path) -> Path:
    return project.resolve() / "tracking"


def record_language(project: Path) -> str:
    """Resolve the output language from the book contract.

    New books must have an explicit book-level language contract.  Falling
    back to English is unsafe: it makes a missing contract look like a valid
    English choice and can contaminate a Chinese-record project before the
    contract is noticed.
    """
    profile = project.resolve() / "AGENTS.md"
    if not profile.exists():
        raise TrackingError(
            f"book language contract is required before tracking initialization: {profile}"
        )
    try:
        text = profile.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise TrackingError(f"unable to read book language contract {profile}: {exc}") from exc
    match = re.search(r"(?im)^\s*(?:[-*]\s*)?Record language\s*:\s*([A-Za-z0-9_-]+)\s*$", text)
    require(match is not None, "book AGENTS.md is missing a complete Record language field")
    value = match.group(1).lower()
    if value in {"zh", "zh-cn", "zh-hans"}:
        return "zh-CN"
    if value in {"en", "en-us", "en-gb", "en-au", "en-ca"}:
        return "en"
    raise TrackingError(f"unsupported Record language in book AGENTS.md: {match.group(1)}")


def labels_for(language: str) -> dict[str, Any]:
    if language == "zh-CN":
        return {
            "context_title": "写作连续性上下文",
            "context_note": "状态修订号：{revision}。仅保留下一章所需的连续性状态。",
            "context_headings": (
                "## 当前状态",
                "## 长期约束",
                "## 核心角色状态",
                "## 活跃伏笔",
                "## 最近章节",
                "## 下一章承诺",
                "## 连续性风险",
            ),
            "current_chapter": "当前章节：{value}",
            "volume": "分卷：{value}（从第{chapter}章开始）",
            "story_time": "故事时间：{value}",
            "scene": "场景：{value}",
            "goal": "目标：{value}",
            "not_started": "未开始",
            "chapter": "第{number}章",
            "none": "无",
            "snapshot_title": "{name} | 当前状态",
            "state_revision": "状态修订号：{value}",
            "through_chapter": "截至章节：{value}",
            "identity": "身份：{value}",
            "location": "地点：{value}",
            "current_goal": "当前目标：{value}",
            "state": "状态：{value}",
            "abilities": "能力与资源",
            "relationships": "关键关系",
            "knowledge": "已知信息",
            "open_threads": "待解线索",
            "foreshadow_title": "当前伏笔状态",
            "foreshadow_note": "状态修订号：{revision}。每个编号只保留一行当前状态；历史记录位于 `chapter-records/`。",
            "foreshadow_headers": "| 编号 | 摘要 | 埋设章节 | 计划回收 | 状态 | 重要性 | 最后更新 |",
            "timeline_author_title": "作者真相时间线",
            "timeline_author_note": "状态修订号：{revision}。记录权威事实与读者已知信息的差异。",
            "timeline_author_headers": "| 编号 | 首次记录章节 | 故事时间 | 客观事实 | 读者信息 | 揭示状态 | 揭示章节 |",
            "timeline_reader_title": "读者认知时间线",
            "timeline_reader_note": "状态修订号：{revision}。只记录读者目前知道或相信的内容。",
            "timeline_reader_headers": "| 编号 | 读者信息 | 已知截至章节 |",
            "planted_chapter": "已埋设于第{number}章",
            "resolution_tbd": "待定",
            "characters": "角色",
            "chapter_record_title": "第{number:03d}章 | {title}",
            "result": "结果",
            "next_commitments": "下一章承诺",
            "character_changes": "角色变化",
            "foreshadow_changes": "伏笔变化",
            "timeline_reveals": "时间线与揭示",
            "continuity_constraints": "连续性约束",
            "retired_entries": "本章停用条目",
            "core": "核心",
            "temporary": "临时",
            "deleted": "已删除当前条目",
            "resolution": "回收",
            "fact": "事实",
            "reader": "读者",
            "status": {"planted": "已埋设", "resolved": "已回收", "expired": "已过期", "abandoned": "已放弃"},
            "importance": {"high": "高", "medium": "中", "low": "低"},
            "reveal_status": {"unrevealed": "未揭示", "partially_revealed": "部分揭示", "revealed": "已揭示"},
        }
    return {
        "context_title": "Writing Continuity Context",
        "context_note": "State revision: {revision}. Only continuity state needed for the next chapter.",
        "context_headings": CONTEXT_HEADINGS,
        "current_chapter": "Current chapter: {value}",
        "volume": "Volume: {value} (starts at Chapter {chapter})",
        "story_time": "Story time: {value}",
        "scene": "Scene: {value}",
        "goal": "Goal: {value}",
        "not_started": "Not started",
        "chapter": "Chapter {number}",
        "none": "None",
        "snapshot_title": "{name} | Current State",
        "state_revision": "State revision: {value}",
        "through_chapter": "Through chapter: {value}",
        "identity": "Identity: {value}",
        "location": "Location: {value}",
        "current_goal": "Current goal: {value}",
        "state": "State: {value}",
        "abilities": "Abilities and Resources",
        "relationships": "Key Relationships",
        "knowledge": "Known Information",
        "open_threads": "Open Threads",
        "foreshadow_title": "Current Foreshadowing State",
        "foreshadow_note": "State revision: {revision}. One current row per ID; history is in `chapter-records/`.",
        "foreshadow_headers": "| ID | Summary | Planted Chapter | Planned Resolution | Status | Importance | Last Updated |",
        "timeline_author_title": "Author-Truth Timeline",
        "timeline_author_note": "State revision: {revision}. Authoritative facts versus reader knowledge.",
        "timeline_author_headers": "| ID | First Recorded Chapter | Story Time | Objective Fact | Reader Knowledge | Reveal Status | Reveal Chapter |",
        "timeline_reader_title": "Reader-Knowledge Timeline",
        "timeline_reader_note": "State revision: {revision}. Shows only what the reader knows or believes so far.",
        "timeline_reader_headers": "| ID | Reader Knowledge | Known Through Chapter |",
        "planted_chapter": "planted Chapter {number}",
        "resolution_tbd": "Resolution TBD",
        "characters": "characters",
        "chapter_record_title": "Chapter {number:03d} | {title}",
        "result": "Result",
        "next_commitments": "Next-chapter commitments",
        "character_changes": "Character Changes",
        "foreshadow_changes": "Foreshadowing Changes",
        "timeline_reveals": "Timeline and Reveals",
        "continuity_constraints": "Continuity Constraints",
        "retired_entries": "Retired Entries This Chapter",
        "core": "Core",
        "temporary": "Temporary",
        "deleted": "Deleted current entry",
        "resolution": "resolution",
        "fact": "Fact",
        "reader": "Reader",
        "status": {"planted": "planted", "resolved": "resolved", "expired": "expired", "abandoned": "abandoned"},
        "importance": {"high": "high", "medium": "medium", "low": "low"},
        "reveal_status": {"unrevealed": "unrevealed", "partially_revealed": "partially_revealed", "revealed": "revealed"},
    }


def state_path(project: Path) -> Path:
    return tracking_root(project) / "_tracking-state.json"


def delta_path(tracking: Path, chapter: int) -> Path:
    width = max(3, len(str(chapter)))
    return tracking / "chapter-records" / f"chapter_{chapter:0{width}d}.md"


def find_retired_tracking_paths(tracking: Path) -> list[str]:
    found = [relative for relative in RETIRED_TRACKING_PATHS if (tracking / relative).exists()]
    found.extend(sorted(path.name for path in tracking.glob("baseline_through_chapter_*.md")))
    return found


def require_no_retired_tracking_paths(tracking: Path) -> None:
    found = find_retired_tracking_paths(tracking)
    require(not found, f"retired tracking files are not supported: {', '.join(found)}")


def archive_retired_tracking_paths(tracking: Path) -> list[str]:
    """Move a pre-transaction tracking/ aside so init can build the current protocol in place.

    Nothing is parsed or converted: the old files are kept verbatim for the author to
    consult, and the new state is reconstructed from the init document alone.
    """
    retired = find_retired_tracking_paths(tracking)
    if not retired:
        return []
    archive = tracking / RETIRED_ARCHIVE_DIR
    for relative in retired:
        require(
            not (archive / relative).exists(),
            f"tracking/{RETIRED_ARCHIVE_DIR}/{relative} already exists; move it away before initializing",
        )
    # 先全量校验再搬运；中断后重跑时已搬走的条目不再出现在待搬列表里，可直接续做。
    for relative in retired:
        target = archive / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        os.replace(tracking / relative, target)
    return retired


def validate_position(value: object, label: str = "context.position") -> dict[str, Any]:
    position = as_mapping(value, label)
    require_known_keys(position, {"volume", "volume_start_chapter", "story_time", "scene"}, label)
    return {
        "volume": safe_file_component(position.get("volume"), f"{label}.volume"),
        "volume_start_chapter": as_int(
            position.get("volume_start_chapter"), f"{label}.volume_start_chapter", minimum=1
        ),
        "story_time": clean_text(position.get("story_time"), f"{label}.story_time", max_bytes=240),
        "scene": clean_text(position.get("scene"), f"{label}.scene", max_bytes=240),
    }


def normalize_snapshot(value: object, label: str) -> dict[str, Any]:
    snapshot = as_mapping(value, label)
    require_known_keys(
        snapshot,
        {"identity", "location", "goal", "state", "abilities_resources", "relationships", "knowledge", "open_threads"},
        label,
    )
    return {
        "identity": clean_text(snapshot.get("identity"), f"{label}.identity", max_bytes=240),
        "location": clean_text(snapshot.get("location"), f"{label}.location", max_bytes=240),
        "goal": clean_text(snapshot.get("goal"), f"{label}.goal", max_bytes=300),
        "state": clean_text(snapshot.get("state"), f"{label}.state", max_bytes=300),
        "abilities_resources": clean_string_list(
            snapshot.get("abilities_resources", []), f"{label}.abilities_resources"
        ),
        "relationships": clean_string_list(snapshot.get("relationships", []), f"{label}.relationships"),
        "knowledge": clean_string_list(snapshot.get("knowledge", []), f"{label}.knowledge"),
        "open_threads": clean_string_list(snapshot.get("open_threads", []), f"{label}.open_threads"),
    }


def normalize_snapshots(value: object, label: str = "character_snapshots") -> dict[str, dict[str, Any]]:
    snapshots = as_mapping(value, label)
    normalized: dict[str, dict[str, Any]] = {}
    portable_names: set[str] = set()
    for raw_name, raw_snapshot in snapshots.items():
        name = safe_file_component(raw_name, f"{label} character name")
        key = portable_name_key(name)
        require(key not in portable_names, f"{label} contains a cross-platform duplicate character {name}")
        portable_names.add(key)
        normalized[name] = normalize_snapshot(raw_snapshot, f"{label}.{name}")
    return normalized


def render_snapshot(
    name: str, snapshot: dict[str, Any], through_chapter: int, revision: int, labels: dict[str, Any]
) -> str:
    def section(title: str, values: list[str]) -> list[str]:
        return [f"## {title}", *(f"- {item}" for item in values or [labels["none"]]), ""]

    lines = [
        f"# {labels['snapshot_title'].format(name=name)}",
        "",
        f"- {labels['state_revision'].format(value=revision)}",
        f"- {labels['through_chapter'].format(value=through_chapter)}",
        f"- {labels['identity'].format(value=snapshot['identity'])}",
        f"- {labels['location'].format(value=snapshot['location'])}",
        f"- {labels['current_goal'].format(value=snapshot['goal'])}",
        f"- {labels['state'].format(value=snapshot['state'])}",
        "",
    ]
    lines.extend(section(labels["abilities"], snapshot["abilities_resources"]))
    lines.extend(section(labels["relationships"], snapshot["relationships"]))
    lines.extend(section(labels["knowledge"], snapshot["knowledge"]))
    lines.extend(section(labels["open_threads"], snapshot["open_threads"]))
    payload = "\n".join(lines).rstrip() + "\n"
    require(
        byte_size(payload) <= SNAPSHOT_MAX_BYTES,
        f"character snapshot {name} exceeds hard cap of {SNAPSHOT_MAX_BYTES} bytes",
    )
    return payload


def normalize_foreshadow_change(
    value: object,
    label: str,
    *,
    allow_delete: bool,
    through_chapter: int,
) -> dict[str, Any]:
    row = as_mapping(value, label)
    require_known_keys(
        row,
        {"action", "id", "summary", "planted_chapter", "planned_resolution_chapter", "status", "importance"},
        label,
    )
    action = clean_text(row.get("action", "upsert"), f"{label}.action", max_bytes=24)
    require(action in ({"upsert", "delete"} if allow_delete else {"upsert"}), f"{label}.action is invalid")
    identifier = clean_text(row.get("id"), f"{label}.id", max_bytes=24)
    require(FORESHADOW_ID.fullmatch(identifier) is not None, f"{label}.id must look like F001")
    if action == "delete":
        return {"action": action, "id": identifier}
    planted_chapter = as_int(row.get("planted_chapter"), f"{label}.planted_chapter", minimum=1)
    require(planted_chapter <= through_chapter, f"{label}.planted_chapter cannot be in the future")
    planned_raw = row.get("planned_resolution_chapter")
    planned_chapter = (
        None if planned_raw is None else as_int(planned_raw, f"{label}.planned_resolution_chapter", minimum=1)
    )
    require(
        planned_chapter is None or planned_chapter >= planted_chapter,
        f"{label}.planned_resolution_chapter cannot precede planted_chapter",
    )
    status = clean_text(row.get("status"), f"{label}.status", max_bytes=24)
    importance = clean_text(row.get("importance"), f"{label}.importance", max_bytes=12)
    require(status in FORESHADOW_STATUSES, f"{label}.status must be one of {FORESHADOW_STATUSES}")
    require(importance in FORESHADOW_IMPORTANCE, f"{label}.importance must be one of {FORESHADOW_IMPORTANCE}")
    return {
        "action": action,
        "id": identifier,
        "summary": clean_text(row.get("summary"), f"{label}.summary", max_bytes=360),
        "planted_chapter": planted_chapter,
        "planned_resolution_chapter": planned_chapter,
        "status": status,
        "importance": importance,
    }


def normalize_foreshadow_state(value: object, last_chapter: int) -> dict[str, dict[str, Any]]:
    rows = as_mapping(value, "tracking state.foreshadow")
    normalized: dict[str, dict[str, Any]] = {}
    for raw_identifier, raw_row in rows.items():
        identifier = clean_text(raw_identifier, "tracking state.foreshadow ID", max_bytes=24)
        row = as_mapping(raw_row, f"tracking state.foreshadow.{identifier}")
        require_known_keys(
            row,
            {"id", "summary", "planted_chapter", "planned_resolution_chapter", "status", "importance", "updated_chapter"},
            f"tracking state.foreshadow.{identifier}",
        )
        require(row.get("id") == identifier, f"tracking state.foreshadow.{identifier}.id does not match its key")
        change = normalize_foreshadow_change(
            {
                "action": "upsert",
                **{key: value for key, value in row.items() if key != "updated_chapter"},
            },
            f"tracking state.foreshadow.{identifier}",
            allow_delete=False,
            through_chapter=last_chapter,
        )
        change.pop("action")
        updated = as_int(row.get("updated_chapter"), f"tracking state.foreshadow.{identifier}.updated_chapter", minimum=1)
        require(updated <= last_chapter, f"foreshadow {identifier} updates after current chapter")
        change["updated_chapter"] = updated
        normalized[identifier] = change
    return normalized


def render_foreshadow(rows: dict[str, dict[str, Any]], revision: int, labels: dict[str, Any]) -> str:
    lines = [
        f"# {labels['foreshadow_title']}",
        "",
        f"> {labels['foreshadow_note'].format(revision=revision)}",
        "",
        labels["foreshadow_headers"],
        "|---|---|---:|---:|---|---|---:|",
    ]
    for identifier in sorted(rows):
        row = rows[identifier]
        planned = labels["chapter"].format(number=row["planned_resolution_chapter"]) if row["planned_resolution_chapter"] else "—"
        lines.append(
            f"| {identifier} | {row['summary']} | {labels['chapter'].format(number=row['planted_chapter'])} | {planned} | "
            f"{labels['status'][row['status']]} | {labels['importance'][row['importance']]} | "
            f"{labels['chapter'].format(number=row['updated_chapter'])} |"
        )
    return "\n".join(lines) + "\n"


def normalize_timeline_change(
    value: object,
    label: str,
    *,
    allow_delete: bool,
    through_chapter: int,
) -> dict[str, Any]:
    event = as_mapping(value, label)
    require_known_keys(
        event,
        {"action", "id", "story_time", "objective_fact", "reader_knowledge", "reveal_status", "reveal_chapter", "characters"},
        label,
    )
    action = clean_text(event.get("action", "upsert"), f"{label}.action", max_bytes=24)
    require(action in ({"upsert", "delete"} if allow_delete else {"upsert"}), f"{label}.action is invalid")
    identifier = clean_text(event.get("id"), f"{label}.id", max_bytes=24)
    require(EVENT_ID.fullmatch(identifier) is not None, f"{label}.id must look like E001")
    if action == "delete":
        return {"action": action, "id": identifier}
    reveal_status = clean_text(event.get("reveal_status"), f"{label}.reveal_status", max_bytes=24)
    require(reveal_status in REVEAL_STATUSES, f"{label}.reveal_status must be one of {REVEAL_STATUSES}")
    reveal_raw = event.get("reveal_chapter")
    reveal_chapter = None if reveal_raw is None else as_int(reveal_raw, f"{label}.reveal_chapter", minimum=1)
    if reveal_status == "unrevealed":
        require(reveal_chapter is None, f"{label} must not put a future reveal chapter in established timeline facts")
    else:
        require(reveal_chapter is not None, f"{label}.reveal_chapter is required once revealed")
        require(reveal_chapter <= through_chapter, f"{label}.reveal_chapter cannot be in the future")
    return {
        "action": action,
        "id": identifier,
        "story_time": clean_text(event.get("story_time"), f"{label}.story_time", max_bytes=240),
        "objective_fact": clean_text(event.get("objective_fact"), f"{label}.objective_fact", max_bytes=480),
        "reader_knowledge": clean_text(event.get("reader_knowledge"), f"{label}.reader_knowledge", max_bytes=480),
        "reveal_status": reveal_status,
        "reveal_chapter": reveal_chapter,
        "characters": clean_string_list(event.get("characters", []), f"{label}.characters", maximum=12, item_max_bytes=120),
    }


def normalize_timeline_state(value: object, last_chapter: int) -> dict[str, dict[str, Any]]:
    events = as_mapping(value, "tracking state.timeline")
    normalized: dict[str, dict[str, Any]] = {}
    for raw_identifier, raw_event in events.items():
        identifier = clean_text(raw_identifier, "tracking state.timeline ID", max_bytes=24)
        event = as_mapping(raw_event, f"tracking state.timeline.{identifier}")
        require_known_keys(
            event,
            {
                "id", "story_time", "objective_fact", "reader_knowledge", "reveal_status", "reveal_chapter",
                "characters", "first_recorded_chapter", "updated_chapter",
            },
            f"tracking state.timeline.{identifier}",
        )
        require(event.get("id") == identifier, f"tracking state.timeline.{identifier}.id does not match its key")
        change = normalize_timeline_change(
            {
                "action": "upsert",
                **{
                    key: value
                    for key, value in event.items()
                    if key not in {"first_recorded_chapter", "updated_chapter"}
                },
            },
            f"tracking state.timeline.{identifier}",
            allow_delete=False,
            through_chapter=last_chapter,
        )
        change.pop("action")
        first = as_int(event.get("first_recorded_chapter"), f"tracking state.timeline.{identifier}.first_recorded_chapter", minimum=1)
        updated = as_int(event.get("updated_chapter"), f"tracking state.timeline.{identifier}.updated_chapter", minimum=1)
        require(first <= last_chapter, f"timeline event {identifier} starts after current chapter")
        require(updated <= last_chapter, f"timeline event {identifier} updates after current chapter")
        change["first_recorded_chapter"] = first
        change["updated_chapter"] = updated
        normalized[identifier] = change
    return normalized


def render_timeline_views(
    events: dict[str, dict[str, Any]], revision: int, labels: dict[str, Any]
) -> tuple[str, str]:
    author_lines = [
        f"# {labels['timeline_author_title']}",
        "",
        f"> {labels['timeline_author_note'].format(revision=revision)}",
        "",
        labels["timeline_author_headers"],
        "|---|---:|---|---|---|---|---:|",
    ]
    reader_lines = [
        f"# {labels['timeline_reader_title']}",
        "",
        f"> {labels['timeline_reader_note'].format(revision=revision)}",
        "",
        labels["timeline_reader_headers"],
        "|---|---|---:|",
    ]
    for identifier in sorted(events):
        event = events[identifier]
        reveal = labels["chapter"].format(number=event["reveal_chapter"]) if event.get("reveal_chapter") else "—"
        characters = ", ".join(event.get("characters", []))
        objective = event["objective_fact"] + (f" ({labels['characters']}: {characters})" if characters else "")
        author_lines.append(
            f"| {identifier} | {labels['chapter'].format(number=event['first_recorded_chapter'])} | {event['story_time']} | {objective} | "
            f"{event['reader_knowledge']} | {labels['reveal_status'][event['reveal_status']]} | {reveal} |"
        )
        reader_lines.append(
            f"| {identifier} | {event['reader_knowledge']} | {labels['chapter'].format(number=event['updated_chapter'])} |"
        )
    return "\n".join(author_lines) + "\n", "\n".join(reader_lines) + "\n"


def validate_context_input(value: object, *, include_initial_fields: bool) -> dict[str, Any]:
    context = as_mapping(value, "context")
    allowed = {"position", "long_term_constraints", "active_character_names", "continuity_risks"}
    if include_initial_fields:
        allowed.update({"recent_chapters", "next_chapter_commitments"})
    require_known_keys(context, allowed, "context")
    normalized: dict[str, Any] = {
        "position": validate_position(context.get("position")),
        "long_term_constraints": clean_string_list(
            context.get("long_term_constraints", []), "context.long_term_constraints", maximum=6
        ),
        "active_character_names": [
            safe_file_component(name, f"context.active_character_names[{index}]")
            for index, name in enumerate(as_list(context.get("active_character_names", []), "context.active_character_names"))
        ],
        "continuity_risks": clean_string_list(
            context.get("continuity_risks", []), "context.continuity_risks", maximum=5
        ),
    }
    require(len(normalized["active_character_names"]) <= 6, "context.active_character_names may contain at most 6 names")
    require(
        len({portable_name_key(name) for name in normalized["active_character_names"]})
        == len(normalized["active_character_names"]),
        "context.active_character_names contains cross-platform duplicates",
    )
    if include_initial_fields:
        recent: list[dict[str, Any]] = []
        for index, raw_item in enumerate(as_list(context.get("recent_chapters", []), "context.recent_chapters")):
            item = as_mapping(raw_item, f"context.recent_chapters[{index}]")
            require_known_keys(item, {"chapter", "summary"}, f"context.recent_chapters[{index}]")
            recent.append(
                {
                    "chapter": as_int(item.get("chapter"), f"context.recent_chapters[{index}].chapter", minimum=1),
                    "summary": clean_text(item.get("summary"), f"context.recent_chapters[{index}].summary", max_bytes=360),
                }
            )
        require(len(recent) <= 3, "context.recent_chapters may contain at most 3 items")
        normalized["recent_chapters"] = recent
        normalized["next_chapter_commitments"] = clean_string_list(
            context.get("next_chapter_commitments", []), "context.next_chapter_commitments", maximum=5
        )
    return normalized


def active_foreshadow_lines(rows: dict[str, dict[str, Any]], labels: dict[str, Any]) -> list[str]:
    importance = {value: index for index, value in enumerate(FORESHADOW_IMPORTANCE)}
    candidates = [row for row in rows.values() if row["status"] == "planted"]
    candidates.sort(
        key=lambda row: (importance[row["importance"]], row["planned_resolution_chapter"] or 10**12, row["id"])
    )
    result = []
    for row in candidates[:8]:
        planned = (
            labels["chapter"].format(number=row["planned_resolution_chapter"])
            if row["planned_resolution_chapter"]
            else labels["resolution_tbd"]
        )
        result.append(
            f"{row['id']} | {row['summary']} | {labels['planted_chapter'].format(number=row['planted_chapter'])} | "
            f"{planned} | {labels['importance'][row['importance']]}"
        )
    return result


def render_context(state: dict[str, Any], labels: dict[str, Any]) -> str:
    context = state["context"]
    position = context["position"]
    current_chapter = (
        labels["not_started"]
        if state["last_committed_chapter"] == 0
        else labels["chapter"].format(number=state["last_committed_chapter"])
    )
    character_lines = [
        f"{name} | {state['characters'][name]['identity']} | {state['characters'][name]['state']} | "
        f"{labels['goal'].format(value=state['characters'][name]['goal'])}"
        for name in context["active_character_names"]
    ]
    sections: list[tuple[str, list[str]]] = [
        (
            labels["context_headings"][0],
            [
                labels["current_chapter"].format(value=current_chapter),
                labels["volume"].format(
                    value=position["volume"], chapter=position["volume_start_chapter"]
                ),
                labels["story_time"].format(value=position["story_time"]),
                labels["scene"].format(value=position["scene"]),
            ],
        ),
        (labels["context_headings"][1], context["long_term_constraints"]),
        (labels["context_headings"][2], character_lines),
        (labels["context_headings"][3], active_foreshadow_lines(state["foreshadow"], labels)),
        (
            labels["context_headings"][4],
            [
                f"{labels['chapter'].format(number=item['chapter'])} | {item['summary']}"
                for item in context["recent_chapters"]
            ],
        ),
        (labels["context_headings"][5], context["next_chapter_commitments"]),
        (labels["context_headings"][6], context["continuity_risks"]),
    ]
    lines = [
        f"# {labels['context_title']} | {state['book_title']}",
        "",
        f"> {labels['context_note'].format(revision=state['state_revision'])}",
        "",
    ]
    for heading, values in sections:
        lines.append(heading)
        lines.extend(f"- {value}" for value in values or [labels["none"]])
        lines.append("")
    payload = "\n".join(lines).rstrip() + "\n"
    headings = tuple(line for line in payload.splitlines() if line.startswith("## "))
    require(headings == labels["context_headings"], "generated context headings do not match the seven-section schema")
    require(byte_size(payload) <= CONTEXT_MAX_BYTES, f"hot context exceeds {CONTEXT_MAX_BYTES} bytes")
    return payload


def normalize_delta(
    value: object,
    *,
    through_chapter: int,
    snapshots: dict[str, dict[str, Any]],
    existing_core_names: dict[str, str],
) -> dict[str, Any]:
    delta = as_mapping(value, "delta")
    require_known_keys(
        delta,
        {
            "result", "character_changes", "foreshadow_changes", "timeline_events", "constraints",
            "next_chapter_commitments", "retired_context_items", "retired_characters",
        },
        "delta",
    )
    retired_characters = [
        safe_file_component(name, f"delta.retired_characters[{index}]")
        for index, name in enumerate(as_list(delta.get("retired_characters", []), "delta.retired_characters"))
    ]
    retired_keys = [portable_name_key(name) for name in retired_characters]
    require(len(retired_keys) == len(set(retired_keys)), "delta.retired_characters contains duplicate characters")
    retiring = set(retired_keys)
    character_changes: list[dict[str, Any]] = []
    for index, raw_change in enumerate(as_list(delta.get("character_changes", []), "delta.character_changes")):
        change = as_mapping(raw_change, f"delta.character_changes[{index}]")
        require_known_keys(change, {"name", "change"}, f"delta.character_changes[{index}]")
        name = safe_file_component(change.get("name"), f"delta.character_changes[{index}].name")
        existing = existing_core_names.get(portable_name_key(name))
        is_core = name in snapshots or existing is not None
        # 本章退役的角色记录最后一次变化即可，不必再交一份马上要删的快照。
        require(
            not is_core or name in snapshots or portable_name_key(name) in retiring,
            f"core character {name} changed but has no current snapshot",
        )
        character_changes.append(
            {"name": name, "change": clean_text(change.get("change"), f"delta.character_changes[{index}].change", max_bytes=360)}
        )
    character_keys = [portable_name_key(item["name"]) for item in character_changes]
    require(len(character_keys) == len(set(character_keys)), "delta.character_changes contains duplicate characters")
    foreshadow_changes = [
        normalize_foreshadow_change(
            raw, f"delta.foreshadow_changes[{index}]", allow_delete=True, through_chapter=through_chapter
        )
        for index, raw in enumerate(as_list(delta.get("foreshadow_changes", []), "delta.foreshadow_changes"))
    ]
    timeline_events = [
        normalize_timeline_change(
            raw, f"delta.timeline_events[{index}]", allow_delete=True, through_chapter=through_chapter
        )
        for index, raw in enumerate(as_list(delta.get("timeline_events", []), "delta.timeline_events"))
    ]
    require(
        len({item["id"] for item in foreshadow_changes}) == len(foreshadow_changes),
        "delta.foreshadow_changes contains duplicate IDs",
    )
    require(
        len({item["id"] for item in timeline_events}) == len(timeline_events),
        "delta.timeline_events contains duplicate IDs",
    )
    require(
        set(snapshots).issubset({item["name"] for item in character_changes}),
        "character_snapshots must contain exactly the core characters changed by this transaction",
    )
    return {
        "result": clean_text(delta.get("result"), "delta.result", max_bytes=480),
        "character_changes": character_changes,
        "foreshadow_changes": foreshadow_changes,
        "timeline_events": timeline_events,
        "constraints": clean_string_list(delta.get("constraints", []), "delta.constraints", maximum=6),
        "next_chapter_commitments": clean_string_list(
            delta.get("next_chapter_commitments", []), "delta.next_chapter_commitments", maximum=5
        ),
        "retired_context_items": clean_string_list(
            delta.get("retired_context_items", []), "delta.retired_context_items", maximum=11
        ),
        "retired_characters": retired_characters,
    }


def render_delta(
    chapter: int, title: str, delta: dict[str, Any], core_names: set[str], labels: dict[str, Any]
) -> str:
    lines = [
        f"# {labels['chapter_record_title'].format(number=chapter, title=title)}",
        f"- {labels['result']}: {delta['result']}",
        f"- {labels['next_commitments']}: " + ("; ".join(delta["next_chapter_commitments"]) or labels["none"]),
        "",
        f"## {labels['character_changes']}",
    ]
    lines.extend(
        f"- {item['name']} | {labels['core'] if item['name'] in core_names else labels['temporary']} | {item['change']}"
        for item in delta["character_changes"]
    )
    if not delta["character_changes"]:
        lines.append(f"- {labels['none']}")
    lines.extend(["", f"## {labels['foreshadow_changes']}"])
    for item in delta["foreshadow_changes"]:
        if item["action"] == "delete":
            lines.append(f"- {item['id']} | {labels['deleted']}")
        else:
            planned = (
                labels["chapter"].format(number=item["planned_resolution_chapter"])
                if item["planned_resolution_chapter"]
                else labels["resolution_tbd"]
            )
            lines.append(
                f"- {item['id']} | {labels['status'][item['status']]} | {item['summary']} | "
                f"{labels['resolution']} {planned}"
            )
    if not delta["foreshadow_changes"]:
        lines.append(f"- {labels['none']}")
    lines.extend(["", f"## {labels['timeline_reveals']}"])
    for item in delta["timeline_events"]:
        if item["action"] == "delete":
            lines.append(f"- {item['id']} | {labels['deleted']}")
        else:
            lines.append(
                f"- {item['id']} | {item['story_time']} | {labels['fact']}：{item['objective_fact']} | "
                f"{labels['reader']}：{item['reader_knowledge']} | {labels['reveal_status'][item['reveal_status']]}"
            )
    if not delta["timeline_events"]:
        lines.append(f"- {labels['none']}")
    lines.extend(["", f"## {labels['continuity_constraints']}"])
    lines.extend(f"- {item}" for item in delta["constraints"])
    if not delta["constraints"]:
        lines.append(f"- {labels['none']}")
    retired = delta.get("retired_context_items", []) + [
        f"Character state: {name}" for name in delta.get("retired_characters", [])
    ]
    if retired:
        # Retired entries remain here so compacted context can still be audited.
        lines.extend(["", f"## {labels['retired_entries']}"])
        lines.extend(f"- {item}" for item in retired)
    payload = "\n".join(lines) + "\n"
    size = byte_size(payload)
    require(size <= DELTA_MAX_BYTES, f"chapter delta is {size} bytes; hard cap is {DELTA_MAX_BYTES}")
    return payload


def normalize_state(document: object) -> dict[str, Any]:
    root = as_mapping(document, "tracking state")
    require_known_keys(
        root,
        {
            "schema_version", "book_title", "last_committed_chapter", "imported_through_chapter",
            "state_revision", "context", "characters", "foreshadow", "timeline",
        },
        "tracking state",
    )
    require(root.get("schema_version") == TRACKING_SCHEMA_VERSION, "tracking state schema is unsupported")
    last_chapter = as_int(root.get("last_committed_chapter"), "tracking state.last_committed_chapter")
    imported_through = as_int(root.get("imported_through_chapter"), "tracking state.imported_through_chapter")
    require(imported_through <= last_chapter, "imported chapter cutoff exceeds current chapter")
    context = validate_context_input(root.get("context"), include_initial_fields=True)
    require(
        context["position"]["volume_start_chapter"] <= max(1, last_chapter),
        "context.position.volume_start_chapter is after the current writing position",
    )
    recent_numbers = [item["chapter"] for item in context["recent_chapters"]]
    require(recent_numbers == sorted(recent_numbers), "context.recent_chapters must be ordered")
    require(len(recent_numbers) == len(set(recent_numbers)), "context.recent_chapters contains duplicates")
    require(all(chapter <= last_chapter for chapter in recent_numbers), "context.recent_chapters cannot include future chapters")
    characters = normalize_snapshots(root.get("characters", {}), "tracking state.characters")
    for name in context["active_character_names"]:
        require(name in characters, f"active core character {name} has no current snapshot")
    foreshadow = normalize_foreshadow_state(root.get("foreshadow", {}), last_chapter)
    timeline = normalize_timeline_state(root.get("timeline", {}), last_chapter)
    if last_chapter == 0:
        require(not foreshadow, "a chapter-0 project cannot have planted foreshadow facts")
        require(not timeline, "a chapter-0 project cannot have established timeline facts")
    return {
        "schema_version": TRACKING_SCHEMA_VERSION,
        "book_title": clean_text(root.get("book_title"), "tracking state.book_title", max_bytes=240),
        "last_committed_chapter": last_chapter,
        "imported_through_chapter": imported_through,
        "state_revision": as_int(root.get("state_revision"), "tracking state.state_revision"),
        "context": context,
        "characters": characters,
        "foreshadow": foreshadow,
        "timeline": timeline,
    }


def load_state(project: Path) -> dict[str, Any]:
    path = state_path(project)
    require(path.exists(), "tracking state is missing; run init first")
    return normalize_state(read_json(path))


def normalize_initial_document(document: object) -> dict[str, Any]:
    root = as_mapping(document, "init input")
    require_known_keys(
        root,
        {"schema_version", "book_title", "last_chapter", "context", "character_snapshots", "foreshadow", "timeline_events"},
        "init input",
    )
    require(root.get("schema_version") == INPUT_SCHEMA_VERSION, "init input schema_version is unsupported")
    last_chapter = as_int(root.get("last_chapter"), "last_chapter")
    context = validate_context_input(root.get("context"), include_initial_fields=True)
    snapshots = normalize_snapshots(root.get("character_snapshots", {}))
    foreshadow: dict[str, dict[str, Any]] = {}
    for index, raw_row in enumerate(as_list(root.get("foreshadow", []), "foreshadow")):
        row = normalize_foreshadow_change(
            raw_row, f"foreshadow[{index}]", allow_delete=False, through_chapter=last_chapter
        )
        require(row["id"] not in foreshadow, f"duplicate foreshadow ID {row['id']}")
        row.pop("action")
        row["updated_chapter"] = max(1, last_chapter)
        foreshadow[row["id"]] = row
    timeline: dict[str, dict[str, Any]] = {}
    for index, raw_event in enumerate(as_list(root.get("timeline_events", []), "timeline_events")):
        event = normalize_timeline_change(
            raw_event, f"timeline_events[{index}]", allow_delete=False, through_chapter=last_chapter
        )
        require(event["id"] not in timeline, f"duplicate timeline event ID {event['id']}")
        event.pop("action")
        event["first_recorded_chapter"] = max(1, last_chapter)
        event["updated_chapter"] = max(1, last_chapter)
        timeline[event["id"]] = event
    return normalize_state(
        {
            "schema_version": TRACKING_SCHEMA_VERSION,
            "book_title": clean_text(root.get("book_title"), "book_title", max_bytes=240),
            "last_committed_chapter": last_chapter,
            "imported_through_chapter": last_chapter,
            "state_revision": 0,
            "context": context,
            "characters": snapshots,
            "foreshadow": foreshadow,
            "timeline": timeline,
        }
    )


def normalize_transaction(state: dict[str, Any], document: object) -> dict[str, Any]:
    root = as_mapping(document, "transaction")
    require_known_keys(
        root,
        {
            "schema_version", "mode", "chapter", "chapter_title", "expected_state_revision",
            "delta", "context", "character_snapshots",
        },
        "transaction",
    )
    require(root.get("schema_version") == INPUT_SCHEMA_VERSION, "transaction schema_version is unsupported")
    mode = clean_text(root.get("mode"), "mode", max_bytes=24)
    require(mode in {"append", "revision"}, "mode must be append or revision")
    chapter = as_int(root.get("chapter"), "chapter", minimum=1)
    expected_revision = as_int(root.get("expected_state_revision"), "expected_state_revision")
    require(expected_revision == state["state_revision"], "tracking state changed since this transaction was prepared")
    last = state["last_committed_chapter"]
    if mode == "append":
        require(chapter == last + 1, f"append chapter must be {last + 1}, got {chapter}")
    else:
        require(chapter <= last, f"cannot revise unwritten chapter {chapter}; last committed chapter is {last}")
    context = validate_context_input(root.get("context"), include_initial_fields=False)
    snapshots = normalize_snapshots(root.get("character_snapshots", {}))
    existing_names = {portable_name_key(name): name for name in state["characters"]}
    for name in snapshots:
        existing = existing_names.get(portable_name_key(name))
        require(existing is None or existing == name, f"character {name} conflicts with existing character {existing}")
    through_chapter = chapter if mode == "append" else last
    delta = normalize_delta(
        root.get("delta"),
        through_chapter=through_chapter,
        snapshots=snapshots,
        existing_core_names=existing_names,
    )
    return {
        "mode": mode,
        "chapter": chapter,
        "title": clean_text(root.get("chapter_title"), "chapter_title", max_bytes=240),
        "delta": delta,
        "context": context,
        "snapshots": snapshots,
    }


def checkpoint_record(
    change: dict[str, Any], chapter: int, previous: dict[str, Any] | None, *, keep_first_chapter: bool = False
) -> dict[str, Any]:
    current = {key: value for key, value in change.items() if key != "action"}
    current["updated_chapter"] = max(previous["updated_chapter"] if previous else chapter, chapter)
    if keep_first_chapter:
        current["first_recorded_chapter"] = previous["first_recorded_chapter"] if previous else chapter
    return current


def merge_transaction(state: dict[str, Any], transaction: dict[str, Any]) -> dict[str, Any]:
    next_state = copy.deepcopy(state)
    chapter = transaction["chapter"]
    if transaction["mode"] == "append":
        next_state["last_committed_chapter"] = chapter
    next_state["state_revision"] += 1
    next_state["characters"].update(transaction["snapshots"])

    next_context = transaction["context"]
    # 退役说的是「从此刻起离开当前状态」，只有 append 的逐章记录代表此刻；
    # 修订记录属于被改写的旧章，落在那里会谎报退役发生的章节。
    is_revision = transaction["mode"] == "revision"
    require(
        not (is_revision and transaction["delta"]["retired_characters"]),
        "retired_characters must be committed in an append transaction, not a revision",
    )
    for name in transaction["delta"]["retired_characters"]:
        require(name in next_state["characters"], f"retired character {name} has no current snapshot")
        require(
            name not in transaction["snapshots"],
            f"character {name} cannot be retired and updated in the same transaction",
        )
        require(
            name not in next_context["active_character_names"],
            f"retired character {name} is still listed in context.active_character_names",
        )
        next_state["characters"].pop(name)

    # 上下文条目是整份提交的；漏写会静默丢历史裁定，因此掉落必须显式声明。
    previous_items = set(state["context"]["long_term_constraints"]) | set(state["context"]["continuity_risks"])
    dropped = previous_items - (set(next_context["long_term_constraints"]) | set(next_context["continuity_risks"]))
    require(
        not (is_revision and dropped),
        "a revision must resubmit every current context item; retire them in an append transaction instead: "
        + "；".join(sorted(dropped)),
    )
    undeclared = sorted(dropped - set(transaction["delta"]["retired_context_items"]))
    require(
        not undeclared,
        "context items were dropped without being declared in delta.retired_context_items: "
        + "；".join(undeclared),
    )
    transaction["delta"]["retired_context_items"] = sorted(dropped)

    for change in transaction["delta"]["foreshadow_changes"]:
        if change["action"] == "delete":
            next_state["foreshadow"].pop(change["id"], None)
        else:
            next_state["foreshadow"][change["id"]] = checkpoint_record(
                change, chapter, next_state["foreshadow"].get(change["id"])
            )
    for change in transaction["delta"]["timeline_events"]:
        if change["action"] == "delete":
            next_state["timeline"].pop(change["id"], None)
        else:
            next_state["timeline"][change["id"]] = checkpoint_record(
                change, chapter, next_state["timeline"].get(change["id"]), keep_first_chapter=True
            )

    recent_by_chapter = {item["chapter"]: item for item in state["context"]["recent_chapters"]}
    if chapter in recent_by_chapter or transaction["mode"] == "append":
        recent_by_chapter[chapter] = {"chapter": chapter, "summary": transaction["delta"]["result"]}
    recent = sorted(recent_by_chapter.values(), key=lambda item: item["chapter"])[-3:]
    current_last = next_state["last_committed_chapter"]
    next_commitments = (
        transaction["delta"]["next_chapter_commitments"]
        if transaction["mode"] == "append" or chapter == current_last
        else state["context"]["next_chapter_commitments"]
    )
    next_state["context"] = {
        **next_context,
        "recent_chapters": recent,
        "next_chapter_commitments": next_commitments,
    }
    return normalize_state(next_state)


def render_views(state: dict[str, Any], project: Path) -> dict[str, str]:
    revision = state["state_revision"]
    labels = labels_for(record_language(project))
    views = {
        "context.md": render_context(state, labels),
        "foreshadowing.md": render_foreshadow(state["foreshadow"], revision, labels),
    }
    author, reader = render_timeline_views(state["timeline"], revision, labels)
    views["timeline/author-truth.md"] = author
    views["timeline/reader-knowledge.md"] = reader
    for name, snapshot in state["characters"].items():
        views[f"character-state/{name}.md"] = render_snapshot(
            name, snapshot, state["last_committed_chapter"], revision, labels
        )
    return views


def write_views(tracking: Path, views: dict[str, str]) -> None:
    # 上下文携带 next revision，先写它；任何后续失败都会让 hook/check 发现
    # 上下文 revision 与最后提交的 _tracking-state.json 不一致。
    write_if_changed(tracking / "context.md", views["context.md"])
    for relative in sorted(path for path in views if path != "context.md"):
        write_if_changed(tracking / relative, views[relative])
    expected_character_files = {
        Path(relative).name for relative in views if relative.startswith("character-state/")
    }
    character_dir = tracking / "character-state"
    character_dir.mkdir(parents=True, exist_ok=True)
    for path in character_dir.glob("*.md"):
        if path.name not in expected_character_files:
            path.unlink()


def warn_sizes(views: dict[str, str], delta_payload: str | None = None) -> None:
    if delta_payload is not None and byte_size(delta_payload) > DELTA_TARGET_BYTES:
        emit(
            f"WARNING: chapter delta is {byte_size(delta_payload)} bytes; target is <= {DELTA_TARGET_BYTES}",
            error=True,
        )
    context_size = byte_size(views["context.md"])
    if context_size > CONTEXT_TARGET_BYTES:
        emit(f"WARNING: hot context is {context_size} bytes; target is <= {CONTEXT_TARGET_BYTES}", error=True)
    for relative, payload in views.items():
        if not relative.startswith("character-state/"):
            continue
        size = byte_size(payload)
        if size > SNAPSHOT_TARGET_BYTES:
            emit(
                f"WARNING: character snapshot {Path(relative).stem} is {size} bytes; target is <= {SNAPSHOT_TARGET_BYTES}",
                error=True,
            )


def initialize(project: Path, document: object) -> dict[str, Any]:
    tracking = tracking_root(project)
    require(not state_path(project).exists(), "tracking state already exists; init never overwrites project state")
    state = normalize_initial_document(document)
    views = render_views(state, project)
    state_payload = json_payload(state)

    # 输入全部校验通过后才动用户文件，失败的 init 不会挪走任何东西。
    archived = archive_retired_tracking_paths(tracking)
    for directory in (tracking / "chapter-records", tracking / "character-state", tracking / "timeline"):
        directory.mkdir(parents=True, exist_ok=True)
    write_views(tracking, views)
    atomic_write_text(state_path(project), state_payload)
    warn_sizes(views)
    if archived:
        emit(
            f"NOTE: retired tracking files were moved to tracking/{RETIRED_ARCHIVE_DIR}/: {', '.join(archived)}; "
            "the current state comes from this init input.",
            error=True,
        )
    return state


def apply_transaction(project: Path, document: object) -> dict[str, Any]:
    tracking = tracking_root(project)
    require_no_retired_tracking_paths(tracking)
    state = load_state(project)
    transaction = normalize_transaction(state, document)
    next_state = merge_transaction(state, transaction)

    delta_payload = render_delta(
        transaction["chapter"],
        transaction["title"],
        transaction["delta"],
        # 本章退役的角色在 next_state 里已被删除，但本章记录里仍应标为核心。
        set(next_state["characters"]) | set(transaction["delta"]["retired_characters"]),
        labels_for(record_language(project)),
    )
    views = render_views(next_state, project)
    next_state_payload = json_payload(next_state)
    path = delta_path(tracking, transaction["chapter"])
    if transaction["mode"] == "append" and path.exists():
        require(
            path.read_text(encoding="utf-8") == delta_payload,
            f"chapter delta {transaction['chapter']} already exists with different content",
        )

    write_if_changed(path, delta_payload)
    write_views(tracking, views)
    # 唯一权威文件最后落盘；在此之前失败可用同一事务直接重跑。
    atomic_write_text(state_path(project), next_state_payload)
    warn_sizes(views, delta_payload)
    return next_state


def check_project(project: Path) -> dict[str, Any]:
    tracking = tracking_root(project)
    require_no_retired_tracking_paths(tracking)
    state = load_state(project)
    last_chapter = state["last_committed_chapter"]
    required_delta_start = state["imported_through_chapter"] + 1
    for chapter in range(required_delta_start, last_chapter + 1):
        require(delta_path(tracking, chapter).exists(), f"chapter delta {chapter} is missing")
    for path in (tracking / "chapter-records").glob("chapter_*.md"):
        match = re.fullmatch(r"chapter_(\d+)\.md", path.name)
        require(match is not None, f"chapter delta has an invalid filename: {path.name}")
        chapter = as_int(int(match.group(1)), f"chapter delta {path.name}", minimum=1)
        require(path == delta_path(tracking, chapter), f"chapter delta {chapter} filename is not canonical")
        require(chapter <= last_chapter, f"chapter delta {chapter} exceeds last_committed_chapter")
        require(path.stat().st_size <= DELTA_MAX_BYTES, f"chapter delta {chapter} exceeds {DELTA_MAX_BYTES} bytes")

    expected_views = render_views(state, project)
    for relative, expected in expected_views.items():
        path = tracking / relative
        require(path.exists(), f"derived view is missing: {relative}")
        require(
            path.read_text(encoding="utf-8") == expected,
            f"derived view differs from _tracking-state.json: {relative}",
        )
    expected_character_files = {
        Path(relative).name for relative in expected_views if relative.startswith("character-state/")
    }
    actual_character_files = {path.name for path in (tracking / "character-state").glob("*.md")}
    require(actual_character_files == expected_character_files, "character snapshot files differ from tracking state")
    return state


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("init", "commit"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument("--project", type=Path, required=True, help="book project root containing tracking/")
        subparser.add_argument("--input", type=Path, required=True, help="UTF-8 JSON input document")
    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("--project", type=Path, required=True, help="book project root containing tracking/")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "init":
            result = initialize(args.project, read_json(args.input))
        elif args.command == "commit":
            result = apply_transaction(args.project, read_json(args.input))
        else:
            result = check_project(args.project)
    except (TrackingError, OSError, UnicodeError) as exc:
        emit(f"ERROR: {exc}", error=True)
        return 2
    emit(
        json.dumps(
            {
                "last_committed_chapter": result["last_committed_chapter"],
                "state_revision": result["state_revision"],
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
