# Murmurs 架构

本文档说明 Murmurs **当前代码**的结构和运行方式，供开发者和 agent 修改代码前阅读。每当结构性改动落地，都要同步更新本文档。

- **目标架构**（多端、Cloudflare 后端、同步）的决策记录在 [`adr/`](../adr/)（ADR-0001 至 ADR-0013）。
- **实施顺序**见 [roadmap.md](./roadmap.md)。
- **功能规格**见 [`openspec/specs/`](../openspec/specs/)。

## 系统概览

Murmurs 目前是一个**单机版** iOS 和 watchOS 语音日记应用。所有数据都存在设备本地；转写、润色、标题和总结由客户端直接调用 Apple Speech 或兼容 OpenAI 的 API 完成。

| 项目 | 值 |
|---|---|
| Bundle ID | `com.tangyue.murmurs` |
| 最低版本 | iOS 18.0 / watchOS 11.0（[ADR-0008](../adr/0008-minimum-ios-18-watchos-11.md)） |
| UI | SwiftUI；文本编辑和分享面板桥接 UIKit（[ADR-0007](../adr/0007-swiftui-first-with-uikit-bridging.md)） |
| 状态管理 | MVVM，ViewModel 是 `@Observable` 类 |
| 本地存储 | SwiftData |
| 构建 | XcodeGen（`project.yml`）、SPM、Fastlane |

```mermaid
flowchart TB
  subgraph iOS["iOS App（Sources/）"]
    App["App/<br/>入口 · AppState · Config · MainView"]
    Modules["Modules/<br/>Timeline · Recording · Summary · Settings · Export · Premium"]
    Services["Services/<br/>OpenAIClient · Transcription · AudioPlayer · IAPManager · Exporter · Readwise"]
    Persistence["Persistence/<br/>SwiftData：Memo · Summary · Prompt · Usage"]
    App --> Modules --> Services --> Persistence
  end
  subgraph Shared["Shared/（iOS 与 watchOS 共用）"]
    Recorder["Recorder/ AudioRecorder"]
    Conn["Connectivity（WatchConnectivity）"]
    Intents["Intents/ · LiveActivity/"]
    L10n["Localization/"]
  end
  Watch["Watch/<br/>录音 · 最近记录 · 播放"]
  Widget["WatchWidget/<br/>表盘复杂功能 · Live Activity"]
  Ext["Apple Speech<br/>兼容 OpenAI 的 API<br/>Readwise API"]

  Modules --> Recorder
  Watch --> Recorder
  Watch -- transferFile --> Conn --> Persistence
  Services --> Ext
  Widget --> Intents
```

## Targets

| Target | 类型 | 平台 | 源码 |
|---|---|---|---|
| `Murmurs` | 应用 | iOS | `Sources/`、`Shared/`、`Resources/` |
| `MurmursWidget` | 扩展 | iOS | `WatchWidget/`、`Shared/LiveActivity/`（Live Activity 和灵动岛） |
| `MurmursWatch` | 应用 | watchOS | `Watch/`、`Shared/` |
| `MurmursWatchWidget` | 扩展 | watchOS | `WatchWidget/`（表盘复杂功能：`accessoryCircular`、`accessoryCorner`） |
| `MurmursTests` | 单元测试 | iOS | `Tests/`（mock 放在 `Tests/Mocks/`） |
| `SnapshotTests` | UI 测试 | iOS | `SnapshotTests/`，使用 `Snapshot` 构建配置 |

## 目录结构

```text
Sources/                 iOS 主应用
├── App/                 入口、AppState、Config、Constants、MainView（Timeline 和 Summary 两个标签页）
├── Modules/             功能模块（MVVM）
│   ├── Timeline/        memo 列表、日历、搜索、快速笔记、编辑
│   ├── Recording/       录音、暂停/继续、续录、录音完成页
│   ├── Summary/         多步骤生成总结、详情、编辑
│   ├── Settings/        服务器、prompt、Readwise、实验功能、关于
│   ├── Export/          CSV / Markdown 导出
│   └── Premium/         付费墙
├── Services/            OpenAI、Transcription、AudioPlayer、IAP、Export、Readwise、Protocols
├── Persistence/         DataContainer 与 SwiftData 实体
├── Models/              配置用的枚举（ChatModel、TranscriptionProvider 等）
└── Components/ Styles/ Helpers/ Extensions/
Shared/                  iOS 与 watchOS 共用：Recorder、Localization、Intents、LiveActivity、Connectivity
Watch/                   watchOS 应用（独立的 SwiftData 存储）
WatchWidget/             表盘复杂功能和 Live Activity 的 UI
Packages/                本地 SPM 包：XLog（日志）、XLang（运行时切换语言）
Tests/  SnapshotTests/   测试
openspec/  adr/  docs/   规格、架构决策、文档
```

## 核心流程

### 录音与转写

```mermaid
sequenceDiagram
  participant U as 用户
  participant R as RecordingView / ViewModel
  participant AR as AudioRecorder
  participant LT as LiveTranscriber
  participant DB as SwiftData
  participant T as Transcription

  U->>R: 开始录音（按钮、长按、Siri、Action Button、URL Scheme）
  R->>AR: 录制 M4A（AAC，24 kHz，单声道）
  R->>LT: 设备上实时转写（iOS 26 用 SpeechAnalyzer，更早版本用 SFSpeechRecognizer）
  U->>R: 暂停 / 继续 / 停止
  R->>DB: 保存 MemoEntity，音频文件存到 Documents/audio/
  alt 已开启转写（trans_enabled）且 memo.needsTranscription
    DB->>T: TimelineViewModel 把 memo 加入转写队列
    T->>T: Apple Speech（并发 1）或 OpenAI（并发 4）
    T->>DB: 写入 content，transcribed = true
    opt 已配置服务器且 memo 还没有标题
      T->>DB: 自动生成标题（OpenAIClient.generateTitle）
    end
  end
```

- **续录**：可以给已有的 memo 追加一段录音；追加后会清空由原内容生成的派生字段（润色、标题），然后重新处理。
- **幻觉过滤**：OpenAI 转写的结果如果和 `Transcription.hallucinationList` 里的某一项完全相同，就当作空结果丢弃。
- **Live Activity**：录音期间通过 `LiveActivityManager` 在灵动岛显示状态；`TogglePauseRecordingIntent` 和 `StopRecordingIntent` 提供暂停和停止按钮。

### AI 润色、标题与总结

所有 AI 调用都经过 `OpenAIClient`（`Sources/Services/OpenAI/`），直接请求用户配置的兼容 OpenAI 的服务（`Config.serverHost`，API Key 存在 Keychain）。

| 功能 | 方法 | 流式返回 | 结果写入 |
|---|---|---|---|
| 润色 | `polish(_:model:)` | 是 | `MemoEntity.polishedContent` |
| 标题 | `generateTitle(_:model:)` | 否 | `MemoEntity.title` |
| 总结 | `summarize(_:model:temperature:)` | 是 | `SummaryEntity` |
| 转写 | `transcribe(_:lang:model:)` | 否 | `MemoEntity.content` |

生成总结分几步：**选择 prompt → 选择或排除 memo → 预览完整消息（支持 `{{date}}` 占位符）→ 流式生成 → 保存**。总结用 MarkdownUI 渲染，也可以导出为 PDF（TPPDF）。

### Watch 同步到 iPhone

```mermaid
sequenceDiagram
  participant W as Watch App
  participant WDB as Watch SwiftData（RecordingEntity）
  participant C as Connectivity（WCSession）
  participant P as iPhone DataContainer

  W->>WDB: 保存录音，isSent = false
  W->>C: transferFile（附带 timezone、createdAt、duration）
  C->>P: 发出 .receivedFileFromWatch 通知
  P->>P: 移动音频文件，创建 MemoEntity（isFromWatch = true）
  P->>P: 进入上面的转写流程
```

### Readwise

`TimelineViewModel` 和 `SummaryView` 调用 `Readwise` 服务（Readwise Reader API v3）保存 memo 和总结，并把返回的文档 ID 写回 `readwiseId`。开启 `readwise_auto_sync` 后，新 memo 在插入时、或转写完成后自动同步。token 存在 Keychain。

## 状态与配置

**`AppState`**（`@Observable`）：保存当前语言、麦克风权限、当前弹出的 sheet、当前标签页、`isPremium`，并处理 URL Scheme。

**`Config`**（`@AppStorage`，敏感值存在 Keychain）：

| 分组 | 键 |
|---|---|
| 通用 | `day_start_time`（默认 2 点）、`dark_mode`、`auto_save`、`hold_to_record_enabled` |
| 转写 | `trans_enabled`、`trans_provider`（`apple` / `openai`）、`trans_lang`、`trans_model` |
| AI | `sum_enabled`、`chat_model`（预设模型或自定义模型 ID）、`server_host`，以及 Keychain 里的 API Key |
| 实验功能 | `custom_whisper_prompt_enabled`、`custom_whisper_prompt`、`auto_start_on_startup` |
| Readwise | `readwise_sync_enabled`、`readwise_auto_sync`，以及 Keychain 里的 token |

**日期分界**：memo 的 `day` 按 `dayStartTime` 计算，默认凌晨 2 点前的录音归到前一天。

## 数据模型（SwiftData）

`DataContainer.shared` 在 `Application Support/DataModel.sqlite` 创建 `ModelContainer`；测试和预览时使用内存存储。

```mermaid
erDiagram
  MemoEntity {
    String content
    String polishedContent
    String title
    Date createdAt
    String timezone
    Int32 day
    String file
    Double duration
    Bool transcribed
    Bool isFromWatch
    Bool isHidden
    String readwiseId
    Date syncedAt
    Date updatedAt
  }
  SummaryEntity {
    String title
    String content
    Date createdAt
    String timezone
    String prompt
    Double temperature
    String model
    String readwiseId
    Date syncedAt
  }
  PromptEntity {
    String title
    String content
    String desc
    Double temperature
    Date createdAt
  }
  UsageEntity {
    Int32 day
    Int32 charsSent
    Int32 charsReceived
    Int32 whisperDuration
    Int32 whisperCount
  }
```

实体之间没有关系字段。Watch 端有自己的 SwiftData 存储，只有一个 `RecordingEntity`（`createdAt`、`file`、`duration`、`isSent`）。

## 付费与限额

- 通过 StoreKit 1（`SKPaymentQueue`）购买一次性商品 `com.tangyue.murmurs.premium`，购买状态存在 Keychain。
- 限额定义在 `Constants.Limit` 中：

| 限额 | 免费 | Premium |
|---|---|---|
| 每日 AI 字符数 | 20,000 | 100,000 |
| 自定义 prompt 数 | 3 | 不限 |
| 数据导出 | – | ✓ |

## 系统集成入口

| 入口 | 实现 |
|---|---|
| URL Scheme | `murmurs://record`、`murmurs://note`、`murmurs://note?text=…`、`murmurs://summarize`（`AppState`） |
| Siri、快捷指令、Action Button | `StartRecordingIntent` 加 `Shortcuts`（`Shared/Intents/`） |
| Live Activity、灵动岛 | `MurmursWidget` 扩展里的 `RecordingLiveActivity` |
| 表盘复杂功能 | `MurmursWatchWidget` 扩展里的 `MurmursStaticWidget` |

## 本地化

`Localizable.csv`（列：key、comment、en、zh-Hans）是文案的唯一来源。运行 `rake l10n`（脚本在 `scripts/l10n`）会生成 `Shared/Localization/LocalizedKeys.swift` 和两种语言的 `.strings` 文件。代码里用 `L(.key)` 引用文案；`XLang` 支持在运行时切换语言。

## 构建与 CI

| 配置 | 用途 |
|---|---|
| `Debug` | 开发 |
| `Snapshot` | UI 快照测试（编译条件 `SNAPSHOT`） |
| `AppStore` | 发布 |

- **CI**：`.github/workflows/run-unit-tests.yml`，推送到 `release/*` 分支时触发，运行 Fastlane `tests` lane。
- **Fastlane**：`beta`（match 签名 → gym 构建 → 上传 TestFlight）；`tests`（在 iPhone 15 Pro 模拟器上运行单元测试）。
- **SPM 依赖**：KeychainAccess、ConfettiSwiftUI、DSWaveformImage、CSV.swift、TPPDF、MarkdownUI，以及本地包 XLog、XLang。

构建和验证命令见 [CLAUDE.md](../CLAUDE.md)。

## 演进方向

当前架构会按 [roadmap.md](./roadmap.md) 逐步变为多端系统。下表列出现有模块的去向，以及依据的 ADR：

| 现有模块 | 去向 | 依据 |
|---|---|---|
| `OpenAIClient`（转写、润色、标题、总结） | 由服务端流水线和 API 取代 | [ADR-0002](../adr/0002-thick-server-thin-clients.md)、[ADR-0006](../adr/0006-cloudflare-workflows-for-memo-pipeline.md) |
| 自定义服务器、API Key 设置 | 删除 | [ADR-0002](../adr/0002-thick-server-thin-clients.md) |
| 纯本地的 SwiftData | 保留，增加同步字段，接入 SyncEngine | [ADR-0005](../adr/0005-per-user-durable-object-with-custom-sync.md)、[ADR-0009](../adr/0009-offline-first-native-online-first-web.md) |
| `UsageEntity`、`Constants.Limit` | 改由服务端记录用量、检查配额 | [ADR-0012](../adr/0012-subscriptions-via-revenuecat.md) |
| StoreKit 1 `IAPManager` | 由 RevenueCat 订阅取代 | [ADR-0012](../adr/0012-subscriptions-via-revenuecat.md) |
| 客户端 Readwise | 移到服务端 | [ADR-0002](../adr/0002-thick-server-thin-clients.md) |
| 仓库根目录下的 Swift 工程 | 移到 `apple/` | [ADR-0013](../adr/0013-monorepo-in-existing-repository.md) |
