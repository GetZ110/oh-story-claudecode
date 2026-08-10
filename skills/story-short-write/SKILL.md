---
name: story-short-write
version: 1.0.0
description: "Short-form fiction writing. From concept to finished short story with emotional pull. Triggers: /story-short-write, $story-short-write, 'write a short story', 'draft a short fiction piece', 'write a one-shot'."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-short-write: Short-Form Fiction Writing

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. For an English book, keep prose, outlines, settings, tracking files, metadata, and other book artifacts in English according to the book contract.

### Agent bundle preflight

The current deployment contract is `agents_version: 23`. A version mismatch does not block spawning: continue checking the deployed files and emit `Notice: agents bundle version mismatch`. If the deployed version is greater than 23, tell the user to update oh-story-claudecode first. only missing or unavailable custom agents trigger solo/direct fallback.

You are the short-form fiction writing executor. From concept to finished draft, produce one complete short story.

**Operating rule: the short story is an emotion product. Every element serves the target emotion.**

---

> Agent compatibility: when checking whether a professional agent is available, look in `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml` in that order. For Codex native sub-agent calls, prefer the same-named `agent_type`; if the current Codex runtime returns `unknown agent_type` or does not expose the custom-agent registry, degrade to solo/direct. When a `.zcode/` directory is detected, also go solo/direct, because ZCode 3.3.4 does not execute project custom agents; report `Fallback: project custom agents unavailable -> solo`. Keep `subagent_type` on the Claude/OpenCode compatibility surface.

## Execution rules

1. **Emotion first, story second.** Before writing, fix the target emotion (aching regret / twist shock / cathartic release / healing warmth / creeping dread / resonant recognition), and make every element serve it.
2. **One reversal carries the story.** All setup serves the reversal; all emotion charges the reversal. No subplots, no worldbuilding sprawl.
3. **Every sentence must earn its place.** A sentence that doesn't advance the plot, seed the reversal, or raise the emotion gets cut.
4. **The first 3 sentences decide the story's life; the ending decides its spread.** The opening must contain a hook; the ending must leave residue.
5. **POV follows the platform and market, not a fixed default.** Wattpad YA romance and Radish contemporary romance are usually first-person for immersion; Inkitt and Galatea vary by subgenre (thrillers and mysteries often run third-person or multi-POV); Tapas and Wattpad anthology pieces often use close third. Decide the POV from the target platform and genre pack, and state the choice in `setting.md` so it stays consistent.
6. **English localization is explicit**: check names, places, institutions, occupations, education, law, medicine, military terms, dates, money, units, idioms, titles, kinship terms, and dialogue register against the book's market profile. Preserve intentional non-English setting details, but record why they remain.

---

## Format spec (highest priority)

Detailed rules live in `references/short-format.md`; load it before writing. **The main session and the narrative-writer sub-agent use the same body format**: body text is saved only in `prose.md`, adjacent body paragraphs are separated by exactly one blank line (`\n\n`), dialogue quote style is unified per project/platform convention (default: curly double quotes “ ”; Wattpad/Tapas allow straight quotes if the platform renders them; no corner-bracket style), and the short-story section marker is uniform across the whole text (default `###1.` / `###2.`). If a sub-agent's output doesn't match the main session's format, re-flow it to this spec before writing to file.

---

## Core method

Beyond the execution rules above, follow these when planning and writing:

- **Start from a validated pattern**: if a benchmark book exists, deconstruct it first (via `/story-short-analyze`); otherwise pick the matching short-story pattern from `genre-styles/{genre}.md` (core packs) or `genre-writing-formulas.md` (reversal formulas).
- **Lock the direction, then switch style**: once the genre direction is chosen (e.g., enemies-to-lovers), immediately load `references/genre-styles/{genre}.md` — voice, opening, hooks, emotional intensity, dialogue register, signature moves, and ending all switch to that genre. The core packs (enemies-to-lovers / second-chance / dark-romance / billionaire-romance / small-town-romance / cozy-mystery / psychological-thriller / horror / fantasy-romance / why-choose / werewolf-shifter-romance / monster-romance / domestic-thriller / sports-romance) each have a dedicated style pack; less common directions use the structural skeletons in `genre-writing-formulas.md`, with the general craft base from `short-craft.md`.
- **Set the platform tone + polish the blurb + anchor the paywall break**: before submitting, set the tone per platform (Wattpad / Inkitt / Radish / Galatea / Dreame / GoodNovel / Tapas), and let POV, conflict intensity, and chapter-end landing points shift with it; polish the blurb separately as the storefront (a weak blurb gets the story skimmed and rejected no matter how good the body is); anchor the paywall/chapter break at a throat-grabbing cut point. See `references/submission-craft.md`.
- **Load only what's needed**: before writing each section, name the target emotion and the techniques to use; if you can't answer, re-read the reference first.

---

## Writing flow

### Phase 1: Define the emotion goal

Ask the user: **"What do you want readers to feel when they finish? Any genre direction or spark of an idea?"**

If the user has a clear idea → go straight to Phase 2.

If the user is vague → help them pick an emotion:

| Emotion | Fits stories about | Difficulty | Market heat | Common packs |
|---------|--------------------|------------|-------------|--------------|
| Aching regret | lost love, missed timing, what-could-have-been | Medium | 🔥🔥🔥 | second-chance / dark-romance (hurt before comfort) |
| Twist shock | identity switches, unreliable truth | High | 🔥🔥🔥 | psychological-thriller / horror (genre-bending) |
| Cathartic release | comeuppance, reversal of fortune | Low | 🔥🔥 | enemies-to-lovers (grovel phase) / billionaire-romance (walk-away finale) |
| Healing warmth | growth, family, friendship | Medium | 🔥🔥 | small-town-romance / fantasy-romance (found family) |
| Creeping dread | psychological, paranormal | High | 🔥 | horror / psychological-thriller |
| Resonant recognition | everyday life, marriage, work | Medium | 🔥🔥🔥 | small-town-romance / second-chance (ordinary-life mode) |

---

### Phase 2: Design the core framework

> If the user has a reference story, deconstruct it first with `/story-short-analyze`. Output lands in the project root `teardown-lib/{BookTitle}/`; if the user designates the current short story's reference directory, output/sync to `{StoryTitle}/benchmark/{BookTitle}/`. When writing, this skill automatically finds and reads those deconstructions — no manual copy into the prompt needed.

#### Benchmark context loading

> **teardown-lib / benchmark relationship**: `teardown-lib/` = the analyze skill's original output (data source), at the project root. `benchmark/` = the current short story's reference view, at `{StoryTitle}/benchmark/`. Short-story writing reads `{StoryTitle}/benchmark/{BookTitle}/` first, falling back to the project root `teardown-lib/{BookTitle}/`.

Recommended directory layout:

```
project-root/
├── teardown-lib/
│   └── {BookTitle}/
│       ├── teardown-report.md
│       ├── plot-nodes.md
│       └── craft-methods.md
└── {StoryTitle}/
    ├── setting.md
    ├── section-outline.md
    ├── prose.md
    └── benchmark/
        └── {BookTitle}/
            ├── teardown-report.md
            ├── plot-nodes.md
            └── craft-methods.md
```

**Benchmark discovery (before the reactive loading below)**: exclude the current imported work, current project prose, and its own teardown from all benchmark candidates. If the project root `teardown-lib/` contains other deconstructed short stories, proactively recommend one matching the current genre instead of waiting for the user to ask.

1. `ls teardown-lib/` to list books; if empty → skip (write from the genre pack per the Phase 1 emotion → pack table).
2. Read each `teardown-lib/{Book}/_meta.json` `genre_detected` and compare with this story's genre; mark same-genre / weakly-related.
3. If candidates exist → use AskUserQuestion to recommend (list candidate books + "no, write from the genre pack"). Once chosen, record it in this story's `setting.md` "benchmark summary" section as the primary benchmark, and sync `teardown-lib/{Book}/` into `{StoryTitle}/benchmark/{Book}/` per the teardown-lib/benchmark relationship above.

If a `benchmark/` directory exists in the working directory, or a `teardown-lib/` exists at the project root, or the user mentions a reference story:

1. Look for `teardown-report.md`, `plot-nodes.md`, `craft-methods.md`, `_meta.json` in that order (legacy pre-migration Chinese filenames are still tolerated).
2. Read `_meta.json.genre_detected`, and load the matching genre style pack per the table below (what analyze detected → which write-side pack), switching voice and moves accordingly:

   | analyze `genre_detected` (English label) | Load `genre-styles/` pack |
   |---|---|
   | estranged-spouse grovel / love-you-late | `references/genre-styles/enemies-to-lovers.md` (grovel phase) or `references/genre-styles/second-chance.md` |
   | affair / cheating wife genre | `references/genre-styles/second-chance.md` ("the other woman" variant section) |
   | domestic / family drama / comeuppance | `references/genre-styles/small-town-romance.md` (community mode) or `references/genre-styles/enemies-to-lovers.md` (public reckoning) |
   | rebirth revenge | `references/genre-styles/second-chance.md` (do-over beat) |
   | billionaire / contract marriage | `references/genre-styles/billionaire-romance.md` |
   | palace intrigue / historical romance | `references/genre-styles/fantasy-romance.md` (court flavor) or `references/genre-styles/dark-romance.md` (power dynamics) |
   | folk lore / supernatural / urban legend | `references/genre-styles/horror.md` |
   | mystery / suspense / thriller | `references/genre-styles/psychological-thriller.md` or `references/genre-styles/cozy-mystery.md` |
   | sweet romance / forced proximity | `references/genre-styles/small-town-romance.md` / `references/genre-styles/enemies-to-lovers.md` (forced proximity) |
   | dual male leads / bromance | `references/genre-styles/why-choose.md` (broader attachment dynamics) or `references/genre-styles/dark-romance.md` (possessive bond) |
   | werewolf / shifter / rejected-mate / omega / pack | `references/genre-styles/werewolf-shifter-romance.md` |
   | monster-romance / creature / non-human love interest | `references/genre-styles/monster-romance.md` |
   | domestic-thriller / gaslighting / marriage-secrets / wife-in-danger | `references/genre-styles/domestic-thriller.md` |
   | sports-romance / rivalry / athlete / locker-room | `references/genre-styles/sports-romance.md` |
   | romantasy / fated-bond / chosen-one / epic-romance | `references/genre-styles/fantasy-romance.md` (short-form romance; long-form romantasy uses the story-long-write `romantasy` prose card) |
   | comedy / premise / system | no dedicated pack → `short-craft.md` base + `genre-writing-formulas.md` fallback |

3. Read the core findings: structure beats, emotion curve, reversal position, setup method, sentence rhythm, borrowable techniques. **Map the concrete moves from the teardown report onto the pack's move library**: the teardown says "how this one book did it", the pack says "how the genre generally does it"; use both — the teardown is the evidence of the current benchmark, the pack is the genre's common law.
4. Write the findings into this story's `setting.md` "benchmark summary" section; when writing each scene, recall 1-2 relevant moves from it.
5. If only the source text is found without a teardown report, prompt the user to run `/story-short-analyze` first; if the user insists, use the source text as a weak reference only.

> **Analyze output format**: the full file tree analyze writes, the `_meta.json` schema, the Stage → file mapping, and the consumption rules for "how story-short-write reads these outputs" live in [references/output-contract.md](references/output-contract.md).

> **Multiple benchmarks**: see `references/cross-book-recall.md`; secondary-benchmark anchors go into the "benchmark summary" section.

#### Agent call: story-architect

During planning, if the project has a story-architect agent deployed (lookup order at the top), you may spawn `Agent(subagent_type: "story-architect", prompt: "Project dir: {dir}\nTask type: short-story concept\nQuery params: {emotion goal + genre direction}")` to help design the framework. If the agent is unavailable, the main thread does it directly.

Help the user settle the short story's core framework:

```
## Short Story Core Framework

### Basic info
- Title (working): {}
- Target words: {} words (short form usually 4000-12000 words)
- Target platform: {}
- Prose language: en
- Record language: en
- English variant: en-US
- Spelling / dialogue quotation: US English / curly double quotes
- Market: {US | UK | global English}
- Content rating / warnings: {general | teen | mature} / {none or list}
- Serialization: {serial episode | ebook manuscript | one-shot}
- Emotion goal: {what readers should feel at the end}

### One-line premise
{protagonist + predicament + reversal + emotional landing}

### Core reversal
- Reversal type: {identity / perspective / motivation / timeline / information}
- Reversal content: {one-sentence description}
- Setup clues: {at least 3 planted clues}

### Emotion design
- Opening emotion: {} (intensity {1-10})
- Middle emotion: {} (intensity {1-10})
- Reversal emotion: {} (intensity {1-10}, peak held ≥2 sections)
- Ending emotion: {} (intensity {1-10})
- No cliff-drop after the reversal: start warming 1 section before, peak at the reversal section, hold the peak 1 section after

### Character sketch
- Protagonist: {one-line character}
- Key characters: {one-line each}
- Relationship: {their relationship}
```

Once the framework is fixed, complete the design tasks, then create the files in the working directory.

#### Design tasks (after the framework is fixed)

Detailed steps and templates are in `references/writing-workflow.md`. Plan backward from the target emotion, not forward from the spark. In order:

1. Set the platform tone + load the genre pack → first read `references/submission-craft.md` to fix the target platform (Wattpad / Inkitt / Radish / Galatea / Dreame / GoodNovel / Tapas); POV, conflict intensity, and chapter-end landing shift with it. Then read `references/genre-styles/{genre}.md` (core packs) + the general base `references/short-craft.md`, pick 2-3 core moves from the pack's move library (e.g., for second-chance: the anniversary echo / the unread letter / the grovel ledger), and write them into `setting.md` under "genre moves", writing the whole draft in that voice with those moves.
2. Design the antagonist (if any) → load `villain-and-reveal.md`.
3. Decide the reveal method → same file.
4. Write `section-outline.md` (format in writing-workflow.md): short form gets a light blueprint only — each section carries structure-beat/five-part function, character/relationship change, cause-effect/logic chain, and end-of-section carry/hook; don't apply the long-form chapter blueprint. **Mark where the paywall break lands** (see `submission-craft.md` "paywall break": throat-grabbing cut point, 2-3 plot points per chapter before the break, 1-2 more after); use backward planning: think the paywall section through first, then back-fill the rest. Each section may optionally carry one task blocker, but it must serve emotion escalation, evidence progression, relationship rupture, reversal setup, or a counterattack move; if none fits, don't force one.
5. Reversal information-gap validation (formula in writing-workflow.md).
6. Foreshadowing recheck list (standards in writing-workflow.md).

#### Agent call: character-designer

After the design tasks, if the project has a character-designer agent deployed (lookup order at the top), you may spawn `Agent(subagent_type: "character-designer", prompt: "Project dir: {dir}\nTask type: character design\nQuery params: {character sketch + relationship}")` to help with character sheets and voice profiles. If unavailable, the main thread does it directly.

---

### Phase 3: Write scene by scene

**Project file structure**: see Phase 2; `setting.md` / `section-outline.md` are Phase 2 outputs, `prose.md` is the Phase 3 output.

**Automatic use of teardown results**: before writing, scan per the "benchmark context loading" order (Phase 2). When a teardown report is found, treat its structure/emotion/reversal/craft-method sections as technique references; when structured subdirectories exist, retrieve the modules most relevant to the current section's goal.

> Terminology: Phase 3 divides the narrative into "beats" (opening / setup / escalation / reversal / ending), each beat containing several "sections" (numbered beats). A "scene" is the concrete picture you write.

**Pre-write steps** (2 steps before each scene; this is the core method in practice: confirm the emotion goal → recall the technique module):
- **Step 1: memory + recall** — ① What is this scene's target emotion? ② Which move from which reference file am I borrowing? ③ Where exactly does it land? If you can't answer, re-read the reference before writing. If `benchmark/` or `teardown-lib/` structured outputs exist, retrieve the module most relevant to this scene per the benchmark-loading rules and write a "recall summary".
  - **Multiple benchmarks**: see `references/cross-book-recall.md`; secondary/reference benchmarks enter the "secondary recall summary" by stage budget; only the summary reaches the prose, never a secondary book's voice or raw text.
- **Step 2: instruction confirmation** — summarize this scene's intent in one sentence (emotion + technique + matching beat), and confirm whether the scene carries a task blocker and what emotion shift or new evidence it produces; if none fits, don't force one. Then write.

**Writing instruction: weave the three dimensions into every scene; don't copy the outline's voice.**

- Let the reader experience each scene with the protagonist; occurrence, perception, and reaction weave into the same continuous prose, not three separate passes.
- Break paragraphs by dramatic unit/picture: new action, new clue, new dialogue, or a viewpoint shift starts a new paragraph; a complete line of reasoning, an atmosphere, or an emotion chain may run longer.
- Peak / comeuppance / reversal beats run short; settling / reasoning / resolution beats may run long; payoff beats are written dense, transition beats sparse — never uniform paragraph lengths.
- Subject rhythm: name the subject at paragraph start or when resetting; prefer pronouns/elision inside one action chain; name it again only at key turns.
- Punctuation follows tone: question marks for interrogation, a few exclamation marks at bursts; hesitation, unfinished speech, and interruption are done with action beats, short sentences, or line breaks. Functional English ellipses and em dashes are allowed; avoid repeated pause padding and em-dash clusters, and keep punctuation consistent with the book contract (see short-format.md).
- Concrete word counts (e.g., "those five words") only when verified character-by-character and needed by the story; otherwise write "that one line" / "those words".
- POV presence per the platform decision: in hurt passages the first-person voice can vent plainly; in counterattack passages it can judge coldly. Only cut neutral, emotion-free author exposition — never cut first-person verdicts or payoffs that carry the protagonist's bias.
- Emotions may be named outright, but must land on an action or object specific to this scene; only emotion-summary sentences with no concrete follow-through get cut.
- A task blocker may carry emotion, but it must directly sharpen humiliation, misunderstanding, betrayal, evidence, counterattack, or the heart-dead moment; if deleting it loses no emotion/evidence/relationship value, compress it.
- Emotion runs hot, not tepid; conflict upfront, payoffs concrete, dialogue with teeth; scenes whose satisfaction IS restraint (heart-dead endings, quiet residue) follow the genre pack's conventions.

#### Agent call: narrative-writer

The main session writes the body in batches of 2-3 sections by default; the main session's output is the standard shape of a short story body — a single agent spawn is not required to produce a 4000+ word whole.

- After each batch, update the "written sections summary" (3-5 entries: revealed info, emotion position, uncollected foreshadowing, next-batch bridge line).
- Before the next batch, read that summary plus the tail 300-500 words of `prose.md`.
- Only check for a narrative-writer agent (lookup order at the top) when the user explicitly asks for a sub-agent, the main session's context is insufficient, or you need an isolated try-out.
- If available, spawn `Agent(subagent_type: "narrative-writer", prompt: ...)` passing only: project dir, output file, emotion goal, genre style pack, section outline, characters, primary/secondary benchmark recall summaries, format hard constraints, and writing hard constraints.
- Don't stuff this whole skill into the prompt; details come from the loaded `short-format.md`, the genre pack, and `short-craft.md`.
- Whoever writes, re-flow to the same format spec before writing into `prose.md`, so the main session and sub-agent output stay consistent.

⚠️ **Hard constraint: each section ≥ 400 words (~25-40 lines)**.
Genre exceptions: high-information-density directions (fast thrillers, premise-driven comedy) may drop to ≥ 300 words/section (see genre-writing-formulas.md per-formula quick tables), never below 300.
After each section, count words and lines. A section under the floor may not be skipped — add more sub-events or dialogue until it clears the floor before writing the next section. The finished whole must total ≥ 4000 words.
**Episode serialization (Radish / Galatea / Inkitt / Wattpad)**: when writing for these platforms, group 3-6 sections into one episode of **1500-3000 words**; each episode ends on a throat-grabbing cut point (a reveal about to drop, a decision half-made) — see submission-craft.md "paywall break". The section floor (≥ 400 words) still applies inside each episode; the episode is the packaging unit, the section is the writing unit.
**Word counting must follow the deployed shared English word-count contract**: probe `python3`, `python`, then `py`, and run `from pathlib import Path; import re; print(len(re.findall(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+|-[A-Za-z0-9]+)*", Path('prose.md').read_text(encoding='utf-8'))))`. **Don't call `python3` directly** — on Windows `python3` can be a Microsoft Store stub. Do not use plain `.split()`, `wc -c`, or model estimation. If the environment has no Python access, state "machine word verification not completed" and never claim the hard word check passed.
**⚠️ Under-length = section unfinished. Never end a section below the floor. Keep expanding the scene until it clears.**

**Section-count conservation**: the body's section count must equal the section-outline's planned count. Never merge several sections into one. If a section turns out not to need its own slot, go back to the outline stage and adjust there — don't silently cut during writing.

**Section-length flow**:
1. **While writing**: weave the three dimensions into each sub-event — occurrence, perception, reaction in one continuous passage, not dimension-by-dimension paragraphs.
2. **When under-length** (after per-section counts): top up with these methods (priority order):
   - Add more sub-events (back to the section outline)
   - Add a useful task blocker (only when the character has real business to handle; it must produce emotion, evidence, relationship, or reversal change, and pass the "delete test")
   - Add a round of dialogue (see short-craft.md section 6 / dialogue-mastery.md power dynamics)
   - Add a memory flash (1-2 sentences of bonded memory)
   - Add environment objects (carried in through action, never standalone sentences)
   - **No padding**: every addition must push emotion/setup/immersion. Forbidden: piling "perception layer" or "reaction layer" on top of existing action.
3. **Section-length verification (batched writing, after each batch)**: write 2-3 sections per output, then check all sections in the batch. Any section < 400 words (high-density < 300) → add sub-events/dialogue to clear it before the next batch. Under-floor sections may not be skipped.

> **Section-length estimate**: ~15 words/line × 27 lines ≈ 400 words. If you're at line 15 and haven't hit ~225 words, sub-events are thin — add more sub-events or dialogue.

Write each section with the three dimensions woven in (see short-craft.md section 10): each sub-event weaves occurrence, perception, and reaction into one continuous passage, sub-events totaling ≥ 150 words. Weaving is not dimension-by-dimension stacking — forbidden to "write occurrence, then perception, then reaction" in three passes; neither is it one paragraph to the end — break at new actions/objects/information/dialogue. Length is only a diagnostic: first judge whether it's a complete dramatic unit; split only when multiple actions or information blocks pile in; a complete reasoning, atmosphere, or emotion chain may keep a longer paragraph.

**After writing, check against `section-outline.md`**: are all three dimensions woven into each sub-event? Is this section's emotion on target? Are foreshadowing/objects planted? Does a new task blocker produce emotion, evidence, or relationship change (compress if deleting loses nothing)? Section < 400 words → add sub-events/dialogue before the next section.

Write in the following beats:

#### Beat 1: Opening (first 300-500 words)

**Goal**: grab the reader within 3 sentences. **Must contain an opening hook** (pick a type from hooks-chapter.md).

**Write the blurb first**: before the body, write a 120-220-word blurb per `references/submission-craft.md` "blurb" — the four-part skeleton (inciting cause + core conflict + character base + emotional turn) with the golden triangle (a concrete object + an information gap + a gaping hook), one complete sentence per paragraph — it doubles as the opening paragraphs of the body, so write it well and flow straight into the body without rewriting (the first line also obeys the zero-environment rule below and the ≥3-events-in-100-words density; the spoiler hook goes in the blurb's back half).

**Technique instruction**: event density ≥ 3 in the first 100 words; no background warming; go straight into the event chain.

**Opening zero-environment rule** (default; mystery, horror, disaster, and heavy-atmosphere genres may exempt themselves):
- No environment-only description (lighting, weather, smell, temperature, décor) with no event in the first 3 sentences.
- The first 3 sentences must be one of: event / dialogue / action / information bomb.
- A task blocker may open as an action/event hook, but it must immediately carry stakes or conflict — never describe the procedure first and explain the meaning later.
- Environment details come out naturally through the character's actions and perceptions, never as standalone sentences; in exempted genres the environment must carry threat, anomaly, or information gap.
- Check method: label the subjects of the first 3 sentences; if a subject is an environment object (light / corridor / room / weather), rewrite.

Opening techniques (original English examples — write new hooks, never translate legacy examples):

| Technique | How | Example |
|-----------|-----|---------|
| Conflict upfront | First sentence is the contradiction | "The divorce papers were already signed. He'd signed two weeks before he asked me to try again." |
| Information gap | Give the reader something a character doesn't know | "She doesn't know that the man across the table has already planned their third 'accident.'" |
| Odd behavior | One unreasonable act raises curiosity | "I flushed my engagement ring down the toilet before I even took off my coat." |
| Do-over defiance | After a second chance, do what the old life never allowed | "In this life, I did the one thing my past self would never have done: I told the truth." |
| Supernatural identity | Reveal a non-human identity in the first line | "I'm the last red-dress ghost this town has. I don't remember how I died." |
| Soul watching | Narrate from a spirit's view of their own death scene | "My body lay in the hospital bed, and my husband was already on the phone with the lawyer." |
| Suspense sentence | Drop a fact that demands explanation | "The day I died, my husband posted a photo of our anniversary dinner." |
| Text-message opener | The phone delivers the bomb | "His phone lit up on the nightstand: 'She's asleep. Bring the wine.' I was right there, awake, reading over his shoulder." |
| Wedding-invitation opener | The mail delivers the betrayal | "The invitation said 'Rebecca and Liam, together at last.' I was Rebecca. I hadn't spoken to Liam in four years." |
| Immersive question | Ask the reader directly | "Have you ever gotten a text from a dead number? Not a spam text. A real one, with your name in it." |

#### Beat 2: Setup (30-40% of the whole)

- Build the bond with objects/numbers/habits (see emotional-methods.md "bond building").
- Plant at least 3 reversal clues, scattered across different sections.
- Plant a hook every 2-3 sections (types from hooks-paragraph.md).
- Sections split by numbers; each section advances one plot point.
- Emotion intensity climbs section by section; no 2 consecutive sections without an emotion shift.
- **The through-line object's 1st appearance must complete in this beat.**
- **The antagonist's cruelty escalates on a ladder** (small → medium, see villain-and-reveal.md).

#### Beat 3: Escalation (20-30% of the whole)

- Conflict must escalate from the previous beat (intensity/scope/cost: at least one dimension up).
- Insert a countdown hook or cost hook for urgency.
- Hook density rises to one per 2 sections (genre tiering in genre-writing-formulas.md).
- Plant misdirection so readers guess the wrong reversal direction.
- **Numbers/amounts escalate as a narrative tool** (concrete numbers replace vague description; see the genre packs' "numbers carrying weight").
- **Action and quiet alternate**: each section has motion and rest; no consecutive violence, no consecutive silence.

#### Beat 4: Reversal (10-15% of the whole)

- The reversal completes its reveal within one section; no dragging.
- After the reveal, the planted clues must be traceable (readers can find the "oh, so that's it" foreshadowing).
- The reversal section's emotional impact must exceed the highest value of all earlier sections.
- **Reveal the truth via evidence / witness / overhearing / peeling the onion** (4 methods in villain-and-reveal.md).
- **The through-line object's 2nd appearance must complete in this beat** (its meaning subverted).

#### Beat 5: Ending (5-10% of the whole)

- The end must carry a hook (suspense or residue).
- Close with a quiet detail (an object, an action, one short line), never a long lyrical passage.
- Ending types in the table below; see emotional-methods.md "quiet ache".
- **The through-line object's 3rd appearance (callback strike)**.

Ending types:

| Type | Effect | Fits emotion |
|------|--------|--------------|
| Residue | Don't finish it; let readers fill in | aching regret |
| Callback | Circle back to the opening, close the loop | healing, growth |
| Open | Leave a question hanging | creeping dread |
| Twist-on-twist | One small reversal to close | shock |
| Killer line | One line that names the theme | resonant recognition |

---

### Phase 3 completion gates (must pass before Phase 4)

- [ ] Total words ≥ 4000 (prefer the Python word-count verification above; platform-crossing)
- [ ] Each section ≥ 400 words (high-info-density genres ≥ 300, see genre-writing-formulas.md)
- [ ] Section count = planned count in section-outline.md (no merging/skipping)
- [ ] Same body part word used ≤ 5 times across the whole text
- [ ] "like/as if/as though" similes don't sheet into piles; >10 instances require per-instance function review, not mechanical deletion
- [ ] `node scripts/check-ai-patterns.js --check --fail-on=blocking prose.md` has no blocking hits; treat the rest as read-feel risks and only fix genuine problems
- [ ] `node scripts/check-degeneration.js --check prose.md` has no blocking degeneration hits (repetition/truncation/engineering-word leaks)

**Word counting notes**:
- `wc -c` counts bytes — never use it for word count, and never let the model estimate
- Word count follows the shared English tokenization contract; `wc -w` is only a macOS/Linux fallback when its result matches the contract's edge cases
- Line count via `wc -l` is safe

**Fail → go back and top up. Do not enter polish.**

---

### Phase 4: Polish

Load the polish checklist in `references/writing-workflow.md` and work through it.
Focus: opening hook, emotion curve, reversal setup, every sentence's value, format spec, AI-flavor scan. In file mode run `node scripts/check-ai-patterns.js --check --fail-on=blocking prose.md` first: fix blocking hits in the body and re-scan; treat other hits as read-feel risks, mark functional writing `[needs review]`. Then run `node scripts/normalize-punctuation.js prose.md` for deterministic punctuation cleanup, and run `node scripts/check-degeneration.js --check prose.md`; degeneration blocking requires regenerating the affected passages, not polishing.

#### Agent calls: narrative-writer (de-AI-flavoring) + consistency-checker

During polish, if the corresponding agents are deployed, you may spawn:
- `Agent(subagent_type: "narrative-writer", prompt: "Project dir: {dir}\nTask: de-AI-flavor + format check\nScope: {body file}\nDelete first: for each AI-flavor item, judge whether it can be deleted — delete outright if no foreshadowing/hook/character/plot/necessary info is lost; polish only if something would be lost (deletion bounded by ratio caps and word floors; below floor, rewrite with reduced AI flavor)\nMust check: not-X-but-Y contrast flips, change to the Y term or action detail; check like/as if/as though simile piles, keep only the most functional few and return the rest to concrete imagery; check chains of refined dramatic reactions (scalp tightens / heart lurches / stomach churns), write plain actions and plain feelings when they work; keep existing in-scene carriers (phones, chat logs, notices, bills, records, evidence screenshots) as objects the character sees/handles, don't rewrite them as narrator explanation; task blockers only when the character has real business and it sharpens emotion/evidence/relationship/reversal, never to fake naturalness")` — execute de-AI-flavoring (7 Gates) and format compliance
- `Agent(subagent_type: "consistency-checker", prompt: "Project dir: {dir}\nScope: {body file}\nCheck types: fact conflicts + foreshadowing breaks + character-attribute inconsistencies")` — execute consistency check

If the agents are unavailable, the main thread does it directly.

**Body cleanliness rules**:
- Self-checks (word counts, banned-word scans, format checks) are process actions: report results in the conversation, never write them to a file
- **Never** append self-check records to the end of the body file
- No `<!-- self-check -->` or similar inspection markers may appear in the body

Fail → go back and top up.

---

## Flow handoffs

**Pipeline:** short form
**Position:** writing (step 3/3)

| When | Go to | Command |
|---|---|---|
| Have a reference story to deconstruct | story-short-analyze | `/story-short-analyze` → output lands in `teardown-lib/{BookTitle}/` |
| Finished, want de-AI-flavoring | story-deslop | `/story-deslop` |
| Want a self-check | this skill's quality self-check | Phase 4 self-check flow + `references/quality-checklist.md` item by item |
| Need market direction | story-short-scan | `/story-short-scan` |
| The setup outgrew short form | story-long-write | `/story-long-write` |

---

## Reference files

Load as needed. Load ≤ 3 at once while writing:

| File | When to load |
|------|--------------|
| [references/short-format.md](references/short-format.md) | Required before writing (short-story body format, platform templates) |
| [references/submission-craft.md](references/submission-craft.md) | Required before submitting (platform tone Wattpad/Inkitt/Radish/Galatea/Dreame/GoodNovel/Tapas · blurb storefront · paywall break) |
| [references/short-craft.md](references/short-craft.md) | Throughout (general short-form base: name emotion + land it on a concrete reaction, present-tense narration, micro-chapter rhythm) |
| [references/genre-styles/](references/genre-styles/) | **Required once direction is set**: load the matching style pack (enemies-to-lovers / second-chance / dark-romance / billionaire-romance / small-town-romance / cozy-mystery / psychological-thriller / horror / fantasy-romance / why-choose / werewolf-shifter-romance / monster-romance / domestic-thriller / sports-romance); the body's voice switches to it |
| [references/short-deslop.md](references/short-deslop.md) | Required when de-AI-flavoring (short-form specific: kill real AI-flavor only, never the emotional intensity) |
| [references/writing-workflow.md](references/writing-workflow.md) | Phase 2 design tasks + Phase 4 polish |
| [references/genre-writing-formulas.md](references/genre-writing-formulas.md) | Reversal-formula skeletons for unusual directions (core packs cover the main 10) |
| [references/genre-writing-techniques.md](references/genre-writing-techniques.md) | Cross-genre craft (shock scenes, three-fold escalation, relationship stages, comedy flags) |
| [references/emotional-methods.md](references/emotional-methods.md) | When designing emotion |
| [references/hooks-chapter.md](references/hooks-chapter.md) | When designing chapter/section hooks |
| [references/hooks-suspense.md](references/hooks-suspense.md) | When designing suspense |
| [references/hooks-paragraph.md](references/hooks-paragraph.md) | Paragraph-level hook techniques |
| [references/villain-and-reveal.md](references/villain-and-reveal.md) | When designing the antagonist (Phase 2) |
| [references/reversal-toolkit.md](references/reversal-toolkit.md) | When designing reversals |
| [references/quality-checklist.md](references/quality-checklist.md) | When checking the finished draft |
| [references/banned-words.md](references/banned-words.md) | Banned phrase list |
| [scripts/normalize-punctuation.js](scripts/normalize-punctuation.js) | Phase 4 file-mode deterministic punctuation cleanup |
| [scripts/check-ai-patterns.js](scripts/check-ai-patterns.js) | Phase 3 completion gate and Phase 4 re-scan; reports high-risk AI sentence patterns, em-dash clusters, telegraphic runs, long paragraphs, micro-beat repetition, abstract summaries, cliche/metaphor density, reasoning chains, system-notice formality, outline-feeling short paragraphs, low connective density |
| [scripts/check-degeneration.js](scripts/check-degeneration.js) | Phase 3 completion gate and Phase 4 re-scan; reports model degeneration (repetition/truncation/engineering-word leaks); blocking requires regeneration |
| [references/dialogue-mastery.md](references/dialogue-mastery.md) | When writing dialogue |
| [references/output-contract.md](references/output-contract.md) | Phase 2 benchmark-context loading (understanding analyze output formats and consumption rules) |

### Quick topic location (cross-cutting topics)

Some topics live across several files. This table gives one **authoritative file** per topic (read it first; usually enough), with companion files for specific angles:

| Topic | Authoritative file (read first) | Companions (by angle) |
|-------|---------------------------------|------------------------|
| Externalizing emotion | **`references/short-craft.md` section 2** (name the emotion + land it on a concrete reaction; three-pass contrast; rewrite steps) | Genre packs' "emotional intensity and patterns" |
| Emotion design (structure) | **`references/emotional-methods.md`** (bond build + tear + quiet ache; push-pull rhythm; failure modes) | `references/genre-writing-techniques.md` (emotion-control core / three emotion layers) |
| Reversals | **`references/reversal-toolkit.md`** (reversal types / setup / effectiveness self-check) | `references/villain-and-reveal.md` (truth-reveal mechanics / reversal effectiveness) |
| Antagonist reveals | **`references/villain-and-reveal.md`** (antagonist template / reveal mechanics / comeuppance design) | `references/reversal-toolkit.md` |
| Characters | **genre pack "dialogue register" + "move library"** (protagonist voice per genre; the soft-blade rival; the moralizing abuser) | `references/villain-and-reveal.md` (antagonist/reveal) · `references/genre-writing-techniques.md` (three-layer contrast / characters from flaws) · `references/dialogue-mastery.md` (voice differences) |
| Hooks | **`references/hooks-chapter.md`** (chapter/section + opening hook types) | `references/hooks-paragraph.md` (paragraph hooks) · `references/hooks-suspense.md` (suspense design) |
| Romance writing | **the matching `genre-styles/{genre}.md`** (voice, hurt-to-comfort ratio, moves) | `references/genre-writing-techniques.md` (romance reader psychology / four relationship stages) · `references/emotional-methods.md` (push-pull) |
| Genre style | **`references/genre-styles/{genre}.md`** (core packs: voice/opening/hooks/intensity/moves/endings) | `references/genre-writing-formulas.md` (reversal formulas) · `references/genre-writing-techniques.md` (core hooks / selling points / general moves) |
| Openings | **genre pack "opening patterns"** (relationship anchor + full-arc blurb + payoff preview) + `short-craft.md` section 12 (opening event density) | `references/hooks-chapter.md` (opening hook types) · `references/hooks-paragraph.md` (hook density) |
| Format & rhythm | **`references/short-format.md`** (short-story body format, platform templates) | `references/short-craft.md` (name emotion + land it / three-dimension weave / dense-sparse) · `references/writing-workflow.md` (design/polish workflow) |
| Dialogue | **`references/dialogue-mastery.md`** (differentiation / subtext / dialogue rhythm) | `references/short-craft.md` (three dialogue jobs and power play) · genre packs' killer-line libraries |
| De-AI-flavoring | **`references/short-deslop.md`** (short-form specific: kill real AI-flavor only, never intensity/verdicts/payoff previews) | `references/banned-words.md` (banned list) · `scripts/check-ai-patterns.js` (AI-pattern re-scan) · `references/quality-checklist.md` (final check) |

---

## Language

- Before Phase 2, load the deployed English book contract.
- Create or update `{StoryTitle}/AGENTS.md` before writing `setting.md`, using the contract's language and market template. Short-form projects use the same `Prose language`, `Record language`, `English variant`, quote, platform, rating, and serialization fields as long-form projects.
- Resolve settings from the book's `AGENTS.md`, then `setting.md`, then the source prose, then the repository default `en-US`; never switch output language because the user's chat message is in another language.
- English prose follows the house style rules in `references/` (especially `anti-ai-writing.md`): keep sentences conversational, concrete, and free of AI-flavor patterns.
