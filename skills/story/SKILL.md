---
name: story
description: "Main entry for the web-fiction toolbox. Routes user needs to the matching skill and can launch the local Dashboard for browsing teardown libraries, writing projects, and editing text. Trigger phrases: /story, $story, /story dashboard, $story dashboard, web fiction toolbox, I want to write a novel, open the workbench, check for updates."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story: Web-fiction toolbox router

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. Keep English novel prose and other project artifacts in the language declared by the book contract or explicitly requested by the user.

### Agent bundle preflight

The current deployment contract is `agents_version: 23`. A version mismatch does not block spawning: continue checking the deployed files and emit `Notice: agents bundle version mismatch`. If the deployed version is greater than 23, tell the user to update oh-story-claudecode first. only missing or unavailable custom agents trigger solo/direct fallback.

You are the routing entry of the web-fiction toolbox. When the user's request is vague, you dispatch it to the concrete skill.

## Routing table

> Codex CLI prefers `$story-*` or `/skills`; Claude Code / OpenCode keep using `/story-*`; OpenClaw may use `/skill story-*` or name the skill in natural language. The table shows slash commands; Codex may substitute `/story-long-write` with `$story-long-write`, OpenClaw with `/skill story-long-write`.

| User intent | Keyword examples | Route to |
|---|---|---|
| Start a novel | start a novel, open a book, outline, long-form, serialize | `/story-long-write` |
| Write a short story | short fiction, episode, 10k words | `/story-short-write` |
| Deconstruct a long-form book | deconstruct this book, break down this novel, analyze this book, first-three-chapters study | `/story-long-analyze` |
| Deconstruct a short story | deconstruct this story, analyze this episode | `/story-short-analyze` |
| Long-form market scan | scan rankings, what's hot, Royal Road lists, webnovel rankings | `/story-long-scan` |
| Topic decision | what should I write, help me pick a topic, topic direction | `/story-long-scan` |
| Short-form market scan | short-fiction rankings, what's hot in short fiction, wattpad trends | `/story-short-scan` |
| De-AI flavor | de-AI, too AI, clean the AI flavor, polish the prose | `/story-deslop` |
| Review a manuscript | review, review my chapter, consistency check, find problems | `/story-review` |
| Cover | cover, cover image, make a cover | `/story-cover` |
| Environment setup | prepare to write, set up the environment, initialize | `/story-setup` |
| Browser automation | browser, scrape, logged-in session, CDP | `/browser-cdp` |
| Import a novel | import, reverse-parse, import my book | `/story-import` |
| Dashboard | dashboard, workbench, browse teardown library, open project panel | see "Dashboard workbench" below |
| Check / update version | check for updates, is there a new version, upgrade, update the toolbox | see "Version update check" below |
| Switch / list books | switch book, change book, list my books, which books am I writing, switch project | see "Multi-book switching" below |
| Story explorer | check a character, check foreshadowing, check progress, check setting, what's the status, where did I leave off | spawn `story-explorer` agent (structured prompt: `Project directory: {dir}\nQuery type: {chosen per intent}\nQuery parameters: {user query}`); when the agent is unavailable, see "Query degradation" below |
| Research | research, look it up, investigate, search | spawn `story-researcher` agent; when unavailable, see "Query degradation" below |

### Import-then-continue order

When the user asks "for import and continuation, setup or import first?", answer directly: **recommend `/story-setup` first, then `/story-import` in a fresh/new session, then `/story-long-write daily` or `/story-long-write chapter N`**. If the user already triggered `/story-import` directly, follow story-import's own environment detection: when not set up, let the user choose to set up first or continue the serial import.

## Dashboard workbench

When the user runs `/story dashboard` (Codex: `$story dashboard`) or explicitly says "open the workbench / browse the project files", launch the local Dashboard shipped with this skill directly; don't forward to another skill:

1. Use the **current working directory** as the default workspace; when the user gives a directory explicitly, use that instead. The directory must exist.
2. Locate `scripts/dashboard-server.mjs` from the currently loaded `story` skill directory; never hardcode repo paths, global skill paths, or the user home directory.
3. After confirming `node` is available, run it as a long-running process:

   ```bash
   node "<story-skill-dir>/scripts/dashboard-server.mjs" --root "<workspace>" --open
   ```

4. Wait for the "local address" output and return the full URL to the user. When the tool supports background processes/PTY, keep the service running; failing to auto-open the browser is not a failure — still return a clickable URL.
5. The Dashboard listens on `127.0.0.1` by default. Do not add `--allow-network` proactively; never expose the workspace to the LAN or public internet.

The workbench recognizes the standard `teardown-lib/{BookTitle}/` layout and the legacy-compatible `teardown-lib-{BookTitle}/`. Writing-project detection supports both:

- Long-form directory structure: a directory containing any of `prose/`, `outline/`, `setting/`, `tracking/` as an ordinary subdirectory.
- Short-form single-file structure: a directory containing the plain file `prose.md`, together with `section-outline.md` or `setting.md`.

Symlinks are not project markers; a plain data directory with only `prose.md` is not misidentified either. The browser can edit `.md`, `.txt`, `.json`, `.yaml`, `.yml`, `.toml`; saves and confirmed deletions are guarded by modification times to avoid clobbering external updates.

To stop the service, terminate the corresponding long-running Node process. If the user only asks how to use it, don't launch it for them; give the two platform entries `/story dashboard` / `$story dashboard`.

## Routing flow

1. Analyze the user request and extract intent keywords
2. Match the table and find the skill
3. On a clear match, call the skill directly (Claude/OpenCode: `Skill("skill-name")` or slash command; Codex: `$skill-name` / `/skills`; OpenClaw: `/skill skill-name` or natural-language naming)
4. On no match, ask the user what they want to do (choose from the table)
5. If the user says "I want to write a novel" without specifying long-form or short-form, ask about length first, then route

## Query degradation

"Story explorer" and "research" do a light availability check before spawning (the router only does this layer; it is not the global deployment policy): not inside a subagent context, the Agent/Task tool is available, and `.claude/agents/{story-explorer|story-researcher}.md`, `.opencode/agents/{story-explorer|story-researcher}.md`, or `.codex/agents/{story-explorer|story-researcher}.toml` exists -> may attempt spawn. If any condition fails, or the Codex runtime returns `unknown agent_type` / does not expose a custom-agent registry, degrade instead of hard-failing:

- `story-explorer` unavailable -> the main thread searches project files directly with Read/Grep (character state / foreshadowing / progress / setting) and labels the answer `Fallback: agent unavailable -> direct lookup`; if the project isn't deployed yet, prompt `/story-setup` first (Codex: `$story-setup`).
- `story-researcher` unavailable -> complete with the main thread's own search/answer capability, or suggest `/browser-cdp` collection, also labeled `Fallback: agent unavailable -> direct lookup`.

## Project state awareness

Check the project state before routing:

- **No project directory** (no book directory containing `tracking/` or `setting/`):
  - Writing requests -> next step is `/story-setup` to initialize (Codex: `$story-setup`)
  - Scan/teardown requests -> route directly
- **Project exists**: check the `.story-deployed` marker; if not deployed, run `/story-setup` first (Codex: `$story-setup`)

## Multi-book switching

When the user wants to switch books or see what's in progress (one project may hold several books):

1. Find all book directories under the project root: directories containing a `tracking/` or `setting/` subdirectory (including subdirectories under any book grouping folders).
2. List the titles, marking which one `.active-book` currently points to.
3. Let the user choose; write the selected book's relative path into the project-root `.active-book` (overwriting the old content).
4. With only one book found, confirm it as the active book without asking.

## Version update check

Run when the user asks "is there a new version" / "check for updates" / "upgrade". **Notify only; updating is the user's call, never auto-install.**

1. **Current version**: read the `VERSION` file in this skill's directory; missing = unknown.
2. **Latest version**: prefer `gh release view --json tagName,name,url -R GetZ110/oh-story-claudecode` for `tagName`; without `gh`, use `curl -fsS --max-time 5 https://api.github.com/repos/GetZ110/oh-story-claudecode/releases/latest` for `.tag_name` (jq or grep). Unreachable -> tell the user "couldn't fetch the latest version; check [Releases](https://github.com/GetZ110/oh-story-claudecode/releases) manually", no error.
3. **Compare**: strip the `v` prefix and compare semantically (major.minor.patch). `gh release` defaults to the latest stable release, excluding pre-releases.
4. **Inform**:
   - Already latest -> "You are on the latest version vX.Y.Z".
   - New version -> list current vA -> latest vB + [Releases](https://github.com/GetZ110/oh-story-claudecode/releases)/[CHANGELOG](https://github.com/GetZ110/oh-story-claudecode/blob/main/CHANGELOG.md) (attach this release's notes when obtainable), then use AskUserQuestion to ask "Update now?":
     - Update -> run `npx skills add GetZ110/oh-story-claudecode -y -g` (`-g` is global; drop it to update only the current directory); when done, remind: deployed projects should re-run `/story-setup` at the project root (Codex: `$story-setup`) to sync hooks/agents/references, and **start a new session** so agents re-register.
     - Not now -> leave everything; tell the user they can ask again anytime.
