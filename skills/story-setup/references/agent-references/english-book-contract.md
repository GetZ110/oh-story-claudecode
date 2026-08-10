# English Book Contract

Use this contract for every English-language writing project, including new,
existing, imported, short-form, and long-form books. The book-level
`AGENTS.md` is the durable source of truth; this file defines the required
fields and the fallback order.

## Resolution order

Resolve prose language and record language as two independent settings:

1. Read the book's `AGENTS.md` fields separately.
2. For a new book with no profile, use `AskUserQuestion` in Plan mode to confirm both fields before creating any artifact.
3. For an existing/imported book, read `setting.md`, `setting/`, or imported metadata only to repair missing fields; source prose can inform the prose-language suggestion, never the record-language choice.
4. Use the repository defaults (`en`, `en-US`) only after the user explicitly confirms them in the setup flow.

The language used in the user's chat message never overrides the book
contract. An English prose language may use Chinese records. A missing or
ambiguous contract is a setup gap, not permission to silently switch output
language or continue with English records. Legacy non-English books may keep
their source language, but must record it explicitly.

## Required book-level fields

```markdown
## Language profile
- Prose language: {selected prose language}
- Record language: {selected record language}
- English variant: en-US
- Spelling: US English
- Dialogue quotation: curly double quotes
- Date convention: prose follows the target market; records use ISO 8601
- Number and currency convention: en-US unless the setting requires another system
- Measurement convention: setting-specific; define conversions when readers need them
```

Use `en-GB` / `British English` when the target market calls for it. Do not
silently mix spelling families (`color/colour`, `organize/organise`) inside one
book. Fictional currencies and invented calendars must be defined in the book
setting rather than normalized to real-world values.

## Platform and market fields

Every project should also record:

```markdown
- Target platform: Royal Road | Wattpad | Inkitt | Radish | Galatea | Dreame | GoodNovel | Tapas | Kindle/KU | Webnovel | other
- Market: US | UK | global English | other
- Content rating: general | teen | mature
- Content warnings: none or an explicit list
- Serialization: serial episode | web chapter | ebook manuscript | one-shot
```

Platform-specific rules may override the default quote style or packaging,
but the override must be recorded in the profile and used by writing,
review, and submission checks.

## English localization pass

Before release, check names, places, institutions, occupations, education,
law, medicine, military terms, dates, money, units, idioms, titles, kinship
terms, and dialogue register against the selected market. Flag direct
translations or culturally unexplained details; preserve a deliberate
non-English setting when the book records why it is intentional.

## Template

New, imported, or existing books without a profile should create `{BookTitle}/AGENTS.md`
with this minimum contract before writing or reviewing:

```markdown
# {BookTitle} - Book-level instructions

## Language profile
- Prose language: {prose_language}
- Record language: {record_language}
- English variant: en-US
- Spelling: US English
- Dialogue quotation: curly double quotes
- Date convention: prose follows the target market; records use ISO 8601
- Number and currency convention: en-US unless the setting requires another system
- Measurement convention: setting-specific

## Market profile
- Target platform: {platform}
- Market: {US | UK | global English}
- Content rating: {general | teen | mature}
- Content warnings: {none or list}
- Serialization: {serial episode | web chapter | ebook manuscript | one-shot}
```
