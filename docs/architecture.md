# Murmurs 项目架构文档

## 项目概述

Murmurs 是一款 AI 驱动的语音日记应用，支持 iOS 和 watchOS 平台。核心功能是通过录音创建日记条目，使用 AI 进行语音转文字和日记摘要生成。所有数据默认存储在设备本地。

- **Bundle ID**: `com.tangyue.murmurs`
- **最低部署版本**: iOS 17.0 / watchOS 10.0
- **构建工具**: XcodeGen + SPM + Fastlane

## 整体架构

```
┌────────────────────────────────────────────────────────────────┐
│                        iOS App (Sources/)                      │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                   App/ (应用入口层)                       │  │
│  │  App.swift · AppState · Config · MainView · Constants   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                 Modules/ (功能模块层)                     │  │
│  │  Timeline · Recording · Summary · Settings · Premium    │  │
│  │  Export                                                  │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                 Services/ (服务层)                        │  │
│  │  OpenAIClient · Transcription · SpeechRecognizer        │  │
│  │  AudioPlayer · IAPManager · Exporter                    │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                 Persistence/ (数据层)                      │  │
│  │  DataContainer · MemoEntity · SummaryEntity              │  │
│  │  PromptEntity · UsageEntity                              │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              │                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐   │
│  │Components│ │ Styles/  │ │ Helpers/ │ │   Models/     │   │
│  └──────────┘ └──────────┘ └──────────┘ └───────────────┘   │
├────────────────────────────────────────────────────────────────┤
│                    Shared/ (跨平台共享层)                       │
│  AudioRecorder · Connectivity · Color+Theme · Localization    │
│  FileHelper · Intents (Siri Shortcuts)                        │
├────────────────────────────────────────────────────────────────┤
│                    Packages/ (本地 SPM 包)                      │
│  XLog (日志系统) · XLang (多语言管理)                           │
├────────────────────────────────────────────────────────────────┤
│                    Watch/ (watchOS 应用)                        │
│  录音 · 最近记录 · 音频播放 · WatchConnectivity 同步           │
└────────────────────────────────────────────────────────────────┘
```

## 目录结构

```
Murmurs/
├── Sources/                 # iOS 主应用源码
│   ├── App/                 # 应用入口、全局状态、配置
│   ├── Models/              # 枚举模型（DarkMode, ServerType 等）
│   ├── Modules/             # 功能模块（MVVM）
│   │   ├── Timeline/        # 时间线（备忘录列表）
│   │   ├── Recording/       # 录音界面
│   │   ├── Summary/         # AI 摘要
│   │   ├── Settings/        # 设置
│   │   ├── Premium/         # 付费升级
│   │   └── Export/          # 数据导出
│   ├── Services/            # 业务服务
│   │   ├── OpenAI/          # OpenAI API 客户端
│   │   ├── Transcription/   # 转写服务
│   │   ├── AudioPlayer/     # 音频播放
│   │   ├── IAP/             # 内购管理
│   │   └── Export/          # 导出器
│   ├── Persistence/         # Core Data 模型与操作
│   ├── Components/          # 可复用 UI 组件
│   ├── Styles/              # 按钮样式
│   ├── Helpers/             # 工具函数
│   └── Extensions/          # Swift 扩展
├── Shared/                  # iOS + watchOS 共享代码
│   ├── Recorder/            # 录音引擎
│   ├── Localization/        # 多语言资源
│   ├── Intents/             # Siri Shortcuts
│   └── Helpers/             # 文件工具
├── Watch/                   # watchOS 应用
│   ├── App/                 # Watch 应用入口与视图
│   ├── Persistence/         # Watch Core Data
│   ├── Services/            # Watch 音频播放
│   └── Views/               # Watch 自定义视图
├── WatchWidget/             # watchOS + iOS Widget
├── Resources/               # 资产目录、启动屏、Info.plist
├── Packages/                # 本地 SPM 包
│   ├── XLog/                # 日志库
│   └── XLang/               # 多语言库
├── Tests/                   # 单元测试
├── SnapshotTests/           # UI 快照测试
├── fastlane/                # CI/CD 配置
├── scripts/                 # 本地化脚本
├── html/                    # 隐私政策、条款、支持页面
└── project.yml              # XcodeGen 项目定义
```

## 核心数据流

### 1. 录音 → 转写

```
用户点击录音按钮
    │
    ▼
AppState.startRecording()
    │ (检查权限、停止播放器)
    ▼
RecordingView (全屏)
    │ (AudioRecorder 录制 M4A: AAC, 24kHz, 单声道)
    ▼
用户停止录音
    │
    ▼
RecordingCompletedView
    │ (显示转写结果、可编辑)
    ▼
保存: MemoEntity + 音频文件 → Documents/audio/
    │
    ▼ (Core Data NSManagedObjectContextDidSave 通知)
    │
TimelineViewModel.contextDidSave()
    │ (检测新增 MemoEntity 是否需要转写)
    ▼
Transcription.shared.transcribe(memo)
    │ (队列管理、并发控制)
    ├── Apple Speech: SpeechRecognizer → SFSpeechRecognizer
    └── OpenAI Whisper: OpenAIClient.transcribe() → API
            │
            ▼
        更新 MemoEntity.content + MemoEntity.transcribed = true
```

### 2. AI 摘要生成

```
用户选择"摘要"功能
    │
    ▼
AddSummaryPromptView (选择提示词模板)
    │
    ▼
AddSummaryMemoSelectionView (选择/排除备忘录)
    │
    ▼
AddSummaryPreviewView (预览完整消息)
    │ (提示词模板 + 日期备忘录内容，支持 {{date}} 占位符)
    ▼
AddSummarySummarizeView
    │
    ▼
OpenAIClient.summarize() ──→ 流式 SSE 响应
    │ (记录 charsSent 使用量)
    ▼
保存: SummaryEntity (标题 + 内容)
```

### 3. Watch → iPhone 同步

```
Watch 录音完成
    │
    ▼
WatchViewModel.syncToIphone()
    │
    ▼
Connectivity.sendFile(url, metadata)
    │ (WCSession.transferFile, 元数据: timezone/createdAt/duration)
    ▼
iPhone: Connectivity (WCSessionDelegate)
    │ (发送 .receivedFileFromWatch 通知)
    ▼
DataContainer.didReceiveFileFromWatch()
    │ (移动音频文件 + 创建 MemoEntity)
    ▼
自动触发转写流程 (同上)
```

## 全局状态管理

### AppState (Sources/App/AppState.swift)

应用级全局状态，通过 `@EnvironmentObject` 注入。

| 属性 | 类型 | 用途 |
|------|------|------|
| `language` | `Language` | 当前应用语言 |
| `micPermission` | `AVAudioSession.RecordPermission` | 麦克风权限状态 |
| `activeSheet` | `ActiveSheet?` | 当前活动的 Sheet |
| `activeTab` | `Int` | 当前 Tab (0=Timeline, 1=Summary) |
| `showRecording` | `Bool` | 是否显示录音全屏 |
| `isPremium` | `Bool` | Premium 订阅状态（Keychain 持久化） |

关键方法:
- `startRecording()`: 检查权限 → 停止播放器 → 显示录音界面
- `startCreatingNote()`: 打开快速笔记 Sheet
- `openURL()`: 处理 URL Scheme (`murmurs://record`, `murmurs://note`, `murmurs://summarize`)

### Config (Sources/App/Config.swift)

用户配置，所有属性通过 `@AppStorage` 持久化到 UserDefaults。

| 属性 | 默认值 | 用途 |
|------|--------|------|
| `dayStartTime` | 2 | 一天的起始时间（小时） |
| `darkMode` | `.dark` | 深色模式 |
| `transEnabled` | false | 是否启用转写 |
| `transProvider` | `.apple` | 转写提供商 |
| `transLang` | `.auto` | 转写语言 |
| `transModel` | `.whisper_1` | Whisper 模型 |
| `sumEnabled` | false | 是否启用摘要 |
| `aiModel` | `.gpt_3_5` | OpenAI Chat 模型 |
| `autoSave` | true | 自动保存 |
| `serverHost` | "" | 自定义服务器地址 |
| `serverAPIKey` | "" | 自定义服务器 API Key（Keychain） |

实验功能:
- `customWhisperPromptEnabled` / `customWhisperPrompt`: 自定义 Whisper 提示词
- `holdToRecordEnabled`: 长按录音
- `autoStartOnStartup`: 启动时自动录音/创建笔记

## Core Data 模型

### 实体关系

```
MemoEntity (备忘录)
├── content: String        # 文本内容
├── file: String?          # 音频文件名
├── day: Int32             # 日期标识 (YYYYMMDD)
├── createdAt: Date        # 创建时间
├── timezone: String       # 时区
├── duration: Double       # 音频时长
├── transcribed: Bool      # 是否已转写
├── isHidden: Bool         # 是否在摘要中隐藏
└── isFromWatch: Bool      # 是否来自 Watch

SummaryEntity (摘要)
├── title: String          # 标题
├── content: String        # 摘要内容
└── createdAt: Date        # 创建时间

PromptEntity (提示词模板)
├── title: String          # 标题
├── desc: String           # 描述
├── content: String        # 模板内容 (支持 {{date}} 占位符)
├── temperature: Double    # AI 温度参数
└── createdAt: Date        # 创建时间

UsageEntity (使用量)
├── day: Int32             # 日期标识
├── charsSent: Int32       # 发送字符数
├── charsReceived: Int32   # 接收字符数
└── whisperDuration: Int32 # Whisper 使用时长
```

Watch 端独立的 Core Data:
```
RecordingEntity (Watch 录音)
├── createdAt: Date
├── file: String
├── duration: Double
└── isSent: Bool           # 是否已同步到 iPhone
```

## 本地化系统

```
Localizable.csv (源文件)
    │
    ▼ scripts/l10n (Ruby 脚本)
    │
    ├── Shared/Localization/LocalizedKeys.swift  (MyLocalizedKey 枚举, 288 个键)
    ├── Shared/Localization/en.lproj/Localizable.strings
    └── Shared/Localization/zh-Hans.lproj/Localizable.strings
```

使用方式:
```swift
// 简单翻译
L(.app_name)  // → "Murmurs"

// 带参数
L(.sum_title_default, dateString)  // → "Summary for 2024-01-01"
```

语言切换通过 `XLang.shared.setLang()` 实现，支持运行时动态切换。

## Premium 与限制系统

### 购买流程
- 使用 StoreKit 1 (`SKPaymentQueue`)
- 产品 ID: `com.tangyue.murmurs.premium`
- 一次性购买（非订阅）
- Premium 状态存储在 Keychain

### 功能限制

| 功能 | 免费 | Premium |
|------|------|---------|
| 每日字符限额 | 20,000 | 100,000 |
| 自定义提示词数 | 3 | 无限 |
| 基本功能 | ✓ | ✓ |

## 构建与 CI/CD

### 构建流程

```
1. bundle install           # 安装 Ruby 依赖 (Fastlane)
2. xcodegen                 # 从 project.yml 生成 Xcode 项目
3. Xcode Build              # 构建应用
```

### CI (GitHub Actions)
- 触发条件: push 到 `release/*` 分支
- 环境: macOS latest
- 步骤: checkout → bundle install → xcodegen → fastlane tests

### Fastlane Lanes
- `beta`: match 签名 → 递增 build number → gym 构建 → 上传 TestFlight
- `tests`: 在 iPhone 15 Pro 模拟器上运行单元测试

### 构建配置
| 配置 | 类型 | 说明 |
|------|------|------|
| Debug | debug | 开发调试 |
| Snapshot | debug | UI 快照测试（额外编译条件 `SNAPSHOT`） |
| AppStore | release | App Store 发布 |

## 第三方依赖

### 本地包
| 包名 | 用途 |
|------|------|
| XLog | swift-log 封装，提供 debug/info/error 三级日志 |
| XLang | 多语言管理，支持动态语言切换 |

### 远程包
| 包名 | 用途 |
|------|------|
| KeychainAccess | Keychain 访问封装 |
| ConfettiSwiftUI | 庆祝动画效果 |
| DSWaveformImage | 音频波形图 |
| CSV | CSV 文件读写 |
| TPPDF | PDF 文档生成 |

## URL Scheme

应用注册了 `murmurs://` URL Scheme，支持以下路由:

| URL | 功能 |
|-----|------|
| `murmurs://record` | 启动录音 |
| `murmurs://note` | 打开快速笔记 |
| `murmurs://note?text=内容` | 直接保存快速笔记 |
| `murmurs://summarize` | 启动今日摘要 |

## 注意事项

1. **日期分界线**: 一天的起始时间由 `Config.dayStartTime` 控制（默认凌晨 2 点），不是午夜 0 点。凌晨 2 点前的记录归属前一天。
2. **Core Data 线程**: 所有 Core Data 操作使用主线程 `viewContext`。
3. **转写并发**: Apple Speech 最多 1 并发，OpenAI Whisper 最多 4 并发。
4. **Whisper 幻觉过滤**: 转写结果会与硬编码的常见幻觉文本比对，命中则返回空字符串。
5. **敏感信息**: API Key 和 Premium 状态存储在 Keychain。
