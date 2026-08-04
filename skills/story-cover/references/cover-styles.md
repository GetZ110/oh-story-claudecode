# Fiction Cover Visual Style Library
Visual style definitions for fiction covers by genre, for building GPT-Image-2 English prompts.

---

## Platform styles

### Royal Road

Visual: polished epic fantasy illustration / character-focused, clean composition / title legible at small thumbnail sizes / premium feel
Keywords: `epic fantasy illustration, refined detailed art, cinematic composition, high contrast subject, professional web serial cover style, clean thumbnail legibility`

### Webnovel (webnovel.com)

Visual: vibrant saturated, character-dominated covers / big bold title with glow / mass-market mobile thumbnail style
Keywords: `vibrant saturated colors, eye-catching bold design, character portrait dominating frame, mass-market mobile novel cover style, high contrast`

### Kindle / KDP

Visual: commercial professional design / typography-led, thumbnail-legible / genre-signaling composition / series consistency matters
Keywords: `professional commercial book cover, bold typography, clean thumbnail legibility, genre-signaling composition, premium quality, series branding`

### Wattpad

Visual: soft romantic aesthetic / pastel and dreamy palettes (pink, lavender, light blue, warm white) / delicate character close-ups / flower petals and bokeh decorations / elegant handwritten or light serif title
Keywords: `dreamy ethereal aesthetic, soft pastel tones, elegant romantic, delicate beauty, flower petals and bokeh`

### Inkitt

Visual: moody premium romance / dark tones or rich atmospheric scenes / strong single-sitting hook feel / modern minimalist typography or elegant serif / cinematic lighting
Keywords: `moody cinematic romance cover, rich atmospheric tones, dark and dramatic lighting, elegant premium typography, independent film poster aesthetic`

---

## Genre inference rules

| Keywords | Genre | Style tags |
|:---------|:------|:-----------|
| dragon / wizard / sword / realm / magic / mage / dungeon / kingdom / elf / knight / sorcerer / crown / blade | fantasy | high fantasy epic |
| duke / lord / king / queen / alpha / wolf / mate / fated / prince / princess / contract / bride / billionaire / ceo / love / heart / kiss / pack | romance / paranormal | romance paranormal |
| detective / murder / mystery / clue / killer / crime / suspect / noir / case | mystery | mystery thriller |
| spaceship / star / galaxy / alien / cyborg / mech / robot / space / starship / void | sci-fi | sci-fi futuristic |
| zombie / apocalypse / haunted / ghost / blood / nightmare / dead / curse | horror | supernatural horror |
| emperor / dynasty / empire / war / general / viking / samurai / gladiator / medieval / battlefield | historical | historical epic |
| system / level / quest / litrpg / gamer / dungeon-crawl | litRPG / game | game litRPG |
| academy / school / slice of life / cozy | contemporary | contemporary warm |
| cat / kitten / fluffy / tiny / reincarnated as | light novel | light novel anime |

---

## Prompt-building formula

```
[platform style] + [text layer: title + author name + font design] + [genre style tags] + [character description]
+ [background elements] + [color instructions] + [light instructions] + [generic polish]
```

Generic polish: `professional book cover design, high detail digital painting, portrait orientation 2:3 ratio, no watermark`

The text layer must specify: title content + position (top center) + font style + color; author-name content + position (bottom center) + font style + color.

---

## Prompt tips

### Text rendering

GPT-Image-2 renders the provided title/author text directly. Format:
```
Title text 'Title' at top center in {font style}
Author name 'Author Name' at bottom center in {font style}
```

### Character descriptions must be specific

Not "a man" — use:
```
a young man in flowing white silk robes with gold embroidery,
long black hair tied back, piercing dark eyes, confident expression,
holding a glowing blue sword
```

### Three-layer background

Foreground (character/props) -> midground (scene: mountains/buildings/forest) -> background (atmosphere: clouds/stars/fire)

### Light

| Light | Keywords | Feel |
|-------|----------|------|
| Divine | `dramatic golden light from above` | sacred |
| Mysterious | `cold moonlight from the left casting long shadows` | mysterious |
| Warm | `warm sunset glow backlighting the figure` | warm |
| Sci-fi | `neon blue and purple lights from below` | futuristic |

### Avoiding a real-photo look

Add `digital painting style`; fiction covers want an illustrated feel.

### Composition variants

| Type | Keywords | Use |
|:-----|:---------|:----|
| Character close-up | `close-up portrait, face filling upper half` | emphasizes the character |
| Full body | `full body shot, dynamic pose` | shows costume and action |
| Pure scene | `no human figure, landscape composition` | mystery / sci-fi |
| Couple | `two figures facing each other` | romance |

---

## Style library

### Fantasy

**Tags**: `high fantasy epic art style, ethereal atmosphere`
**Colors**: deep blue + gold + black, cool base with warm golden accents
**Character**: hero in flowing robes with a blade/artifact, banners and towers behind | heroine in flowing gown with jeweled crown
**Background**: cloud sea, citadel, ancient castle, magical glow
**Light**: `divine golden light rays, mystical mist, magical energy glow`
**Example**:
```
Web fiction cover, high fantasy epic style.
Title text 'The Sword Sovereign' at top center in bold golden brush calligraphy with metallic glow and sharp strokes.
Author name 'J. R. Ashford' at bottom center in small refined white serif text with faint golden glow, flanked by delicate cloud-scroll ornaments, resting on a thin horizontal gold line.
A young swordsman in flowing white robes standing on a mountain peak,
holding a glowing blue sword, long black hair flowing in the wind.
Ethereal clouds swirling below, dramatic golden divine light from above,
magical energy particles. Dark misty mountain peaks in background.
Color palette: deep blue, gold, white, black.
Professional book cover, high detail digital painting, portrait 2:3 ratio, no watermark
```

### Contemporary

**Tags**: `modern urban contemporary style, clean cinematic composition`
**Colors**: deep blue + grey + gold, neon accents (night) / warm orange (dusk)
**Character**: man in suit/casual wear, sharp silhouette | woman in fashion-forward outfit, confident expression
**Background**: city skyline, high-end office, campus, neon streets
**Light**: `sharp city lights, sunset glow reflecting on glass buildings, neon rim light`

### Romance / Paranormal

**Tags**: `romance cover art, elegant classical beauty, passionate atmospheric`
**Colors**: deep red + gold + black (dark romance) or soft rose + cream (sweet)
**Character**: duke/lord/alpha in tailored coat or ceremonial uniform, smoldering gaze | heroine in flowing gown, wind-touched hair
**Background**: manor hall, moonlit garden, ballroom, misty woods
**Light**: `warm candle glow, golden chandelier light, silk fabric shimmering`

### Sweet romance

**Tags**: `modern romance cover art, soft dreamy warm atmosphere`
**Colors**: pink + warm white + light gold, warm and soft
**Character**: couple-focused composition, sweet interaction (embrace/eye contact/holding hands)
**Background**: cafe, garden, cozy interior, sunset beach
**Light**: `soft warm backlighting, dreamy bokeh, gentle sunset glow`

### Mystery / Thriller

**Tags**: `dark mystery thriller, noir atmosphere, high contrast shadows`
**Colors**: black + dark grey + dark blue, blood red / cold white accents
**Character**: silhouette / half-hidden face / back view, calm or tense
**Background**: rainy night street, old building, locked room, dark alley
**Light**: `dramatic chiaroscuro, single spotlight, rain-slicked reflections`

### Sci-fi

**Tags**: `sci-fi futuristic, space opera, post-apocalyptic`
**Colors**: deep blue + black + silver, neon blue / electric purple / energy green accents
**Character**: mech suit / tactical gear / lab coat, sci-fi weapon / holographic interface
**Background**: space, ruined city, laboratory, space station
**Light**: `holographic blue glow, neon rim lighting, energy arcs`

### Historical epic

**Tags**: `historical epic war panorama, grand battlefield atmosphere`
**Colors**: iron grey + dark red + earth yellow, gold armor gleam / beacon orange accents
**Character**: general in armor / strategist in robes, holding a weapon
**Background**: battlefield, city wall, army camp, beacons
**Light**: `dramatic battlefield firelight, smoke-filled sky, sunset over war`

### Horror

**Tags**: `supernatural horror, eerie ghostly atmosphere`
**Colors**: ink black + sickly green + dark red, paper white / candle yellow accents
**Character**: ordinary person caught in the eerie, ghost figure / shadow in the background
**Background**: graveyard, old temple, dark alley, coffin
**Light**: `eerie green glow, flickering candlelight, cold ghostly luminescence`

### LitRPG / Game

**Tags**: `game litRPG cover, vibrant isekai game art, system UI accents`
**Colors**: electric blue + violet + dark, glowing stat-panel accents
**Character**: adventurer with class outfit, glowing level-up aura, floating UI panels
**Background**: dungeon, guild hall, fantasy battlefield, portal
**Light**: `holographic blue glow, spell flash, neon energy arcs`

### Light novel / Anime

**Tags**: `anime light novel cover, vibrant colorful moe style`
**Colors**: bright multicolor, star / petal accents
**Character**: chibi/moe character, cat ears / wings / other moe traits
**Background**: fantasy world, school, other world, starry sky
**Light**: `sparkly star effects, magical particle effects, soft luminous glow`
