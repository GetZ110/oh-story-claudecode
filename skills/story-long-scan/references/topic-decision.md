# Topic Decision: From Scan Data to "What Should I Write"

Turns scan results into directly usable topic recommendations: **what to write, why it could hit, whether it's viable, and how to verify**. Phase 5 produces `topic-decision.md` — the market-side topic draft: "why it could hit" starts as a hypothesis, gets backfilled by teardown (story-long-analyze) after validation, and is read directly when a book opens (story-long-write).

---

## Decision routing

| What you're doing | Read this section |
|-------------------|-------------------|
| Turning scan results into topic recommendations | The four topic steps |
| Judging whether a direction is viable | Feasibility judgment |
| No network / no ranking data | Built-in-knowledge mode |
| Writing the deliverable | topic-decision.md template + delivery |

---

## The four topic steps

Every recommended topic must complete all four steps:

1. **Why it could hit (as a hypothesis)**: from **repeated samples** on the lists (exclude single-book anecdotes) + extracted new elements, infer "this direction could hit because X structure/trope/character setup feeds these readers." A single ranked book is an anecdote (scan principle 1: repetition across books is the signal). Record this as a hypothesis marked `needs teardown verification`; confirmation comes from teardown backfill.
2. **Market validation**: how many books in this direction are on the lists + trend (up/->/down) + counter-examples (books in the same direction that flopped or fizzled). More samples and a steadier trend = more credible.
3. **Differentiated positioning**: author advantage x market gap = "how your version differs from what's already on the lists." No differentiation = too homogeneous to break in.
4. **Feasibility + risk + verification**: give feasibility high/medium/low (rules in the next section), the most likely failure point, and how to verify cheaply before writing (usually: "write the first three chapters, test follow-through, switch if it fails").

---

## Feasibility judgment

Three tiers; with insufficient samples you may not give "high" — don't let a few data points manufacture false confidence:

| Feasibility | Meaning | Conditions |
|-------------|---------|------------|
| High | Safe to write | Enough samples in this direction on the lists (>=15; small platforms >=10) + trend up or flat + author material can support it + differentiation room |
| Medium | Write but verify first | Samples sufficient but trend down / or differentiation unclear / or material only half-supports |
| Low | Not recommended | Direction saturated (many flop counter-examples) / or material can't support it / or platform mismatch |

**Hard rule**: if the list backing a direction is marked `[data sparse]` (valid entries <15, small platforms <10 — the sparse threshold from the scan quality check), that direction may **not** be rated "high"; force it to "medium" and write "sample too thin — scan more or run a cheap test before committing".

**Built-in-knowledge mode**: with no live lists, purely knowledge-based trends, **every direction is rated "medium"**, with the reason "based on general knowledge, no list validation — scan or run a small test before writing." Never "high".

---

## topic-decision.md template

```
# Topic decision: {platform/direction}
- Scan date: {YYYYMMDD}     # data freshness; writing re-prompts a re-scan if stale
- Data source: {ranking file names / built-in knowledge}

## Recommended topics

### Topic 1: {one-line direction}
- Genre mix: {primary + secondary/trope}
- Target readers: {profile}
- Core appeal: {why readers keep following}
- Why it could hit: {X structure/trope and why it feeds this audience} (hypothesis, `needs teardown verification`)
- Differentiated positioning: {how it differs from what's on the lists}
- Feasibility: high/medium/low — {reason: how many books in this direction + trend}
- Failure risk: {most likely place it collapses}
- Verification action: {cheap check before writing}
- Length/platform: {suggested word range + target platform}

### Topic 2 ...
### Topic 3 ...
```

2-3 topics is right; sort by feasibility (high first).

---

## Delivery

1. Write to this scan's output directory (same directory as the ranking files): `{outdir}/topic-decision.md`.
2. Tell the user the path and the next step: "When you open a book, put `topic-decision.md` in the project root and writing will read it automatically; to confirm the 'why it could hit' claims, run `/story-long-analyze` on benchmark books first — teardown backfills the file."
3. Downstream handoff (this file only explains, never executes): teardown backfills the "why it could hit" field of the matching topic after the summary report is produced; story-long-write reads `topic-decision.md` as the opening point in its Phase 1.
