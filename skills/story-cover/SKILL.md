---
name: story-cover
version: 1.0.0
description: "Fiction cover generation. Analyzes genre style from the title and author name, then calls GPT-Image-2 to generate a professional cover with the title and byline rendered. Trigger phrases: /story-cover, /cover, make me a cover, generate a cover image, cover design."
metadata: {"openclaw":{"requires":{"env":["GPT_IMAGE_API_KEY"],"bins":["curl","jq","base64"]},"primaryEnv":"GPT_IMAGE_API_KEY","source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-cover: Fiction cover generation

You are a fiction cover designer. Based on the title and genre, call GPT-Image-2 once to generate a complete cover with the title and author name rendered in.

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. Keep the cover title, byline, image prompt, and other requested cover artifacts in the language specified by the user or book profile.

**Core principle: the cover is the reader's first impression — it must convey genre and mood at a glance.**

---

## Environment variables

| Variable | Required | Default | Notes |
|:---------|:--------:|:--------|:------|
| `GPT_IMAGE_API_KEY` | ✅ | — | OpenAI or compatible proxy API key |
| `GPT_IMAGE_BASE_URL` | | `https://api.openai.com/v1` | change for a compatible proxy |
| `GPT_IMAGE_MODEL` | | `gpt-image-2` | only override to test new models |
| `GPT_IMAGE_SIZE` | | `1024x1536` | target ratio hint (3:4 -> `768x1024` for Royal Road, default 2:3 -> `1024x1536`). Official gpt-image-2 accepts any 16-multiple size (ratio <=3:1), but **many relay proxies ignore `size` and return about 2:3** (tested) — platform size is not guaranteed by this; the "export platform upload size" step is the backstop |
| `UPLOAD_SIZE` | | — | the platform's fixed upload pixels (e.g., Kindle `1600x2560`); when set, the "export platform upload size" step center-crops + scales to the upload version (no distortion, independent of the generated size) |
| `BOOK_DIR` | ✅ | — | output directory, suggested `./covers/<book title>` |
| `REF_IMAGE` | | — | reference image local path or URL; when set, uses `images/edits` image-to-image |

---

## Generation workflow

### Step 1: Collect information

Required: title, author name (pen name), target platform, output directory `BOOK_DIR` (suggested `./covers/<book title>`, export before calling)
Optional: reference image `REF_IMAGE` (local path or URL; switches to image-to-image), style preference, size

> **Title and pen name are required cover information**: if either is missing, first use AskUserQuestion to ask the user; never invent or leave blank.

**Set the cover size by target platform**: Royal Road uploads at 300x400 which is **3:4** (not 2:3) — if the generated ratio is wrong and the platform crops it again, the title/byline can get cut off.

| Platform | Upload size | Ratio | Generate `GPT_IMAGE_SIZE` (when possible) |
|:---------|:------------|:------|:------------------------------------------|
| Royal Road | 300x400 | 3:4 | `768x1024` |
| Other platforms (default portrait) | per platform spec | 2:3 | `1024x1536` |

`export GPT_IMAGE_SIZE` for the target ratio (official honors it; many proxies ignore it and return about 2:3); if the platform has fixed upload pixels, also `export UPLOAD_SIZE` (e.g., Kindle `1600x2560`, Royal Road `300x400`). **Platform size is ultimately guaranteed by the "export platform upload size" step's center-crop + scale, not by whether the proxy honors `size`.** Platform and genre styles: see [references/cover-styles.md](references/cover-styles.md).

### Step 2: Genre detection

Scan the title (and the blurb if needed) for keywords, and match against the "genre inference rules" table in [references/cover-styles.md](references/cover-styles.md).

- Single genre hit -> use it
- Multiple hits -> take one by priority: fantasy > sci-fi > romance/paranormal > mystery > horror > historical > contemporary > light novel
- Zero hits -> default `contemporary`

### Step 3: Build the prompt

Prompt = **text layer** + **style layer** + **visual layer**, all written in English.

#### Text layer: title + author name typography

Include the title and author name directly in the prompt; GPT-Image-2 renders the provided text. **Emphasize the font style**:

```
Title text 'Title' at top center in [title font style].
Author name 'Author Name' at bottom center in [author font style].
```

#### Title font styles

| Genre | Style keywords |
|:------|:---------------|
| Fantasy | `bold golden brush calligraphy with metallic glow and sharp strokes` |
| Contemporary | `modern bold sans-serif with metallic silver finish` |
| Romance/paranormal | `elegant golden traditional serif with ornate decoration` |
| Sweet romance | `soft rounded handwritten style in white with pink glow` |
| Mystery/thriller | `distorted bold cracked letters in blood red` |
| Sci-fi | `neon glowing futuristic font in electric blue` |
| Historical epic | `heavy stone-carved seal script in deep red` |
| Horror | `eerie dripping handwritten font in sickly green` |
| Light novel | `colorful cartoon outlined bubbly font` |

#### Author-name font styles (key: the author name must be deliberately designed, not just "small text")

The author name is small but it is the difference between a pro cover and an amateur one. Always specify: **font + color + decorative element**, echoing the title style without stealing focus.

| Genre | Author-name style prompt |
|:------|:-------------------------|
| Fantasy | `small refined white serif text with faint golden glow, flanked by delicate cloud-scroll ornaments on both sides, resting on a thin horizontal gold line` |
| Contemporary | `small clean white modern text with subtle drop shadow, positioned above a thin silver horizontal divider line` |
| Romance/paranormal | `small elegant dark red traditional text inside a thin golden rectangular border frame with corner decorations` |
| Sweet romance | `small soft pink-white handwritten text with a tiny heart motif on the left side, light sparkle effect` |
| Mystery/thriller | `small pale grey text with slight blur effect, almost hidden in the shadows, a thin cracked line underneath` |
| Sci-fi | `small crisp white monospace text with subtle cyan scanline overlay, flanked by small geometric brackets` |
| Historical epic | `small dignified white classic typeface text above a double horizontal line in dark red` |
| Horror | `small faded grey-green text slightly tilted, with a thin dripping ink line above` |
| Light novel | `small playful rounded white text with pastel color outline, tiny star decorations on both sides` |

**Author-name universal rules**:
- Size: `small` (not so big it steals the title's focus, not so small it can't be read)
- Position: `at bottom center`, with proper spacing from the bottom edge
- Must have a decorative element: at least one of line / border / small icon / glow
- Color contrasts with the background without being harsh

#### Style layer: platform style

Platform-style keyword strings come from the "platform style" section of [references/cover-styles.md](references/cover-styles.md); take the matching string per target platform. No copies are maintained in this file, so the reference file can't drift.

#### Visual layer: genre + composition

Read the genre's style tags, colors, characters, and background descriptions from [references/cover-styles.md](references/cover-styles.md).

Composition variants (first output 2-3 options):

| Option | Composition | Fits |
|:-------|:------------|:-----|
| A | character close-up + scene | all genres |
| B | full body + dynamic pose | fantasy, contemporary, sci-fi |
| C | pure scene/atmosphere | mystery, sci-fi, historical |

#### Full prompt template

```
Web fiction cover design, [platform style].
Title text '{Title}' at top center in [title font style].
Author name '{Author Name}' at bottom center in [author font style — pick from the table].
[genre style tags]. [character description]. [background description].
[color instructions]. [light instructions].
Professional book cover, high detail digital painting, portrait [platform ratio: Royal Road=3:4, default=2:3] ratio, keep title and author name inside the central safe area away from edges (inner ~85%), no watermark
```

#### Prompt tips (verified in practice)

- The more specific the character description, the better: clothing, pose, hairstyle, expression, props — specify each dimension
- Layered background: foreground (character) -> midground (scene) -> background (atmosphere)
- Light: specify direction + color (e.g., `dramatic golden light from above`)
- Use `digital painting style` rather than `photo` to avoid a real-photo look

### Step 4: Call the API and save

`gpt-image-2` always returns base64; the request body must not carry `response_format` (a legacy DALL-E parameter; the gpt-image series doesn't support it). `$PROMPT` is the full prompt from the "build the prompt" step.

Two call paths: no `REF_IMAGE` -> text-to-image; set -> image-to-image.

#### Text-to-image (default)

```bash
set -euo pipefail
: "${GPT_IMAGE_API_KEY:?please export GPT_IMAGE_API_KEY=your-key}"
: "${PROMPT:?please export PROMPT=the full prompt from the build-prompt step}"
BASE_URL="${GPT_IMAGE_BASE_URL:-https://api.openai.com/v1}"
MODEL="${GPT_IMAGE_MODEL:-gpt-image-2}"
SIZE="${GPT_IMAGE_SIZE:-1024x1536}"
BOOK_DIR="${BOOK_DIR:?please export BOOK_DIR=./covers/<book title>}"

mkdir -p "$BOOK_DIR/covers"

# Auto-increment version so previous covers are never overwritten
i=1
while [ -f "$BOOK_DIR/covers/cover_v${i}.png" ]; do i=$((i+1)); done
OUT="$BOOK_DIR/covers/cover_v${i}.png"
RESP=$(mktemp)
trap 'rm -f "$RESP"' EXIT

# Use jq to build the JSON body so quotes/newlines in PROMPT can't break the shell string
BODY=$(jq -n \
  --arg m "$MODEL" \
  --arg p "$PROMPT" \
  --arg s "$SIZE" \
  '{model:$m, prompt:$p, size:$s}')

curl -fsS --max-time 180 --retry 2 --retry-delay 5 \
  "$BASE_URL/images/generations" \
  -H "Authorization: Bearer $GPT_IMAGE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY" > "$RESP"

# Exit early on API errors instead of writing an error JSON as a broken PNG
if jq -e '.error' "$RESP" >/dev/null 2>&1; then
  echo "API error:" >&2
  jq '.error' "$RESP" >&2
  exit 1
fi

# `// empty` turns a missing field into an empty string (not "null"); combined with -s below, avoids writing a 3-byte fake PNG
jq -er '.data[0].b64_json // empty' "$RESP" | base64 --decode > "$OUT"
[ -s "$OUT" ] || { echo "empty or malformed output: $OUT" >&2; head -c 300 "$RESP" >&2; exit 1; }

# Save a copy of the prompt so the next iteration can tweak from the previous one
printf '%s\n' "$PROMPT" > "${OUT%.png}.prompt.txt"

file "$OUT"
ls -lt "$BOOK_DIR/covers/"
```

#### Image-to-image (with a reference image)

`/v1/images/edits` uses `multipart/form-data`; **do not** use `Content-Type: application/json`. Text fields use `--form-string` (so `@` is not misread as a file reference), the image field uses `-F image=@path`.

```bash
set -euo pipefail
: "${GPT_IMAGE_API_KEY:?please export GPT_IMAGE_API_KEY=your-key}"
: "${PROMPT:?please export PROMPT=the full prompt from the build-prompt step}"
BASE_URL="${GPT_IMAGE_BASE_URL:-https://api.openai.com/v1}"
MODEL="${GPT_IMAGE_MODEL:-gpt-image-2}"
SIZE="${GPT_IMAGE_SIZE:-1024x1536}"
BOOK_DIR="${BOOK_DIR:?please export BOOK_DIR=./covers/<book title>}"
REF_IMAGE="${REF_IMAGE:?please export REF_IMAGE=local path or URL}"

mkdir -p "$BOOK_DIR/covers"

# Auto-increment version
i=1
while [ -f "$BOOK_DIR/covers/cover_v${i}.png" ]; do i=$((i+1)); done
OUT="$BOOK_DIR/covers/cover_v${i}.png"
RESP=$(mktemp)
REF_TMP=""
trap '[ -n "$REF_TMP" ] && rm -f "$REF_TMP"; rm -f "$RESP"' EXIT

# Download URLs to a temp file; local paths are used directly. Bare mktemp keeps macOS/Linux behavior consistent.
case "$REF_IMAGE" in
  http://*|https://*)
    REF_TMP=$(mktemp)
    curl -fsSL --max-time 60 -o "$REF_TMP" "$REF_IMAGE"
    REF_LOCAL="$REF_TMP"
    ;;
  *)
    [ -f "$REF_IMAGE" ] || { echo "reference image does not exist: $REF_IMAGE" >&2; exit 1; }
    REF_LOCAL="$REF_IMAGE"
    ;;
esac

curl -fsS --max-time 240 --retry 2 --retry-delay 5 \
  "$BASE_URL/images/edits" \
  -H "Authorization: Bearer $GPT_IMAGE_API_KEY" \
  --form-string "model=$MODEL" \
  --form-string "size=$SIZE" \
  --form-string "prompt=$PROMPT" \
  -F "image=@$REF_LOCAL" > "$RESP"

if jq -e '.error' "$RESP" >/dev/null 2>&1; then
  echo "API error:" >&2
  jq '.error' "$RESP" >&2
  exit 1
fi

# `// empty` turns a missing field into an empty string (not "null"); combined with -s below, avoids writing a 3-byte fake PNG
jq -er '.data[0].b64_json // empty' "$RESP" | base64 --decode > "$OUT"
[ -s "$OUT" ] || { echo "empty or malformed output: $OUT" >&2; head -c 300 "$RESP" >&2; exit 1; }

printf '%s\n' "$PROMPT"    > "${OUT%.png}.prompt.txt"
printf '%s\n' "$REF_IMAGE" > "${OUT%.png}.ref.txt"

file "$OUT"
ls -lt "$BOOK_DIR/covers/"
```

### Step 5: Export platform upload size (when the platform has fixed pixels)

With `UPLOAD_SIZE` set (e.g., Kindle `1600x2560`, Royal Road `300x400`), **center-crop + scale** the original to the upload size — whether the generated image is 2:3 or 3:4, crop it to the platform's exact pixels without distortion, so the platform doesn't crop the title/byline itself. The original is kept; an `_upload` copy is written:

```bash
SRC="${OUT:-$(ls -t "${BOOK_DIR:-.}"/covers/cover_v*.png 2>/dev/null | grep -v _upload | head -1)}"  # reuse $OUT from the API step; in a new shell find the latest original under BOOK_DIR
TARGET="${UPLOAD_SIZE:-}"   # Kindle=1600x2560, Royal Road=300x400; unset = skip
if [ -n "$TARGET" ] && [ -f "$SRC" ]; then
  UP="${SRC%.png}_upload.png"; W="${TARGET%x*}"; H="${TARGET#*x}"
  if command -v magick >/dev/null 2>&1; then M=magick
  elif command -v convert >/dev/null 2>&1; then M=convert; else M=""; fi
  if [ -n "$M" ]; then
    "$M" "$SRC" -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" "$UP"  # scale to fill, then center-crop
  elif command -v sips >/dev/null 2>&1; then
    cp "$SRC" "$UP"
    sw=$(sips -g pixelWidth "$UP" | awk '/pixelWidth/{print $NF}')
    sh=$(sips -g pixelHeight "$UP" | awk '/pixelHeight/{print $NF}')
    if [ $((sw*H)) -ge $((sh*W)) ]; then sips --resampleHeight "$H" "$UP" >/dev/null
    else sips --resampleWidth "$W" "$UP" >/dev/null; fi
    sips -c "$H" "$W" "$UP" >/dev/null   # sips -c is height width, center-crop
  else
    echo "no magick/convert/sips found; skipping. Center-crop + scale $SRC to $TARGET manually before uploading" >&2
  fi
  [ -f "$UP" ] && file "$UP"
fi
```

> The title/byline already reserve a central safe area in the prompt, so center-cropping won't cut them.

### Step 6: Quality check + iterate

| Check | Standard |
|:------|:---------|
| Text rendering | title clearly legible; font style matches the genre |
| Genre match | visual style consistent with the title's genre |
| Composition sound | subject prominent; text does not block the core image |
| Platform fit | matches the target platform's cover-style conventions |
| Platform size | ratio matches the platform; after scaling to upload size, title and byline fully visible, not cropped |

Dissatisfied? Adjust direction: change composition, adjust color tone, swap font style, swap platform style.

---

## Reference materials

| File | When to load |
|:-----|:-------------|
| [references/cover-styles.md](references/cover-styles.md) | genre -> visual style mapping, platform style details, prompt templates |

---

## Language

- Load the deployed English book contract; use the book's `Record language` and `English variant` for cover metadata, title treatment, and prompts. Do not change output language because the user's chat message uses another language.
- English prose follows the house style rules in the skill's `references/` files
  (especially `anti-ai-writing.md`); keep sentences conversational, concrete,
  and free of AI-flavor patterns.
