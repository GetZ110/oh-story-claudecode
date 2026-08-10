# Tracking Transaction Protocol

> **Legacy fixture note:** the JSON payloads below retain Chinese names and
> prose so UTF-8 and backward-compatibility tests remain meaningful. They are
> test data, not the English default. New books must use the book language
> contract and English field examples.

The protocol is one structured authority state plus deterministic derived views. The views are not written separately; `_tracking-state.json` is the only commit point. Keep the transaction JSON and directly rerun the same `commit` after an environment failure. It uses `expected_state_revision`, writes a complete continuity record, and is not a concurrency lock.

When rendering Markdown views, `tracking_commit.py` reads the book root `AGENTS.md` and uses its `Record language` for headings, labels, status descriptions, and chapter-record prose. `Prose language` never controls tracking output. Stable JSON field names, enum values, IDs, file paths, and proper nouns remain canonical; the surrounding Markdown is localized. A missing contract keeps legacy standalone fixtures in English, but a new writing workflow must create and validate `AGENTS.md` before initializing tracking.

The authority records the imported cutoff chapter as `imported_through_chapter`; chapter records may be overlay records, while the JSON remains the sole authority. The tool does not reverse-parse Markdown. A failed transaction JSON must be retained until the same input succeeds.

`tracking/` 使用“一个结构化权威状态 + 多个确定性派生视图”。模型只提交一份语义 JSON，不分别 `Write/Edit/echo >>` 多个tracking文件。

## 权威层与派生层

| 层级 | 文件 | 语义 |
|---|---|---|
| 唯一权威 | `_tracking-state.json` | schema、最后提交章、导入截止章、状态修订号、上下文结构、全部当前角色/伏笔/timeline状态 |
| 章节记录 | `chapter-records/第NNN章.md` | 本章对未来连续性有用的紧凑变化；目标 ≤1536 字节，硬上限 3072 字节；导入范围内修订写成覆盖记录 |
| Derived views | `context.md`, character snapshots, foreshadowing, author-truth timeline, and reader-knowledge timeline under the project's `tracking/` directory | Fully generated from `_tracking-state.json`; do not edit or use as program input |

Markdown 只负责给作者和 Agent 阅读，工具不再反向解析 Markdown。`check` 直接从 `_tracking-state.json` 重渲染并逐文件比较。未来“第几章揭示”的计划写在卷纲/细纲，不写成timeline既成事实。
chapter-records只是便于人阅读的紧凑变化记录，不承诺单独无损重建全部当前状态；完整当前语义以 `_tracking-state.json` 为准。

## 运行工具

先按运行环境探测 Python 3 解释器（依次尝试 `python3`、`python`、`py -3`），再用当前 skill 根目录执行：

```text
{PYTHON} {当前 skill 根}/scripts/tracking_commit.py init   --project {书项目根} --input {初始化事务.json}
{PYTHON} {当前 skill 根}/scripts/tracking_commit.py commit --project {书项目根} --input {逐章事务.json}
{PYTHON} {当前 skill 根}/scripts/tracking_commit.py check  --project {书项目根}
```

- `init`：只在 `_tracking-state.json` 不存在时执行，绝不覆盖已初始化项目。
- `commit`：读取唯一权威状态，在内存中完成合并、引用检查、全部视图渲染和容量检查；随后写chapter-records与派生视图，最后原子替换 `_tracking-state.json` 作为唯一提交点。
- `check`：严格验证 state schema、chapter-records连续性/规范名/体积、固定 7 栏、角色快照硬上限、派生文件集合，以及所有派生视图与 state 的逐字一致性。

同一本书只允许工作流串行提交，不支持多个 Agent 或终端并发写。`expected_state_revision` 用于拒绝基于旧状态构造的顺序 stale transaction，不是并发锁。

事务 JSON 在成功前必须保留。若文件写入失败，`_tracking-state.json` 尚未推进；修正环境后直接重跑**同一份** `commit`。append 重跑只接受内容完全相同的既有chapter-records，不维护 `dirty/pending/repair` 状态机。

Validation failures and write failures are different: fix the transaction itself for invalid fields, retirement violations, or capacity limits, then rerun it unchanged. If a manually edited derived view makes `check` report `derived view differs from _tracking-state.json`, resubmit that chapter as `mode=revision` so the tool rebuilds every derived view; take `expected_state_revision` from `tracking/_tracking-state.json`. Do not edit derived files or delete `_tracking-state.json`.

This tool does not parse legacy `_tracking-meta.json`, `timeline/event-library.json`, or earlier tracking layouts, and provides no semantic compatibility layer. When `init` finds legacy files, move them unchanged into `tracking/_retired-tracking-archive/` before creating the current protocol in place. The archive remains available for author reference but is not parsed; current state comes entirely from the `init` input. A failed `init` validation moves no files. `commit` and `check` reject legacy layouts and run only on projects using the current protocol.

## 初始化事务

新书从第 0 章初始化。`story-import` 导入已有小说时把最后完整章写入 `last_chapter=N`；第 1..N 章不伪造日更记录，常规续写从 N+1 章开始。

```json
{
  "schema_version": 1,
  "book_title": "让你管账号，你高燃混剪炸全网",
  "last_chapter": 0,
  "context": {
    "position": {
      "volume": "第一卷·军宣整顿",
      "volume_start_chapter": 1,
      "story_time": "江晨到火箭军文工团报到前",
      "scene": "火箭军文工团"
    },
    "long_term_constraints": ["军宣爽点要用作品效果和围观反应链兑现，不能只靠系统播报"],
    "active_character_names": [],
    "continuity_risks": [],
    "recent_chapters": [],
    "next_chapter_commitments": ["让江晨报到，并落下五天百万粉的新手任务"]
  },
  "character_snapshots": {},
  "foreshadow": [],
  "timeline_events": []
}
```

导入初始化时直接传入当前核心角色快照、伏笔当前行、timeline事件和固定 7 栏状态输入。阶段/卷级回看按需查询正文，不作为每章强一致tracking产物。

## 逐章事务

```json
{
  "schema_version": 1,
  "mode": "append",
  "chapter": 10,
  "chapter_title": "专业团队拍得还不如他拍的好？",
  "expected_state_revision": 9,
  "delta": {
    "result": "专业团队重拍的高清版在高层看片会上被判定缺了灵魂，张耀祖拍板继续采用江晨的手机原版。",
    "character_changes": [
      {"name": "江晨", "change": "作品价值获军内高层确认，从爆款新人升为不可替代的军宣创作者"}
    ],
    "foreshadow_changes": [
      {
        "action": "upsert",
        "id": "F027",
        "summary": "专业团队仍拍不出江晨原版的灵魂，继续验证其创作能力不可复制",
        "planted_chapter": 10,
        "planned_resolution_chapter": null,
        "status": "planted",
        "importance": "中"
      }
    ],
    "timeline_events": [
      {
        "action": "upsert",
        "id": "E010",
        "story_time": "实弹训练两天后",
        "objective_fact": "文工团高层否决专业重拍版，决定沿用江晨手机拍摄的原版视频",
        "reader_knowledge": "读者已看到周薄森指出专业版缺了灵魂，张耀祖当场拍板用回原版",
        "reveal_status": "revealed",
        "reveal_chapter": 10,
        "characters": ["江晨", "周薄森", "张耀祖"]
      }
    ],
    "constraints": ["后续继续用作品落地效果和围观反应放大江晨的高光，不能只写系统奖励数字"],
    "next_chapter_commitments": ["结算五天百万粉任务，并承接老兵主题的新任务"]
  },
  "context": {
    "position": {
      "volume": "第一卷·军宣整顿",
      "volume_start_chapter": 1,
      "story_time": "实弹训练两天后",
      "scene": "火箭军文工团高层看片会"
    },
    "long_term_constraints": ["军宣爽点要用作品效果和围观反应链兑现，不能只靠系统播报"],
    "active_character_names": ["江晨"],
    "continuity_risks": ["钟嘉嘉说江晨只猜对一半，未公开的培养安排不能被当成读者已知事实"]
  },
  "character_snapshots": {
    "江晨": {
      "identity": "火箭军文工团宣传兵；军宣爆款创作者",
      "location": "火箭军文工团高层看片会",
      "goal": "完成五天百万粉任务，持续做出真正能打的军宣内容",
      "state": "专业团队反向验证原版价值，军内认可继续抬升",
      "abilities_resources": ["前世MCN爆款运营经验", "《中国军魂》伴奏", "大师级导演能力"],
      "relationships": ["钟嘉嘉持续提供军报资源", "周薄森和张耀祖已明确认可其创作能力"],
      "knowledge": ["《军报》采访稿已经过审", "原版视频将继续作为正式军宣内容"],
      "open_threads": ["五天百万粉任务尚未结算", "钟嘉嘉所谓只猜对一半仍未解释"]
    }
  }
}
```

约束：

- 构造事务前运行 `check`，把当前 `state_revision` 原样写入 `expected_state_revision`；若状态已经变化，重新读取 state 并重构事务。
- `context` 的允许字段随子命令不同：`init` 收 `position`、`long_term_constraints`、`active_character_names`、`continuity_risks`、`recent_chapters`、`next_chapter_commitments` 六项；`commit` 只收前四项。`recent_chapters` 与 `next_chapter_commitments` 在 commit 时由工具从当前视图和本章 `delta` 派生，手填会在任何写入前被拒（`context contains unsupported fields: ...`，exit 2）。照 init 示例套 commit 事务是最容易踩的一处。
- `character_snapshots` 中出现的角色视为核心复用角色，必须同时出现在 `character_changes`；已经建立快照的核心角色再次变化时必须提交新快照。
- 角色快照的四个列表不限制条数，只限制单项长度和最终文件总字节：目标 ≤4096 字节，超过警告；硬上限 8192 字节，超过则在任何写入前拒绝。
- 没有快照的角色变化视为临时角色，不建立状态文件；`context.active_character_names` 最多 6 人且必须已有当前快照。
- `context.long_term_constraints` and `context.continuity_risks` are the complete current values. Every item present before but absent now must be listed in `delta.retired_context_items`; otherwise the tool rejects the transaction before any write because omission is not deletion. The tool records retired items in this chapter's `chapter-records` under `## Retired Entries This Chapter` for later lookup.
- Put reusable core characters that are no longer active in `delta.retired_characters`. The tool removes their current snapshot and `character-state/{Character Name}.md`, while preserving an archive entry in `chapter-records`. A transaction cannot both retire a character and submit its snapshot, and a retired character cannot remain in `context.active_character_names`. A death or exit belongs in `character_changes`; retiring the character only means removing it from hot context and does not alter the prose or chapter records.
- Both retirement operations are allowed only in `mode=append`. Retirement means leaving current state from this point onward; a revision rewrites an old chapter record and must not claim that retirement happened in that old chapter. `mode=revision` must resubmit the complete current context, with retirement deferred to the next append.
- `foreshadowing.md` 只呈现已经埋设过的当前状态。未来规划仍留在大纲。
- `timeline_events.action` 可为 `upsert/delete`。`unrevealed` 的 `reveal_chapter` 必须为 `null`；部分/完全揭示只能填写已经发生的实际章节。
- `mode=revision` 时，chapter-records必须重算为修订后该章仍然成立的完整连续性记录；当前角色、伏笔、timeline和上下文则提交受影响对象截至最新已写章的当前值。
- 修订导入截止章内的正文时，会新增或覆盖该章的chapter-records；`imported_through_chapter` 不变。

## 续写状态卡固定格式

`context.md` ≤12288 字节，由 state 整份生成，只含以下 7 个顶层区块：

1. `## Current Position`
2. `## Long-Term Constraints`
3. `## 核心character-state`
4. `## Active Foreshadowing`
5. `## Recent Chapters`
6. `## Next-Chapter Commitments`
7. `## Continuity Risks`

其中活跃角色最多 6 人、活跃伏笔确定性选取最多 8 条、近章只保留 3 章。这些是下一章热上下文容量，不是完整character-state的容量限制。
