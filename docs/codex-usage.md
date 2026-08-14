# Codex 使用说明

本文说明 `oh-story-claudecode` 在 Codex 中的安装、初始化、交互式选择和日常使用方式。

## 1. 安装技能

首次安装：

```powershell
Install this skill https://github.com/GetZ110/oh-story-claudecode
```

安装完成后重启 Codex。

全局安装只负责让 Codex 识别技能；每个写作项目仍需要执行 `story-setup`，部署项目级的 hooks、agents、`AGENTS.md` 和写作规则。

## 2. 初始化写作项目

在 Codex 中打开小说项目根目录，例如：

```text
D:\novels\SecondNovel
```

切换到“计划模式”，执行：

```text
$story-setup
```

首次运行时选择 `Codex`。部署完成后，重新开始一个 Codex 会话，让项目自定义 agents 生效。

项目通常会生成：

```text
.codex/agents/
.codex/hooks.json
.codex/hooks/
.codex/skills/story-setup/
AGENTS.md
.story-deployed
```

可以在新会话中执行 `$story-review` 验证部署：

```text
Effective Mode: full
```

表示多代理正常工作；`Fallback: ... -> solo` 表示 agents 未加载，需要重新运行 `$story-setup` 或重启会话。

## 3. 计划模式与交互式选择

技能内部使用 `AskUserQuestion` 进行选项选择。在 Codex 中，想看到真正的交互式选项，应先切换到“计划模式”。

### 必须或强烈建议使用计划模式

| 命令 | 使用场景 |
|---|---|
| `$story-setup` | 选择 Codex、OpenCode、Claude Code 等部署目标 |
| `$story-long-write start a novel` | 新建长篇、选择题材、书名、市场和语言 |
| `$story-short-write` | 新建短篇、选择情绪目标、题材和平台 |
| `$story-long-scan` | 选择 Royal Road、Webnovel、Wattpad、Kindle 等平台 |
| `$story-short-scan` | 选择 Wattpad、Inkitt、Radish、Galatea 等平台 |
| `$story-import` | 选择导入文件、长篇/短篇、章节状态和语言契约 |
| `$story-long-analyze` | 选择分析范围，尤其是 Stage 1 后是否继续完整拆解 |
| `$story` 切换书籍 | 多本书存在时选择当前活动书 |
| `$story-cover` | 未提供书名或作者名，需要交互询问时 |

例如市场扫描应在计划模式中执行：

```text
$story-long-scan
```

然后选择平台和题材。

### 通常不需要计划模式

```text
$story-long-write write chapter 1
$story-long-write daily
$story-long-write revise chapter 3
$story-short-write continue
$story-review full
$story-review lean
$story-review solo
$story-deslop D:\path\chapter.md
$story dashboard
```

如果已经在命令中提供了路径、章节号和模式，普通模式即可执行。

## 4. 新建英文长篇小说

第一次写新书，建议在计划模式执行：

```text
$story-long-write start a novel
```

根据提示确认：

- 小说标题
- 题材和情绪方向
- 目标平台
- 英文市场
- 正文语言
- 记录文档语言
- benchmark 参考作品
- 英语变体，例如 `en-US` 或 `en-GB`

技能会创建：

```text
{BookTitle}/
├── AGENTS.md
├── setting/
├── outline/
├── prose/
├── tracking/
└── benchmark/
```

默认先完成设定、结构和前 10 章大纲，然后停止，不会自动开始写正文。

切换普通模式后执行：

```text
$story-long-write write chapter 1
```

继续写作：

```text
$story-long-write daily
```

指定章节或修改章节：

```text
$story-long-write write chapter 2
$story-long-write write chapters 3-5
$story-long-write revise chapter 3
```

注意：只执行裸命令 `$story-long-write` 时，它只检查项目状态并列出下一步选项，不会自动询问书名、语言，也不会直接开始写作。新书应使用 `$story-long-write start a novel`。

## 5. 新建短篇小说

在计划模式执行：

```text
$story-short-write
```

回答情绪目标、题材、平台和故事想法。短篇项目通常包含：

```text
{StoryTitle}/
├── setting.md
├── section-outline.md
└── prose.md
```

短篇正文相邻段落之间使用一个空行。

## 6. 市场扫描

长篇英文平台：

```text
$story-long-scan
```

支持 Royal Road、Webnovel、Wattpad、Amazon Kindle、Inkitt 等。

短篇英文平台：

```text
$story-short-scan
```

支持 Wattpad、Inkitt、Radish、Galatea、Dreame、GoodNovel、Tapas 等。

扫描完成后可执行 `$story-long-write start a novel`，技能会读取 `topic-decision.md` 并询问是否采用推荐方向。

## 7. 拆解参考小说

长篇拆解：

```text
$story-long-analyze
```

在计划模式中提供源文件路径。Stage 1 完成后选择是否继续完整拆解。也可以直接说明 `full teardown`，让流程不中途等待选择：

```text
$story-long-analyze full teardown D:\path\source.txt
```

输出位置：

```text
teardown-lib/{BookTitle}/
```

短篇拆解：

```text
$story-short-analyze
```

## 8. 导入已有小说并继续写作

推荐顺序：

1. 在项目根目录执行 `$story-setup`。
2. 开始新的 Codex 会话。
3. 在计划模式执行 `$story-import`。
4. 提供已有小说文件或目录。
5. 确认长篇/短篇、最后完成章节、正文语言和记录语言。
6. 导入完成后执行：

```text
$story-long-write daily
$story-long-write write chapter 21
```

## 9. 审查与去除 AI 痕迹

```text
$story-review full
$story-review lean
$story-review solo
```

完整模式默认使用多角度审查；`lean` 使用较少的 agents；`solo` 不启动子代理。

去除 AI 写作痕迹：

```text
$story-deslop D:\path\to\chapter.md
```

默认直接修改文件，只调整表达方式，不改变故事内容。

## 10. 打开本地写作面板

在项目根目录执行：

```text
$story dashboard
```

Dashboard 可以浏览小说和拆解资料库、预览和编辑 Markdown 文件、搜索内容并安全保存。服务只监听 `127.0.0.1`，不需要计划模式。

## 11. 语言规则

技能对话默认使用简体中文；小说项目内部遵循书籍目录下的 `AGENTS.md`。

例如本项目面向英文市场、正文用英文而记录用中文时，应设置为：

```text
Prose language: en
Record language: zh-CN
English variant: en-US
```

因此：

- Codex 的解释、询问和状态报告默认中文。
- 正文使用英文。
- 大纲、设定、tracking、导入摘要、拆解报告和其他记录使用简体中文。
- 英文正文相邻段落之间保留一个空行。

`Prose language` 和 `Record language` 必须分别确认，不能因为正文是英文就自动把记录改成英文。新书建档时，必须先选择书名候选，再把最终标题和两种语言写入书籍目录下的 `AGENTS.md`。后续所有 skill 和项目级 agent 都必须读取这份契约；如果契约缺失或语言字段不完整，应暂停并要求补充，而不是自行推断。

如果当前书籍已经出现中英文混用，应按以下顺序处理：

1. 检查书籍根目录 `AGENTS.md` 的 `Prose language` 和 `Record language`。
2. 将 `outline/`、`setting/`、`tracking/`、`benchmark/` 和报告中的自然语言统一为 `Record language`。
3. 保留英文正文、英文书名、章节标题、人名、地名、公司名和其他创作标识，不把这些专有名词误译成记录语言。
4. 更新 skill 后重新执行 `$story-setup`，再开始新的 Codex 会话，使项目级 agent 和 references 载入最新规则。

写作流程产生的 `tracking/` 派生文件由 `tracking_commit.py` 根据 `_tracking-state.json` 重建；它会读取书籍根目录 `AGENTS.md` 的 `Record language`，因此不需要手动修改 `context.md`、角色快照、伏笔和时间线。若旧书已经混用，先修复语言契约和源码部署，再用 canonical renderer 重建派生 tracking 文件，最后运行 `tracking_commit.py check`。

## 12. 更新后处理

更新全局技能后：

1. 重启 Codex。
2. 已部署的小说项目重新执行 `$story-setup`，同步项目 hooks、agents 和 references。
3. 再开始一个新会话，让 `.codex/agents/` 和 hooks 重新加载。

日常最常用的流程：

```text
计划模式：
$story-setup
$story-long-write start a novel

新会话，普通模式：
$story-long-write write chapter 1
$story-long-write daily
$story-review full
```
