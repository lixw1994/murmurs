## Why

随着录音条目增多，Timeline 首页变成一堆等长的文字墙，用户难以快速区分每条 memo 的内容。需要两个互补的功能：AI 自动生成短标题让每条 memo 一目了然，以及长文本折叠让首页更紧凑可扫视——类似邮件 App 的"标题 + 预览"模式。（GitHub Issue #51 建议 2+3）

## What Changes

- MemoEntity 新增 `title: String?` 持久化字段，存储 AI 生成的短标题
- AIClientProtocol 新增 `generateTitle()` 方法，用专门的 system prompt 从 memo 内容生成 ≤15 字的标题
- 转写完成后自动触发标题生成（需要 AI 服务器已配置）
- 用户可手动触发/重新生成/删除标题
- TimelineEntryView 改为"标题 + 折叠预览"布局：有标题时显示标题为主文本、正文折叠为 2 行预览；无标题时对超长内容也默认折叠为 3 行，点击展开/收起

### Non-goals

- 不支持用户手动编辑标题（MVP 只做 AI 生成）
- 不修改 Summary 或 Export 模块
- 不修改 Watch 端
- 不做标签/分类系统
- 不做搜索功能

## Capabilities

### New Capabilities

- `memo-title-generation`: AI 自动生成 memo 短标题的完整流程（数据模型、API 调用、自动/手动触发、UI 显示）
- `memo-text-collapse`: Timeline 条目的文本折叠/展开交互

### Modified Capabilities

- `ai-text-polish`: polish 完成后，如果 memo 无标题且服务器已配置，应自动触发标题生成

## Impact

- `Sources/Persistence/MemoEntity.swift` — 新增 `title` 字段
- `Sources/Services/Protocols/AIClientProtocol.swift` — 新增 `generateTitle` 方法
- `Sources/Services/OpenAI/OpenAIClient.swift` — 实现 `generateTitle`
- `Sources/Modules/Timeline/TimelineViewModel.swift` — 标题生成逻辑、自动触发
- `Sources/Modules/Timeline/TimelineEntryView.swift` — 标题显示 + 折叠/展开布局
- `Tests/Mocks/` — Mock 更新
- `Localizable.csv` — 新增本地化字符串
