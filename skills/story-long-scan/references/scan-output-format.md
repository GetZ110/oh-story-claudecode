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

### Field-tested collection recipe (2026-08, live verified)

**Use the API, not the tag pages.** Old URLs (`/tag/{tag}`, `/browse`) 404 or redirect to the homepage; search-result cards carry no author name. The API v3 search endpoint works from inside a wattpad.com page (see the CORS rule below):

- Endpoint: `https://www.wattpad.com/api/v3/stories?query={tag}&limit=50&offset={0|50|100}` (fetch with `{ credentials: "include" }`)
- One story object gives everything: `id, title, user.name (author), readCount, voteCount, commentCount, numParts, completed, modifyDate, tags[], description, url, language`
- **The default sort is a relevance blend, not pure popularity** — page 1 can mix a 11M-read hit with 30K-read entries. Verified recipe: fetch 3 pages (`offset` 0/50/100), dedupe by `id`, sort by `readCount` descending, take top 20. Record "sorted by readCount desc" in the file header.
- `fields=` is **not supported** on this endpoint (HTTP 400 `InvalidValue`); the full per-story response is large (includes `parts`), so compact fields inside the eval before returning.
- `limit=20-50` is fine per request; do not batch all tags into one eval if the payload gets big (see browser-cdp P2/P5).

**CORS rule (verified failure):** same-origin `fetch()` only works while the active tab is on `wattpad.com`. Running the fetch from an amazon.com tab returns `TypeError: Failed to fetch`. Always `open "https://www.wattpad.com/"` first, then eval the collection script.

**PowerShell serialization pit:** `$obj | Set-Content` writes PowerShell's `@{...}` text, not JSON (tags arrays degrade to `System.Object[]`). Always `$json = $data | ConvertTo-Json -Depth 6 -Compress` before writing files, and double-parse agent-browser eval output (`ConvertFrom-Json | ConvertFrom-Json`).

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

### Field-tested grid extraction recipe (2026-08, live verified)

The new Best Sellers grid replaces the old `zg-ordered-list`; the selectors below are current:

- Container: `#gridItemRoot` (one per item; 30 items per page — **scrolling does NOT lazy-load more**)
- Rank badge: `.zg-bdg-text` (text like `#1`); ASIN: `[data-asin]`; title: `a[class*="aok-block"] [class*="line-clamp"]`; author: `a.a-link-child`
- Rating + review count: the `a[aria-label*="star"]` (or `aria-label*="颗星"`) label contains both, e.g. `4.6 颗星，最多 5 颗星，486,558 个评级`. Parse with `/([\d.]+)\s*(?:颗星|out of 5 stars)/i` and `/([\d,]+)\s*(?:个评级|ratings)/i` — the naive `[^,]*?` between them breaks on the thousands separator (`486,558` → `558`).
- Price: `[class*="p13n-sc-price"]` (NOT `.a-price .a-offscreen` — not present in this grid). The new grid shows **no Kindle Unlimited badge**; record price and treat the free list as the KU/free proxy.
- Blurbs are not on grid cards — mark `[needs fill]` and note it in the header rather than visiting 30+ detail pages.
- Pagination quirks: `?pg=2` starts at **#51** (ranks #31-50 are not exposed by this grid); the "free" bestsellers URL (`/zgbs/digital-text/154606011/`) **redirects to the paid overall list** — free/KU must be proxied via category lists or price.
- Locale: `?language=en_US` is **ignored** on list pages; prices/ratings follow the account locale (e.g. zh-CN → `HKD` prices, `颗星/个评级` labels). Normalize in the output and record the currency in the header (HKD ≈ USD/7.8).

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
