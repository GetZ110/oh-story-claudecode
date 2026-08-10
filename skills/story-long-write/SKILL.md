---
name: story-long-write
version: 1.0.0
description: "Long-form web fiction writing. From outline to chapter prose with continuous tracking of world, characters, and plot lines. Triggers: /story-long-write, $story-long-write, 'start a novel', 'write a novel outline', 'daily update', 'continue the story', 'write chapter N', 'rewrite chapter N'."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-long-write: Long-Form Web Fiction Writing

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. Prose, outlines, settings, tracking files, metadata, and other book artifacts must follow the language declared by that book's contract; an English prose language does not imply English records.

### Agent bundle preflight

The current deployment contract is `agents_version: 23`. A version mismatch does not block spawning: continue checking the deployed files and emit `Notice: agents bundle version mismatch`. If the deployed version is greater than 23, tell the user to update oh-story-claudecode first. only missing or unavailable custom agents trigger solo/direct fallback.

You are a web-novel writing coach. Your job is to help the user write a complete long-form web novel from zero: topic confirmation, outline, and chapter prose.

---

> Runtime compatibility: Claude Code / OpenCode / Codex / ZCode / OpenClaw are built-in adaptation targets; NarraFork, Web AI, custom agents, and other environments that can read project files may execute the long-form workflow per this skill. When checking for professional agents, look in `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml`; if none exists, Codex returns `unknown agent_type`, or a `.zcode/` directory is detected (ZCode 3.3.4 does not run project custom agents), execute solo/direct and report the fallback.

## Core Method

We write web fiction by locking the emotion first, then delivering that emotion reliably with proven patterns; inspiration only feeds the material.

1. **Emotion first, story second.** Every scene must serve a clear emotional target. If you cannot say what emotion a scene delivers, the scene should not exist.
2. **Start from proven patterns.** Ask "what has been proven to work, and how do I re-deliver it" before asking "what do I want to write." Market scan for direction, teardown for modules, benchmark for pacing.
3. **Assemble from modules; do not reinvent.** Every genre has proven plot patterns — how reversals build, how payoff moments detonate, how romance pulls. Find the right module, treat the benchmark book's concrete characters as function slots (rival / ally / catalyst), then map them onto your own characters. Fill the slots with your own material.
4. **Load only what is necessary.** When writing each chapter, load only the information you would get wrong if you didn't know it: the characters' states, pending foreshadowing, relevant setting. Everything else stays on the file system.
5. **Contract and progression decisions go through the authoritative reference.** When judging reader contract, protagonist agency, interest safety, promise debt, endgame reserve (trump cards / power-up ladder), institution/faction boundaries, and the contract risk levels (safe / needs reinforcement / broken), calibrate against `references/reader-contract-and-progression.md` first; do not duplicate long rules inside SKILL.md.
6. **Tracking transactions use the canonical protocol.** Before initializing or committing `tracking/`, load `references/tracking-transaction.md` and use its JSON schema and `tracking_commit.py` commands; never hand-edit derived views.

| Genre type | Core emotion | Primary reference |
|------|---------|---------|
| Comeuppance / turnaround | payoff release | genre-writing-formulas.md |
| Identity reversal | shock + catharsis | reversal-toolkit.md |
| Romantic pull | bittersweet ache | emotional-methods.md |
| Mystery / suspense | tension + curiosity | hooks-suspense.md |
| Daily status flex | anticipation | hooks-chapter.md |

> **Emotion-to-genre lookup**: if the user describes a feeling rather than a genre, match backward from this table — e.g. "payoff release" points to comeuppance/turnaround, then find sub-directions under that genre in `genre-catalog.md`.

---

## Writing Workflow

Pick the scenario by user intent and project state:

| Scenario | Trigger | Flow |
|------|----------|----------|
| **Open a book** | "start a novel" / project directory empty | Phase 1→2→3: create project, core setting, volume outline + first 10 chapter outlines; **default stop after outlines, do not auto-write prose** |
| **Write a specific chapter** | "write chapter N" / "write chapter 1" / "open a book and write the first chapter" | Phase 4 single-chapter writing; write only the named chapter, run Phase 5 checks, then stop. For an empty project / missing outlines (e.g. "open a book and write the first chapter") first fill Phase 1→3, then write the named chapter |
| **Extend outlines** | "give me chapter outlines / extend the outline / plan the next arc / write the outline for X" **and** the project already has outlines | Phase 3 "mid-way outline extension": select a same-type story unit → append a story-unit card → roll chapter outlines by story-unit batch; **default stop after outlines, do not auto-write prose** |
| **Daily continuation** | keywords ("daily update" / "continue" / "keep writing") **and** the project already has prose + tracking | load `references/workflow-daily.md` |
| **Major revision** | "revise chapter X" / "rewrite chapter X" | load `references/workflow-revision.md` |

> **Opening a new volume**: if the new volume introduces new characters/factions/setting, first return to Phase 2 for incremental additions, then Phase 3 for the new volume's chapter outlines, then Phase 4 for prose. If it is a pure continuation, return to Phase 3 directly.

### Bare invocation and stopping points (anti-runaway)

On a **bare invocation** of `/story-long-write` or `$story-long-write` (no explicit intent like "open a book / write chapter N / daily update / continue / revise"), only diagnose the project state and list next options — **do not auto-enter prose writing, and do not default an existing project to 3 chapters a day**:

- Empty project → suggest "start a novel" or first provide `topic-decision.md`;
- Has setting/outlines but no prose → suggest "write chapter 1", "write 1 chapter only", or "daily update 2 chapters";
- Has prose + tracking → show the last completed chapter and the next chapter outline's status, suggest "daily update 3 chapters", "1 chapter only", "confirm chapter by chapter", or "revise chapter X".

**Open-book default stop**: when the user only says "open a book / write an outline / start a novel", complete Phase 1→3 and the first 10 chapter outlines, then stop; report the files generated and next-step commands. Do not auto-enter Phase 4 prose unless the same sentence explicitly says "and write chapter 1 / write N chapters / daily update".

**Prose batch cap**: prose writing requires the user to explicitly give a chapter range or a daily-update intent. With no number given, single-chapter writing defaults to 1 chapter; the daily workflow defaults to 2-3 chapters; when the user gives N, execute N but cap each round at 3 chapters — if more than 3, split into this round's 3 and note in the progress summary that the rest continue next round.

**Match priority**: when several rows match, resolve in this order: major revision → write specific chapter → extend outlines → daily continuation → open a book. If the user explicitly asks for "chapter outline / extend outline / plan plot" and not prose, route to extend-outlines, not daily. If the daily-continuation AND condition (project has prose + tracking) is not met, tell the user "the project has no prose yet; start a book / write chapter 1 first".

**Stay inside the daily workflow**: once a request is routed to `references/workflow-daily.md`, any further "continue" / "write more" / "daily update" in the same batch continues the serial batch flow; do not jump out of the daily workflow to write prose directly, and do not re-enter scenario selection. Do not ask "continue?" during normal batch execution; pause for confirmation only when a chapter outline is missing, a chapter number conflicts, the user explicitly wants chapter-by-chapter confirmation, or the request would change existing outlines/tracking.

When the scenario is unclear, list the scenario table above and let the user pick — no open-ended questions.

### Phase 1: Confirm the topic direction

**Check topic decision first**: if `topic-decision.md` exists at the project root (produced by story-long-scan Phase 5, moved in before opening the book), read it — take the top-ranked recommendation (highest feasibility) as the opening topic, confirm with the user: "The scan suggests writing X (why it could hit: Y, differentiation: Z). Open the book on this?" Also check the `scan date`: if it is old, note "market data may be stale, consider rescanning". On user agreement → enter Phase 2 with that topic's genre/selling point/differentiation. If missing, ask once: "Is there a `topic-decision.md` from a scan? Put it at the project root or paste the path; if not, answer the questions below." If still none, use the normal questions below.

**Topic-decision lifecycle rules (multi-book safety)**:
1. **Book-level lookup first**: if the current book directory already contains `topic-decision.md` (e.g., re-opening the same book later), read that copy instead of the project-root one.
2. **Leftover detection**: if the project-root `topic-decision.md` exists AND a copy already exists inside any other book directory, it is a leftover from a previous book — do not auto-offer it; ask the user whether to reuse it for this book, remove it, or skip to the normal questions.
3. **Archive on use**: once the user confirms a topic taken from the project-root `topic-decision.md`, move the file into the book directory as `{BookTitle}/topic-decision.md` and do not leave a copy at the project root — otherwise it will be re-offered to every future book opening.

If the user already has a direction → skip the direction questions below, but still do the "benchmark context load" (including benchmark findings) before Phase 2.

If the user has no direction:

Ask: **"What do you want readers to feel? Any favorite books to benchmark against? What is your edge (wild ideas / prose skill / sense of pacing / life experience)?"**

#### Benchmark context load

> **teardown-lib / benchmark relationship**: `teardown-lib/` = the analyze skill's raw output, the data source. `benchmark/` = the writing project's reference view, holding the subset of teardown data relevant to this project. On first referencing a benchmark book, copy the relevant subdirectories (`chapters/`, `characters/`, `plot/`, `setting/`), `plot/pacing.md`, `plot/emotional-beats.md`, `style.md`, and `teardown-report.md` from `teardown-lib/{BookTitle}/` into `benchmark/{BookTitle}/`.
>
> **Benchmark path lookup**: prefer `{project}/benchmark/{BookTitle}/`, fall back to `teardown-lib/{BookTitle}/`. All benchmark-data loading below uses this rule.

**Benchmark findings (before the reactive loads below)**: exclude the current imported work, current project prose, and its own teardown from all benchmark candidates. For the remaining external books, scan `teardown-lib/` and recommend by genre proactively — do not wait passively.

1. `ls teardown-lib/` (data source) and the project's `benchmark/` (reference view); if both are empty → skip to item 4.
2. Read each book's genre (short-form: `teardown-lib/{Book}/_meta.json` `genre_detected`; long-form: head of `overview.md` or the "genre" in `teardown-report.md` basic info), compare with this book's genre/direction, and label same-genre / weakly related / unrelated.
3. If there are same-genre or weakly related candidates → recommend via AskUserQuestion (list candidates + "use none" + "teardown another book"); 1 primary benchmark for prose/style, the rest as secondary benchmarks. On selection, write the `Primary benchmark book` / `Benchmark book list` fields in `setting/genre-positioning.md` (Phase 2 writes the file; record the choice here), and per the "first reference" rule copy the chosen book from `teardown-lib/{Book}/` to `benchmark/{Book}/`.
4. No candidates → continue without a benchmark (arrange the outline by the eight-node structure, see Phase 3); if the user wants a benchmark, they can run `/story-long-analyze` on a book first.

If the user mentions a benchmark book or a `benchmark/` directory already exists in the working directory:

1. Check `plot/emotional-beats.md` and `plot/pacing.md` using the benchmark path lookup rule.
2. If either primary artifact is missing, stop, set `missing_primary_contract: true`, and give a `repair_action`: re-run `/story-long-analyze` Stage 3+ or re-run `/story-import`; do not substitute `teardown-report.md`, chapter summaries, or storylines.
3. If both primary artifacts exist, first read the reader needs / emotional engine and reproducible modules in `plot/emotional-beats.md`, then read key information advancement, emotional trigger points, and burst pacing in `plot/pacing.md`; `teardown-report.md` is only a human-readable overview.
4. If `characters/`, ordinary story-unit, or `setting/` subdirectories exist, recall relevant modules on demand during writing.

Match by the user's answer:
- Good at wild ideas → recommend: system novels, multi-world travel, infinite-flow dungeon novels
- Good prose → recommend: cultivation/xianxia, historical, literary urban
- Good pacing → recommend: urban payoff fiction, second-chance, game novels
- Rich life experience → recommend: industry novels, urban daily life, homestead/cozy farming

#### Agent call: story-architect

story-architect is a high-level structural design agent. Lightweight genre positioning is done in the main session; only call story-architect for complex worldviews, multi-line structures, heavy reversal engineering, or explicit user request. After confirming the topic, if the project has deployed a story-architect agent (check whether `.claude/agents/story-architect.md` exists), you may spawn `Agent(subagent_type: "story-architect", prompt: "Project directory: {dir}\nTask type: genre positioning\nQuery params: {user-selected direction + benchmark info}")` to help analyze the genre and design the core hook. If the agent is unavailable, execute in the main thread directly.

> **story-architect contract summary (must be attached verbatim when spawning)**: the deployed story-architect agent does not know this skill's `references/reader-contract-and-progression.md`; it can only align schema via this summary in the spawn prompt, otherwise the main thread and the delegated output would use different progression rules. Summary:
> - **Endgame reserve boundaries**: endgame trump cards (head rival / ultimate truth / cheat ceiling / identity endpoint / core emotional endpoint) are one-time resources, unlocked volume by volume; do not burn them early. Power-up ladder rungs (realm/level/map/faction tier) unlock one rung at a time; no skipping.
> - **Overdraw two questions** (answer "yes" to either → roll back or revise the outline): ① Did you touch an endgame trump card that this stage should not unlock yet? ② Did any progression line near its ceiling with no ladder rung left to climb?
> - **Story units**: write story-unit cards inside the volume outline: unit ID, primary push line (1) + result lines (several; one battle many gains is allowed), chapter-level advancement floor (fast-paced genres keep a visible-event/payoff floor).
> - **Chapter-outline fields**: every chapter outline must carry Unit ID/position, Protagonist goal/key choice; the new field pair "Action cost (optional) / Benefit attribution" replaces the old "cost settlement" — action cost may be absent, never fabricate costs; benefit attribution must be visible.
> - **Reader contract & protagonist agency**: the protagonist is irreplaceable in causal rights (decisions / setups / delegations / key information determine how things happen and turn) plus settlement rights (core benefits/recognition return to the deserved party per the promise); the protagonist need not do everything personally. Side characters may execute local actions but must not silently steal promised highlights/benefits.
> - **Key-node four questions** (ask when designing key nodes): ① Who decides why things happen / how they enter? ② Who makes the irreplaceable key choice? ③ Who bears or chooses the key consequence? ④ To whom are the core benefits/recognition/power finally settled?
> - The full rules are governed by `references/reader-contract-and-progression.md` loaded in the main session; this is only a compressed version for story-architect; the agent does not have the file deployed and cannot read it itself.

---

### Phase 1.5: Book language & book-level AGENTS.md (all books, mandatory)

Before any prose, outline, setting, tracking, or review output is written, load the deployed book contract. For a new book, use `AskUserQuestion` in Plan mode to confirm the prose language and the record language as two separate choices, plus the market settings. Never infer the record language from the prose language, target market, source language, or chat language. If interactive questioning is unavailable, stop and ask in plain text; do not silently choose English and continue.

1. **Prose language**: ask separately; for this English-fiction toolkit, suggest English but require confirmation.
2. **Record language** (outline, setting, tracking, reports): ask separately; it may be English, Simplified Chinese (`zh-CN`), or another explicitly chosen language.
3. **English variant**: ask for `en-US` or `en-GB` when prose is English.
4. **Dialogue quotation**: curly double quotes by default; record a platform override explicitly.

The selected `Record language` governs all natural-language content in `outline/`, `setting/`, `tracking/`, reports, and book-level metadata. Keep stable file paths, schema keys, command names, code identifiers, and proper nouns/book titles in their required canonical form; translate surrounding labels, explanations, summaries, and values into the selected record language. Run a final language scan over the generated artifacts before reporting completion.

Once the working title is fixed (Phase 2 sheet), create `{BookTitle}/AGENTS.md`:

```markdown
# {BookTitle} — Book-level instructions

## Language rules (mandatory)
- Prose language: en
- Record language (outline / setting / tracking / reports): {record_language}
- English variant: {en-US or en-GB when prose is English}
- Spelling: US English
- Dialogue quotation: curly double quotes
- Date convention: prose follows the target market; records use ISO 8601
- Number and currency convention: en-US unless the setting requires another system
- Measurement convention: setting-specific
- Target platform: {platform}
- Market: {US | UK | global English}
- Content rating: {general | teen | mature}
- Content warnings: {none or list}
- Serialization: {serial episode | web chapter | ebook manuscript | one-shot}
- All story-* outputs for this book must follow these languages; do not switch on your own.

## Book identity
- Title: {title}
- Genre: {genre}
- Protagonist: {name}
```

- ZCode sessions opened inside the book directory load this file automatically; other CLIs treat it as the book's ground rules.
- Phase 4 prose must follow its `Prose language`; all outline/setting/tracking/report outputs (Phase 2–5) must follow its `Record language`.
- If the book directory already has an AGENTS.md, preserve user-authored sections but add any missing language/market fields before continuing.

---

### Phase 2: Core setting

Starting from the target emotion fixed in Phase 1, find the corresponding plot pattern inside the genre framework, extract reusable modules from the benchmark book (treating its concrete characters as function slots), and fill them with the user's own characters and setting.

#### Title selection gate

Before creating the book directory, `AGENTS.md`, or any book artifacts, resolve the working title:

1. If the user supplied an exact title, repeat it back and confirm it through `AskUserQuestion` unless the user explicitly said to use it without changes.
2. If no exact title was supplied, generate 3-5 concise title candidates calibrated to the chosen genre, platform, and hook. Present them through `AskUserQuestion` with options for each candidate, `Use a custom title`, and `Generate more candidates`.
3. Do not invent one title and continue when the user has not chosen. If `AskUserQuestion` is unavailable, stop after displaying the candidates and wait for a title choice.
4. Record the result in the book `AGENTS.md` as `Title selection: user-selected candidate`, `user-provided title`, or `custom title`; retain the candidate list in a short `Title candidates considered` field for traceability.

The title gate is separate from topic selection. A market-scan recommendation can choose the story direction, but it cannot choose the book title on the user's behalf.

Establish the following core elements with the user:

```
## Core Setting Sheet

### Basic info
- Book title: {working title}
- Genre/type: {primary + secondary}
- Target platform: {Royal Road / Webnovel / Wattpad / Kindle / other}
- Market / English variant: {US/en-US | UK/en-GB | global English}
- Content rating / warnings: {general | teen | mature} / {none or list}
- Serialization: {serial episode | web chapter | ebook manuscript | one-shot}
- Target length: {X} thousand words
- Target reader: {profile}
- Reader contract: {the core reading pleasure this book promises; see reader-contract-and-progression.md}
- Protagonist highlight/agency: {the protagonist's irreplaceable judgment, choice, or contribution}
- Core promise debt: {the promise the opening must repay}

### Logline
{protagonist + goal + obstacle + reversal, one sentence for the whole book}

### Protagonist sheet
- Name: {}
- Age: {}
- Core traits: {2-3 keywords}
- Cheat/core ability: {}
- Weakness/flaw: {what makes the character feel round}
- Core motivation: {why he/she does this}

### World skeleton
- Era/background: {}
- Core premise: {the unique premise that separates this from similar books}
- Power system: {if any, summarize briefly}
- Social structure: {key setting that affects the story}

### Core conflict
- Main-line contradiction: {}
- Final boss / ultimate obstacle: {}
```

After the core setting, create the following artifacts (load the corresponding templates in [references/artifact-protocols.md](references/artifact-protocols.md)):
- **setting/relationships.md**: character relationship map (see character-relations.md "four relationship types")
- **setting/genre-positioning.md**: genre core-hook three-layer analysis + benchmark analysis (see genre-core-mechanics.md "core hook analysis"). Keep 2-3 summary rows of the benchmark analysis table; full data lives in the `benchmark/` directory
- **setting/genre-prose-card.md**: extract this book's prose-layer genre card from `setting/genre-positioning.md` + `references/genre-prose-cards.md` (index) + `references/genre-prose-cards/` (single-genre card directory; prefer by genre) + `references/style-genre-modules.md` (generic style modules). Write only genre boundaries, core logic, reader expectations, core payoff/emotion, prose landing points, early/mid/late play, pacing density, scene granularity, drift bans; no generic format rules, and never override `setting/style.md`

> **Multiple benchmark books**: see `references/cross-book-recall.md`; secondary benchmark anchors go into the appendix of the "benchmark analysis" table

#### Agent calls: story-architect + character-designer

During core setting, if the project has deployed the corresponding agents (check `.claude/agents/` for `story-architect.md` and `character-designer.md` first; then `.opencode/agents/`, then `.codex/agents/`), you may spawn:
- `Agent(subagent_type: "story-architect", prompt: "Project directory: {dir}\nTask type: core setting\nQuery params: worldview building + core conflict design")` — helps design worldview and core conflict; the spawn prompt must attach the Phase 1 "story-architect contract summary" verbatim (the ladder-rung check constrains power-system design)
- `Agent(subagent_type: "character-designer", prompt: "Project directory: {dir}\nTask type: character setting\nQuery params: {protagonist sheet info}")` — helps with character setting and language style profile

If agents are unavailable, execute in the main thread directly.

---

### Phase 3: Outline building

#### Book length & stage overview (prerequisite to volume outlines)

Before volume-level outlines, write the book-wide length and stage boundaries as the shared constraint for all later volume outlines, chapter outlines, and daily-extension outlines. Percentages are default references only — adjust by genre, target length, and benchmark pacing; do not apply templates mechanically.

```
## Book Length & Stage Overview

- Total chapters: {X}
- Target length: {X} thousand words
- Whole-book emotion curve: {suppressed/anticipatory → pressure/reversal → payoff/shock → afterglow/completion; mark key stages}

### Stage breakdown
1. Opening stage (chapters {A}-{B}, ~10-15%): core task {establish character/establish world/plant main-line hook}; tone {suppressed/anticipatory/surprising}; by stage end the reader should hold {identification with the protagonist + anticipation for the main conflict}
2. Development stage (chapters {A}-{B}, ~50-60%): core task {conflict expansion/parallel subplots/resources and relationships upgrading}; tone {anticipation/tension/intermittent payoff}; by stage end the reader should hold {urgent anticipation for the core antagonist or endgame conflict}
3. Climax stage (chapters {A}-{B}, ~20-25%): core task {core conflict detonation/multi-line convergence/back-to-back payoffs}; tone {payoff/shock/reversal}; by stage end the core conflict should {be largely resolved or enter the final showdown}
4. Closing stage (chapters {A}-{B}, ~5-10%): core task {foreshadowing collection/relationships settled/ending afterglow}; tone {relief/moving/completion}; by stage end the main-line foreshadowing should {be fully collected and the ending settled}

### Per-stage pacing formula
- Opening: core task / tone / payoff density / foreshadowing strategy / conflict tier / stage hook / forbidden early release
- Development: core task / tone / payoff density / foreshadowing strategy / conflict tier / stage hook / forbidden early release
- Climax: core task / tone / payoff density / foreshadowing strategy / conflict tier / stage hook / forbidden early release
- Closing: core task / tone / payoff density / foreshadowing strategy / conflict tier / stage hook / must-collect list

### Key nodes and hook chain
- Key turning points: chapters {X/Y/Z}, each carrying {event function + emotional effect}
- Small/mid/large climaxes: small climax chapters {X/Y/Z}; mid climax chapters {X/Y}; large climax chapter {X}
- Stage hook chain: opening-stage end points to development; development end points to climax; climax end points to closing
```

#### Volume outline (whole-book structure)

```
## Volume Outline

### Volume 1: {name} (~{X} thousand words, {Y} chapters)
- Function: {setup/launch/first big payoff}
- Stage: {opening/development/climax/closing; if it spans stages, mark the boundary chapters}
- Volume contract: {the reading pleasure, protagonist highlights, and main promise debts promised this volume}
- Endgame reserve: {1 primary push line + several result lines (one battle many gains allowed); which endgame milestone this volume unlocks, which un-unlocked trump cards it must not touch; see the "endgame trump cards & power-up ladder" section of setting/genre-positioning.md and reader-contract-and-progression.md}
- Story units: {write story-unit cards of 10k-30k words inside the volume outline, not as separate files; field template in references/artifact-protocols.md, contract/progression rules in references/reader-contract-and-progression.md}
- Stage boundary: this volume may release {info/relationships/abilities}; this volume must not release early {late-core truth/endgame trump cards}
- Core event: {one sentence}
- Start state → end state: {the protagonist goes from {A} to {B}}

### Volume 2: {name}
...

### Final volume: {name}
- Function: {climax + close}
- Core event: {one sentence}
```

> **Multiple benchmark books**: see `references/cross-book-recall.md`; recall secondary-benchmark `chapters/*_summary.md` + `plot/*.md` for volume-level pacing

> **Benchmark pacing migration (with a primary benchmark, do once before finalizing volume outlines)**: read the primary benchmark's `benchmark/{Book}/plot/pacing.md`; if missing, set `missing_primary_contract: true` and stop, prompting to re-run `/story-long-analyze` Stage 3+ or re-run `/story-import`; do not substitute chapter summaries, storylines, or the teardown report. When the file exists, per references/outline-structure-theory.md "benchmark pacing migration", replace the material of the benchmark's level-1 structure key points (1/4 · midpoint · 3/4) with your own and place them into this volume's "benchmark structure coordinates" — select segments at the granularity of the primary benchmark's story units, matching same-type units by "type / beat-tag" (see step 1 of that section); write the selected story units into the story-unit card's "benchmark plot reference". If no primary benchmark is registered but `teardown-lib/` has a same-genre candidate, return to Phase 1 "benchmark findings" to register one first; if there is truly no benchmark book, arrange pacing by the eight-node percentages yourself.

#### Chapter outlines (one per chapter, whole book)

⚠️ **Outline safety seven checks (batch-level required: answer the full set once before designing each volume/batch of chapter outlines; when designing individual chapters, only re-answer ⑥⑦ and write the risk level into that chapter outline's `Contract risk:` line — do not re-answer the whole table per chapter; when appending story units mid-way, ⑦'s key-plot anchoring uses the unit-internal 1/4·midpoint·3/4 scale and does not change the already-locked volume-scale coordinate table)**: ① What emotion does this volume deliver, and what plot pattern reliably delivers it? ② What is this volume's core conflict? ③ Which parts of the volume rhythm accelerate and which decelerate? ④ What new foreshadowing does this volume need to plant, and how are the previous volume's pending foreshadowings handled? ⑤ Is the chapter-positioning spread tiered (not all high pressure), and are low-pressure + transition chapters restrained (total ≤ ~15%)? ⑥ Which stage is this volume/chapter in, what may it release, and what must it hold? ⑦ Are reader contract, protagonist agency, promise debt, and endgame reserve (trump cards / power-up ladder) rated contract safe / needs reinforcement / contract broken per reader-contract-and-progression.md? With a benchmark book, is a key plot anchored at each of 1/4 · midpoint · 3/4 (see references/outline-structure-theory.md "chapter positioning & tension / benchmark pacing migration")?

**Outline safety review (order must not be inverted; run once per batch, covering all story units and chapters in the batch)**: first design the positive emotional engine and genre-core delivery per `references/emotional-methods.md`, then diagnose with the authoritative file's protagonist-agency/ownership/growth negative-risk guardrails. The latter checks causal rights + settlement rights, the key-node four questions, and expectation ownership for every story unit's protagonist goal, key choices, attribution of delivery, core-asset exchanges, institution/faction boundaries, new-element debt, and progression lines; the protagonist need not personally perform every action. **Contract broken** must be fixed in the outline; **needs reinforcement** must add exchange/setup/cost. Then run two falsifiable degradation checks: ① after deleting the genre-core object/relationship/problem, does the story degrade into a generic career-upgrade or reskinned plot? ② After deleting the protagonist, does the emotional delivery stay essentially unchanged? Answer "yes" to either → fix the engine first.

**Every chapter must have a chapter outline file** (`outline/outline_chapter_NNN.md`); skipping chapters is not allowed.

Default is batched outline building: build the first 10 chapter outlines then **stop**, report "ready to write chapter 1 / daily update"; enter Phase 4 only when the user explicitly asks for prose. Rolling extension follows the numbering rules (see references/outline-structure-theory.md "chapter outlines by story-unit batch"):
1. **Batch boundaries**: one batch ≈ one story unit (5-15 chapters); story units longer than 10 chapters split into two batches. **First batch = capped at the first 10 chapters, may cross units**: recall the crossed-into story unit once when building its card; remaining chapters share that unit card's conclusions in later rolling batches. When the written content reaches the unit's tail (remaining unbriefed chapters ≤2), roll the next unit's full batch; when the user explicitly gives a chapter count/range, follow the user, but still recommend ≤10 chapters per batch with consecutive delivery.
2. **Batch positioning & stage constraints** (write before each batch's outlines): which stage and which story unit (unit ID) the current chapter range belongs to, this batch's advancement target, what this batch may release, what this batch is strictly forbidden from releasing early, and the boundary chapter-end hooks may not cross.
3. **Story-unit consumption**: the card-building batch reads the story-unit files referenced by the batch's story-unit card "benchmark plot reference" (≤3 files, including structure distribution/plot-point index), mapping beats → chapters and swapping plot-point material; later batches of the same story unit share the card's frozen conclusions without re-reading the unit files. Missing reference fields or legacy volume outlines follow the original flow without blocking.
4. **End-of-batch budget check** (required after each batch): uniformly verify each chapter's `Total budget:` Σ∈[chapter target, ×1.1]; chapters failing get dense points added / light points compressed before delivery — no repeated mental math at prose-writing time.

Do not force 30 full chapter outlines in a single conversation.
If the whole book is short (≤30 chapters), Phase 3 may build them all at once.

```
## Chapter Outline (Chapter N)

### Chapter N: {title}
- Core event: {one sentence; consumed uniformly by daily updates and imports}
- Target words: {X} words
- Stage position: {opening/development/climax/closing; stage Y chapter Z of this stage; what this chapter does inside the stage}
- Unit ID/position: {story-unit ID from the volume outline; which beat inside the unit / what function}
- Target emotion: {specific emotion pre-state → post-state; which link of the unit's emotional engine this chapter advances; do not write bare labels like "hyped/sad"}
- Protagonist goal/key choice: {what the protagonist wants this chapter; the judgment or choice that must be made}
- Chapter positioning: {high pressure/advancement/training trial/relationship payoff/low-pressure life/information assembly; may be left blank, blank = advancement. See references/outline-structure-theory.md "chapter positioning & tension"}
- Chapter structure formula: {node 1 (purpose) + node 2 (purpose) + node 3 (purpose) + node 4 (purpose)}
- Opening hook: {pick from the 7 chapter-opening hook techniques} — {specific content; low-pressure/transition chapters may write "weak hook / emotion-only hook, function is…"}
- Payoff: {this chapter's payoff; low-pressure/training/transition chapters may write "no explicit payoff, function is…", but must still give the reader a reason to keep reading}
- Forbidden early release: {late-stage core truth / trump cards / relationship conclusions / endgame conflict; write "none" if none}
- Contract risk: {contract safe / needs reinforcement / contract broken; per chapter only re-verify per checks ⑥⑦ and fill; the full table was answered at batch level}

#### Content summary (five-part)
- Cause: {why this chapter's events happen}
- Development: {how the conflict advances}
- Turn: {where information/relationships/situation change}
- Climax: {this chapter's emotional or action peak}
- Ending: {whose action/image/line the chapter lands on — write the concrete landing point, not state verdicts like "dust settled" or "everything ended"}

#### Plot arrangement (multi-line)
- Main line: {this chapter's advancement of the main goal}
- Sub-line: {may write "none"; never fabricate}
- Event & task line: {external event chain}
- Task blockers (if applicable): {what the character needs to get done → where it gets stuck → what change the block produces → what is lost if deleted → the closing action; write "none" if none; never force one}
- Relationship line: {with no explicit romance/relationship line, write "no explicit line, but relationship changes as: …"}
- Logic line: cause → action → result → consequence/new problem

#### Characters and appearance order
- Appearance order: {characters/factions/key objects in actual order of appearance}
- Relationship changes: {before this chapter → after this chapter}
- POV & information gap: {who knows what; what the reader knows; what the protagonist misjudges}

#### Plot detail
- Plot-point sequence: budget by words, not by count. Label each plot point **dense/light** and give a word budget: dense (payoff/comeuppance/reversal/emotional climax, expanded) ≥250 words, slow-motion payoffs 400-600; light (transitions/travel/info dumps, skimmed) ≈40 words; setup/daily ≈120-150 words. The point budgets sum Σ into [chapter target, chapter target×1.1]: below the target add expansion points (break payoffs into detail beats, add concrete examples to key nodes); above the cap compress transitions/merge light points — never pad, never stack payoffs to hit length. Point count follows Σ (usually 10+; short chapters targeting <1500 words take 5-8 points with the dense floor scaled down to ~120-250; when the target is a range, compute Σ against the range's upper bound). End the Plot detail subsection with a line `Total budget: X words (target Y, range Y-Z)` for easy Σ checks. Each plot point must state "who did what + function tag" (the function tag is the purpose word: setup/climax/payoff/comeuppance/characterization/setting — it decides whether the point expands or skims), e.g. "the protagonist finds the 4,800-dollar transfer on the bill 【info reveal·dense 250】" rather than just "finds it"
- Task-blocker note: if a plot point is "getting something done but stuck", its function tag must state which of info reveal / relationship change / cost settlement / foreshadowing advancement / choice pressure / rhythm breathing / hook handoff it serves; blockers whose deletion loses nothing do not enter the chapter outline
- Action cost (optional) / benefit attribution: {action cost may be absent; if present, who pays what cost; who gets the benefit, how it is visible, whether it leaves a future account}

#### Ending and hook
- Ending design: {which concrete action or image the close lands on (not state verdicts like "just like that…" / "he finally understood…"); unresolved problems; next chapter's driving force}
- Chapter-end hook: {pick from the 13 chapter-end hook techniques} — {specific content, expectation strength: strong/medium/weak; low-pressure/transition chapters may use a weak hook or a stage goal; how it hands off to the next chapter}
```

**Outline locking**: the first 10 chapter outlines are locked once prose writing has started on them; they may not change without user confirmation. Later rolling outlines may be fine-tuned with prose feedback. **Volume-outline locking definition**: once a volume has prose chapters, the existing story-unit cards and benchmark structure coordinates covering the written range are locked — existing content is not changed without user confirmation, but new story-unit cards may be **appended** at the volume's tail (append-only). Appending happens only when the user explicitly asks for outline extension; the daily/prose flows never auto-append story-unit cards. All "never auto-modify a locked volume outline" rules in workflow-daily follow this definition.

**Mid-way outline extension mini-flow** (project already has outlines; user asks "chapter outlines / extend outline / plan next arc"):
1. Locate the current volume, written progress, and existing story-unit cards: read `outline/outline.md`, the current `outline/volume_outline_N.md`, `tracking/context.md`, plus `tracking/foreshadowing.md` (pending foreshadowing), `tracking/character-state.md` (protagonist current state), `setting/genre-positioning.md` (endgame trump cards & power-up ladder) — missing tracking files are inferred per the original flow, no blocking;
2. Per references/outline-structure-theory.md "benchmark pacing migration" step 1, select a same-type story unit, design the new story-unit card (including "benchmark plot reference"), **append** it to the current volume outline's tail, and with the card **append-only** (add rows, never edit existing ones) the corresponding rows in the volume outline's "emotion curve" table and "volume foreshadowing" table; newly planned foreshadowing is registered as "unplanted" in `tracking/foreshadowing.md` — the user asking for extension counts as authorization to append; locked existing story-unit cards do not move; if the new unit's size exceeds the volume's plan, confirm with the user whether to expand the volume or open a new one;
3. Answer the full "outline safety seven checks" at batch level and run the "outline safety review" (when appending a unit, ⑦ uses the unit-internal 1/4·midpoint·3/4 scale);
4. Per "chapter outlines by story-unit batch", roll chapter outlines with the new unit as the batch (one batch ≈ one story unit; >10 chapters split into two batches sharing recall); after each batch run "post-outline setting completion" and the end-of-batch budget check;
5. Update `tracking/context.md` with two-line records: 「New story unit: {unit ID} (chapters A-B, benchmark plot reference: {…})」→ "New story unit: {unit ID} (chapters A-B, benchmark plot reference: {…})" and 「Batch positioning: {stage/advancement target/release boundary, one sentence}」→ "Batch positioning: {stage/advancement target/release boundary, one sentence}".

**Chapter-outline quality requirements**: each chapter outline must directly guide prose from the current chapter blueprint (stage position, structure formula, forbidden early release, content summary, plot arrangement, characters & appearance order, plot detail, ending & hook all present), but **intensity is allocated by chapter positioning, not maxed every chapter**: high-pressure/advancement chapters get the full hook+payoff+suspense set; low-pressure/relationship/training/information-assembly chapters may have no explicit payoff, weak hooks, or emotion-only hooks, focusing on writing the function (breathing, relationships, setup, transition) properly. The floor is: every chapter gives the reader a reason to keep reading, and adjacent chapters do not converge on the same emotion (see references/outline-structure-theory.md "chapter positioning & tension"). Complete missing fields first; where a relationship or sub-line cannot be determined from the material, write `[to be determined]` — never fabricate.

> **Chapter-outline hook sources**: prefer designing the hook chain along the batch story-unit card's "benchmark plot reference" unit beats and delivery style; with multiple benchmark books see `references/cross-book-recall.md` — same-tone `chapters/*_summary.md` of secondary benchmarks may still inspire single-chapter hooks (optional)

**Chapter title rules**: lightweight dedup only; when titles are identical or clearly duplicated, rename by this chapter's core event, keeping the outline title and the prose filename consistent.

**Post-outline setting completion (after each batch of outlines)**: scan newly appearing named characters/factions/key setting in the batch's outlines; for anything **that will be reused** (judged by the volume outline/chapter outlines: appears multiple times later or carries plot function), create files automatically without waiting for user confirmation:
- Characters → create `setting/characters/{Name}.md` (blank template in character-basics.md protagonist/supporting sheets), and register the initial state in `tracking/character-state.md` (create the file too if absent);
- Factions/organizations → create `setting/factions/{Name}.md` (name, position, core goals, key people, relationship to the protagonist);
- Worldview rules affecting multiple chapters → create/complete `setting/worldview/{Topic}.md` (rules, scope).

Existing setting files get **incremental additions, not overwrites**; the same character is not double-registered in `tracking/character-state.md`. One-off extras and side characters with no later scenes are not filed. File only what the outlines confirm; leave placeholder for undetermined fields; do not fabricate ahead.

After the outline is complete, create the following artifacts (load the corresponding templates in [references/artifact-protocols.md](references/artifact-protocols.md)):
- **outline/outline.md**: whole-book volume-level bird's-eye view (volume name + words + chapters + core event + state change, one-paragraph summary)
- **outline/volume_outline_N.md**: per volume — story units + emotion curve (incl. chapter positioning) + character arcs + foreshadowing + reversals + benchmark structure coordinates (see outline-methods.md "three-layer outline method" + outline-structure-theory.md "chapter positioning & tension / benchmark pacing migration" + emotional-arc-design.md "six-arc quick reference" + reversal-toolkit.md "reversal types")
- **tracking/foreshadowing.md** + **tracking/timeline.md** + **tracking/character-state.md**: foreshadowing state table + story timeline + character state snapshots (see plot-core-methods.md "continuity tracking", state-tracking.md "character state snapshot format")

The first 3 chapter outlines additionally load [references/opening-design.md](references/opening-design.md) (opening hook chapters: the golden three + six standards).

#### Agent call: story-architect

During outline building the main session produces the volume outline + first batch of chapter outlines first; call the story-architect agent only for complex structures, long reversal chains, or when the main session's plan is unstable.

If a story-architect agent is deployed (check `.claude/agents/story-architect.md` first), it may assist with:
- Tasks: volume-level structure, first batch of chapter outlines, hooks/reversals/emotion curves.
- Chapter positioning: mark each chapter high pressure/advancement/training trial/relationship payoff/low-pressure life/information assembly; low-pressure chapters may have weak payoffs but still need a reason to keep reading.
- Word budgets: label each plot point dense/light with a budget; dense points expand, light points skim; end with `Total budget: X words (target Y, range Y-Z)`.
- Main-session validation: every plot point has a budget and Σ lands in `[chapter target, chapter target×1.1]`; fix the outline before writing prose if it fails.
- **Attach the contract summary verbatim**: this stage's volume outline must directly produce the endgame reserve (this volume's primary push line/result lines, the endgame milestone it unlocks, the un-unlocked trump cards it must not touch) and story units (unit ID and other fields); the spawn prompt must include the "story-architect contract summary" from Phase 1's "Agent call: story-architect" so the main thread and the delegated output share one schema.

If the agent is unavailable, execute in the main thread directly.

---

### Phase 4: Prose writing

#### Project file structure

Long-form writing must use the file system — do not pile content into the conversation. In the user-specified working directory, create:

```
{Book Title}/
├── setting/
│   ├── worldview/
│   │   ├── background.md        # era, geography, history
│   │   ├── power-system.md      # cultivation/ability/level systems
│   │   └── ...
│   ├── characters/
│   │   ├── {Character Name}.md  # one file per person, filename = character name
│   │   └── ...
│   ├── factions/
│   │   ├── {Faction Name}.md    # one file per faction/organization
│   │   └── ...
│   ├── relationships.md         # character relationship map
│   ├── genre-positioning.md     # genre core hook + benchmark analysis + endgame trump cards/power-up ladder (anti-exhaustion)
│   ├── genre-prose-card.md      # prose-layer genre core: boundaries/expectations/payoff/pace/drift bans
│   └── style.md                 # custom style profile (highest priority when substantive)
├── outline/
│   ├── outline.md               # whole-book volume-level structure
│   ├── volume_outline_1.md      # one per volume: benchmark structure coordinates + story units + emotion curve (incl. positioning) + character arcs + foreshadowing + reversals
│   └── outline_chapter_001.md   # one per chapter: positioning + event + hooks (by positioning, chapter-open/close/paragraph-level) + payoff + suspense
├── prose/
│   ├── chapter_001_Title.md
│   └── ...
├── benchmark/                      ← structured assets from teardowns
│   └── {Benchmark Book Title}/
│       ├── source/
│       │   ├── chapter_001_Title.md
│       │   └── ...
│       ├── characters/             ← synced from teardown-lib/ structured output
│       │   └── {Character Name}.md
│       ├── plot/                   ← synced from teardown-lib/ structured output
│       │   ├── {Story Unit Name}.md
│       │   ├── storylines.md
│       │   ├── pacing.md           # key info advancement + emotional trigger points + burst pacing (authoritative pacing index)
│       │   └── emotional-beats.md  # reader needs / emotional engine + reproducible modules (authoritative module index)
│       ├── setting/                ← synced from teardown-lib/ structured output
│       │   ├── worldview/          ← split by topic into subdirectories
│       │   │   ├── background.md
│       │   │   ├── power-system.md
│       │   │   ├── geography.md
│       │   │   └── cheat.md
│       │   └── factions/
│       │       └── {Faction Name}.md
│       └── teardown-report.md
├── tracking/                      ← character states, foreshadowing, timeline
│   ├── foreshadowing.md           ← cross-volume tracking
│   ├── timeline.md                ← whole-book timeline
│   ├── character-state.md         ← current character state snapshots
│   └── context.md                 ← prose-level (daily progress summary)
├── reference/
│   └── {topic}.md             # research material output by story-researcher
```

**Artifact map** (creation templates in [references/artifact-protocols.md](references/artifact-protocols.md)):

| File | Granularity | Created at | Read at |
|------|------|---------|---------|
| setting/relationships.md | whole book | Phase 2 | on demand: story-explorer relationship queries, story-review setting checks (not per-chapter in the writing loop) |
| setting/genre-positioning.md (with `Primary benchmark book` field; required when multi-benchmark) | whole book | Phase 2 | Phase 3 outlines, before each volume, Phase 4 pre-write recall |
| setting/genre-prose-card.md | book/genre | Phase 2 (if missing, generate on the fly before Phase 4 writing) | Phase 4 before every chapter: match via the `genre-prose-cards.md` index, read the matching single-genre card in `genre-prose-cards/` first, fall back to `style-genre-modules.md` generic modules; assemble the prompt together with generic prose requirements, emotion/rhythm recall, and style |
| setting/characters/{Name}.md, setting/factions/{Name}.md | character/faction | Phase 3 incremental completion after outlines (first batch includes protagonist/major characters) | Phase 4 state filtering/writing |
| setting/style.md (custom style, highest priority) | this book | user-written (Claude Code may ghost-write); imports/teardowns never overwrite | Phase 4 before every chapter: with substantive content, replaces the benchmark style as the authoritative style base |
| benchmark/{Book}/style.md | benchmark book | analyze Stage 6 output → story-import sync | Phase 4 before every chapter (style recall; demoted to reference/sentence-length fallback when a custom style exists) |
| outline/volume_outline_N.md | volume | Phase 3 | Phase 4 before the volume's first chapter |
| tracking/foreshadowing.md | whole book | from Phase 3 | Phase 4 before every chapter |
| tracking/timeline.md | whole book | from Phase 3 | Phase 4 before every chapter |
| benchmark/{Book}/teardown-report.md | benchmark book | user manual + analyze | Phase 2 core setting, Phase 3 outlines, Phase 4 writing |
| tracking/context.md | whole book | Phase 4 first daily update (auto-created by workflow-daily) | at the start of every daily session |
| reference/{topic}.md | on demand | Phase 4 (story-researcher output) | reused when writing later chapters |
| tracking/character-state.md | whole book | Phase 3 | Phase 4 before every chapter (state filtering step) |
| benchmark/{Book}/characters/{Name}.md | benchmark book | analyze output | Phase 4 module recall (character reference) |
| benchmark/{Book}/plot/{Story Unit Name}.md | benchmark book | analyze output | Phase 3 volume segment selection and chapter-outline batches (story-unit card "benchmark plot reference"), Phase 4 module recall (plot module reference) |
| benchmark/{Book}/plot/emotional-beats.md | benchmark book | analyze Stage 3 output → story-import sync | Phase 2 core setting, Phase 3 outlines, Phase 4 before every chapter (reader needs / emotional engine, reproducible module selection) |
| benchmark/{Book}/plot/pacing.md | benchmark book | analyze Stage 3 output → story-import sync | Phase 3 outlines, Phase 4 before every chapter (key info advancement, emotional trigger points, burst pacing) |
| benchmark/{Book}/setting/*.md | benchmark book | analyze output | Phase 2 setting reference, Phase 4 worldview constraints |

**Missing-file handling**: explicitly repair when the current primary artifact is missing; never assemble degraded substitutes:
0. **Tracking authority missing or invalid** → if an existing book has prose and `tracking/` but `_tracking-state.json` is missing or invalid, treat the semantic checkpoint as corrupted and stop before writing; re-run `/story-import` and initialize/repair the JSON authority before continuing.
1. **Character-state file missing** → infer the current state from the character setting files and prior prose.
2. **Non-primary subdirectories missing (characters, ordinary story units, setting)** → look up the project view then the root data source per the "benchmark path lookup" rule; if still missing, skip that optional module. This item does not apply to `plot/emotional-beats.md` and `plot/pacing.md`.
3. **`plot/emotional-beats.md` / `plot/pacing.md` missing** → pre-write preparation must stop, set `missing_primary_contract: true`, and give a `repair_action`: re-run `/story-long-analyze` Stage 3+ or re-run `/story-import`; never fake recall of the authoritative modules with summary files.
4. **Benchmark book exists but `style.md` is missing** → if `setting/style.md` (with substantive content) exists, continue in custom-style mode; otherwise daily style recall fails fast: prompt to run `/story-long-analyze` Stage 6 and `/story-import` to sync. **A project with no benchmark at all** skips style recall without blocking (write with `setting/style.md` if present). The emotion/pacing axis (`missing_primary_contract`) is independent; custom-style mode does not exempt it from fail-fast.
5. **Foreshadowing/timeline files missing** → no check; the volume outline or master outline may carry that information.
6. **`setting/genre-prose-card.md` missing** → non-blocking; before writing, exactly match the `references/genre-prose-cards.md` index from `setting/genre-positioning.md`, and read only the corresponding single-genre card in `references/genre-prose-cards/` (keep the card's high/medium/low confidence labels); if nothing matches, generate a short `genre_prose_card` from `references/style-genre-modules.md` generic style modules on the fly. Only when `setting/genre-positioning.md` is also missing, fall back to a low-confidence card from the chapter outline and target platform, and state that in the intent confirmation.

**Benchmark authority priority (authoritative read order)**:
1. `plot/emotional-beats.md` is the authoritative source for reader needs / emotional engine, payoff-genre framework, reproducible modules, and recombination guidance.
2. `plot/pacing.md` is the authoritative source for key information advancement, chapter-expansion technique aggregation, emotional trigger points, and burst pacing.
3. `style.md` only governs sentence length, punctuation, dialogue subtext, source anchors, and tone; it cannot override emotional-module or pacing intent. **Custom style `setting/style.md` (user-written, never overwritten by imports/teardowns) outranks the benchmark `style.md`**: with substantive content it is the authoritative style base and the benchmark style drops to reference and sentence-length numeric fallback; structural safety rules (blank-line spacing between paragraphs/fragments, `--`, repeated ellipses, and em-dash clusters) still normalize per narrative-writer, while a functional single em dash or ellipsis remains valid English punctuation.
4. `chapters/chapter_K_summary.md` is chapter-level evidence for verifying and supplementing the authoritative indexes; it does not reverse-override `emotional-beats.md` / `pacing.md`.
5. `teardown-report.md` and `plot/storylines.md` are projections/summaries; if they conflict with `plot/emotional-beats.md` or `plot/pacing.md`, write per the two authoritative files and record the conflict source in pre-write `gaps.conflict`.

**File organization principles:**
- **One file per person**: `characters/{Name}.md`, easy on-demand reads
- **One file per faction**: `factions/{Name}.md`, for organizations/sects/families/nations
- **Worldview split by topic**: background, power system, social structure each independent
- **One outline per chapter**: `outline_chapter_NNN.md`, with hook design, 1:1 with prose
- **One prose file per chapter**: `chapter_NNN_Title.md`
- Write each finished chapter directly into `prose/` — never output it to the conversation first

#### Single-chapter writing flow

When the user is ready to write a chapter:

1. **Check the outline**: read `outline/outline_chapter_{N}.md`, and from the corresponding `outline/volume_outline_N.md` read the current story unit (unit ID/position, volume contract, this volume's primary push line/result lines, endgame trump card boundaries, risk level). If it does not exist, **the outline must be built before writing prose** — writing without an outline is not allowed. When building it, reference the volume outline's event plan and context for this chapter, and complete it per the new "chapter blueprint" template: stage position, structure formula, forbidden early release, content summary, plot arrangement, characters & appearance order, plot detail, ending & hook; legacy outlines missing these fields do not block reading, but if backfilling this round, unknown items get `[to be determined]`.
2. **Load context** (on-demand loading; skip when missing. Optional fast path: if the project has deployed a story-explorer agent (check `.claude/agents/story-explorer.md` first; then `.opencode/agents/`; then `.codex/agents/`), you may spawn `Agent(subagent_type: "story-explorer", prompt: "Project directory: {dir}\nQuery type: context_load\nQuery params: preparing to write chapter {N}")` to fetch context in one shot):
   - (1) `prose/chapter_{N-1}_*.md` — previous chapter's prose
   - (2) `outline/outline_chapter_{N}.md` — this chapter's outline (with hook design)
   - (2a) `outline/volume_outline_N.md` — current story unit, volume contract, endgame reserve (primary push line/result lines, endgame trump card boundaries)
   - (3) `tracking/foreshadowing.md` (if exists) — pending foreshadowing
   - (4) `setting/characters/{relevant}.md`, `setting/factions/{relevant}.md` (if exist) — characters and factions in this chapter (filter by outline appearance)
   - (5) `teardown-report.md` under the benchmark path (per benchmark path lookup) — benchmark reference
   - (6) `benchmark/{Benchmark Book}/source/chapter_N_*.md` (if exists) — same-position chapter reference
   - (7) `reference/{topic}.md` (if exists) — historical research material (produced by story-researcher)
   - (8) `tracking/character-state.md` (if exists) — current character state snapshots
   - (9) `plot/storylines.md` under the benchmark path (per benchmark path lookup) — story-unit index to determine which units this chapter touches
   - (10) `plot/{relevant story unit}.md` under the benchmark path (per benchmark path lookup) — select unit files relevant to this chapter from the index
   - (11) `setting/worldview/*.md` under the benchmark path (glob, per benchmark path lookup) — reference from the teardown's topicalized setting; if the directory is missing, record the gap and skip this item; do not read the flat legacy path
   - (12) `plot/emotional-beats.md` under the benchmark path (per benchmark path lookup) — reader needs / emotional engine, payoff-genre framework, reproducible modules; if missing, set `missing_primary_contract` per "missing-file handling" above and stop preparation
   - (13) `plot/pacing.md` under the benchmark path (per benchmark path lookup) — key info advancement, emotional trigger points, burst pacing; if missing, set `missing_primary_contract` per "missing-file handling" above and stop preparation
   - (14) `setting/genre-prose-card.md` (if exists) — this book's prose-layer genre card; if missing, generate a `genre_prose_card` on the fly from `setting/genre-positioning.md` + the `references/genre-prose-cards.md` index + the single-genre card directory `references/genre-prose-cards/` (prefer by genre) + `references/style-genre-modules.md` (fallback), without blocking
3. **Pre-write preparation** (these 3 steps are the core method applied to single-chapter writing: filter state → recall modules → confirm intent):
   - **State filtering**: filter the current states of this chapter's characters from `tracking/character-state.md`, and the foreshadowing this chapter needs to collect/advance from `tracking/foreshadowing.md`. Output the section notes (see state-tracking.md). If the character-state file does not exist, infer from character setting and prior prose
   - **Module recall, genre-card & style recall**:
     - ① What is this chapter's target emotion word? ② Which technique from which reference file? ③ Which paragraphs use it? If you cannot answer, reread the reference before writing
     - (a) **Emotion module recall**: per the "benchmark path lookup" rule read `{benchmark path}/plot/emotional-beats.md`, select 1 `selected_emotion_module` closest to this chapter's target emotion (reader needs, triggers, dramatic units, replaceable elements, anti-plagiarism note). If missing, set `missing_primary_contract: true`, return a clear `repair_action`, and stop preparation
     - (b) **Pacing recall**: read `{benchmark path}/plot/pacing.md`, select 1 `rhythm_reference` (key info → expansion technique → emotional trigger → burst/cooldown). If missing, set `missing_primary_contract: true`, return a clear `repair_action`, and stop preparation
     - (c) **Genre prose card recall**: prefer `setting/genre-prose-card.md`; if missing, read `setting/genre-positioning.md` + the `references/genre-prose-cards.md` index, exactly match the primary genre and read only the matching single card in `references/genre-prose-cards/` (e.g. contemporary-romance / mafia-romance / cultivation; low-confidence cards must be flagged low-confidence in the intent confirmation and calibrated against a same-genre benchmark), then fall back to `references/style-genre-modules.md` generic style modules. Cross-genre: 3-5 items from the primary genre, 1-2 from the secondary, produce a short `genre_prose_card` (genre boundaries, core logic, reader expectations, core payoff/emotion, prose landing points, early/mid/late play, pacing density, scene granularity, drift bans, this-chapter tradeoffs, card confidence). The genre card only constrains prose-layer genre flavor — it does not change outline plot, does not override `selected_emotion_module` / `rhythm_reference` / `setting/style.md`; calibrate tradeoffs internally only; card names/labels/confidence/items/compliance self-assessments must never appear in the prose
     - (d) **Style recall**: first read `setting/style.md` directly (not via explorer): with substantive content (≥200 words after whitespace removal, or containing style subsections for sentence length / punctuation / dialogue / anchors / tone with executable constraints: ratios / examples / bans or preferences) set `custom_style=true` and enter "custom-style mode" — it is the authoritative style base (sentence length / soft punctuation / subtext / emotional alternation), and the benchmark/teardown `style.md` drops to reference (anchors + sentence-length fallback); empty / whitespace-only / title-only / placeholder stubs (TODO / to be added / ___) count as nonexistent. Otherwise, per the "benchmark path lookup" rule read `{benchmark path}/style.md` (path preference `{project}/benchmark/{Book}/`, fall back `teardown-lib/{Book}/`); with multiple benchmark books read the `Primary benchmark book` field from `setting/genre-positioning.md`. **Not in custom-style mode and** the style file does not exist → **fail-fast error**: 「Benchmark book X is missing style.md. Run `/story-long-analyze` Stage 6 to generate the style profile, then `/story-import` to sync.」 Do not inline-generate (custom-style mode does not fail-fast; the emotion/pacing axis `missing_primary_contract` still blocks independently)
     - (e) **Matching chapter selection**: from `{benchmark path}/chapters/*_summary.md` grep `tone: (tense|light|sad|hot|sweet|warm|horror|oppressive|other)` and pick chapter K by this chapter's target emotion — when multiple chapters share the tone: first compare payoff type proximity, then compare plot-point count/estimated word count of the original chapter with this chapter's target words, finally take the smallest chapter number; must read `{benchmark path}/chapters/chapter_K_summary.md`; if `chapter_K_deep-dive.md` exists for the same chapter, read it too; otherwise fall back to the golden-three-chapters deep dives or transferable techniques inside the style file — do not fail because non-golden chapters lack deep dives
     - (f) **Structured module recall**: search the benchmark's structured subdirectories (characters/plot/setting) for modules relevant to this chapter's plot; if conflicting with `plot/emotional-beats.md` / `plot/pacing.md`, the authoritative files win — record `conflict`
     - (g) Output "primary benchmark recall summary + secondary benchmark recall summary + selected_emotion_module + rhythm_reference + genre_prose_card + style recall directive + source anchor excerpts" as the input for narrative-writer. **Multiple benchmark books**: see `references/cross-book-recall.md` — the primary benchmark provides style, source anchors, and selected_emotion_module / rhythm_reference; secondary/reference benchmarks provide structured summaries within the stage budget, without limiting how many books are registered; do not read secondary books' `style.md` / source; when over budget, trim items, not book registrations
     - **Fast path**: when the project has deployed a story-explorer agent, recall style/module material in one shot.
       - Check order: `.claude/agents/story-explorer.md` → `.opencode/agents/` → `.codex/agents/`.
       - Query type: `benchmark_style_load`; pass project directory, chapter number, target tone/word count and payoff type.
       - Must return: `style_profile_path`, `style_profile_summary`, `selected_emotion_module`, `rhythm_reference`, source paths, matched chapter, anchor excerpts, `gaps`.
       - When `gaps.missing_primary_contract` is true, repair per `repair_action` first; do not proceed to prose generation.
       - The main session additionally reads `setting/style.md` directly: with substantive content it serves as the book's style base; but it does not exempt emotion/pacing absence.
   - **Intent confirmation**: combine the chapter outline, section notes, and module recall results; write this chapter's intent in one sentence.
     - New-format outlines must consume: stage position, unit ID/position, protagonist goal/key choice, structure formula, forbidden early release, content summary, plot arrangement, characters & appearance order, plot detail, ending hook — cross-checked against the current story unit's volume contract, this volume's primary push line/result lines, and endgame trump card boundaries.
     - **Outline-priority boundary**: prose may only expand this chapter's existing outline events, people, conflicts, foreshadowing, and ending hook; do not invent new main lines, new characters, new reversals, or write later-chapter plot early to fill words or "make it better"; necessary transitional action may only serve outline-listed plot points. Later-stage truths, trump cards, relationship conclusions, and endgame conflicts must not leak early through the chapter-end hook. Conversely, the outline is a contract of "what happens", not the shape of the prose: prose may freely reorder narration, merge/interleave plot points — no need for one point per paragraph or writing the five-part sequence in order; play each point as a scene instead of copying the summary wording (see writing-craft.md "from outline to prose").
     - Before a payoff lands there must be an identifiable crisis/anticipation setup; status-flex/comeuppance/reveal chapters must write the differentiated reactions of present side characters.
     - High-pressure/life-and-death/grief beats tighten dialogue voice: comedy relief yields, info-role characters do not lecture, lines answer the other person's emotion line by line.
     - Check task blockers: if this chapter has "getting something done but stuck", it must block into info/relationship/cost/choice/foreshadowing change; if not, do not force one.
     - Contract risk check: per `references/reader-contract-and-progression.md` judge contract safe / needs reinforcement / contract broken; if highlights/benefits are captured by side characters, institutions, or chance without a visible exchange, fix the outline first, then write.
     - Legacy outlines fall back to reading core event, plot-point sequence, target emotion, chapter-open/close hooks, and target words.
     - Example: 「Fast comeuppance — bill exposed → interrogation → counter-evidence → public cost; the reader waited three chapters, this one must land the punch.」
4. **Research** (on demand): if the writing needs external facts verified (historical dates, geography, professional details, etc.) and the project has deployed a story-researcher agent (check `.claude/agents/story-researcher.md` first; then `.opencode/agents/`; then `.codex/agents/`), spawn the `story-researcher` agent to search and output into the `reference/` directory. If unavailable, execute in the main thread directly. Continue writing after research completes.
5. **Title pre-check**: read the chapter title from the outline before writing; if it duplicates or clearly resembles an existing title, rename by this chapter's core event, and keep the outline title and prose filename in sync.
6. **Writing**: if chapter 1 opens with interiority, setting exposition, or solitude, first externalize the inner change into visible events (decisions, misjudgments, dialogue, object changes, external pressure) before expanding per the word target; do not pad with long interior monologue. If chapter 1 falls short of target, or immersion/advancement feels thin, prefer returning to the outline to add useful sub-events, dialogue clashes, or choice costs — do not add explanatory interiority; task blockers only when the character actually has something to get done and the block can produce info/relationship/cost/choice/foreshadowing change; otherwise do not force one.
   - **Prose meta-information isolation**: `Chapter: chapter N`, `Previous: prose/chapter_{N-1}_*.md`, `Matched chapter K`, `Outline file`, etc. are for locating material only. Outside the title line, prose must not contain writing/engineering words such as: chapter outline / plot point / story unit / target words / this chapter / the reader / foreshadowing (and their variants like "the last chapter / previous chapter / next chapter / earlier text / later text"). When referring back to earlier text, use an event anchor or relative time the character can perceive — e.g. "more painful than those three seconds of gunfire in chapter one" must be written "more painful than those three seconds of gunfire". Exceptions: a character genuinely reads/discusses "chapter X" text inside the story world, or is truly an author/reader talking about being a reader.
   - **Specific word-count expressions check**: when prose evaluates a line of dialogue, inscription, letter, decree, thought, or comment barrage, use concrete count expressions ("these five words" / "those four words" / "the three words land" / "eight words slam down") only when the counting basis is explicit, has been verified word-by-word with a script, and the story genuinely needs it. When the count cannot be guaranteed, use non-numeric expressions: "when the sentence landed" / "those words" / "this line". Example: `Xun Yu only said: "He will suspect, but not be quick." Those five words land` should become `Xun Yu only said: "He will suspect, but not be quick." When the sentence landed`.
7. **Prose execution**:
   - First check the narrative-writer agent: `.claude/agents/narrative-writer.md` → `.opencode/agents/` → `.codex/agents/`.
   - If available, spawn `Agent(subagent_type: "narrative-writer", prompt: ...)`, passing only this chapter's necessary material:
     - Project directory, chapter number, outline file, previous chapter, output path.
     - Pre-write preparation output: section notes, emotion target, involved characters, referenced techniques.
     - Primary benchmark/teardown path, primary/secondary benchmark recall summaries.
     - `selected_emotion_module`, `rhythm_reference`, and their source paths.
     - `genre_prose_card` (genre prose card summary, only this-chapter-relevant items).
     - Style path, style recall directive, source anchor excerpts.
     - Stage position, this chapter's structure formula, this chapter's releasable info, this chapter's forbidden early release.
     - Word target, plot-point budgets, format hard constraints.
     - Outline-priority boundary: only expand this chapter's outline, no self-invented plot; if the word target cannot be met with existing plot points, return `outline_underfilled` deficit points; the main session supplements/confirms the outline before writing.
   - Do not copy this file's whole rule set into the prompt; details follow the loaded references and the narrative-writer template.
   - Agent output writes to `prose/chapter_NNN_Title.md`. If the agent is not deployed, the main thread writes directly.
8. **Word-count verification** (the first thing after writing): count the chapter's actual words with the deployed shared English word-count tokenization, probing `python3/python/py`; do not use `wc -c`, character statistics, or model estimation; do not assume `python3` exists on Windows. macOS/Linux may use `wc -w` only when its result matches the shared tokenization.
   - Words < 90% of outline target: find deficit points against the plot-point budgets. Dense points (payoff/comeuppance/reversal) written thin → rewrite to their budgets; low-pressure/relationship/information-assembly chapters → expand existing setup, interaction, or performance beats inside the outline — do not force payoffs in. If the existing outline lacks expandable content, stop and output `outline_underfilled` deficit points; supplement/confirm the outline first — prose must not invent new plot.
   - Words > chapter target×1.1: compress transitions, merge light points, cut redundant transitions — do not cut main-line payoffs to hit length.
   - 90% is only the release floor; the target is still `[chapter target, chapter target×1.1]`; re-count after rewriting and enter step 9 once inside the range.
9. **Check**: is there a reason to turn the page at the chapter end (low-pressure/transition chapters need only a weak hook or stage goal — no payoff required), and did the payoff land (per chapter positioning; high-pressure/advancement chapters always check). Two falsifiable checks (fail → fix): ① is there an identifiable crisis/anticipation passage before the payoff lands (point at the concrete plot point)? Cannot point = hollow → return to step 8 and add setup plot points (plot-emotion-system back-derivation); ② in status-flex/comeuppance/reveal chapters, do the present side characters have differentiated reactions (collective shock / varied), or only the protagonist acts? None → add side-character reactions (plot-core-methods).
10. **Meta-information scan**: check the prose outside the title line for engineering words — `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` (plus the variants listed in step 6) — rewrite any hit into in-scene expression; exceptions are the same as step 6.
11. **Banned-word scan**: first pass the **most toxic sentence patterns** (the ones that slip through most in practice; hit → fix): ① the whole "It wasn't X. It was Y." family — including the "No X. No Y. (only Z)" parallel negation, the reversed "It was Y, not X", and the rise-after-fall "He didn't X, nor did he Y. He only Z"; ② voice-contrast "voice was quiet/low… but…"; ③ the universal adverbial ", with a trace of …"; ④ trailer/summary endings "No one knew…" / "(it was) only the beginning" / "was pressing toward…" / "the curtain was about to rise" / "in that moment…"; ⑤ short words in quotes for emphasis in narration (he was hired to "keep an eye on" things). Then check the full table in `references/banned-words.md`: tier-1 words (high-frequency AI flavor) replaced on hit; tier-2 (low-frequency/context-sensitive) replaced when frequent, occasional use judged qualitatively per `references/anti-ai-writing.md`.
12. **Update tracking**: immediately after writing, update `tracking/foreshadowing.md` (new/collected foreshadowing), `tracking/timeline.md` (event order), and `tracking/character-state.md` (if the chapter changed a character's state — identity, ability, relationship, public image — update the entry and append a change record). If this chapter first introduces a reusable named character/faction, build the corresponding `setting/` files per Phase 3 "post-outline setting completion". Character-state update rules see state-tracking.md.
13. **English localization pass**: before release, check names, places, institutions, occupations, education, law, medicine, military terms, dates, money, units, idioms, titles, kinship terms, and dialogue register against the book's market profile. Preserve intentional non-English setting details, but mark the reason in `setting/` rather than silently leaving direct translations.
14. **Mid-way snapshot** (long-form safety net): after every 3 consecutive chapters, before continuing:
   - Write current progress into `tracking/context.md` (progress meta only — current position, recent decisions, pending threads — do not repeat character-state/foreshadowing specifics)
   - `ls -la prose/` to confirm the last 3 chapter files landed on disk with sane sizes (>100 bytes)
   - If files are missing or sizes are abnormal, rewrite them immediately
   - Continue writing after the snapshot

> **Daily-update mode**: this step auto-skips — workflow-daily Step 2 updates context.md per chapter.

#### Writing technique reminders

| Scenario | Technique |
|------|------|
| Opening 500 words | must have a hook; cannot start from weather/scenery (unless the contrast is extreme) |
| Dialogue | advances plot or reveals character; cannot exist just to fill words |
| Fights | no play-by-play; write strategy and reversals, not "you punch, I kick" |
| Daily scenes | need character interaction and foreshadowing, not "eat and sleep" |
| Task blockers | the character gets stuck getting something done and it must block into info/relationship/cost/choice/foreshadowing change; if deletion loses nothing, compress or delete |
| Payoff release | set up fully, release cleanly; the longer the reader waits, the better the release must feel |
| Payoff density | high-pressure/advancement chapters: one payoff emotion node per 3000-5000 words; low-pressure/relationship/training/information-assembly chapters not required, but every chapter still needs a reason to keep reading (see references/outline-structure-theory.md "chapter positioning & tension") |
| Formula constraints | follow the creation formulas in genre-writing-formulas.md |
| Chapter end | every chapter end needs something that makes the reader want to turn the page |
| Emotion verification | after each chapter, look back: what should the reader feel here? Did they feel it? No → supplement per positioning: high-pressure/advancement chapters add conflict or hooks, low-pressure/relationship chapters add relationship or emotional texture — don't always add payoffs |

#### Word-count hard constraints

| Pace | Target range | Notes |
|------|----------|------|
| Fast advancement | 2000-2500 words | one clear event per chapter |
| Normal pace | 2500-3000 words | main line + a little sub-line |
| Slow setup | 2500-3000 words | character interaction + foreshadowing |
| Climax burst | 2000-2500 words | concentrated release, no dragging |

**Default target: 2000-3000 words per chapter. Short chapters targeting 1500-2000 words are allowed when the chapter outline explicitly targets that range (e.g. fast-paced genres or low-pressure transitions); short chapters never go below 1500 words. The chapter outline's `Target words:` field wins over the defaults. Budgets are calculated in words; the plot-point budget Σ must land in [chapter target, chapter target×1.1]. Low-pressure/transition chapters still need a reason to keep reading and must land their function (see outline-structure-theory.md "chapter positioning & tension" for the low-point budget rules).

#### Tracking file archiving

Every 50 chapters or at a volume end, do a light archive of `tracking/context.md`: keep the last 5 chapters in detail, compress older content into `tracking/archive/chapter_NNN-NNN.md`, and keep an archive index in context. Foreshadowing, timeline, and character state stay in their current files; active threads are never moved into the archive.

---

### Phase 5: Quality check

Check three dimensions: (1) **Emotion delivery** — did each chapter deliver the target emotion planned in the outline? (2) **Contract risk** — per `references/reader-contract-and-progression.md`, check causal rights + settlement rights, key-node four questions, expectation ownership, promise debt, endgame reserve (the overdraw two questions), and new-element debt; chapter-level advancement tiers per the authoritative file's seven state types (fast-paced keeps the visible-event/payoff floor), strength judged relative to this book's genre and benchmark, marked contract safe / needs reinforcement / contract broken; **contract broken** → fix the prose first or fix later outlines. (3) **Technical quality** — consistency, format, banned words. See the generic checks and long-form specific list in [references/quality-checklist.md](references/quality-checklist.md).

**Prose meta-information scan**: the quality check must cover prose outside the title line; on finding engineering words — `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` and variants — first rewrite into events, objects, actions, or relative time the character can perceive right now, then proceed with other checks; in-story reading/discussion of "chapter X" or genuine reader-identity contexts excepted.

**Same-round zeroing after writing**: prose landing on disk is not the moment to report — after each chapter lands, run Phase 4 steps 10-11 scans, the deterministic finishing scripts below, and the narrative-writer review in the **same round**; the chapter is done only when blocking findings are zero. Do not report "written" and wait for instructions. The write-hook automatically scans landed prose for deterministic toxic patterns and pushes hits back — that is a safety net, not a substitute; clear hook-reported hits in the same round. **The only exemption**: the user explicitly says "skip deslop/checks for this chapter" — on exemption, add a line `<!-- deslop:skip -->` under the chapter's title line (the write-hook's toxic-pattern push-back and the pre-next-chapter deficit interception both recognize this marker; the rest of the net stays on).

**Deterministic finishing**: after the batch's prose lands, the main session runs `node scripts/check-ai-patterns.js --check --fail-on=blocking prose/chapter_NNN_*.md` on the actually landed files. Blocking hits → rewrite the prose first and rescan; advisory is reading-feel hints only — change only genuine problems; functional writing gets `[needs review]`.
Then run `node scripts/normalize-punctuation.js prose/chapter_NNN_*.md` (default `--quote-mode keep`) to clean non-functional ellipses, dashes, double hyphens, and standalone separators. The narrative-writer agent does not run these scripts.

**Degeneration protection**: after prose lands, run `node scripts/check-degeneration.js --check prose/chapter_NNN_*.md`. Blocking (verbatim repetition, truncation, refusal language, tier-1 engineering-word leaks) → rewrite only the affected chapters, at most 2 times; if still failing, report the evidence and let the user decide.
Advisory only points at suspicious spots; first check the exceptions the script gives; in-story system/interface wording, barrage spam, and repeated lines with function may stay.

#### Agent call: consistency-checker

During quality checking, if the project has deployed a consistency-checker agent (check `.claude/agents/consistency-checker.md` first; then `.opencode/agents/`; then `.codex/agents/`), spawn `Agent(subagent_type: "consistency-checker", prompt: "Project directory: {dir}\nCheck scope: {chapters written this round}\nCheck type: factual conflicts + broken foreshadowing + character attribute inconsistencies")` and get the S1-S4 graded report. If unavailable, the main thread checks directly per quality-checklist.md.

#### Agent call: narrative-writer (de-AI review)

During quality checking, if the project has deployed a narrative-writer agent (check `.claude/agents/narrative-writer.md` first; then `.opencode/agents/`; then `.codex/agents/`), you may spawn `Agent(subagent_type: "narrative-writer", prompt: "Project directory: {dir}\nTask: review + de-AI flavor\nScope: {chapters written this round}\nDelete first: for each AI-flavor item decide whether deletion loses foreshadowing/hooks/characters/plot/necessary info — delete directly if not; otherwise polish (deletion obeys the ratio cap and word floor; below the floor, rewrite to lower AI flavor instead)\nMust check: the "not X but Y" reversal family, fix by writing Y directly or with action detail; author explanation/summary and meaning tails (he realized / this meant / what really mattered / this growth), prefer deleting or landing on in-scene action, dialogue, object state; metaphor sheets (like/as if/as though), when truly stacked keep only the most functional few and return the rest to concrete images; consecutive refined dramatic-reaction phrases (scalp tightening, an eyelid twitching, heart sinking, stomach churning) — when a plain action or plain feeling works, write the plain thing; existing phone/screen/notice/nameplate/form/bill/evidence/rule-line info stays as in-scene carriers the character sees or handles, not rewritten into narrator explanation; task blockers only when the character has something to get done and the block produces info/relationship/cost/choice/foreshadowing change — never add process for naturalness or word count")` for text quality review and de-AI checks. If unavailable, the main thread executes directly.

After the checks, update tracking files:
- Update expired and collected foreshadowing in `tracking/foreshadowing.md`
- Update timeline doubts in `tracking/timeline.md`

---

## Pipeline Handoff

**Pipeline:** long-form
**Position:** writing (step 3 of 3)

| When | Jump to | Command |
|---|---|---|
| Done writing, de-AI | story-deslop | `/story-deslop` |
| Want to compare reference books | story-long-analyze | `/story-long-analyze` |
| Need market direction | story-long-scan | `/story-long-scan` |
| Too long, better as short form | story-short-write | `/story-short-write` |

---

## Reference Index

Load by scenario; never load everything at once.

### Phase 1: Topic direction

| Scenario | Load |
|------|---------|
| Confirm genre type | `references/genre-catalog.md` |
| Judge market direction | `references/genre-readers.md` |
| Special-genre considerations | `references/plot-special-topics.md` |
| Romance-focused long form (genre/blurb/platform/relationship line) | `references/female-audience-writing.md` |

### Phase 2: Core setting

| Scenario | Load |
|------|---------|
| Design characters | `references/character-basics.md` |
| Design relationships | `references/character-relations.md` |
| Genre framework & positioning | `references/genre-catalog.md` + `references/genre-core-mechanics.md` |
| Create artifacts | `references/artifact-protocols.md` |
| Reader contract & protagonist highlights | `references/reader-contract-and-progression.md` |

### Phase 3: Outline building

| Scenario | Load |
|------|---------|
| Build outlines | `references/outline-methods.md` |
| Design conflict & structure | `references/outline-conflict.md` |
| Deep structure design | `references/outline-structure-theory.md` |
| Rhythm & progression feel | `references/outline-rhythm.md` |
| Mini-outlines & stuck writing | `references/plot-core-methods.md` |
| Choose narrative frameworks | `references/plot-frameworks.md` |
| Genre writing formulas | `references/genre-writing-formulas.md` |
| Golden three chapters | `references/opening-design.md` |
| Emotion arcs | `references/emotional-arc-design.md` |
| Contract/endgame reserve/story-unit safety review | `references/reader-contract-and-progression.md` |
| Reversal design | `references/reversal-toolkit.md` |

### Phase 4: Prose writing

| Scenario | Load |
|------|---------|
| Chapter hooks | `references/hooks-chapter.md` |
| Suspense design | `references/hooks-suspense.md` |
| Paragraph-level hooks | `references/hooks-paragraph.md` |
| Genre prose card / genre cards | `references/genre-prose-cards.md` index + `references/genre-prose-cards/` single-card directory (prefer by genre) + `references/style-genre-modules.md` (generic style supplement) |
| Combat/status flex | `references/style-combat-face.md` |
| Writing craft | `references/style-craft.md` |
| Commercial core methods | `references/commercial-core-methods.md` |
| Dialogue | `references/dialogue-mastery.md` |
| Character deepening | `references/character-design-methods.md` |
| Emotion techniques + narrative units | `references/plot-emotion-system.md` + `references/emotional-methods.md` |
| Full writing craft reference | `references/writing-craft.md` |
| Format & structure norms | `references/format-and-structure.md` (dialogue/paragraph formats only for long form) |
| State tracking protocol | `references/state-tracking.md` |
| Current story unit & contract calibration | `references/reader-contract-and-progression.md` |

### Phase 5: Quality check

| Scenario | Load |
|------|---------|
| Quality check | `references/quality-checklist.md` + `references/reader-contract-and-progression.md` |
| Banned-word scan | `references/banned-words.md` |
| AI-pattern script rescan | `scripts/check-ai-patterns.js` |
| De-AI flavor | `references/anti-ai-writing.md` |

### Quick topic lookup (cross-cutting)

Some topics span multiple phases and live in several files. The table below gives one **authoritative file** per topic (read it first; usually enough); companion files only load when you need that angle. Parentheses show the relevant section inside the file.

| Topic | Authoritative file (read first) | Companion files (by angle) |
|------|-----------------|----------------------|
| Payoff (route by intent) | **`references/plot-emotion-system.md`** (payoff design system: essence/six types/back-derivation — "how to design payoffs" starts here) | Turnaround/climax payoffs →`references/plot-core-methods.md` (false win → collapse) · comeuppance/status-flex release →`references/style-combat-face.md` · genre comeuppance formulas →`references/genre-writing-formulas.md` · payoff loops/multi-layer →`references/outline-methods.md`·`references/outline-conflict.md` |
| Emotion modules | **`benchmark/{Book Title}/plot/emotional-beats.md` (project/book-level authority)**; read `references/plot-emotion-system.md` only when there is no benchmark or when designing new modules | `references/outline-rhythm.md` is theory reference only; it may not override the benchmark book's authoritative modules |
| Pacing | **`benchmark/{Book Title}/plot/pacing.md` (project/book-level authority)**; read `references/outline-rhythm.md` only when there is no benchmark or when designing new pacing | `references/plot-core-methods.md` is theory reference only; it may not override the benchmark book's authoritative pacing |
| Climax | **`references/plot-core-methods.md`** (climax construction formula: charge → false win → collapse) | `references/outline-rhythm.md` (climax classification & back-derivation) · `references/outline-methods.md` (eight-node story structure: structural positioning) |
| Cheat | **`references/plot-special-topics.md`** (cheat decomposition & power-creep prevention + advanced design) | `references/outline-conflict.md` (cheat & identity: four-point unity) |
| Romance line | **`references/character-relations.md`** (affinity system/four stages + male-/female-audience differences) | `references/outline-conflict.md` (romance-line design) · `references/style-combat-face.md` (harem lead design / male-audience minimal romance-line shape) · `references/plot-special-topics.md` (romance-line purification strategy) |
| Reversal | **`references/reversal-toolkit.md`** (reversal types/setup/effectiveness self-check) | `references/plot-core-methods.md` (false win: give hope first, then shatter) |
| Characters | **`references/character-basics.md`** (protagonist/supporting/antagonist/motivation blank templates) | `references/character-design-methods.md` (three-layer tag contrast/nine-dimension deepening) · `references/character-relations.md` (relationship types/romance line) |
| Romance-focused writing | **`references/female-audience-writing.md`** (romance-focused long form: core principles/blurb/genres/relationship long-line/platforms) | `references/genre-readers.md` (reader psychology/platform differences) · `references/character-relations.md` (romance-line overall framework) |
| De-AI flavor | **`references/anti-ai-writing.md`** (AI fingerprints/core rules/Show Don't Tell) | `references/banned-words.md` (banned-word scan) · `references/quality-checklist.md` (finished-text checks) |

---

## Language

- Follow the book's language rules: read `{BookTitle}/AGENTS.md` and the deployed book contract. `Prose language` governs prose drafting, `Record language` governs outline/setting/tracking/report outputs, and `English variant` governs spelling and conventions. If the profile is missing, stop for the language-selection gate before writing; never fall back to the user's chat language or silently choose English records.
