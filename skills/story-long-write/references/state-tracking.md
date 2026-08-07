# State Tracking Protocol

> This file defines the extraction logic for "section notes" and the "character state snapshot" format. The writing skill loads it during the state-filtering step of pre-write preparation.

---

## Section Notes

Before writing each chapter/section, filter only the information relevant to this section from all loaded context. The goal is to keep the LLM context from being diluted by irrelevant information via full loading.

### Filtering logic

Extract three kinds of information from context:

1. **Current state**: the latest abilities, relationship changes, and public image of this chapter's characters
2. **Historical causation**: foreshadowing origins and prior events directly related to this chapter's events
3. **World constraints**: worldview rules this chapter touches (power system, social rules, geographic limits)

### Filtering criteria

**Keep only "information you would get wrong this chapter if you didn't know it."**

Concretely:
- A character appears in this chapter's outline → keep that character's current state
- This chapter collects foreshadowing → keep the foreshadowing's planting details and prior setup
- This chapter involves a specific place/ability/rule → keep the relevant worldview constraints
- Pure background knowledge (no causal link to this chapter's events) → discard

### Output format

After filtering, output a compact "section notes" block:

```
## Section Notes (Chapter {N})

### Character states
{CharacterA}: {one-sentence current state, including recent changes}
{CharacterB}: {one-sentence current state}

### Relevant foreshadowing / prior events
{Foreshadowing 1}: {planting details, planted in chapter {N}}, this chapter needs to {collect/advance}

### World constraints
{Constraint 1}: {rule/setting relevant to this chapter}
```

**Example (urban entertainment novel, chapter 12):**
```
## Section Notes (Chapter 12)

### Character states
Shao Yang: transmigrator, ex-B-list singer in his past life, just stunned everyone with a song at Song Jialun's concert; his "temporary girlfriend" Xue Jiajia is at his side
Xue Jiajia: the female lead, a top producer in hiding, publicly Shao Yang's temporary girlfriend, privately already warming to him
Song Li: ex-girlfriend, conflicted after watching Shao Yang blow up, cracks appearing in her relationship with her new fling Zheng Song

### Relevant foreshadowing / prior events
Xue Jiajia's hidden identity: hinted in chapter 3 when Shao Yang helped her out of a jam; this chapter needs the precursor of her identity surfacing in public
The fifty-thousand-dollar bride price: money Song Li took under the guise of a trainee fee, planted in chapter 2; this chapter Shao Yang decides to demand it back

### World constraints
Parallel-Earth Blue Star: no Earth entertainment works; Shao Yang's past-life memory is a one-sided information advantage
```

---

## Character State Snapshot Format

> ⚠️ **This section applies only to long-form writing.** Short-form usually does not need an independent character-state tracking file.

`tracking/character-state.md` tracks state changes of major characters. Phase 3 creates the initial state after the outline is complete; Phase 4 updates it after each chapter.

### Format

```markdown
# Character State Tracking

> Use: data source for section notes. Before writing each chapter, filter this chapter's relevant character states from this file.
> Update timing: create the initial state after Phase 3 outline completion; update changes after each Phase 4 chapter.

## {Character name}
- **Current identity**: {latest identity/occupation}
- **Current abilities**: {latest ability level}
- **Key relationships**:
  - With {CharacterB}: {current relationship state} (changed in chapter {N})
  - With {CharacterC}: {current relationship state}
- **Public image**: {how the outside world sees this character}
- **Pending foreshadowing**: {uncollected foreshadowing related to this character}
- **State change log**:
  - Chapter {N}: {change description}
```

### Update rules

1. After each chapter, check whether the chapter changed any character's state (identity, ability, relationship, public image)
2. If changed: update the corresponding fields and append a line to the "State change log"
3. If unchanged: skip
4. Track only major characters (appearing ≥3 times or carrying their own plot line); do not track passersby
5. Log maintenance: keep the 10 most recent detailed log entries per character. Beyond 10, compress the oldest entries into the corresponding fields (e.g. "Current identity: chapters 1-20 went from student to singer"), deleting the merged old lines
