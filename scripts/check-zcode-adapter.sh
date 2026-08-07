#!/usr/bin/env bash
# Deterministic checks for the ZCode plugin and story-setup deployment surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "required file missing: $1"; }
assert_grep() { grep -Eq "$1" "$2" || fail "$3 ($2)"; }

# Probe a working python interpreter (Windows python3 may be the Store stub).
PYBIN=""
for c in python3 python py; do "$c" -c "" >/dev/null 2>&1 && { PYBIN="$c"; break; }; done
[ -n "$PYBIN" ] || { echo "FAIL: no working python interpreter (tried python3 python py)" >&2; exit 1; }

ROOT="skills/story-setup/references/zcode"
HOOK="$ROOT/hooks/story_zcode_hook.js"
HOOK_CORE="$ROOT/hooks/story_hook_core.js"

echo "ZCode adapter check"
echo "==================="
echo "Repo: $REPO_ROOT"

for file in \
  .zcode-plugin/plugin.json \
  marketplace.json \
  "$ROOT/AGENTS.md.tmpl" \
  "$ROOT/config.json.patch" \
  "$ROOT/hooks/hooks.json" \
  "$HOOK" \
  "$HOOK_CORE"; do
  assert_file "$file"
done

for file in .zcode-plugin/plugin.json marketplace.json "$ROOT/config.json.patch" "$ROOT/hooks/hooks.json"; do
  "$PYBIN" -m json.tool "$file" >/dev/null
done
node --check "$HOOK"
node --check "$HOOK_CORE"
echo "  OK JSON/JavaScript syntax"

"$PYBIN" - <<'PY'
import json, re
from pathlib import Path

plugin = json.loads(Path('.zcode-plugin/plugin.json').read_text())
assert re.fullmatch(r'[a-z0-9][a-z0-9._-]{0,127}', plugin['name'])
assert plugin['name'] == 'oh-story'
assert plugin['skills'] == 'skills'
assert plugin['commands'] == 'skills/story-setup/references/zcode/commands'
assert plugin['hooks'] == 'skills/story-setup/references/zcode/hooks/hooks.json'
for key in ('agents', 'channels', 'lspServers', 'outputStyles', 'settings'):
    assert key not in plugin, f'non-runnable ZCode component declared: {key}'

market = json.loads(Path('marketplace.json').read_text())
assert market['name'] == 'oh-story-zcode'
assert market['version'] == 1
assert len(market['plugins']) == 1
entry = market['plugins'][0]
assert entry['name'] == plugin['name'] and entry['source'] == './'
assert entry['version'] == plugin['version']
assert plugin['version'] == Path('skills/story/VERSION').read_text().strip()
PY
echo "  OK native plugin/marketplace manifest"

"$PYBIN" - <<'PY'
import re
from pathlib import Path

skills = sorted(Path('skills').glob('*/SKILL.md'))
commands = sorted(Path('skills/story-setup/references/zcode/commands').glob('*.md'))
assert len(skills) == 13, f'expected 13 skills, got {len(skills)}'
assert len(commands) == 13, f'expected 13 commands, got {len(commands)}'
expected = {p.parent.name for p in skills}
assert {p.stem for p in commands} == expected

for skill in skills:
    text = skill.read_text(encoding='utf-8')
    front = text.split('---', 2)[1]
    name = re.search(r'^name:\s*["\']?([^"\'\n]+)', front, re.M)
    desc = re.search(r'^description:\s*(.+)$', front, re.M)
    assert name and name.group(1).strip() == skill.parent.name, skill
    assert desc, f'{skill}: missing description'
    value = desc.group(1).strip().strip('"\'')
    assert len(value) <= 1024, f'{skill}: description too long'

allowed = {'description', 'argument-hint', 'allowed-tools', 'model', 'skills', 'disable-noninteractive'}
for command in commands:
    assert re.fullmatch(r'[a-z0-9][a-z0-9_:-]{0,63}', command.stem), command
    text = command.read_text(encoding='utf-8')
    assert text.startswith('---\n'), command
    front, body = text.split('---', 2)[1:]
    keys = {line.split(':', 1)[0] for line in front.splitlines() if ':' in line}
    assert keys <= allowed, f'{command}: unsupported keys {keys - allowed}'
    assert 'description' in keys and 'skills' in keys
    assert '$ARGUMENTS' in body
PY
echo "  OK 13 Skills + 13 Commands (schema and one-to-one names)"

"$PYBIN" - <<'PY'
import json
from pathlib import Path

supported = {'SessionStart', 'UserPromptSubmit', 'PreToolUse', 'PermissionRequest', 'PostToolUse', 'PostToolUseFailure', 'Stop'}
# event → allowed handlers. Validating handler names by set membership alone
# ("the name is in the allowlist") would let a whole-block copy-paste that forgot to
# change args[1] pass, e.g. SessionStart wired to post-tool-prose-check:
# story_zcode_hook.js dispatches only on process.argv[2] and never compares
# hook_event_name, so the session start would silently skip the context injection /
# the after-write check would receive the wrong payload and report nothing. Every
# event must be locked to its handler.
EVENT_HANDLERS = {
    'SessionStart': {'session-start'},
    'PreToolUse': {'pre-tool-prose-guard', 'pre-tool-commit-advisory'},
    'PostToolUse': {'post-tool-prose-check'},
}
plugin = json.loads(Path('skills/story-setup/references/zcode/hooks/hooks.json').read_text())['hooks']
config = json.loads(Path('skills/story-setup/references/zcode/config.json.patch').read_text())['hooks']
assert config['enabled'] is True
assert set(plugin) == set(EVENT_HANDLERS)
assert set(config['events']) == set(plugin)
assert set(plugin) <= supported

def flatten(events):
    # The event name must be carried along: dropping the event key would make it
    # impossible to bind the handler back to the event it serves.
    return [(event, hook) for event, groups in events.items() for group in groups for hook in group['hooks']]

plugin_hooks = flatten(plugin)
workspace_hooks = flatten(config['events'])
assert len(plugin_hooks) == len(workspace_hooks) == 4
expected_routes = {(event, handler) for event, handlers in EVENT_HANDLERS.items() for handler in handlers}
# The two registrations are checked independently: drifting by editing only
# hooks.json without config.json.patch (or vice versa) must also turn red. They are
# maintained by hand separately, and check-shared-files.sh deliberately excludes
# hooks.json from byte parity.
for source, pairs in (('hooks.json', plugin_hooks), ('config.json.patch', workspace_hooks)):
    for event, hook in pairs:
        assert set(hook) <= {'type', 'command', 'args', 'timeoutMs'}
        assert hook['type'] == 'process' and hook['command'] == 'node'
        assert hook['args'][1] in EVENT_HANDLERS[event], (
            f'{source}: {event} routed to the wrong handler', hook['args'][1], sorted(EVENT_HANDLERS[event]))
    routes = {(event, hook['args'][1]) for event, hook in pairs}
    assert routes == expected_routes, (
        f'{source}: event→handler registration drift', sorted(expected_routes - routes), sorted(routes - expected_routes))
post_groups = plugin['PostToolUse']
assert len(post_groups) == 1 and post_groups[0]['matcher'] == 'Bash|Write|Edit|ApplyPatch'
# Routing test (guards against a false green from "calling the runner directly,
# bypassing the matcher"): the pre-tool-prose-guard matcher must agree between the
# plugin and the workspace config, and must route every tool test-zcode-hooks feeds
# it — including ApplyPatch (apply-patch prose targets must really be sent into the
# handler by the matcher, not just be interceptable by a direct runner call).
import re
def prose_guard_matcher(events):
    for group in events['PreToolUse']:
        if any(h['args'][1] == 'pre-tool-prose-guard' for h in group['hooks']):
            return group['matcher']
    return None
mc = prose_guard_matcher(config['events'])
mp = prose_guard_matcher(plugin)
assert mc is not None and mc == mp, ('pre-tool-prose-guard matcher drift between config and plugin', mc, mp)
for tool in ('Bash', 'Write', 'Edit', 'ApplyPatch'):
    assert re.search(mc, tool), ('pre-tool-prose-guard matcher does not route tool', tool, mc)
for _event, hook in plugin_hooks:
    assert hook['args'][0].startswith('${ZCODE_PLUGIN_ROOT}/')
for _event, hook in workspace_hooks:
    assert hook['args'][0] == '${ZCODE_PROJECT_DIR}/.zcode/hooks/story_zcode_hook.js'
PY
echo "  OK supported events + strict process-hook shape"

if grep -RqsE 'PreCompact|PostCompact|SessionEnd|SubagentStop|Notification' "$ROOT/hooks" "$ROOT/config.json.patch"; then
  fail "ZCode adapter contains unsupported hook events"
fi
[ ! -e "$ROOT/agents" ] || fail "ZCode 3.3.4 must not ship project agents"
[ ! -e "$ROOT/rules" ] || fail "ZCode has no .zcode/rules discovery surface"

assert_grep '\$story-long-write|\$story-setup' "$ROOT/AGENTS.md.tmpl" 'ZCode AGENTS template must document $skill invocation'
assert_grep 'project custom agents unavailable.*solo' "$ROOT/AGENTS.md.tmpl" "ZCode AGENTS template must document solo fallback"
assert_grep 'target_cli = zcode|target_cli.*zcode' skills/story-setup/SKILL.md "story-setup must document zcode target_cli"
assert_grep 'references/zcode/config\.json\.patch' skills/story-setup/SKILL.md "story-setup manifest missing ZCode config patch"
# Combined-install verification proxy (CI has no ZCode runtime): the plugin
# manifest and the workspace config register the same hooks, so the deployment
# algorithm must record their mutual exclusion (plugin installed → skip the config
# hooks merge), otherwise PreToolUse/PostToolUse double-fire.
assert_grep 'Hooks mutual exclusion|mutual exclusion' skills/story-setup/SKILL.md "story-setup must document the plugin/workspace hooks mutex (skip config hooks merge when plugin installed, avoid double-firing)"
assert_grep '\.zcode/skills/story-setup/references/agent-references' skills/story-setup/SKILL.md "story-setup missing ZCode reference path"

for skill in story-long-write story-short-write story-long-analyze story-import story-deslop story-review; do
  assert_grep 'ZCode 3\.3\.4|\.zcode/' "skills/$skill/SKILL.md" "$skill must document ZCode fallback"
done

echo "  OK deployment instructions + explicit capability boundaries"
echo ""
echo "OK: ZCode adapter checks passed"
