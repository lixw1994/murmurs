## 1. Intent 元数据完善

- [x] 1.1 为 `StartRecordingIntent` 添加 `static var description: IntentDescription` 属性 (`Shared/Intents/StartRecordingIntent.swift`)
- [x] 1.2 为 `AppShortcut` 添加 Siri phrases（英文和中文）和 `shortTitle` (`Shared/Intents/Shortcuts.swift`)
- [x] 1.3 构建验证：`xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 2. Settings 快捷操作引导

- [x] 2.1 在 Settings 模块中添加快捷操作引导 section，展示 Action Button / Siri 配置步骤
- [x] 2.2 添加引导所需的本地化字符串到 `Localizable.csv`，运行 `rake l10n` 生成
- [x] 2.3 构建验证：`xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
