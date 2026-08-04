# Genre Style Modules

> Core principles, key techniques, and writing points per genre. Consult the matching module after fixing the genre direction.

---

## Decision routing

| What you're doing | Which module |
|-----------|-------------|
| Write humor/comedy/absurdity | humor / comedy / absurd style |
| Write mystery/investigation/horror | mystery / investigation / horror |
| Write romance/redemption | romance / redemption-conflict design |
| Write fantasy/cultivation | fantasy/cultivation + progression/payoff fiction |
| Write realistic/slice-of-life/new-media | realistic/slice-of-life |
| Write light-novel/anime style | light-novel/anime style |
| Write cyberpunk | cyberpunk style |
| Write ranking/mock/live-stream fiction | ranking-info-gap fiction / mock fiction / live-stream fiction |
| Pick a genre / fix the track | market positioning & topic strategy -> traffic & track -> bandwagon & innovation |
| Design the opening | creation approach & opening design -> low-position opening flow -> the five opening keys |
| Judge genre boundaries | boundary feel & atmosphere -> per-site style differences |
| Generate a genre prose card by genre | `genre-prose-cards.md` index + `genre-prose-cards/{genre}.md` single card |
| Design combat/fights | go to style-combat-face.md |

## Directive tone

This file is written in "genre operations manual" tone. Each genre module gives the genre's **core rules and operation points** — **must-follow** constraints when writing that genre. On cross-genre fusion: primary-genre rules > secondary-genre rules > generic advice.

## Genre prose card combination mode

Prose writing uses the three-piece set: **generic prose requirements + genre prose card + this book's style**; no longer copying a full prose prompt per genre.

- **Generic prose requirements** are handled by `story-long-write` Phase 4: strictly consume the chapter outline, write per plot-point budgets, advance slowly, no early later-plot writing, complete word-count/hook/banned-word/degeneration validation.
- **The genre prose card** governs the genre layer's stable core: worldview or life logic, reader expectations, core payoff/emotion, pacing density, scene granularity, drift bans. The project matches the `genre-prose-cards.md` index first, then reads the single card `genre-prose-cards/{genre}.md`; this file only supplements generic style modules.
- **This book's style** comes from `setting/style.md` or the benchmark `style.md`: sentence length, punctuation, subtext, anchor excerpts, and tone; it does not override genre core or chapter intent.
- On conflict between the three: chapter outline & continuity > genre prose card > this book's style > generic technique advice.

### Genre prose card template

The project may generate `setting/genre-prose-card.md` in Phase 2. Without that file, Phase 4 pre-write first matches the `genre-prose-cards.md` index from `setting/genre-positioning.md` and reads the single card `genre-prose-cards/{genre}.md`; if still no match, extract a lightweight card from this file on the fly. Keep the card short; pass the summary to `narrative-writer`; never copy whole reference files into the prompt.

```markdown
## Genre Prose Card

- Primary genre / platform: {e.g. Webnovel male · urban martial}
- Genre boundaries: {what this book must taste like, and what it must not drift into}
- Core logic: {how worldview/social relationships/life pressure/ability rules drive conflict}
- Reader expectations: {what readers come in waiting for: comeuppance, progression, emotional debt, info gaps, approaching suspense, etc.}
- Core payoff / emotion: {the 1-3 most stable release modes of this genre}
- Pacing density: {ratios of setup, burst, cooldown; what low-pressure chapters are allowed to do}
- Scene granularity: {which concrete carriers this genre needs: bills/stores/sect rules/comment barrages/case clues, etc.}
- Dialogue & character voice: {what dialogue carries in this genre; which roles must not sound the same}
- Drift bans: {must not become exposition, pure setting, pure science lecture, pure sugar, pure battle reports, etc.}
- This-chapter tradeoffs: {2-4 items used only this chapter; drawn from the above, not executed in full}
```

### Webnovel-first calibration

When Webnovel is the priority platform for long-form prose, the card emphasizes "clear entry hook, fast emotion delivery, function-slot reuse, few transitions." But do not turn pseudo-metrics into hard gates:

- No forced 50-60 char lines; quality samples' paragraph lengths vary by scene; fixed line lengths look fake
- No forced 50%-60% dialogue share; dialogue only increases when conflict, relationships, or info reveals need it
- No global replacement of function words/particles; first judge whether it is genuinely oily, hollow, or template-y
- No random inversions; when smoothness must be broken, prefer switching entry points — POV entry, object entry, sound entry, or action-result entry
- No added "process" for naturalness; task blockers must block into information, relationship, cost, choice, or foreshadowing change

### Generation / reading rules

1. First read the primary genre, target platform, primary benchmark book, and core hook from `setting/genre-positioning.md`.
2. The project first exactly matches the category in `genre-prose-cards.md`, then reads the single card `genre-prose-cards/{genre}.md` (e.g. contemporary-romance / mafia-romance / cultivation); low-confidence cards must be flagged low-confidence and calibrated with a same-genre benchmark book.
3. With no category match, find the closest generic genre module in this file; cross-genre: take 3-5 items from the primary genre, 1-2 from the secondary.
4. Write the extraction as a `genre_prose_card`, carrying only the items relevant to this chapter's emotion/events.
5. The genre card must not change plot order, replace character personas, or override the authoritative recall of `plot/emotional-beats.md` / `plot/pacing.md`.

---

## Humor

### Core principles
Humor is a pressure-release valve, not joke delivery. The best humor comes from characters trying to keep dignity/authority/composure while reality refuses to cooperate.

### Humor sources
- The character's embarrassment (trying to look cool and failing)
- Deadpan contrast (a straight-faced person meets the absurd)
- Relationship ribbing (teasing between close people)
- Black humor (one acid line in a hopeless spot)
- Observational humor (precise mockery of daily scenes)

### Operation rules
- Humor comes from the character's desires/prejudices/stubbornness/misjudgments, not joke skits detached from plot
- The punchline changes status, exposes relationships, or creates future costs
- Setup short, payoff clear, aftermath more important than the punchline itself
- Callbacks must escalate (more embarrassing / more public / more serious)

### Mixing rules
- Humor + romance: expose attraction/stubbornness
- Humor + mystery: comes from false confidence
- Humor + literary: serves dignity and social texture

---

## Mystery

### Core principles
Mystery's key: make the reader feel a question/danger/cost approaching while the answer stays out of reach; not just hiding information.

### Core rules
- One main unresolved question per chapter
- Delayed reveals need in-story reasons (timing, POV limits, costs, possible errors)
- Suspense works by "the question becoming more expensive," not "the information becoming scarcer"
- Scenes must be clear (obscurity is not mystery)

### Chapter operations
1. Define the unknown
2. Define the cost of getting it wrong
3. Arrange the information asymmetry among reader/characters/opponents
4. In the second half, narrow choices or raise stakes
5. Grow hooks from existing clues; no sudden jump-scares

### Mixing rules
- Mystery + investigation: what happens next vs what actually happened
- Mystery + horror: approaching vs distorting
- Mystery + romance: relationship exposure, missed timing, emotional costs as suspense sources

---

## Romance

### Core principles
Romance works by desire, fear, pride, care, misjudgment, and emotional debt rubbing against each other — not by "finally together."

### Core rules
- Chemistry comes from concrete character differences, not empty compliments
- Best tension = wanting closeness + fearing loss/exposure/debt
- Every big relationship scene changes the depth of trust/hope/possessiveness/vulnerability/boundaries/misunderstanding
- Delays are allowed but must bring new pressure/debt/understanding/cost
- The most moving intimacy hides in small things, care, misjudgments, and unsaid words

### Chapter operations
1. Define what each side wants and fears
2. Decide whether this chapter pulls closer, pushes away, or drags into more dangerous entanglement
3. Let one real action carry the emotional meaning
4. If a misunderstanding, root it in the character's cognition/situation/scars, not cheap "not talking it out"
5. End with a new emotional debt/risk/anticipation

---

## Investigation

### Core principles
Investigation's core is "the reader feels they could solve it too," so clues must be presented fairly.

### Key techniques
- Clues mixed into natural narration (no stopping to list clues)
- 1-2 misleading clues beside each real clue
- Reveal order matters more than the truth itself (guess the motive first, then the person)
- Every suspect has one key secret; only one relates to the case

---

## Horror

### Core principles
Horror works through "limited POV" — what the character doesn't know is scarier than the monster shown.

### Key techniques
- Fear must escalate (not one intensity forever)
- Restrict information sources (power cuts, no signal, being alone)
- Physiological reactions replace direct fear description
- Brief returns of safety make the next wave hit harder

---

## Fantasy / cultivation

### Core principles
A worldview's power lies in rules and costs, not "can do anything."

### Key techniques
- Power systems need clear boundaries and costs
- Worldview expansion tied to plot advancement (no exposition essays)
- Daily details make the world "alive" more than grand settings (market currency, inn prices)
- Every 5 chapters: at least one worldview-level new piece of information

### Cheat design points
- The cheat decides the payoff ceiling: the stronger, the bigger the solvable conflicts
- Avoid one-time secret treasures only — collapses as you write
- Fragment the cheat: split complex abilities, fuse fragments into the plot
- Before collection completes = long-term anticipation; each fragment collected means at least one conflict solvable
- Setting serves plot; don't be reverse-constrained by setting; the protagonist must be a special variable inside the rules

---

## Realistic / slice-of-life

### Core principles
Realistic genres' power is "the reader knows these people"; resonance comes from precise daily observation.

### Key techniques
- Dialogue must be colloquial (no bookish register)
- Scenes specific to store names, brands, neighborhoods (the more specific, the more real)
- Conflict comes from real social pressure (money, face, relationships, class)
- Details use the five senses (cooking-oil smoke, mahjong clicks, the hum of an e-bike charging)

### Values & commercial principles
- Web fiction is commercial writing; judge text quality by target-reader feedback and writing goals
- Plain values: a life for a life, debts repaid, an eye for an eye, kindness repaid, good and evil settled
- High-end expression = telling stories so readers draw conclusions themselves
- Clear views, sharp stance: the wicked must be punished for their deeds
- Don't disgust readers to show "human complexity"

---

## Progression / payoff fiction

### Core principles
Payoff fiction's essence is "the reader knows the ending's unknown process." Core anticipation: getting stronger, richer, recognized.

### Key techniques
- The upgrade-gain-flex triple loop is the universal core loop
- Upgrades bring gains (comparison), gains bring flex (shock), flex drives new upgrades
- Gains release in layers; extra, uncertain gains surprise more than fixed ones
- The payoff core is four words: the protagonist is awesome — how the problem is solved decides the payoff
- Calm one-finger annihilation >> hysterical hard-fought victory
- When it should be satisfying and isn't, it reads more toxic than a poison point

### Core-hook distillation
- The core hook decides the track and audience; blind imitation and bandwagoning all crash
- The core hook decides the cheat's resource-acquisition method (killing vs managing relationships + homesteading)
- The core hook affects the book's tone (light daily vs serious hype)

### Persona consistency principles
- The source of power decides behavior logic:

| Power type | Source | Behavior traits |
|----------|------|----------|
| Personal strength | cultivation type; strength is the way | skills and treasures belong to self |
| Deference | lord type; power from subordinates' deference | conflicting interests = can't command |

- The smart-persona cannot collapse: smart characters must obey the energy-saving principle (minimum cost for maximum gain)
- When the antagonist rallies an army for a head-on, consider whether the army obeys and interests align
- Persona collapse = characters acting against their power structure/personality just to advance the plot

### Power/scale design principles
- The scale ceiling depends on genre boundaries and controllability; guarantee no collapse
- Below single-universe scale is basically enough; no multiverse tricks needed
- Rule-type abilities: avoid, too easy to lose control
- Scale must match the genre's boundary feel

---

## Comedy

- Comedy ≠ insanity; logic is the foundation — comedy happens under logical reasoning (a solution inside the rules, but not the expected one)
- An illogical insane protagonist is fun early, but later readers can't sync brainwaves and it gets awkward
- Meme rules: forcing a meme is worse than no meme — memes have lifecycles; past their heat, only awkwardness remains
- Correct approach: distill the meme's inner comedic logic and adapt it into the novel's situation

---

## Light-novel / anime style

- Core definition: novels selling dramatic personas, especially pretty girl personas
- Persona as selling point: every character has a sharp "labeled" trait, remembered at a glance
- Daily feel over plot advancement: character interaction and daily fragments are the main content
- Dense banter/interiority: the protagonist as "tsukkomi" — reactions to absurdity are themselves payoffs
- Persona differences extreme: tsundere/yandere/kuudere/airhead — the sharper the label the better
- Selling personas > selling plot: plot serves displaying character charm
- Dialogue volume > description volume: interaction advances via dialogue; cut long interior monologues

---

## Absurd style

- Absurd style = humor via absurd, anti-conventional narration
- Character behavior surprising but internally consistent (sane absurdity, no randomness)
- Serious scenes defused by the character's absurd behavior; contrast makes the joke
- Sect daily > combat progression: in absurd-sect fiction, progression is a background element
- Ensemble strong: a group propping each other up; jokes don't ride one character alone
- Absurd ≠ stupidity: character behavior has its own logic, just a ridiculous logic
- Core risk: pure absurdity with no emotional depth — readers laugh and forget; a foundation of real feeling is needed

---

## Cyberpunk style

- High-tech low-life texture: neon, cybernetics, data streams, class rigidity
- High information density: lots of worldview details fused naturally into narration, no exposition essays
- Cold-hard tone: alienation, oppression, technological estrangement throughout
- Worldview details > plot complexity: cyberpunk readers come for the atmosphere
- The opening chapters must establish enough atmosphere: rain nights, neon, cybernetic modification, virtual networks
- Avoid fantasy wearing a cyberpunk skin: power systems must obey technological logic

---

## Ranking / info-gap fiction

- Core mechanism: the protagonist displays exclusive information to unknowing bystanders, creating shock and flex effects
- Knowledge info gaps are the core payoff: the reader and protagonist "crush" the unknowing world together
- Unit structure: one ranked subject = one flex unit, looping forward
- Resonance first: the ranking direction must pick content the reader resonates with (culture/profession)
- Each ranking unit needs: setup of the audience's ignorance -> protagonist displays -> bystanders shocked -> info gap closes
- Can fuse with other genres: ranking + game fiction, ranking + transmigration, ranking + entertainment
- Boundary rule: ranking fiction is info-gap-driven; must not become pure science lecture

---

## Mock / simulation fiction

- Core structure: gain rewards and info gaps through "simulation," then advance the main line and satisfy anticipation in reality
- Unit structure: simulation creates an emotional gap -> rewards in the simulation (forming an info gap) -> reality satisfies anticipation
- Volume structure: simulation reveals a big crisis/big anticipation -> multiple small-unit loops of 【simulate + get reward + advance reality】 -> finally achieve/resolve the core anticipation
- Info gaps in the simulation = chips for flexing in reality
- Simulation content can show "what would happen without intervention," reinforcing urgency
- Reward tiers: small simulations give small rewards (upgrade resources); big simulations give key info (plot turns)
- Simulation is not omniscient: keep unknown variables; the protagonist cannot know everything through simulation

---

## Live-stream fiction

- Core mechanism: live-streaming as the frame, fusing money-making, flexing, confrontation, and chaos payoffs

| Payoff source | Concrete form |
|----------|----------|
| Money-making | direct tips/gifts; money numbers visibly grow |
| Confrontation | PKs, leaderboards, competing with peers |
| Identity masks | hidden big shots in the audience; barrage info gaps make surprises |
| Chaos content | absurd/funny stream content drawing onlookers |
| Talent display | a window for the protagonist's unique abilities |

- Clear goals: every stream has a concrete target (raise X money / gain X followers), giving readers a defined expectation
- The live-room barrage = an instant feedback system: built-in flex audience, no extra design needed
- Can fuse slice-of-life: each stream receives one guest / handles one matter = one slice-of-life unit story
- Rhythm requirement: cannot stream forever; a reality line interleaves for advancement

---

## Redemption-conflict design

| Conflict type | Approach | Example |
|----------|------|------|
| Redemption-goal conflict | one side's redemption comes from the other's sacrifice | a sworn-brother sacrifice |
| Redemption-action conflict | redemption built on lies/harm/zero-sum | taking over another's identity |
| Triangle | one side's redemption causes a third party to need redemption | chain effects |
| Redemption countdown | must complete before something happens or fall into the abyss | time pressure |
| Rising redemption cost | one side's payment to redeem the other keeps growing | emotional/resource/body-mind costs escalating |
| Scarce redemption resources | both need redemption but resources only suffice for one | zero-sum |
| Stance opposition | both have stance differences but need each other's help | redemption vs stance |
| Personality contrast | optimism vs pessimism, cold-blooded vs compassionate | blocks understanding and communication |

---

## Boundary feel & atmosphere

### The nature of boundary feel
Boundary feel = the genre/style's specific information-point set. Use these information points to shape atmosphere, giving the reader "this is that flavor" feeling.

### The three layers of boundary feel

| Layer | Content | Failure symptom |
|------|------|----------|
| Genre boundary | the genre's unique setting, rhythm, tone | urban fiction tasting like fantasy, homestead tasting like conquest |
| Style boundary | the school's language texture, narrative rhythm | light-novel voice in serious literature, fantasy voice in slice-of-life |
| Audience boundary | the target reader group's expectations and minefields | male-audience rhythm for romance readers, Webnovel standards on Royal Road |

### Tone consistency principle
- The book's tone must hold throughout; changing tone mid-way = core appeal collapse
- Tone = readers' consensus on "what this book feels like"
- Check method: after each chapter ask "is this chapter consistent with the opening's tone?"

### Boundary feel when fusing genres
- Before fusing, define both genres' core hooks
- Does the fused collision point exceed the core hooks? Exceeding = off-boundary = dangerous
- Correct fusion: one genre as the main tone, the other provides the cheat or setting shell
- Wrong fusion: two rhythms alternating; readers don't know what they're reading

### Benchmark-selection boundary feel
- The benchmark book must be same site + same genre + same type; all three mandatory
- Different sites' reader expectations differ; writing methods cannot be transplanted directly

---

## Per-site style differences

| Site | Core competitiveness | Reader preference | Strategy |
|------|-----------|----------|------|
| Royal Road | progression/career lines main | long-line anticipation, stable rhythm, worldview depth | prefer clearly bounded genres with mature audiences |
| Webnovel | fast payoff, strong emotion, high payoff density | fast rhythm, no dragging, chapter 1 needs a hook | tear down same-platform same-genre samples' front structures; reuse function slots not scenes |
| Wattpad | chaos > rhythm, persona > plot | anime-fan + game readers; "fun" matters more than "stable rhythm" | adapt toward fanfiction, light-novel, wild-idea, chaos |
| Downstream market | chaos fiction core | unhinged, absurd, free-spirited | write freely; the style must match |

---

## Market positioning & topic strategy

- Prefer categories with wide audiences, many samples, and clear boundaries; concrete heat must be validated by the current scan/analyze or user samples.
- A hot category only means a bigger potential reader pool, not that any concrete hook currently works.
- To lower competition pressure: keep the genre boundary, replace the entry angle, character relationships, or emotion trigger.
- Do not use "that's how traditional fiction is" to explain slow rhythm, weak conflict, or unclear selling points.

---

## Genre essence = element assembly

- Genre essence: all genres are combinations of elements
- Elements = things readers find interesting + things that have been popular in web fiction
- Elements are not the cheat and not channel categories
- The sign-in genre's elements: 【lying low + high-intensity gains + strong anticipation】
- Genres with two split elements (xianxia + tech) are extremely hard; first self-justify + create fun
- Track selection: prefer emerging tracks with scattered competition and valid recent samples; avoid mature tracks with strong brands and hard-to-reuse function slots
- Study mid-tier samples, not just top hits — the former's structure is more reusable
- Commercialization = respecting the target reader; private expression cannot override the core selling point and reading experience

---

## Traffic & track

- Traffic = a genre's ceiling; sometimes the genre itself is the problem, not the writing
- Track = the genre's runway; different tracks have different reader pools and expectations
- Track selection three dimensions: traffic (ceiling) + competition (opponent count) + material/ability match
- Look at the ceiling before choosing; small reader pools mean lowering length and commercial expectations

---

## Bandwagon & innovation

- Web-fiction writing core = whether you can tell a story, not literary talent / novel creativity / broad knowledge
- Bandwagon = reusing proven function slots; one way to reduce risk
- Homogenization essence = bandwagoning without deep processing of the target, mere imitation
- Bandwagoning is fine; the problem is copying even the actions and tone — the dumped-fiancé genre has many combinations
- Novel settings ≠ innovation; the mainstream is mainstream because most people accept it
- Innovation core: distill the meme's inner comedic logic and adapt it into new situations

---

## Element assembly & school thinking

- Distill one school's elements + another school's elements -> fuse into a new book
- An idea only works when "material, characters, conflict, length" all support it
- Anti-pattern = overturning old patterns to give readers freshness
- Common problem: the prose fails to make key information explicit, so readers can't see the selling point
- The novel must be recognizable to target readers on its core selling point, or commercial value cannot settle

---

## Market cognition & creation points

- Opening rhythm rule: early focus on fast expansion of the core selling point/cheat; avoid over-investing in setting and foreshadowing that slows the prose
- Chasing perfection -> addicted to writing setting/plot/foreshadowing -> prose rhythm slows
- Info-gap risk: pre-write prep imagines a brilliant later expansion, but the prose delivers a dragging protagonist and a sabotaging heroine
- New-media entries depend on hooks and first-glance appeal; the opening must immediately deliver the entry promise
- No poking everywhere; every plot segment must tightly drive the core conflict

---

## Creation approach & opening design

- Three-step creation approach: fix the protagonist's identity -> match the cheat type -> set the opening environment -> establish the image (label)
- Image = labels on characters and plot to deepen them
- The opening need not write conflict; environment is fine — the key is flow, carrying all information out
- Don't deliver background via narration; deliver information via dialogue
- Protagonist identity -> facing a trap -> finding a way -> ability insufficient -> the cheat arrives
- Don't flood information at once
- Rhythm misconception: if the book bores readers, even a god-king protagonist in chapter 1 means nothing

---

## The low-position opening flow

- Low-position opening core = flow; no reversals and pulls needed
- Carry all information out while staying smooth — the reader's thoughts follow the content
- Don't dump all pressure on the protagonist at once; give pressure bit by bit
- Deliver info via dialogue more; less narration background
- After the cheat arrives, an immediate change must appear — let the reader see the change process
- The cheat arrives when the protagonist is actively handling the crisis but under-able — so the protagonist isn't a waste
- What identity does what: a horse-slave has no right to morality; overstepping = structural damage
- When writing big plots, check: is the protagonist's current level, identity, and resources sufficient?

---

## The five opening keys

- **Simple**: state the five elements concisely (who / where / what / why / what-to-do), chapter 1 makes them clear
- **On-track**: the opening plot must fit the main line; off-track = zero-point opening
- **Fast**: enter the plot fast; dawdling background delivery = verbose
- **Satisfying**: the first small plot must have a payoff; no shock within five chapters = failure; no poison points/minefields/driving-away points
- **Not flat**: text is like a mountain — flat conflict-free water = failure

**Common opening problems**:
- Opening prologue of A/B/C/D transcendent figures talking in riddles -> readers baffled
- Haze with no meaning -> readers leave without understanding
- Verbose "setup" that is all filler -> rhythm too slow

---

## Quality checklist

After writing a genre's chapter/volume, verify:

- [ ] **Genre boundary feel**: this chapter tastes like the target genre, no flavor bleed
- [ ] **Tone consistent**: consistent with the opening tone, no mid-way key change
- [ ] **Genre core techniques executed**: the genre module's "core rules" all followed
- [ ] **Persona matches labels**: character behavior based on labels, no persona collapse
- [ ] **Dialogue colloquial**: no bookish register (mandatory for realistic/slice-of-life/progression)
- [ ] **Five-sense details**: scenes have concrete sensory details, not abstract summaries
- [ ] **Five opening keys** (when checking an opening): simple / on-track / fast / satisfying / not flat
- [ ] **Fusion boundary feel** (cross-genre): primary genre as main tone, secondary genre as shell
- [ ] **Benchmark consistency**: benchmark book same site + same genre + same type
- [ ] **Market match**: target track's reader pool sufficient; genre matches existing material/ability strengths
