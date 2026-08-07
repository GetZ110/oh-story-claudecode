# Length-Routing Rules

Phase 1's "basic-info confirmation" uses these rules to decide whether the imported book is long-form or short-form; the verdict decides which migration path follows.

---

## Verdict priority

Verdicts run in this order; a hit stops the process, no further checks.

| Priority | Signal source | Verdict rule |
|----------|---------------|--------------|
| 1 | user explicit declaration | the user says "this is long-form / short-form" → user wins; locked directly |
| 2 | structural signals | clear chapter separators detected and chapter count ≥5 → long-form; no chapter separators anywhere, single file single piece → short-form |
| 3 | word-count fallback | only when 1 and 2 are both unclear; see the "word-count fallback rules" below |
| — | conflict handling | when signals contradict, don't auto-decide; go back to Phase 1, repeat the findings, and let the user decide |

---

## Priority 1: user explicit declaration

In the Phase 1 info confirmation, ask the user: **"Is this long-form or short-form?"**

- Clear answer → lock the type; skip further detection.
- No answer or "not sure" → proceed to priority 2 structural-signal detection.

---

## Priority 2: structural signals

### Chapter-separator recognition

Reuses the separator recognition table in `structure-mapping-long.md`:

| Separator pattern | Example |
|-------------------|---------|
| `Chapter X` / `Chapter X ` / `Chapter X:` / `Chapter X XXX` | Chapter 1 Entering the Jianghu |
| Plain numbered + title | 1. Awakening |

### Verdict rules

| Detection result | Verdict |
|------------------|---------|
| Clear chapter separators and recognized chapter count ≥5 | strong long-form signal → **long-form** |
| No chapter separators anywhere; single file, single piece | strong short-form signal → **short-form** |
| Chapter separators exist but count <5 | structural signal unclear → proceed to priority 3 word-count fallback |
| Separator pattern ambiguous (e.g., only one title line) | structural signal unclear → proceed to priority 3 word-count fallback |

---

## Priority 3: word-count fallback

**Only when priorities 1 and 2 can't give a clear verdict.** The current import contract takes 30,000 words as the suggested upper bound for short-form (typical short-form range 8000-20,000 words), leaving margin for genre differences.

| Condition | Verdict | Notes |
|-----------|---------|-------|
| Total words < 30,000 and no chapter structure | **short-form** | — |
| Total words ≥ 30,000 | **long-form** | — |
| Chapter count ≥5 (any word count) | **long-form** | — |
| Total words < 30,000 but chapter count ≥5 | initially **long-form**, but must tell the user | see "chaptered short serials" below |

> **Suggested-value note**: the 30,000-word threshold is an estimate; short-form ceilings differ by platform and genre. When executing, list it in open-questions and suggest the user verify whether it fits the book being imported.

### Chaptered short serials

When total words < 30,000 but chapter count ≥5, prompt the user in the confirmation step:

> "Detected a chaptered structure ({N} chapters total), but the total is about {X} words — under 30,000. This may be a chaptered short serial. Confirm: import as long-form, or treat it as short-form?"

The user's decision locks the type.

---

## Conflict handling

When signals contradict, **don't auto-decide**; go back to Phase 1 and repeat the detection results:

| Typical conflict | Handling |
|------------------|----------|
| User says "short-form" but 20 chapters detected | repeat: "20 chapters of chapter structure detected, usually long-form. Confirm import as short-form?" — user decides |
| User says "long-form" but no chapter separators and words < 30,000 | repeat: "No chapter separators; about {X} words total, usually short-form. Confirm import as long-form?" — user decides |
| Structural signal and word-count signal point opposite ways | show both signals; user decides |

The user's decision is recorded in the Phase 1 context; subsequent steps follow it without re-judging.

---

## Verdict and the following path

After the verdict, route the migration path by the mapping:

| Verdict | Migration path | Mapping-rules reference |
|---------|----------------|------------------------|
| **long-form** | long-form migration path (Phase 3-L) | `structure-mapping-long.md` |
| **short-form** | short-form migration path (Phase 3-S) | `structure-mapping-short.md` |

> Note: `structure-mapping-long.md` is the long-form migration mapping rules; `structure-mapping-short.md` is the short-form migration mapping rules.

---

## Verdict flowchart

```
Phase 1 asks the user: "Long-form or short-form?"
         │
         ├─ clear answer ─────────────────────────────► lock the type
         │
         └─ no answer / not sure
                  │
                  ▼
          detect chapter separators
                  │
                  ├─ separators + count ≥ 5 ───────────► long-form
                  │
                  ├─ no separators, single piece ──────► short-form
                  │
                  └─ signals unclear
                            │
                            ▼
                   word-count fallback (30,000-word threshold)
                            │
                            ├─ < 30,000 and no chapter structure ─► short-form
                            ├─ ≥ 30,000 ──────────────────────────► long-form
                            ├─ chapter count ≥ 5 ─────────────────► long-form
                            └─ < 30,000 but chapter count ≥ 5 ────► user decides
```
