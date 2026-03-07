## Why

iPhone 15 Pro 及以上机型配备了 Action Button，用户可以将其映射为 App Shortcut 快速启动语音记录。当前 `StartRecordingIntent` 和 `AppShortcutsProvider` 已存在，但 `phrases` 为空，导致 Action Button 的 "Shortcut" 选项中无法自然发现和展示该功能。需要补全 Siri phrases、优化 Intent 元数据，使 Action Button → 开始录音 的体验完整流畅。

## What Changes

- 为 `StartRecordingIntent` 添加 `description` 属性，提供清晰的 Intent 描述
- 为 `AppShortcut` 添加 Siri phrases（中英文），使 Action Button Shortcut 选项和 Siri 都能识别
- 在 `StartRecordingIntent` 上实现 `parameterSummary`，优化系统 UI 展示
- 在 Settings 中添加 Action Button 设置引导，帮助用户配置

## Non-goals

- 不涉及 Live Activities 或 Dynamic Island 集成
- 不修改录音核心逻辑（AudioRecorder, RecordingView）
- 不引入新的 App Intent 类型（仅完善现有 StartRecordingIntent）
- 不涉及 watchOS Action Button（Ultra 系列）

## Capabilities

### New Capabilities

- `action-button-setup`: Action Button 集成所需的 Intent 元数据完善和用户设置引导

### Modified Capabilities

_(无需修改现有 spec)_

## Impact

- **代码**: `Shared/Intents/StartRecordingIntent.swift`, `Shared/Intents/Shortcuts.swift`, Settings 模块
- **系统集成**: Siri、Shortcuts app、Action Button 配置界面会展示该 Intent
- **依赖**: 无新增依赖，使用 iOS 17 原生 AppIntents 框架
