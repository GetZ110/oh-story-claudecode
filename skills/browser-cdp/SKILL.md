---
name: browser-cdp
description: "Use this skill when you need to control a Chrome browser via CDP (Chrome DevTools Protocol) to reuse existing login sessions. Covers: launching Chrome in debug mode, opening URLs, waiting for page load, evaluating JavaScript, taking snapshots, and extracting auth tokens. Trigger phrases: browser automation, CDP, agent-browser, Chrome CDP, reuse login session, extract token from browser."
metadata: {"openclaw":{"requires":{"bins":["agent-browser"]},"source":"https://github.com/worldwonderer/oh-story-claudecode"}}
---
# Browser CDP Operations

Control Chrome over the CDP protocol, reuse existing login sessions, and run browser automation.

## Prerequisites

- macOS / Linux / Windows (experimental), Google Chrome installed
- Node.js 20+
- `agent-browser` installed: `npm install -g agent-browser`

> **First launch kills the user's regular Chrome.** You must get the user's consent before launching (see "Launch flow" below); otherwise the user may lose unsaved tabs/drafts.

---

## Launch flow (mandatory steps in skill mode)

**Step 1: probe the current state (no side effects)**

```bash
node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --detect-only
```

Output looks like:

```
CDP_STATUS=ready                        # ready; can reuse directly
CDP_URL=http://127.0.0.1:9222/json/version
BROWSER=Chrome/148.0.7778.168
```

or:

```
CDP_STATUS=needs-setup
CHROME_RUNNING=yes                      # user has Chrome running; launching will kill it
CHROME_PID_COUNT=3
```

**Step 2: branch on the probe result**

- `CDP_STATUS=ready` -> use `agent-browser --cdp 9222 ...` directly; **do not run setup**.
- `CDP_STATUS=needs-setup` and `CHROME_RUNNING=no` -> safe launch:
  ```bash
  node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --yes
  ```
- `CDP_STATUS=needs-setup` and `CHROME_RUNNING=yes` -> **confirm with the user first via the AskUserQuestion tool**: tell them N Chrome processes will be killed and unsaved work may be lost; launch with `--yes` only after consent; if the user declines, abandon this automation round.

**Why not just `--yes`:** in a non-TTY context (skill mode / Bash tool), if the script detects Chrome running without `--yes`, it exits with code 3 reporting `NEEDS_CONSENT: ...` and aborts — it will **not** silently kill processes. This is an intentional backstop — but the skill flow should still ask the user first, not blindly pass `--yes` when it sees exit code 3.

---

## Launch script options

| Option | Description |
|--------|-------------|
| `--detect-only` | probe only; change nothing (skill use) |
| `--yes` | consent already given; skip the interactive prompt |
| `--reset` | wipe `~/chrome-debug-profile` before launch (use when login has expired) |
| `--profile <name>` | use a non-Default Chrome profile (e.g., `"Profile 1"`) |
| `--dry-run` | print the steps that would run; don't run them |

Exit codes: `0` success / `1` general error / `2` user declined (TTY) / `3` consent needed but `--yes` missing.

---

## Common operations

### Open a page and wait for load

```bash
agent-browser --cdp 9222 open "<URL>"
agent-browser --cdp 9222 wait 3000
```

### Extract page text

```bash
agent-browser --cdp 9222 eval 'document.body.innerText.substring(0, 8000)'
```

### Extract an auth token

```bash
agent-browser --cdp 9222 eval 'localStorage.getItem("token") || document.cookie'
```

### Complex JS (quotes / `$` / backticks)

Shell escaping is error-prone; use one of these two:

```bash
# 1) base64 wrapper
agent-browser --cdp 9222 eval -b "$(echo -n "document.querySelectorAll('a').length" | base64)"

# 2) heredoc + --stdin
cat <<'EOF' | agent-browser --cdp 9222 eval --stdin
const links = document.querySelectorAll('a');
links.length;
EOF
```

### Page interaction (snapshot for element refs)

```bash
agent-browser --cdp 9222 snapshot -i        # interactive elements only
agent-browser --cdp 9222 click "<CSS or @e1>"
agent-browser --cdp 9222 type "<sel>" "<text>"
```

---

## Stop / clean up

- Close the debug Chrome window (or `pkill -9 -x 'Google Chrome'` / `taskkill /F /IM chrome.exe`).
- Login expired: `node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --reset --yes` (note: `--yes` also requires asking the user first).

---

## OpenCode environment notes

opencode has no background command-line tool; long CDP operations (waiting for page load, bulk scraping) block the whole session and the CLI stops responding.

### Timeout wrapper

On Windows, wrap CDP commands in a PowerShell Job with a timeout:

```powershell
$job = Start-Job { agent-browser --cdp 9222 eval "window.location.replace('https://www.royalroad.com/rankings/')" }
Wait-Job $job -Timeout 30 | Out-Null
if ($job.State -eq 'Running') { Stop-Job $job; Write-Output "CDP operation timed out (30s); retry or interrupt manually" }
else { Receive-Job $job }
Remove-Job $job -Force
```

On macOS / Linux use the `timeout` command:

```bash
timeout 30 agent-browser --cdp 9222 eval "window.location.replace('https://www.royalroad.com/rankings/')" || echo "CDP operation timed out (30s); retry or interrupt manually"
```

### Known limitations

Even with the timeout wrapper, these scenarios can still fail:

| Scenario | Risk | Mitigation |
|----------|------|------------|
| Page load timeout | eval waits forever | 30s timeout; retry after timeout |
| Bulk data scraping | cumulative waits across pagination | per-page independent timeouts; resume from the breakpoint after failure |
| Chrome process stuck | CDP connection drops but the process lingers | clean with `pkill` / `taskkill`, then reconnect |
| Network fluctuation | requests hang with no timeout | retry once automatically after timeout |

If an operation keeps hanging in opencode, press `ESC` to interrupt manually.

---

## FAQ

| Problem | Solution |
|---------|----------|
| `NEEDS_CONSENT` + exit code 3 | ask the user via AskUserQuestion whether killing Chrome is OK; on consent re-run with `--yes` |
| CDP port not listening | re-check with `--detect-only`; port busy -> use another port |
| Page redirected to login | `snapshot -i` to find the login button and operate it |
| `eval` returns `null` | check the localStorage key name; quote-heavy JS uses `eval -b` or `--stdin` |
| Login expired | `setup-cdp-chrome.js 9222 --reset --yes` to re-copy |
| Multiple Chrome profiles | specify with `--profile "Profile 1"` |
| Chrome won't start (30s timeout) | try `--reset`; check port conflicts; check whether `~/chrome-debug-profile/` is corrupted |
