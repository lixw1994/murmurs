## Context

MemoEntity 当前有 `content`（原文）和 `polishedContent`（AI 润色）两个文本字段，没有标题概念。TimelineEntryView 直接显示全文，随着内容增多，首页变成难以扫视的文字墙。

AI 润色（polish）已建立完整的流式调用模式：AIClientProtocol 方法 → ViewModel 状态追踪（Set + Dict） → View 条件渲染。标题生成将复用这套模式。

## Goals / Non-Goals

**Goals:**
- MemoEntity 新增 `title` 字段，通过 AI 生成 ≤15 字的短标题
- 转写/润色完成后自动触发标题生成
- Timeline 条目采用"标题 + 折叠预览"布局，提升信息密度
- 用户可手动生成/重新生成/删除标题

**Non-Goals:**
- 不支持用户手动编辑标题
- 不修改 Export/Summary/Watch 模块
- 不做搜索或标签系统

## Decisions

### 1. 标题生成用非流式请求，而非流式

标题只有几个字，流式传输没有意义。使用 `stream: false` 的普通 chat completion 请求，解析完整 JSON 响应中的 `choices[0].message.content`。

**理由**：简化实现，避免为几个字的响应拼接流式碎片。polish/summarize 用流式是因为内容长、用户需要看到实时进度。

**替代方案**：复用现有流式模式。缺点：过度设计，标题生成 < 1 秒完成，进度条无意义。

### 2. AIClientProtocol 新增 `generateTitle` 方法返回 `String`

```swift
func generateTitle(_ text: String, model: ChatModel) async throws -> String
```

不返回 `AsyncThrowingStream`，直接返回 `String`。System prompt 指示 AI 只输出一个简短标题。

**理由**：标题是原子操作（要么成功得到标题、要么失败），不需要中间状态。

### 3. 自动触发时机：转写完成后 + 润色完成后

在 `TimelineViewModel.transcribe()` 的成功回调中，如果 `config.isServerSet` 且 memo 无标题，自动调用 `generateTitle()`。同样在 `polish()` 完成后触发。

**理由**：用户录完音 → 转写 → 自动生成标题，形成无感链路。润色后内容变化，标题也应更新。

### 4. 文本折叠用 `@State expanded` 局部状态，点击切换

每个 TimelineEntryView 维护 `@State private var expanded = false`。默认折叠（`.lineLimit(3)`），点击正文区域切换展开/折叠。有标题时正文默认 `.lineLimit(2)`。

**理由**：展开/折叠是纯 UI 状态，不需要持久化。局部 `@State` 最简单。

**替代方案**：全局追踪哪些 memo 已展开。缺点：过度设计，每次重新进入页面默认折叠是合理行为。

### 5. System Prompt 设计

```
You are a title generator. Given voice memo transcription text, generate a concise title (max 15 characters).
Rules:
- Output ONLY the title text, nothing else
- No quotes, no punctuation at the end, no prefixes
- Capture the core topic or theme
- Use the same language as the input text
```

**理由**：15 字限制保持标题紧凑。要求与输入同语言（用户可能说中文或英文）。

## Risks / Trade-offs

**[API 额外调用开销]** → 标题生成是一次轻量 chat completion（< 100 tokens），成本可忽略。且仅在转写/润色完成后自动触发一次，非频繁操作。

**[标题质量依赖模型]** → 用户可删除不满意的标题并重新生成。标题不影响核心数据（content/polishedContent 不变）。

**[已有 memo 无标题]** → 不做迁移。用户可通过菜单手动为旧 memo 生成标题。SwiftData 的 `title` 字段默认 `nil`，不影响已有数据。

**[折叠状态不持久化]** → 每次进入页面所有 memo 默认折叠。这是符合预期的——类似邮件 App 每次打开都是列表预览模式。

## Affected Files

| File | Change |
|------|--------|
| `Sources/Persistence/MemoEntity.swift` | 新增 `title: String?` 字段 |
| `Sources/Services/Protocols/AIClientProtocol.swift` | 新增 `generateTitle` 方法签名 |
| `Sources/Services/OpenAI/OpenAIClient.swift` | 实现 `generateTitle`（非流式 chat completion） |
| `Sources/Modules/Timeline/TimelineViewModel.swift` | 标题生成逻辑、自动触发链 |
| `Sources/Modules/Timeline/TimelineEntryView.swift` | 标题显示 + 折叠/展开布局 |
| `Tests/Mocks/MockAIClient.swift` | 新增 `generateTitle` mock |
| `Localizable.csv` | 新增本地化字符串 |
