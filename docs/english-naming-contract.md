# English Naming Contract (Single Source of Truth)

This repo is the English-language edition of the oh-story toolkit. Every directory,
file, regex, and marker listed below **must** use the English names exactly as
specified. Any deviation breaks hooks, the dashboard, skill contracts, and tests.
Chinese names from the legacy edition are shown in parentheses for history only —
they must not appear in shipped content.

## 1. Project root directories (writing project)

| English (canonical) | Legacy Chinese | Notes |
|---|---|---|
| `teardown-lib/` | `拆文库/` | Book-deconstruction library, one folder per book |
| `teardown-lib-{BookTitle}/` | `拆文库-{书名}/` | Legacy-compatible variant still recognized |
| `prose/` | `正文/` | Long-form chapter files |
| `outline/` | `大纲/` | Master outline + volume/chapter outlines |
| `setting/` | `设定/` | World, characters, style, genre positioning |
| `tracking/` | `追踪/` | Context, foreshadowing, timeline, character state |
| `benchmark/` | `对标/` | Benchmark-book material |

## 2. Long-form project files

| English (canonical) | Legacy Chinese |
|---|---|
| `outline/outline.md` | `大纲/大纲.md` |
| `outline/volume_outline_N.md` | `大纲/卷纲_第N卷.md` |
| `outline/outline_chapter_NNN.md` | `大纲/细纲_第NNN章.md` |
| `prose/chapter_NNN_Title.md` | `正文/第NNN章_标题.md` |
| `setting/characters/*.md` | `设定/角色/*.md` |
| `setting/relationships.md` | `设定/关系.md` |
| `setting/style.md` | `设定/文风.md` |
| `setting/genre-positioning.md` | `设定/题材定位.md` |
| `setting/worldview/*.md` | `设定/世界观/*.md` |
| `tracking/context.md` | `追踪/上下文.md` |
| `tracking/foreshadowing.md` | `追踪/伏笔.md` |
| `tracking/timeline.md` | `追踪/时间线.md` |
| `tracking/character-state.md` | `追踪/角色状态.md` |

## 3. Teardown library structure (`teardown-lib/{BookTitle}/`)

| English (canonical) | Legacy Chinese |
|---|---|
| `teardown-report.md` | `拆文报告.md` |
| `overview.md` | `概要.md` |
| `quick-preview.md` | `快速预览.md` |
| `style.md` | `文风.md` |
| `source/` | `原文/` |
| `chapters/chapter_N_summary.md` | `章节/第N章_摘要.md` |
| `chapters/chapter_N_deep-dive.md` | `章节/第N章_深度拆解.md` |
| `characters/*.md` | `角色/*.md` |
| `characters/relationships.md` | `角色/角色关系.md` |
| `plot/emotional-beats.md` | `剧情/情绪模块.md` |
| `plot/pacing.md` | `剧情/节奏.md` |
| `plot/storylines.md` | `剧情/故事线.md` |
| `plot/loose-threads.md` | `剧情/散落情节.md` |
| `plot/*.md` (free-named) | `剧情/*.md` |
| `setting/worldview/*.md` | `设定/世界观/*.md` |
| `setting/factions/*.md` | `设定/势力/*.md` |
| `setting/cheat.md` | `设定/金手指.md` |
| `_progress.md`, `_meta.json` | unchanged |

## 4. Short-form project markers (dashboard / hooks)

| English (canonical) | Legacy Chinese |
|---|---|
| `prose.md` | `正文.md` |
| `section-outline.md` | `小节大纲.md` |
| `setting.md` | `设定.md` |

## 5. Regexes and markers

| English (canonical) | Legacy Chinese | Used by |
|---|---|---|
| `/^chapter[_ -]?\d+/i` chapter files | `/^第.*章/` | hooks, dashboard |
| `/^chapter[_ ]?0*\d+[_ \-]+(.+)$/` title extraction | `/^第0*\d+章[_\- 　]+(.+)$/` | hooks |
| `outline_chapter_` prefix scan | `细纲_第` | hooks |
| `volume_outline_` prefix scan | `卷纲_第` | hooks |
| `Target words:` field in outline | `字数目标：{X} 字` | hooks |
| `<!-- deslop:skip -->` exemption marker | `去味:跳过` | hooks, deslop |
| `.active-book` | unchanged | hooks |
| `LONG_PROJECT_DIRECTORY_MARKERS = {prose, outline, setting, tracking}` | `{正文, 大纲, 设定, 追踪}` | dashboard |
| `SHORT_PROJECT_BODY_FILE = prose.md`; companions `{section-outline.md, setting.md}` | `正文.md`; `{小节大纲.md, 设定.md}` | dashboard |
| character sheet: `setting/characters|people` branches | `设定/角色\|人物` | hooks |
| character-sheet skip list: `relationships.md\|genre-positioning.md\|style.md\|worldview.md\|cheat.md` | `关系.md\|题材定位.md\|文风.md\|世界观.md\|金手指.md` | hooks |
| stat fields `height\|weight\|age`, name field `name` | `身高\|体重\|年龄`, `名字\|姓名\|名称` | hooks |

## 6. Chapter-outline template fields (细纲 → chapter outline)

| English (canonical) | Legacy Chinese |
|---|---|
| `## Chapter Outline (Chapter N)` | `## 细纲（第 N 章）` |
| `Core event:` | `核心事件：` |
| `Target words:` | `字数目标：` |
| `Stage position:` | `阶段位置：` |
| `Unit ID/position:` | `单元ID/位置：` |
| `Target emotion:` | `目标情绪：` |
| `Protagonist goal/key choice:` | `主角目标/关键选择：` |
| `Chapter positioning:` | `章节定位：` |
| `Chapter structure formula:` | `本章结构公式：` |
| `Opening hook:` | `章首钩子：` |
| `Payoff:` | `爽点：` |
| `Forbidden early release:` | `本章禁止提前释放：` |
| `Contract risk:` | `契约风险：` |
| `Content summary (five-part):` — Cause / Development / Turn / Climax / Ending | `内容概括（五段式）：` 起因/发展/转折/高潮/结尾 |
| `Plot arrangement (multi-line):` — Main line / Sub-line / Event & task line / Task blockers / Relationship line / Logic line | `情节安排（多线）：` 主线/辅线/事件线/任务线/感情线/逻辑线 |
| `Characters and appearance order:` — Appearance order / Relationship changes / POV & information gap | `人物关系和出场顺序：` 出场顺序/人物关系变化/视角·信息差 |
| `Plot detail:` — plot-point sequence with dense/light budget labels + function tags; `Total budget:` | `情节细化：` 情节点序列 密/疏 + 功能标签；`预算合计：` |
| `Ending and hook:` — Ending design / Chapter-end hook (from the 13 techniques, expectation strength strong/medium/weak) | `结尾设定和钩子：` 结尾设定/章尾钩子（章尾13式，期待度 强/中/弱） |

## 7. Outline file names (volume/master)

| English (canonical) | Legacy Chinese |
|---|---|
| `master outline` | `总纲` |
| `volume outline` | `卷纲` |
| `chapter outline` | `细纲` |
| `story unit` | `剧情单元` |

## 8. Platform names (market scanning)

| English (canonical) | Legacy Chinese |
|---|---|
| Royal Road | 起点 (Qidian) |
| Webnovel (webnovel.com) | 番茄 (Fanqie) |
| Wattpad | 晋江 (Jinjiang) |
| Amazon Kindle (Top 100 / KU) | — |
| Inkitt / Radish / Galatea / Dreame / GoodNovel / Tapas | 知乎盐言 / 七猫 / 黑岩 / 点众 |
| PocketFM (audio) | — |

## 9. Global style directive (replaces the Chinese one in every SKILL.md tail)

> - Follow the user's language.
> - English prose follows the house style rules in the skill's `references/` files
>   (especially `anti-ai-writing.md`); keep sentences conversational, concrete,
>   and free of AI-flavor patterns.
