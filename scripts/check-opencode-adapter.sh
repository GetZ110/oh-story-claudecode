#!/usr/bin/env bash
# check-opencode-adapter.sh — deterministic checks for the OpenCode adapter surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$REPO_ROOT/skills/story-setup/references/opencode"
TMP_DIR="$(mktemp -d)"
SYNC_LOG="$TMP_DIR/sync.log"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "required file missing: $1"; }
assert_dir() { [ -d "$1" ] || fail "required directory missing: $1"; }
assert_grep() { grep -Eq "$1" "$2" || fail "$3 ($2)"; }

cd "$REPO_ROOT"

echo "OpenCode adapter check"
echo "======================"
echo "Repo: $REPO_ROOT"

# Locate a working Python interpreter: python3 may be a Windows Store stub that
# exits without running anything, so probe python3 -> python -> py.
PYBIN=""
for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then
    PYBIN="$cand"
    break
  fi
done
[ -n "$PYBIN" ] || fail "no usable Python interpreter (tried python3, python, py)"

# Windows without developer mode cannot create symlinks (os.symlink -> WinError
# 1314). The symlink-redirection scenario is then untestable; skip it so the rest
# of the rollback suite still runs (same policy as the Codex adapter check).
SYMLINKS_OK=1
if ! "$PYBIN" -c "import os,tempfile; d=tempfile.mkdtemp(); os.symlink(d, d+'-ln'); os.unlink(d+'-ln')" >/dev/null 2>&1; then
  SYMLINKS_OK=0
fi

assert_dir "$ROOT"
assert_file "$ROOT/AGENTS.md.tmpl"
assert_file "$ROOT/opencode.json.patch"
assert_file "$ROOT/plugin.ts"
assert_file "$ROOT/story_hook_core.js"
assert_dir "$ROOT/agents"
assert_dir "$ROOT/commands"
assert_file "scripts/sync-opencode.py"

"$PYBIN" -m json.tool "$ROOT/opencode.json.patch" >/dev/null
"$PYBIN" - <<'PY'
import json
from pathlib import Path
cfg = json.loads(Path('skills/story-setup/references/opencode/opencode.json.patch').read_text())
assert cfg.get('$schema') == 'https://opencode.ai/config.json', cfg
plugins = cfg.get('plugin')
assert isinstance(plugins, list), plugins
assert './.opencode/plugins/story-hooks.ts' in plugins, plugins
PY

echo "  OK config patch"

# Snapshot the generated surface so --check itself is held to its read-only contract,
# including when a developer already has unrelated worktree changes.
cp -R "$ROOT" "$TMP_DIR/opencode-before"
if ! "$PYBIN" scripts/sync-opencode.py --check >"$SYNC_LOG" 2>&1; then
  cat "$SYNC_LOG" >&2 || true
  echo "::error::OpenCode templates are out of sync with Claude Code templates." >&2
  echo "::error::Run 'python3 scripts/sync-opencode.py' locally and commit the changes." >&2
  exit 1
fi
diff -qr "$TMP_DIR/opencode-before" "$ROOT" >/dev/null \
  || fail "sync-opencode.py --check modified generated files"

echo "  OK generated OpenCode templates are in sync (--check stayed read-only)"

SYMLINKS_OK="$SYMLINKS_OK" "$PYBIN" - "scripts/sync-opencode.py" "$TMP_DIR" <<'PY'
import importlib.util
import sys
from pathlib import Path

script_path = Path(sys.argv[1]).resolve()
tmp = Path(sys.argv[2]) / "opencode-transaction"
spec = importlib.util.spec_from_file_location("sync_opencode", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

src = tmp / "skills/story-setup/references/templates/agents"
templates = src.parent
dst_root = tmp / "skills/story-setup/references/opencode"
dst = dst_root / "agents"
src.mkdir(parents=True)
dst.mkdir(parents=True)
(templates / "CLAUDE.md.tmpl").write_text("valid instructions\n", encoding="utf-8")
(src / "a.md").write_text(
    "---\nname: a\ndescription: valid first fixture\ntools: [Read]\n---\nbody\n",
    encoding="utf-8",
)
(src / "b.md").write_text("missing frontmatter\n", encoding="utf-8")
(dst / "a.md").write_text("keep old a\n", encoding="utf-8")
(dst / "sentinel.md").write_text("keep sentinel\n", encoding="utf-8")
before = {path.name: path.read_bytes() for path in dst.iterdir()}
module.ROOT = tmp
old_argv = sys.argv
sys.argv = [str(script_path)]
try:
    module.main()
except ValueError:
    pass
else:
    raise SystemExit("sync-opencode must reject malformed agent source")
finally:
    sys.argv = old_argv
after = {path.name: path.read_bytes() for path in dst.iterdir()}
if after != before:
    raise SystemExit("sync-opencode modified destination before validating all sources")
PY

echo "  OK malformed source cannot partially update generated agents"

SYMLINKS_OK="$SYMLINKS_OK" "$PYBIN" - "scripts/sync-opencode.py" "$TMP_DIR" <<'PY'
import importlib.util
import os
import sys
from pathlib import Path

script_path = Path(sys.argv[1]).resolve()
tmp = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("sync_opencode_atomic", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


def snapshot(root: Path) -> dict[str, tuple[str, bytes]]:
    result = {}
    if not root.exists():
        return result
    for path in sorted(root.rglob("*")):
        rel = path.relative_to(root).as_posix()
        if path.is_symlink():
            result[rel] = ("symlink", str(path.readlink()).encode())
        elif path.is_dir():
            result[rel] = ("dir", b"")
        else:
            result[rel] = ("file", path.read_bytes())
    return result


def write_agent(path: Path, name: str) -> None:
    path.write_text(
        f"---\nname: {name}\ndescription: valid {name} fixture\ntools: [Read]\n---\n{name} body\n",
        encoding="utf-8",
    )


def run_normal(root: Path) -> None:
    old_root, old_argv = module.ROOT, sys.argv
    module.ROOT = root
    sys.argv = [str(script_path)]
    try:
        module.main()
    finally:
        module.ROOT = old_root
        sys.argv = old_argv


# Cross-phase failure: valid agents followed by a missing CLAUDE.md.tmpl must
# leave the entire OpenCode adapter tree byte-for-byte unchanged.
missing_root = tmp / "opencode-missing-agents-template"
missing_src = missing_root / "skills/story-setup/references/templates/agents"
missing_dst = missing_root / "skills/story-setup/references/opencode"
missing_src.mkdir(parents=True)
(missing_dst / "agents").mkdir(parents=True)
write_agent(missing_src / "a.md", "a")
(missing_dst / "agents/a.md").write_text("keep old a\n", encoding="utf-8")
(missing_dst / "plugin.ts").write_text("keep manual plugin\n", encoding="utf-8")
before = snapshot(missing_dst)
try:
    run_normal(missing_root)
except RuntimeError:
    pass
else:
    raise SystemExit("sync-opencode must reject a missing CLAUDE.md.tmpl")
if snapshot(missing_dst) != before:
    raise SystemExit("sync-opencode partially updated agents before CLAUDE.md.tmpl validation")


# Publication failure: b.md is deliberately a directory in the destination.
# The failed second agent output must not expose the earlier a.md update or
# mutate AGENTS.md.tmpl/manual OpenCode assets.
write_root = tmp / "opencode-write-failure"
write_src_root = write_root / "skills/story-setup/references/templates"
write_src = write_src_root / "agents"
write_dst = write_root / "skills/story-setup/references/opencode"
write_src.mkdir(parents=True)
(write_dst / "agents/b.md").mkdir(parents=True)
write_agent(write_src / "a.md", "a")
write_agent(write_src / "b.md", "b")
(write_src_root / "CLAUDE.md.tmpl").write_text("new instructions\n", encoding="utf-8")
(write_dst / "agents/a.md").write_text("keep old a\n", encoding="utf-8")
(write_dst / "AGENTS.md.tmpl").write_text("keep old instructions\n", encoding="utf-8")
(write_dst / "plugin.ts").write_text("keep manual plugin\n", encoding="utf-8")
before = snapshot(write_dst)
try:
    run_normal(write_root)
except (IsADirectoryError, OSError):
    pass
else:
    raise SystemExit("sync-opencode must fail when a generated target is a directory")
if snapshot(write_dst) != before:
    raise SystemExit("sync-opencode exposed a partial adapter update after a write failure")


# Fail the second os.replace after the first agent was committed. The normal
# exception path must restore agents, AGENTS.md.tmpl, and manual assets.
commit_dst = tmp / "opencode-commit-failure"
(commit_dst / "agents").mkdir(parents=True)
(commit_dst / "agents/a.md").write_text("old a\n", encoding="utf-8")
(commit_dst / "agents/b.md").write_text("old b\n", encoding="utf-8")
(commit_dst / "AGENTS.md.tmpl").write_text("old instructions\n", encoding="utf-8")
(commit_dst / "plugin.ts").write_text("manual plugin\n", encoding="utf-8")
before = snapshot(commit_dst)
real_replace = module.os.replace
calls = 0

def fail_second_replace(src, dst):
    global calls
    calls += 1
    if calls == 2:
        raise OSError("injected second-commit failure")
    return real_replace(src, dst)

module.os.replace = fail_second_replace
try:
    module.publish_tree(
        {"a.md": "new a\n", "b.md": "new b\n"},
        "new instructions\n",
        commit_dst,
    )
except OSError:
    pass
else:
    raise SystemExit("sync-opencode did not surface injected commit failure")
finally:
    module.os.replace = real_replace
if snapshot(commit_dst) != before:
    raise SystemExit("sync-opencode failed to roll back an interrupted commit")


if os.environ.get("SYMLINKS_OK") == "1":
    # A copied symlink at opencode/agents must never redirect staging writes into
    # an external/user directory.
    link_root = tmp / "opencode-symlink-parent"
    link_src_root = link_root / "skills/story-setup/references/templates"
    link_src = link_src_root / "agents"
    link_dst = link_root / "skills/story-setup/references/opencode"
    external = tmp / "opencode-external"
    link_src.mkdir(parents=True)
    link_dst.mkdir(parents=True)
    external.mkdir()
    write_agent(link_src / "a.md", "a")
    (link_src_root / "CLAUDE.md.tmpl").write_text("instructions\n", encoding="utf-8")
    (external / "a.md").write_text("external sentinel\n", encoding="utf-8")
    (link_dst / "agents").symlink_to(external, target_is_directory=True)
    before_external = snapshot(external)
    try:
        run_normal(link_root)
    except ValueError:
        pass
    else:
        raise SystemExit("sync-opencode must reject a symlinked agents directory")
    if snapshot(external) != before_external:
        raise SystemExit("sync-opencode followed agents symlink and modified external files")
else:
    print("  [SKIP] symlink-redirection test (host cannot create symlinks)")
PY

echo "  OK OpenCode generated-file failures roll back without replacing the adapter root"

# A stale generated agent that cannot be removed (immutable flag, lock, read-only
# mount) must not abort the rollback: restorable files return to their prior
# bytes, the un-removable file keeps its content, and manual assets stay put.
SYMLINKS_OK="$SYMLINKS_OK" "$PYBIN" - "scripts/sync-opencode.py" "$TMP_DIR" <<'PY'
import importlib.util
import sys
from pathlib import Path

script_path = Path(sys.argv[1]).resolve()
root = Path(sys.argv[2]) / "opencode-immutable-stale"
agents = root / "agents"
agents.mkdir(parents=True)
(agents / "a.md").write_text("old a\n", encoding="utf-8")
(agents / "stale.md").write_text("old stale\n", encoding="utf-8")
(root / "AGENTS.md.tmpl").write_text("old instructions\n", encoding="utf-8")
(root / "plugin.ts").write_text("manual plugin\n", encoding="utf-8")


def snap() -> dict[str, bytes]:
    return {
        path.relative_to(root).as_posix(): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


before = snap()
spec = importlib.util.spec_from_file_location("sync_opencode_immutable", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

real_unlink = Path.unlink
real_copy2 = module.shutil.copy2
# Key the fault on the file's OWN path, not its name: a real immutable file
# still allows being read/copied into the backup dir, so only writes and unlinks
# targeting stale.md itself must fail. Keying on the name would also block the
# backup copy and abort before the rollback path is ever exercised.
victim = (agents / "stale.md").resolve()


def blocked_unlink(self, *args, **kwargs):
    if self.resolve() == victim:
        raise PermissionError("simulated immutable stale file")
    return real_unlink(self, *args, **kwargs)


def blocked_copy2(src, dst, *args, **kwargs):
    if Path(dst).resolve() == victim:
        raise PermissionError("simulated immutable stale file")
    return real_copy2(src, dst, *args, **kwargs)


Path.unlink = blocked_unlink
module.shutil.copy2 = blocked_copy2
try:
    module.publish_tree({"a.md": "new a\n"}, "new instructions\n", root)
except PermissionError:
    pass
else:
    raise SystemExit("sync-opencode did not surface the un-removable stale file")
finally:
    Path.unlink = real_unlink
    module.shutil.copy2 = real_copy2
after = snap()
if after != before:
    raise SystemExit(
        f"sync-opencode rollback left a partial update past an un-removable file: {before} -> {after}"
    )
PY

echo "  OK OpenCode rollback survives an un-removable stale agent file"

"$PYBIN" - <<'PY'
from pathlib import Path
expected = {
    'chapter-extractor', 'character-designer', 'consistency-checker',
    'narrative-writer', 'story-architect', 'story-explorer', 'story-researcher',
}
read_only = {'chapter-extractor', 'consistency-checker', 'story-explorer'}
base = Path('skills/story-setup/references/opencode/agents')
found = {p.stem for p in base.glob('*.md')}
assert found == expected, found
for p in sorted(base.glob('*.md')):
    text = p.read_text()
    assert text.startswith('---\n'), f'{p}: missing frontmatter'
    try:
        fm = text.split('---', 2)[1]
    except IndexError:
        raise AssertionError(f'{p}: malformed frontmatter')
    assert 'mode: subagent' in fm, f'{p}: missing mode: subagent'
    assert 'description:' in fm, f'{p}: missing description'
    assert 'read: allow' in fm, f'{p}: missing read allow'
    assert 'steps:' in fm, f'{p}: missing steps limit'
    if p.stem in read_only:
        assert 'edit: deny' in fm, f'{p}: read-only agent must deny edit'
    else:
        assert 'edit: allow' in fm, f'{p}: write-capable agent must allow edit'
    assert '.claude/skills/story-setup/references/agent-references/' not in text, f'{p}: leaked Claude reference path'
    assert '.opencode/skills/story-setup/references/agent-references/' not in text, f'{p}: stale hidden OpenCode reference fallback'
    if p.stem in {'character-designer', 'consistency-checker', 'narrative-writer', 'story-architect'}:
        assert '{project root}/skills/story-setup/references/agent-references/' in text, f'{p}: missing canonical OpenCode reference path'
PY

echo "  OK agent templates"

# Frontmatter parsing must anchor on a `---` that owns its own line (triple dashes
# inside values must not truncate permission/steps), and Bash in disallowedTools
# must become a real scalar deny: OpenCode returns ask (not deny) when bash
# permission is undeclared, so an edit: deny read-only agent could still write
# prose through shell redirection. No "read-only command" exceptions: upstream
# shell.ts only feeds the command's **direct parent** redirected_statement into
# the check, so `( allowlisted-command ) > prose.md` has a subshell as the direct
# parent and slips past the literal allowlist.
"$PYBIN" - "scripts/sync-opencode.py" <<'PY'
import importlib.util
import sys
from pathlib import Path

script_path = Path(sys.argv[1]).resolve()
spec = importlib.util.spec_from_file_location("sync_opencode_permissions", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

source = (
    "---\nname: a\ndescription: |\n  read-only agent --- 7 Gate.\n"
    "tools: [Read, Glob, Grep]\ndisallowedTools: [Write, Edit, Bash]\nmaxTurns: 9\n"
    "# note --- at the same level as the main skill\n---\nbody\n"
)
fm, body = module.parse_frontmatter(source)
missing = {'name', 'description', 'tools', 'disallowedTools', 'maxTurns'} - set(fm)
assert not missing, f'frontmatter truncated at an inline ---: missing {missing}'
assert body.strip() == 'body', body

# The body is the sole basis for permissions, so it is a required parameter: giving
# it a default would silently change permissions when a caller forgets to pass it.
try:
    module.convert_claude_to_opencode(fm)
except TypeError:
    pass
else:
    raise AssertionError('convert_claude_to_opencode must require the agent body (no default)')

# If a read-only agent's body asks for a command, the generator must fail loudly
# instead of silently opening a shell exception.
try:
    module.convert_claude_to_opencode(
        fm, '**Determine the project root:** run `git rev-parse --show-toplevel`, falling back to the current working directory.\n'
    )
except ValueError as error:
    assert 'git rev-parse --show-toplevel' in str(error), error
else:
    raise AssertionError('restricted agent instructions must not require Bash')

# Body never mentions the command -> emit nothing (a scalar deny also makes
# upstream disabled() drop the bash tool entirely)
plain = module.convert_claude_to_opencode(fm, 'read-only agent, body has no shell steps\n')
assert plain['permission']['bash'] == 'deny', (
    f'read-only agent whose body never asks for a command must get a plain bash deny: {plain}'
)

# The generator must fail loudly rather than silently produce an agent that cannot
# run or was pried open. Body requires any shell command -> generation must abort
# and name the command.
try:
    module.convert_claude_to_opencode(fm, '**Prepare the environment:** run `npm install`, then start the review.\n')
except ValueError as error:
    assert 'npm install' in str(error), error
else:
    raise AssertionError('generator must fail loudly when the body needs an ungranted command')


def bash_rules_in_file_order(fm_text: str):
    """Collect bash rules in **file order** — order is priority, so dict/set won't do.

    Also accepts the scalar form `bash: deny`: upstream fromConfig() expands it
    into a single `*` rule.
    """
    import re
    rules = []
    in_bash = False
    for line in fm_text.split('\n'):
        scalar = re.match(r'^ {2}bash:\s*(\S+)\s*$', line)
        if scalar:
            rules.append(('*', scalar.group(1)))
            in_bash = False
            continue
        if re.match(r'^ {2}bash:\s*$', line):
            in_bash = True
            continue
        if in_bash:
            matched = re.match(r'^ {4}"(.+)":\s*(\S+)\s*$', line)
            if matched:
                rules.append((matched.group(1), matched.group(2)))
                continue
            if line.strip():
                in_bash = False
    return rules


# format_frontmatter must not reorder keys: sorting would silently erase the
# generator's "broad deny first, narrow allow after" ordering. Probe it with a
# reverse-alphabetical insertion order.
probe = {
    'permission': {
        'read': 'allow',
        'bash': {'zzz cmd': 'deny', '*': 'deny', 'aaa cmd': 'allow'},
    }
}
probe_rules = bash_rules_in_file_order(module.format_frontmatter(probe))
assert probe_rules == [('zzz cmd', 'deny'), ('*', 'deny'), ('aaa cmd', 'allow')], (
    f'format_frontmatter reordered permission globs (must preserve dict order): {probe_rules}'
)

# The generator's own output: a read-only agent must carry a non-overridable scalar deny.
generated_rules = bash_rules_in_file_order(module.format_frontmatter(plain))
assert generated_rules == [('*', 'deny')], generated_rules
PY

echo "  OK generator makes read-only Bash unavailable and rejects contradictory instructions"

# Adjudication matrix for generated artifacts (#265 second-round review). This
# independently reimplements upstream opencode v1.18.5's decision logic and
# deliberately does not reuse the same-named functions in sync-opencode.py — if
# the replica itself were wrong, reusing it would let the test fail together with it:
#   util/wildcard.ts     match()
#   permission/index.ts  fromConfig() / evaluate() (findLast) / Permission.ask()
#   tool/shell.ts        source() (whole redirected_statement when redirected) / collect()
"$PYBIN" - <<'PY'
import re
from pathlib import Path


def wildcard_match(value: str, pattern: str) -> bool:
    value = value.replace('\\', '/')
    pattern = pattern.replace('\\', '/')
    escaped = re.sub(r'[.+^${}()|\[\]\\]', r'\\\g<0>', pattern)
    escaped = escaped.replace('*', '.*').replace('?', '.')
    # Upstream comment: a pattern ending in " *" makes the trailing segment
    # optional so "ls *" also matches "ls".
    # This is exactly what lets a prefix glob swallow a whole redirected statement.
    if escaped.endswith(' .*'):
        escaped = escaped[:-3] + '( .*)?'
    return re.match('^' + escaped + '$', value, flags=re.DOTALL) is not None


def evaluate(rules, pattern: str) -> str:
    """findLast: the last matching rule wins; if none match, upstream defaults to ask."""
    action = 'ask'
    for rule_pattern, rule_action in rules:
        if wildcard_match(pattern, rule_pattern):
            action = rule_action
    return action


def resolve(rules, patterns) -> str:
    """Permission.ask(): if any pattern resolves to deny, the whole shell call is rejected."""
    verdict = 'allow'
    for pattern in patterns:
        action = evaluate(rules, pattern)
        if action == 'deny':
            return 'deny'
        if action != 'allow':
            verdict = 'ask'
    return verdict


def bash_rules_in_file_order(fm_text: str):
    rules = []
    in_bash = False
    for line in fm_text.split('\n'):
        scalar = re.match(r'^ {2}bash:\s*(\S+)\s*$', line)
        if scalar:
            rules.append(('*', scalar.group(1)))
            in_bash = False
            continue
        if re.match(r'^ {2}bash:\s*$', line):
            in_bash = True
            continue
        if in_bash:
            matched = re.match(r'^ {4}"(.+)":\s*(\S+)\s*$', line)
            if matched:
                rules.append((matched.group(1), matched.group(2)))
                continue
            if line.strip():
                in_bash = False
    return rules


NEEDED = 'git rev-parse --show-toplevel'
TARGET = 'book/prose/chapter_001.md'
# Each item = (display command, the scan.patterns collect() would produce).
# One shell command may contain several tree-sitter `command` nodes; a redirected
# node contributes the whole redirected_statement text.
ESCAPES = [
    (f'{NEEDED} > {TARGET}', [f'{NEEDED} > {TARGET}']),
    (f'{NEEDED} >> {TARGET}', [f'{NEEDED} >> {TARGET}']),
    (f'{NEEDED} 2> {TARGET}', [f'{NEEDED} 2> {TARGET}']),
    # Upstream source() only inspects the command's direct parent. Wrapped in a
    # subshell/compound, collect() still sees the bare NEEDED pattern and the outer
    # redirection never enters the authorization patterns.
    (f'( {NEEDED} ) > {TARGET}', [NEEDED]),
    (f'{{ {NEEDED}; }} > {TARGET}', [NEEDED]),
    (f'{NEEDED} | tee {TARGET}', [NEEDED, f'tee {TARGET}']),
    (f'{NEEDED} && cat > {TARGET}', [NEEDED, f'cat > {TARGET}']),
    (f'{NEEDED}; rm -rf /', [NEEDED, 'rm -rf /']),
    ('git rev-parse HEAD', ['git rev-parse HEAD']),
    ('git push', ['git push']),
    ('rm -rf /', ['rm -rf /']),
    ("python3 -c 'print(1)'", ["python3 -c 'print(1)'"]),
    ('echo x > chapter_001.md', ['echo x > chapter_001.md']),
    ('bash -c "cat /etc/passwd"', ['bash -c "cat /etc/passwd"']),
]

read_only = {'chapter-extractor', 'consistency-checker', 'story-explorer'}
base = Path('skills/story-setup/references/opencode/agents')
for name in sorted(read_only):
    fm_text = (base / f'{name}.md').read_text(encoding='utf-8').split('\n---\n', 1)[0]
    rules = bash_rules_in_file_order(fm_text)
    assert rules, f'{name}: read-only agent must declare a bash restriction'
    assert rules == [('*', 'deny')], (
        f'{name}: read-only Bash must be a scalar deny without exceptions: {rules}'
    )
    assert resolve(rules, [NEEDED]) == 'deny', (
        f'{name}: bare {NEEDED!r} must also be denied'
    )
    # Reverse direction: redirection/append/stderr/pipe/chain and any unprivileged
    # command must all resolve to deny
    for shown, patterns in ESCAPES:
        got = resolve(rules, patterns)
        assert got == 'deny', (
            f'{name}: `{shown}` resolved to {got!r}, must be deny — a read-only agent'
            f'must not overwrite author prose via redirection/pipe/chain (rules in file order: {rules})'
        )
PY

echo "  OK read-only agents deny bare commands plus redirection/subshell/pipe/chain escapes"

# Generation must be idempotent: two runs produce identical output. Otherwise
# --check would randomly report out-of-sync when nobody touched the templates.
SYMLINKS_OK="$SYMLINKS_OK" "$PYBIN" - "scripts/sync-opencode.py" "$TMP_DIR" <<'PY'
import contextlib
import importlib.util
import io
import shutil
import sys
from pathlib import Path

script_path = Path(sys.argv[1]).resolve()
root = Path(sys.argv[2]) / "opencode-idempotent"
spec = importlib.util.spec_from_file_location("sync_opencode_idempotent", script_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

src = Path("skills/story-setup/references")
dst = root / "skills/story-setup/references"
dst.mkdir(parents=True)
shutil.copytree(src / "templates", dst / "templates")
shutil.copytree(src / "opencode", dst / "opencode")


def snapshot() -> dict[str, bytes]:
    base = dst / "opencode"
    return {
        path.relative_to(base).as_posix(): path.read_bytes()
        for path in sorted(base.rglob("*"))
        if path.is_file()
    }


def run() -> None:
    old_root, old_argv = module.ROOT, sys.argv
    module.ROOT = root
    sys.argv = [str(script_path)]
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            module.main()
    finally:
        module.ROOT, sys.argv = old_root, old_argv


run()
first = snapshot()
run()
second = snapshot()
if first != second:
    drift = sorted(key for key in set(first) | set(second) if first.get(key) != second.get(key))
    raise SystemExit(f"sync-opencode.py is not idempotent; drifting files: {drift}")
PY

echo "  OK generation is idempotent (second run is byte-identical)"

"$PYBIN" - <<'PY'
from pathlib import Path
skill_names = {p.parent.name for p in Path('skills').glob('*/SKILL.md')}
command_names = {p.stem for p in Path('skills/story-setup/references/opencode/commands').glob('*.md')}
assert skill_names == command_names, f'missing={skill_names-command_names}, extra={command_names-skill_names}'
for p in sorted(Path('skills/story-setup/references/opencode/commands').glob('*.md')):
    text = p.read_text()
    assert text.startswith('---\n'), f'{p}: missing frontmatter'
    fm = text.split('---', 2)[1]
    assert 'description:' in fm, f'{p}: missing description'
    assert f'Use the {p.stem} skill' in text, f'{p}: command body must route to same skill'
PY

echo "  OK slash command templates"

assert_grep 'experimental\.session\.compacting' "$ROOT/plugin.ts" "OpenCode plugin must inject pre-compact context"
assert_grep 'tool\.execute\.before' "$ROOT/plugin.ts" "OpenCode plugin must guard tool writes"
assert_grep 'proseBlockReason' "$ROOT/plugin.ts" "OpenCode plugin must keep outline-before-prose guard"
assert_grep 'tool\.execute\.after' "$ROOT/plugin.ts" "OpenCode plugin must run the prose backstop after writes"
assert_grep 'proseAfterWrite' "$ROOT/plugin.ts" "OpenCode plugin must surface backstop findings on the write result"
assert_grep 'from "\./lib/story_hook_core\.js"' "$ROOT/plugin.ts" "OpenCode plugin must consume the shared prose-guard core"
# CI has no opencode CLI to actually load the plugin, so this is a structural proxy: the
# deploy manifest must place the core under .opencode/plugins/lib/, never flat in
# .opencode/plugins/ (a flat *.js there is auto-loaded by OpenCode as a broken second plugin).
assert_grep '\.opencode/plugins/lib/story_hook_core\.js' "$REPO_ROOT/skills/story-setup/SKILL.md" "SKILL.md deploy manifest must target .opencode/plugins/lib/story_hook_core.js, not a flat .opencode/plugins/story_hook_core.js"
assert_grep 'prose/' "$ROOT/plugin.ts" "OpenCode plugin must inspect prose targets"
assert_grep '@opencode-ai/plugin' "$ROOT/plugin.ts" "OpenCode plugin must import OpenCode plugin types"
# The shared prose-guard core (light net / outline guard / wordcount·landing·dup-title) deploys
# alongside plugin.ts and is imported by it; it must be byte-identical to the ZCode copy and valid JS.
ZCODE_CORE="$REPO_ROOT/skills/story-setup/references/zcode/hooks/story_hook_core.js"
cmp -s "$ROOT/story_hook_core.js" "$ZCODE_CORE" || fail "story_hook_core.js drifted from the ZCode copy (must be byte-identical)"
node --check "$ROOT/story_hook_core.js" || fail "story_hook_core.js is not valid JavaScript"
assert_grep 'proseNetFindings' "$ROOT/story_hook_core.js" "shared core must carry the light prose net (parity with codex/claude)"
# #242: runtime behavioral test — actually loads the plugin against the deployed core layout and
# exercises the before/after/compacting hooks (stronger than the structural greps above).
node --experimental-strip-types scripts/test-opencode-plugin.mjs
assert_grep 'AGENTS\.md|OpenCode' "$ROOT/AGENTS.md.tmpl" "OpenCode AGENTS template must be present"
assert_grep 'story-long-write|story-short-write|story-review' "$ROOT/AGENTS.md.tmpl" "OpenCode AGENTS template must mention story skill routing"

echo "  OK plugin behavior and instruction anchors"
echo ""
echo "OK: OpenCode adapter checks passed"
