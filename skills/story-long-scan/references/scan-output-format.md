# Scan Data Collection Format Specification

Field definitions, output templates, and cleaning rules for Royal Road / Webnovel / Wattpad / Amazon Kindle / Inkitt collection.

---

## Royal Road

### Collection notes

Ranking list and URLs are in SKILL.md's Royal Road research table. Use WebSearch to locate the current ranking URLs, then open pages with `/browser-cdp` (`agent-browser --cdp 9222 open "<URL>"`). Extract rows with `evalJSON` from `scripts/cdp-utils.js` (base64 channel; never hand-escape JS with quotes). Output header records the collection method.

### Fields

rank | title | author | genre | status | length (words) | follows | rating | votes | views | tags | latest update | fiction page URL | blurb (truncated ~150 words)

### Output template

```markdown
# Royal Road · {ranking name}
- Source: {ranking URL}
- Collected: {ISO 8601}
- Valid entries: {N}
- Data quality: [OK / issues found]

---

## #{rank} {title}
*{author} · {genre} · {status} · {length} words · {follows} follows · {rating}★ ({votes} votes) · {views} views*
**Tags:** {tags}
**Latest update:** {YYYY-MM-DD} · {chapter title}

[Fiction page]({URL})

**Blurb**
{blurb text}
```

### Collection notes

The ranking page has rank/title/author/genre/length; detail pages add follows/rating/votes/views/tags/blurb. Rising Stars and Popular This Week re-rank frequently; record the collection timestamp in the header.

---

## Webnovel

### Fields

rank | title | author | genre | status | views | power stones | favorites | rating | chapters | latest update | bookId | book page URL | blurb (truncated ~150 words)

### Output template

```markdown
# Webnovel · {channel}{ranking name} · {N} entries
- Source: {ranking URL}
- Collected: {ISO 8601}
- Data quality: [OK / issues found]

---

## #{rank} {title}
*{author} · {genre} · {status} · {views} views · {power stones} power stones · {favorites} favorites*
**Latest update:** {chapter}
**bookId:** {bookId}

[Book page]({URL})

**Blurb**
{blurb text}
```

### Collection notes

webnovel.com is a heavy client-side app; list pages need browser state. If a page requires login or shows a verification wall, open it manually in the logged-in Chrome first, then re-collect. When a title/author fails to decode, show `(title pending)` but always keep the bookId and book-page URL for manual re-check.

---

## Wattpad

### Fields

rank | title | author | genre/tag | status | reads | votes | comments | parts | last update | story URL | description (truncated ~150 words)

### Output template

```markdown
# Wattpad · {tag/ranking name} · {N} entries
- Source: {ranking URL}
- Collected: {ISO 8601}
- Valid entries: {N}

---

### #{rank} {title}
*{author} · {tag} · {status} · {reads} reads · {votes} votes · {comments} comments · {parts} parts*
**Last update:** {date}

[Story page]({URL})

**Description**
{description text}
```

### Collection notes

Wattpad rankings are tag-scoped; collect per hot tag. Reads vs votes ratio is a cheap engagement-quality signal.

---

## Amazon Kindle

### Fields

rank | title | author | category | price/KU badge | rating | reviews | page count | publication date | series position | ASIN | product page URL | blurb (truncated ~150 words)

### Output template

```markdown
# Kindle · {list name} · {N} entries
- Source: {list URL}
- Collected: {ISO 8601}
- Valid entries: {N}

---

### #{rank} {title}
*{author} · {category} · {price}/{KU} · {rating}★ ({reviews} reviews) · {page count} pages · {publication date} · {series position}*
**ASIN:** {asin}

[Product page]({URL})

**Blurb**
{blurb text}
```

### Collection notes

Kindle pages are bot-tolerant but slow; batch with per-page waits and re-verify rank at collection time (Best Seller rank floats hourly). For KU reads, the page displays "Kindle Unlimited" but exact page-read totals are only visible to enrolled authors — record page count as the proxy and mark reads as `[needs fill]` when unavailable.

---

## Inkitt

### Fields

rank | title | author | genre | status | reads | votes | chapters | story URL | blurb (truncated ~150 words)

### Output template

```markdown
# Inkitt · {list name} · {N} entries
- Source: {list URL}
- Collected: {ISO 8601}
- Valid entries: {N}

---

### #{rank} {title}
*{author} · {genre} · {status} · {reads} reads · {votes} votes · {chapters} chapters*
[Story page]({URL})

**Blurb**
{blurb text}
```

---

## Data cleaning

General: remove platform boilerplate text -> truncate blurbs over ~150 words at a sentence end with `...` -> mark empty values `[needs fill]`.

| Platform | Extra required fields |
|----------|-----------------------|
| Royal Road | genre, length, follows (or rating+votes) |
| Webnovel | views (or power stones) |
| Wattpad | reads (or votes) |
| Kindle | category, rating+reviews (or price/KU badge) |
| Inkitt | reads (or votes) |

Minimum collection volume: 15 entries for main platforms, 10 for small platforms. Below the floor, mark `[data sparse]`.

---

## Batch collection

| Platform | Default combination |
|----------|---------------------|
| Royal Road | Rising Stars + Popular This Week + top follows |
| Webnovel | Power Rankings (main genres) + New Books |
| Kindle | Top 100 Paid + Top 100 Free (target category) |
| Wattpad | Hot lists for 2-3 target tags |
| Full sweep | Royal Road + Webnovel + Kindle default combinations |
