## Context

Murmurs 已有 `StartRecordingIntent`（AppIntent）和 `Shortcuts`（AppShortcutsProvider），但 phrases 为空，Intent 缺少 description。iPhone 15 Pro+ 的 Action Button 可通过 "Shortcut" 选项调用 App Shortcut，但当前元数据不完整影响发现性和体验。

现有文件：
- `Shared/Intents/StartRecordingIntent.swift` — AppIntent 实现
- `Shared/Intents/Shortcuts.swift` — AppShortcutsProvider
- `Sources/App/AppState.swift` — `startRecording()` 入口
- `Sources/Modules/Settings/` — 设置界面

## Goals / Non-Goals

**Goals:**
- Action Button → Shortcut → 开始录音，一键即达
- 补全 Intent 元数据（description, phrases），使系统 UI 展示自然
- 在设置中提供 Action Button 配置引导

**Non-Goals:**
- 不修改 AudioRecorder 或 RecordingView
- 不添加新的 Intent 类型
- 不支持 watchOS Ultra Action Button

## Decisions

### 1. 完善 StartRecordingIntent 元数据

**选择**: 在现有 `StartRecordingIntent` 上添加 `description` 静态属性。

```swift
static var description: IntentDescription = "Start a voice memo recording"
```

**理由**: AppIntents 框架通过 `description` 属性在 Shortcuts app 和 Action Button 配置界面展示 Intent 说明。

### 2. 添加 Siri Phrases

**选择**: 在 `AppShortcut` 的 `phrases` 中添加中英文短语。

```swift
AppShortcut(
    intent: StartRecordingIntent(),
    phrases: [
        "Record with \(.applicationName)",
        "Start recording in \(.applicationName)",
        "\(.applicationName)开始录音",
    ],
    shortTitle: "Start Recording",
    systemImageName: "mic.circle.fill"
)
```

**理由**: phrases 让 Siri 和 Spotlight 能发现该功能；`shortTitle` 用于 Action Button 配置界面的紧凑展示。

### 3. Settings 中添加设置引导

**选择**: 在 Settings 页面添加一个 section，展示 Action Button 配置步骤的静态引导文字，使用 `Link` 打开系统 Action Button 设置（如果可用）。

**替代方案**: 使用 TipKit 弹出提示 → 过于侵入，用户可能错过或觉得烦。

**理由**: 静态引导简单可靠，不需要管理 Tip 的显示状态。仅在 iPhone 15 Pro+ 设备上显示该 section。

### 4. 设备检测策略

**选择**: 通过检查 Action Button 是否可用来决定是否显示引导（iOS 17.0+ 可用 `UIDevice` 检测或简单的设备型号判断）。

实际上 Apple 没有提供直接的 API 来检测 Action Button 是否存在。最简单的方式是：所有 iOS 17+ 设备都显示 Shortcuts 引导（因为即使没有 Action Button，Siri 和 Shortcuts 仍然有用），标题改为更通用的"快捷操作设置"。

**理由**: 避免硬编码设备型号列表，向所有用户展示有用的 Shortcuts 集成信息。

## Risks / Trade-offs

- **[Risk] phrases 本地化** → 使用硬编码的 `LocalizedStringResource`，Xcode 会自动提取到 Localizable 目录。但当前项目使用 `Localizable.csv` + `rake l10n` 管道。需确认 AppShortcut phrases 是否需要走同一管道。实际上 AppIntents 框架的 phrases 使用 String Catalogs 或硬编码 `LocalizedStringResource`，与项目的 csv 管道独立，无冲突。
- **[Risk] iOS 版本兼容** → `shortTitle` 需要 iOS 17.0+，项目最低部署目标正好是 iOS 17.0，无风险。
