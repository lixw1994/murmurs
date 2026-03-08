## Why

随着录音条目积累，用户无法快速找到特定内容（"记得日记里有记录过哪天去医院"）。多个 Issue (#48, #51, #13) 提到缺少搜索功能。当前 Timeline 只能按日期顺序浏览，没有任何搜索入口。加上刚完成的标题功能，搜索标题+正文的价值更大。

## What Changes

- Timeline 页面新增搜索栏，支持按关键词搜索 memo 内容
- 搜索范围覆盖 `title`、`content`、`polishedContent` 三个字段
- 搜索结果以列表形式展示，关键词高亮
- 空搜索状态显示搜索提示，无结果时显示空状态
- 搜索使用 SwiftData `#Predicate` 本地全文匹配，无需外部依赖

### Non-goals

- 不做模糊搜索或拼音搜索
- 不做搜索历史记录
- 不做标签系统（独立功能）
- 不修改 Watch 端
- 不做跨设备搜索同步

## Capabilities

### New Capabilities

- `memo-search`: Timeline 中的 memo 全文搜索功能，包括搜索 UI、查询逻辑、结果展示

### Modified Capabilities

(none)

## Impact

- `Sources/Modules/Timeline/TimelineView.swift` — 新增搜索栏 UI 和搜索状态
- `Sources/Modules/Timeline/TimelineEntryView.swift` — 可能需要支持搜索结果中的关键词高亮
- `Localizable.csv` — 新增搜索相关本地化字符串
