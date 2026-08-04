#!/usr/bin/env python
"""Sync Claude Code agent templates to OpenCode format.

Scans templates/agents/*.md, converts frontmatter to opencode format,
and writes to opencode/agents/. Also syncs CLAUDE.md.tmpl -> AGENTS.md.tmpl.
"""

import argparse
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# The only way an agent body expresses a shell step: "Run `<command>`" (the sole
# form used across the template repo). A read-only agent with such an instruction
# fails generation outright: OpenCode's shell.ts only checks the command's direct
# parent, so even a full-command-literal allowlist can be bypassed by the outer
# redirection of `( command ) > prose.md` in a subshell.
# `(?<![\w-])` excludes "re-run `/story-setup`": the read-only template only
# tells the agent to have the PARENT flow re-run setup, which is not a shell step
# of the agent itself.
BODY_COMMAND_RE = re.compile(r"(?<![\w-])[Rr]un\s*`([^`]+)`")


def body_bash_commands(body: str) -> list[str]:
    """Extract the commands an agent body explicitly requires running (deduped by
    appearance order).

    Deliberately no hardcoded "agent name set" — that is exactly the anti-pattern
    called out by an earlier audit in generate-codex-agents.py: the list and the
    bodies drift apart, agents that gained an instruction lose their permission and
    agents that lost one keep it. The body is the single source of truth; a
    read-only agent with any extracted command fails the conversion stage.
    """
    commands: list[str] = []
    for match in BODY_COMMAND_RE.finditer(body):
        command = match.group(1).strip()
        if command and command not in commands:
            commands.append(command)
    return commands


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML-like frontmatter and body from markdown content."""
    # The closing separator must be a `---` on its own line (anchored "\n---\n");
    # content.split("---", 2) would treat a triple-hyphen inside a frontmatter value
    # (a description's `---`, a comment's `---`) as the terminator, truncating the
    # remaining keys with permission/steps into the body while silently exit 0.
    # Same parsing stance as the sibling generator generate-codex-agents.py.
    if not content.startswith("---\n"):
        return {}, content
    end = content.find("\n---\n", len("---"))
    if end < 0:
        return {}, content
    fm_text = content[len("---") : end].strip()
    body = content[end + len("\n---") :]
    fm = {}
    lines = fm_text.split("\n")
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        if ":" in stripped:
            key, _, val = stripped.partition(":")
            key = key.strip()
            val = val.strip()

            if val == "|":
                continuation = []
                i += 1
                while i < len(lines):
                    cont_line = lines[i]
                    if cont_line.startswith((" ", "\t")) and cont_line.strip():
                        continuation.append(cont_line.strip())
                        i += 1
                    elif not cont_line.strip():
                        continuation.append("")
                        i += 1
                    else:
                        break
                fm[key] = "\n".join(continuation).strip()
                continue
            else:
                fm[key] = val

        i += 1

    return fm, body


def convert_claude_to_opencode(fm: dict, body: str) -> dict:
    """Convert Claude Code agent frontmatter to OpenCode format.

    `body` is not optional: the bash rules are granted per agent based on
    whether the body actually requires the command, so omitting the body would
    silently tighten or loosen permissions. The caller must always hand it over.
    """
    result = {}
    name = fm.get("name", "")

    if "description" in fm:
        result["description"] = fm["description"]

    result["mode"] = "subagent"

    tools = _parse_list(fm.get("tools", ""))
    disallowed = _parse_list(fm.get("disallowedTools", ""))

    perm = {}
    if any(t in tools for t in ("Read", "Glob", "Grep")):
        perm["read"] = "allow"
    has_write = any(t in tools for t in ("Write", "Edit"))
    has_edit_disallowed = any(t in disallowed for t in ("Write", "Edit"))

    # deny priority: disallowedTools overrides Write/Edit in tools
    # story-researcher is a known exception — opencode's edit permission controls
    # both Write and Edit, cannot distinguish. story-researcher needs to create
    # new files (research output), so set edit: allow
    if name == "story-researcher":
        perm["edit"] = "allow"
    elif has_edit_disallowed:
        perm["edit"] = "deny"
    elif has_write:
        perm["edit"] = "allow"

    # Bash follows the same "disallowedTools wins" rule. OpenCode defaults to ask
    # when bash permission is undeclared; a read-only agent must carry a scalar
    # deny so upstream disabled() removes the bash tool entirely.
    # No "read-only command" allowlist: shell.ts only authorizes the command's
    # direct parent, and `( allowlisted-command ) > prose.md` hides the outer
    # redirection in a subshell — a literal allowlist can't hold the filesystem
    # boundary either.
    mentioned_bash = body_bash_commands(body)
    restricted_bash = "Bash" in disallowed
    if restricted_bash:
        if mentioned_bash:
            raise ValueError(
                f"{name or '<unnamed>'}: read-only agent forbids Bash but the body requires running "
                + ", ".join(f"`{command}`" for command in mentioned_bash)
                + "; rewrite the body to use the host-provided workspace and Read/Glob/Grep — no shell exceptions."
            )
        perm["bash"] = "deny"
    elif "Bash" in tools:
        perm["bash"] = "allow"
    if perm:
        result["permission"] = perm

    if "maxTurns" in fm:
        try:
            result["steps"] = int(fm["maxTurns"])
        except ValueError:
            pass

    return result


def _parse_list(val: str) -> list[str]:
    """Parse a YAML-like list like '[Read, Glob, Grep]'."""
    match = re.search(r"\[(.*)\]", val)
    if not match:
        return []
    items = match.group(1).split(",")
    return [item.strip().strip("'").strip('"') for item in items if item.strip()]


def format_frontmatter(fm: dict) -> str:
    """Format frontmatter dict to YAML-like string."""
    lines = ["---"]
    for key, value in fm.items():
        if key == "permission" and isinstance(value, dict):
            lines.append("permission:")
            for pk, pv in value.items():
                if isinstance(pv, dict):
                    # Command glob form (e.g. bash): glob keys must be quoted — a
                    # bare `*` is an alias marker in YAML.
                    # Never reorder these keys: OpenCode resolves with findLast,
                    # later rules override earlier ones, so key order is priority.
                    # Must be emitted exactly in dict insertion order.
                    lines.append(f"  {pk}:")
                    for glob, action in pv.items():
                        lines.append(f'    "{glob}": {action}')
                else:
                    lines.append(f"  {pk}: {pv}")
        elif key == "description" and "\n" in value:
            lines.append("description: |")
            for desc_line in value.split("\n"):
                lines.append(f"  {desc_line}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n"


def replace_claude_paths(body: str) -> str:
    """Replace .claude/ path references with .opencode/ equivalents.

    The path-rules section is handled idempotently by fix_path_rules_section();
    no manual fix needed.
    """
    replacements = [
        (".claude/skills/", ".opencode/skills/"),
        (".claude/agents/", ".opencode/agents/"),
        (".claude/hooks/", ".opencode/hooks/"),
        ("~/.claude/", "~/.config/opencode/"),
        ("$HOME/.claude/", "$HOME/.config/opencode/"),
        ("CLAUDE.md", "AGENTS.md"),
    ]
    for old, new in replacements:
        if old in body:
            body = body.replace(old, new)
    return body


def fix_path_rules_section(body: str) -> str:
    """Normalize the reference file path rules section for the OpenCode deployment.

    Detects the "## Reference File Path Rules" section and swaps the deployment
    literal (`.claude/skills/` from the source template, already rewritten to
    `.opencode/skills/` by replace_claude_paths) for the canonical prefix-less
    form `{项目根}/skills/...` that story-setup deploys for OpenCode — generated
    agents must not carry either CLI's literal path.
    This is idempotent — running multiple times produces the same output.
    """
    # Some agents do not read reference files and intentionally have no such
    # section. Only warn when the section marker exists but its shape drifted.
    if "## Reference File Path Rules" not in body:
        return body

    fixed = body
    for prefix in (".claude/skills/", ".opencode/skills/"):
        for root, name in (("{project root}", "{fileName}"), ("{项目根}", "{文件名}")):
            fixed = fixed.replace(
                root + "/" + prefix + "story-setup/references/agent-references/" + name,
                root + "/skills/story-setup/references/agent-references/" + name,
            )
    fixed = fixed.replace(
        "the canonical path of the current Claude deployment",
        "the canonical path of the current OpenCode deployment",
    )

    if fixed == body:
        print(
            "  [WARN] fix_path_rules_section: path rules section found but the "
            "canonical path line was not rewritten; the source template may have "
            "changed shape",
            file=sys.stderr,
        )
    return fixed


def file_status(dst: Path, output: str) -> tuple[str, bool]:
    """Compare one generated file without mutating the destination."""
    if not os.path.lexists(dst):
        return "missing", True
    if dst.is_symlink() or not dst.is_file():
        return "stale", True
    old_content = dst.read_text(encoding="utf-8")
    if old_content == output:
        return "unchanged", False
    return "stale", True


def render_agents() -> dict[str, str]:
    """Validate and render every OpenCode agent before any destination write."""
    src_dir = ROOT / "skills/story-setup/references/templates/agents"
    sources = sorted(src_dir.glob("*.md"))
    if not sources:
        raise RuntimeError(f"no agent markdown files found in {src_dir}")
    rendered: dict[str, str] = {}
    for md_file in sources:
        content = md_file.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(content)
        name = str(fm.get("name", "")).strip()
        description = str(fm.get("description", "")).strip()
        if not name:
            raise ValueError(f"{md_file}: missing agent name")
        if name != md_file.stem:
            raise ValueError(
                f"{md_file}: agent name {name!r} must match filename {md_file.stem!r}"
            )
        if not description:
            raise ValueError(f"{md_file}: missing agent description")
        # Derive the bash rules from the **source template body** (before the
        # .claude -> .opencode path replacement): the grant authority is whether
        # the source definition mentions the command, not the wording of the
        # generated artifact.
        new_fm = convert_claude_to_opencode(fm, body)
        new_body = replace_claude_paths(body)
        new_body = fix_path_rules_section(new_body)  # undo wrong path replacements in the rules section
        output = format_frontmatter(new_fm) + new_body
        output = output.rstrip("\n") + "\n"  # canonical single trailing newline; avoid an EOF blank line
        if md_file.name in rendered:
            raise ValueError(f"duplicate generated agent filename: {md_file.name}")
        rendered[md_file.name] = output
    return rendered


def agent_statuses(
    rendered: dict[str, str], dst_dir: Path, check: bool
) -> tuple[list[str], bool]:
    """Return deterministic status lines for the generated agent surface."""
    results: list[str] = []
    changed = False
    for filename, output in rendered.items():
        dst_file = dst_dir / filename
        raw_status, file_changed = file_status(dst_file, output)
        if check:
            status = raw_status
        else:
            status = (
                "created"
                if raw_status == "missing"
                else "updated"
                if raw_status == "stale"
                else raw_status
            )
        changed = changed or file_changed
        results.append(f"  [{status}] {dst_file.name}")

    for stale in sorted(dst_dir.glob("*.md")):
        if stale.name in rendered:
            continue
        changed = True
        results.append(f"  [{'extra' if check else 'deleted'}] {stale.name}")

    return results, changed


def render_agents_md() -> str:
    """Validate and render CLAUDE.md.tmpl for OpenCode."""
    src = ROOT / "skills/story-setup/references/templates/CLAUDE.md.tmpl"
    if not src.is_file():
        raise RuntimeError(f"source template not found: {src}")

    content = src.read_text(encoding="utf-8")
    new_content = replace_claude_paths(content)
    return new_content.rstrip("\n") + "\n"  # canonical single trailing newline; avoid an EOF blank line


def publish_tree(rendered: dict[str, str], agents_md: str, dst_root: Path) -> None:
    """Publish generated OpenCode files with rollback, preserving manual assets."""
    if dst_root.is_symlink():
        raise ValueError(f"destination directory must not be a symlink: {dst_root}")
    if dst_root.exists() and not dst_root.is_dir():
        raise ValueError(f"destination is not a directory: {dst_root}")
    existing_agents = dst_root / "agents"
    if existing_agents.is_symlink():
        raise ValueError(
            f"generated agents directory must not be a symlink: {existing_agents}"
        )
    if existing_agents.exists() and not existing_agents.is_dir():
        raise ValueError(
            f"generated agents path is not a directory: {existing_agents}"
        )

    dst_root.mkdir(parents=True, exist_ok=True)
    existing_agents.mkdir(parents=True, exist_ok=True)
    staging = Path(
        tempfile.mkdtemp(prefix=f".{dst_root.name}.staging-", dir=dst_root.parent)
    )
    backup = Path(
        tempfile.mkdtemp(prefix=f".{dst_root.name}.backup-", dir=dst_root.parent)
    )
    try:
        agents_dir = staging / "agents"
        backup_agents = backup / "agents"
        agents_dir.mkdir()
        backup_agents.mkdir()
        for filename, output in rendered.items():
            (agents_dir / filename).write_text(output, encoding="utf-8", newline="\n")

        staged_agents_md = staging / "AGENTS.md.tmpl"
        staged_agents_md.write_text(agents_md, encoding="utf-8", newline="\n")

        existing_md = sorted(existing_agents.glob("*.md"))
        for path in existing_md:
            if path.is_dir() and not path.is_symlink():
                raise IsADirectoryError(f"generated target is a directory: {path}")
            if path.is_symlink():
                (backup_agents / path.name).symlink_to(os.readlink(path))
            else:
                shutil.copy2(path, backup_agents / path.name)

        target_agents_md = dst_root / "AGENTS.md.tmpl"
        had_agents_md = os.path.lexists(target_agents_md)
        if target_agents_md.is_dir() and not target_agents_md.is_symlink():
            raise IsADirectoryError(
                f"generated target is a directory: {target_agents_md}"
            )
        if had_agents_md:
            if target_agents_md.is_symlink():
                (backup / "AGENTS.md.tmpl").symlink_to(
                    os.readlink(target_agents_md)
                )
            else:
                shutil.copy2(target_agents_md, backup / "AGENTS.md.tmpl")

        try:
            for filename in rendered:
                os.replace(agents_dir / filename, existing_agents / filename)
            os.replace(staged_agents_md, target_agents_md)
            for stale in existing_md:
                if stale.name not in rendered:
                    stale.unlink()
        except BaseException:
            # Best-effort rollback: a single un-removable file must not abort the
            # restore and strand a partial commit. Backed-up files are overwritten
            # in place; only outputs absent before the commit are removed.
            restore_names = {path.name for path in backup_agents.iterdir()}
            for current in list(existing_agents.glob("*.md")):
                if current.is_dir() and not current.is_symlink():
                    continue
                if current.name in restore_names:
                    continue
                try:
                    current.unlink()
                except OSError:
                    pass
            for original in backup_agents.iterdir():
                target = existing_agents / original.name
                try:
                    if original.is_symlink():
                        if target.is_symlink() or target.exists():
                            target.unlink()
                        target.symlink_to(os.readlink(original))
                    else:
                        # target is provably a regular file (a commit only
                        # os.replace's regular staged outputs), so copy2 safely
                        # overwrites it in place.
                        shutil.copy2(original, target)
                except OSError:
                    pass
            original_agents_md = backup / "AGENTS.md.tmpl"
            try:
                if had_agents_md:
                    if original_agents_md.is_symlink():
                        if target_agents_md.is_symlink() or target_agents_md.exists():
                            target_agents_md.unlink()
                        target_agents_md.symlink_to(os.readlink(original_agents_md))
                    else:
                        shutil.copy2(original_agents_md, target_agents_md)
                elif os.path.lexists(target_agents_md) and (
                    not target_agents_md.is_dir() or target_agents_md.is_symlink()
                ):
                    target_agents_md.unlink()
            except OSError:
                pass
            raise
    finally:
        shutil.rmtree(staging, ignore_errors=True)
        shutil.rmtree(backup, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify generated files without modifying the working tree",
    )
    args = parser.parse_args()

    # The agents and top-level instructions form one generated adapter. Render
    # and validate both phases before inspecting or publishing either one.
    rendered = render_agents()
    agents_md = render_agents_md()
    dst_root = ROOT / "skills/story-setup/references/opencode"
    agent_results, agents_changed = agent_statuses(
        rendered, dst_root / "agents", args.check
    )
    raw_md_status, agents_md_changed = file_status(
        dst_root / "AGENTS.md.tmpl", agents_md
    )
    if args.check:
        md_status = raw_md_status
    else:
        md_status = (
            "created"
            if raw_md_status == "missing"
            else "updated"
            if raw_md_status == "stale"
            else raw_md_status
        )

    print("=== opencode sync script ===\n")
    print("1. Syncing agents...")
    for r in agent_results:
        print(r)

    print("\n2. Syncing AGENTS.md.tmpl...")
    print(f"  [{md_status}] AGENTS.md.tmpl")

    if args.check:
        if agents_changed or agents_md_changed:
            print(
                "\nERROR: generated OpenCode templates are out of sync.",
                file=sys.stderr,
            )
            return 1
        print("\nOK: generated OpenCode templates are in sync.")
        return 0

    publish_tree(rendered, agents_md, dst_root)

    print("\n3. Manual maintenance required:")
    print("  - skills/story-setup/references/opencode/plugin.ts (hooks logic)")
    print("  - skills/story-setup/references/opencode/commands/ (slash commands)")
    print(
        "  - skills/story-setup/references/opencode/opencode.json.patch (config fragment)"
    )
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
