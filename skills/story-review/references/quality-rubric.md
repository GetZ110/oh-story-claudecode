# Generic Web-Fiction Content Review Rubric

> Purpose: when the user does not specify Royal Road, Webnovel, Kindle, or another target platform, this is the default fiction-content scoring standard for `/story-review`. It evaluates **story text quality**, not skill/plugin implementation quality.

## Scoring method

Mark each item PASS / WARN / FAIL and convert FAIL/WARN into the unified Findings Schema:
- Breaks the main line, character motivation, world rules, or reader trust -> S1
- Clearly hurts retention, pacing, chapter effect, or character credibility -> S2
- Local quality, format, wording, minor pacing issues -> S3
- Style suggestions or optional enhancements -> S4

## Core dimensions

| Dimension | PASS | WARN | FAIL |
|---|---|---|---|
| Core appeal | Chapter advances a clear appeal; readers know why they keep reading | Appeal exists but is weak or diluted by subplots | No visible appeal/main line this chapter serves |
| Conflict advancement | Clear conflict, blocker, choice, or cost this chapter | Conflict light; weak sense of advancement | Mostly explanation/chat/summary, no real advancement |
| Task blockers | A character gets stuck and the stuck state yields information, relationship, cost, choice, or foreshadowing change | Blocker exists but the change is weak; compressible | Blocker is only process detail; deleting it loses nothing |
| Emotional curve | Setup, escalation, release, or reversal present | Emotion changes but beats unclear | Flat emotion or abrupt turn |
| Hooks and anticipation | At least one anticipation created at opening or ending | Hook weak but a follow-up question remains | No suspense, goal, or unfinished anticipation |
| Opening freshness (first chapter / first 3 only) | Opening cuts into a concrete character/situation, not the genre default | Has a hook but the opening shape collides with the genre | Opening is the genre template, swappable onto any comparable book (homogeneous) |
| Character motivation | Behavior follows goals, personality, situation, and relationship pressure | Local behavior lacks setup | Character distorted to push the plot |
| Dialogue quality | Subtext, information control, character differentiation | Some info stacking or voices blur | Manual-style dialogue; every voice the same |
| Setting consistency | No violations of established rules, timeline, or character attributes | Minor blur needing evidence | Conflicts with written setting or earlier text |
| Prose naturalness | Concrete, perceptible, actions carrying information | Occasional templates or abstract summaries | Clear AI flavor, cliches, or summary voice |
| Sentence rhythm | Narration defaults to comma-linked mid-length sentences; short sentences are occasional isolated heavy beats that return to mid-length | Local fragments or telegraph style, or occasional mechanical long-short alternation | Consecutive <=5-word clauses, whole-passage ultra-short sentences like an outline, or review edits shattering comma-linked sentences |
| Format readability | Paragraphs break at dramatic unit/shot; dialogue standalone; no stray blank lines; natural subject rhythm | Some local paragraphs too long/short or slight subject repetition | Big blocks, mechanical splitting, hard-to-read dialogue/narration, subject overload |
| Plot loop | Goal -> blocker -> action -> cost/feedback -> new anticipation closes clearly | Loop exists but one link missing or feedback weak | No goal, no blocker, or no feedback; readers can't tell how the situation changed |
| Climax construction | Energy build -> false win -> collapse -> reversal/payoff with layers | Has a detonation but weak build or payoff | Flat delivery, no cost, no payoff, or emotional miss |
| Relationship progress | Interaction intensity matches relationship stage; overstepping has setup | Local advancement slightly fast but evidence can be added | Sudden intimacy/trust/hostility; relationship jumps |
| Foreshadowing state | Planting, status, and collection path traceable | Density a bit high/low but comprehension unaffected | Foreshadowing conflicts with setting, breaks, or confuses the main line |

## The three golden questions

1. **Why would the reader turn the page?** If you can't answer, at least S2.
2. **What changed in this chapter?** Plot, relationship, information, or emotion — at least one; otherwise at least S2.
3. **What evidence supports your judgment?** Findings without original-text evidence are not output; write "insufficient evidence" instead.

## Release suggestion threshold

| Overall | Verdict |
|---|---|
| No S1/S2; S3 quickly fixable | APPROVE |
| Has S2, or enough S3s to hurt reading | CONCERNS |
| Has S1, or core appeal/motivation/rules collapse | REJECT |

## Output requirements

- Every problem must include severity, category, location, evidence, issue, fix.
- List S1/S2 first, then S3/S4.
- No vague praise; every finding must steer the next revision round.
- `consistency` / `factual` findings' fix only states the fact-unification direction; no creative suggestions.
