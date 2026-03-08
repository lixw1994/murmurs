## Context

Timeline 当前使用 `@Query` 获取所有 `MemoEntity`，按 `day` 分组显示。没有搜索入口。`MemoEntity` 有三个可搜索文本字段：`title`（AI 标题）、`content`（原文/转写）、`polishedContent`（AI 润色）。

SwiftUI 原生提供 `.searchable()` modifier，配合 `@Query` 的动态 `#Predicate` 可实现本地全文搜索，无需引入外部搜索引擎。

## Goals / Non-Goals

**Goals:**
- 在 Timeline 页面提供搜索入口
- 搜索 `title`、`content`、`polishedContent` 三个字段
- 搜索结果实时更新（随输入变化）
- 搜索模式下显示扁平结果列表（不按日期分组）

**Non-Goals:**
- 不做 Spotlight 集成
- 不做搜索排序/相关度排序
- 不做 Watch 端搜索

## Decisions

### 1. 使用 SwiftUI `.searchable()` 而非自定义搜索栏

使用系统 `.searchable(text:isPresented:)` modifier，搜索栏自动嵌入 NavigationStack。

**理由**：原生组件自动处理键盘、动画、取消按钮、无障碍。与现有 NavigationStack 无缝集成。用户已习惯 iOS 原生搜索交互。

**替代方案**：自定义 TextField 搜索栏。缺点：需要手动处理键盘管理、动画，且不符合 iOS HIG。

### 2. 搜索逻辑放在 View 层用 `@Query` + 计算属性，而非 ViewModel

搜索使用 `@State searchText` 驱动，对 `allMemos` 做本地过滤。不引入新的 `@Query` 或 ViewModel 方法。

**理由**：当前 `allMemos` 已通过 `@Query` 获取了所有数据。`localizedStandardContains` 提供大小写/变音符号不敏感的搜索，性能对于个人日记数量级（千级别）完全足够。保持架构一致——现有 `sections` 计算属性也是在 View 层做的分组。

**替代方案**：ViewModel 中添加搜索方法 + `ModelContext.fetch` 带 `#Predicate`。缺点：过度设计，增加不必要的状态同步复杂度。

### 3. 搜索结果扁平展示，不按日期分组

搜索时显示扁平的结果列表（每条结果显示时间戳），不做日期 section 分组。

**理由**：搜索场景用户关注的是"找到内容"而非"按日期浏览"。扁平列表更紧凑、扫视效率更高。实现也更简单。

**替代方案**：保持日期分组。缺点：搜索结果可能分散在很多天，大量只有一条结果的 section header 反而降低效率。

### 4. 搜索时隐藏日历和录音按钮

进入搜索模式时隐藏 `CalendarView` 和底部录音按钮，让搜索结果独占视图空间。

**理由**：日历和录音在搜索场景下无用，隐藏它们减少视觉干扰，且避免键盘遮挡问题。

### 5. 搜索匹配使用 `localizedStandardContains`

使用 `String.localizedStandardContains()` 而非简单的 `contains()`。

**理由**：自动处理大小写不敏感、变音符号不敏感（如 é → e），对中英文混合内容友好。这是 Apple 推荐的搜索匹配方式。

## Risks / Trade-offs

**[大数据量性能]** → 个人日记数量级不会很大（年均数百到数千条），内存过滤完全可行。如果未来数据量显著增长，可改用 `#Predicate` fetch 或 FTS。

**[搜索无结果反馈]** → 显示空状态文案 "No results"，帮助用户确认搜索词无误。

**[隐藏 memo 是否参与搜索]** → 隐藏的 memo（`isHidden = true`）不参与搜索结果，与 Timeline 展示逻辑一致。实际上 `allMemos` 已包含它们，需要在过滤时排除。

## Affected Files

| File | Change |
|------|--------|
| `Sources/Modules/Timeline/TimelineView.swift` | 添加 `.searchable()`、搜索状态、搜索结果视图 |
| `Localizable.csv` | 新增搜索相关本地化字符串 |
