# Murmurs 架构

本文档说明 Murmurs **当前代码**的结构和运行方式，供开发者和 agent 修改代码前阅读。每当结构性改动落地，都要同步更新本文档。

- **目标架构**（多端、Cloudflare 后端、同步）的决策记录在 [`adr/`](../adr/)（ADR-0001 至 ADR-0015）。
- **实施顺序**见 [roadmap.md](./roadmap.md)。
- **功能规格**见 [`openspec/specs/`](../openspec/specs/)。

## 系统概览

仓库是一个 monorepo（[ADR-0013](../adr/0013-monorepo-in-existing-repository.md)）：

| 目录 | 现状 |
|---|---|
| `apple/` | 已上线的**单机版** iOS 和 watchOS 应用。所有数据都存在设备本地；转写、润色、标题和总结由客户端直接调用 Apple Speech 或兼容 OpenAI 的 API 完成 |
| `web/` | 一个 Cloudflare Worker：占位的 Web 页面，以及 `/api/v1`（health 和匿名账号），见 [Web 与 API](#web-与-apiweb) 和 [账号](#账号) |
| `contract/` | 由 API 代码生成的 OpenAPI 契约及其检查脚本，见 [API 契约](#api-契约contract) |
| `l10n/` | Apple 和 Web 共用的文案源文件与生成器，见 [本地化](#本地化l10n) |

下面几节先说明 Apple 应用（除特别说明外，路径都相对于 `apple/`），再说明 Web、契约和本地化。

**Apple 应用概要：**

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

`apple/` 的内容：

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
├── Services/            OpenAI、Transcription、AudioPlayer、IAP、Export、Readwise、Account、Protocols
├── Persistence/         DataContainer 与 SwiftData 实体
├── Models/              配置用的枚举（ChatModel、TranscriptionProvider 等）
└── Components/ Styles/ Helpers/ Extensions/
Shared/                  iOS 与 watchOS 共用：Recorder、Localization、Intents、LiveActivity、Connectivity
Watch/                   watchOS 应用（独立的 SwiftData 存储）
WatchWidget/             表盘复杂功能和 Live Activity 的 UI
Packages/                本地 SPM 包：XLog（日志）、XLang（运行时切换语言）、MurmursAPI（由契约生成的 API 客户端）
Tests/  SnapshotTests/   测试
fastlane/  Gemfile       发布与测试工具
```

仓库根目录另有 `web/`、`contract/`、`l10n/`、`openspec/`、`adr/`、`docs/`，以及运行 `rake l10n` 的 `Rakefile`。

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

## 账号

账号是匿名的，靠恢复码找回（[ADR-0015](../adr/0015-anonymous-accounts-with-recovery-codes.md)）。首次打开 App 时没有登录页面。

```mermaid
sequenceDiagram
  participant App as iOS AccountService
  participant KC as Keychain
  participant API as /api/v1
  App->>KC: 有 token？
  alt 有 token
    App->>App: state = ready
  else 没有 token，但 iCloud 钥匙串里有恢复码
    App->>API: POST /sessions/recover
    API-->>App: userId、token
  else 什么都没有
    App->>API: POST /accounts
    API-->>App: userId、token、recoveryCode
  end
  App->>KC: token（仅本机）、恢复码（通过 iCloud 同步）
```

**服务端**（`web/src/server/api/routes/accounts.ts`）

| 接口 | 鉴权 | 说明 |
|---|---|---|
| `POST /api/v1/accounts` | 无，按 IP 限流 10 次/分钟 | 201：`userId`、`token`、`recoveryCode` |
| `POST /api/v1/sessions/recover` | 无，按 IP 限流 5 次/分钟 | 用恢复码开一个新会话；码无效返回 401 `invalid_recovery_code` |
| `GET /api/v1/me` | bearer | `userId`、`isAnonymous`、`createdAt`、`recoveryCodeCreatedAt` |
| `POST /api/v1/me/recovery-code` | bearer | 生成新恢复码，旧码立即失效 |
| `DELETE /api/v1/sessions/current` | bearer | 退出当前会话 |
| `DELETE /api/v1/me` | bearer | 删除账号、所有会话和恢复码（App Store 要求） |

- **恢复码**：25 个 Crockford base32 字符（125 位随机性），显示为 5 组。输入时不区分大小写，忽略空格和连字符。D1 的 `recovery_code` 表里只存 SHA-256 哈希。
- **会话**：有效期 365 天，使用时自动延长；客户端用 `Authorization: Bearer <token>` 访问。
- **限流**：用的是 Cloudflare 的限流绑定，在线上只是近似生效（按边缘节点计数，最终一致）。它只用来防滥用；恢复码本身的熵保证了无法被猜中。

**iOS**（`apple/Sources/Services/Account/`）

| 组件 | 职责 |
|---|---|
| `KeychainCredentialStore` | token 和 userId 只存本机（`afterFirstUnlockThisDeviceOnly`）；恢复码可同步到 iCloud 钥匙串，同一 Apple ID 的新设备能自动恢复 |
| `LiveAccountAPI` | 封装 `MurmursAPI` 包里由契约生成的客户端，把各种响应映射成 `AccountAPIError` |
| `AccountService` | 状态：`none`、`working`、`ready`、`needsRestore`。场景变为活跃时调用 `ensureAccount()`（Snapshot 构建和单元测试时跳过）；token 被拒时用恢复码重试一次，失败则进入 `needsRestore`，不会悄悄换成另一个账号 |
| 设置 → 账号 | 显示和复制恢复码、生成新恢复码、用恢复码恢复、删除账号（本机笔记保留） |

API 地址来自 Info.plist 的 `MurmursAPIBaseURL`：Debug 和 Snapshot 构建用 staging，AppStore 构建用 production。命令行构建需要加 `-skipPackagePluginValidation`，因为 `MurmursAPI` 用了 swift-openapi-generator 的构建插件。

## Web 与 API（`web/`）

`web/` 基于 `react-tanstarter` 模板，是**一个** Cloudflare Worker（[ADR-0004](../adr/0004-single-worker-from-react-tanstarter.md)），同时提供 Web 页面和 API：

```mermaid
flowchart LR
  Req["请求"] --> Entry["src/server-entry.ts<br/>注入 env、db、getAuth"]
  Entry --> TSS["TanStack Start"]
  TSS -->|"/"| UI["占位落地页（SSR）"]
  TSS -->|"/api/auth/*"| Auth["Better Auth<br/>自带的登录入口已关闭"]
  TSS -->|"/api/v1/*"| Hono["Hono 应用<br/>src/server/api"]
  Hono --> Health["GET /health"]
  Hono --> Accounts["账号接口<br/>accounts · sessions · me"]
  Accounts --> Auth
  Auth --> D1[("D1")]
```

| 部分 | 说明 |
|---|---|
| API | `src/server/api/app.ts` 用 `@hono/zod-openapi` 构建，挂在 `/api/v1`；`src/routes/api/v1/$.ts` 把所有方法转发给它。API 代码不依赖 TanStack Start，原生客户端只调用 `/api/v1` |
| `GET /api/v1/health` | 返回 `{ status: "ok", version, environment }`，不需要登录 |
| 错误格式 | `{ "error": { "code", "message", "details"? } }`：未知路径 404 `not_found`，请求不符合 schema 时 400 `invalid_request`（`details.issues` 里是 zod 的校验问题），未处理异常 500 `internal_error`，不返回内部信息 |
| 账号 | 匿名账号和恢复码，全部通过 `/api/v1` 提供，见 [账号](#账号)。Better Auth（anonymous、bearer 插件）只作为用户和会话的存储，它自己在 `/api/auth/*` 下的注册和登录入口都通过 `disabledPaths` 关闭了。auth 实例在第一次使用时才创建，`/api/v1/health` 不依赖它的密钥 |
| 数据库 | D1 + Drizzle。schema 在 `src/lib/db/schema/`，迁移文件在 `drizzle/`（0000 创建 Better Auth 的表，0001 给 `user` 加 `is_anonymous` 并创建 `recovery_code`），通过 `wrangler d1 migrations apply` 应用 |
| 环境 | `wrangler.toml` 顶层是本地开发（`ENVIRONMENT=development`）。`[env.staging]` 部署在 https://murmurs-staging.denkit.app（Worker `murmurs-staging`，D1 `murmurs-db-staging`）；`[env.production]` 配置为 https://murmurs.denkit.app，尚未部署。两者都只通过自定义域名访问（关闭了 `workers.dev`），`BETTER_AUTH_URL` 指向各自的域名 |
| 页面与文案 | 只有一个落地页；主题和语言切换沿用模板。文案来自 `l10n/`，语言为 `en` 和 `zh-Hans` |
| 测试 | Vitest 4 + `@cloudflare/vitest-pool-workers`，在 Workers 运行时里测试 `test/api-worker.ts`（只挂载 Hono 应用）、账号接口的全部场景（含限流）、Better Auth 自带入口已关闭、恢复码的生成与规范化、契约覆盖（每个注册的路由都在契约里）和 i18n 插值 |

## API 契约（`contract/`）

`contract/openapi.json`（OpenAPI 3.0.3）由 `pnpm --dir web contract:generate` 从 API 的 zod 路由定义生成，并提交进仓库（[ADR-0010](../adr/0010-openapi-contract-with-generated-clients.md)）。原生端构建时直接读取这个文件，不需要 Node 工具链。

| 脚本 | 作用 |
|---|---|
| `contract/scripts/check-drift.sh` | 重新生成并比较，文件过期时失败，并提示重新生成的命令 |
| `contract/scripts/check-breaking.sh` | 用 oasdiff 对比主分支上的契约，发现破坏性变更时失败（[ADR-0014](../adr/0014-api-v1-compatibility-policy.md)）；本机没有 oasdiff 时改用 Docker 镜像 |
| `contract/scripts/check-generators.sh` | 用 `swift-openapi-generator` 构建 `apple/Packages/MurmursAPI`（也就是 App 实际使用的包）和 Kotlin `openapi-generator`（Docker）实际生成一次代码 |

错误码 `code` 在契约里是字符串而不是枚举，这样以后新增错误码时，生成的客户端不会因为遇到未知值而解码失败。

## 本地化（`l10n/`）

`l10n/Localizable.csv`（列：key、comment、platforms、en、zh-Hans）是 Apple 和 Web 文案的唯一来源。`platforms` 取 `apple`、`web` 或 `apple web`，Web 独有的 key 放在 `web.` 命名空间下。在仓库根目录运行 `rake l10n`（生成器是 `l10n/generate`，测试是 `l10n/test_generate.rb`）会生成：

- `apple/Shared/Localization/LocalizedKeys.swift` 和两种语言的 `.strings`：Swift 里用 `L(.key)` 引用，`XLang` 支持运行时切换语言
- `web/src/i18n/locales/en.json` 和 `zh-Hans.json`：按 `.` 嵌套；`%@`、`%d` 转成 i18next 的 `%{0}`、`%{1}`，所以 prompt 模板里的字面量 `{{date}}` 不会被当成插值

分节注释行（如 `# Plist #`）不生成 key；缺翻译时生成器会报出来，并回退到英文。

## 构建与 CI

| 配置 | 用途 |
|---|---|
| `Debug` | 开发 |
| `Snapshot` | UI 快照测试（编译条件 `SNAPSHOT`） |
| `AppStore` | 发布 |

- **CI**：每个区域一个 workflow，在 PR 和推送到 `master` 时按改动路径触发：
  - `apple.yml`：macOS 上在 `apple/` 里运行 xcodegen 和 Fastlane `tests`；推送到 `release/*` 时也会运行
  - `web.yml`：pnpm check、test、build，外加契约的漂移检查和破坏性变更检查
  - `contract.yml`：Swift 生成器检查（macOS）和 Kotlin 生成器检查（Ubuntu + Docker）
  - `l10n.yml`：生成器测试，以及确认生成的文件是最新的
- **Fastlane**（`apple/fastlane`）：`beta`（match 签名 → gym 构建 → 上传 TestFlight）；`tests`（在 iPhone 17 Pro 模拟器上运行单元测试）。
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
| 只有匿名账号 | 以后增加社交登录，并把匿名账号绑定到真实身份 | [ADR-0015](../adr/0015-anonymous-accounts-with-recovery-codes.md) |
