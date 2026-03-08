## Why

用户录完一段语音后，经常需要补充更多内容——想起遗漏的事情、收到新信息、或者录音中途被打断。当前 Murmurs 每次录音都会创建一条新 memo，无法在已有 memo 上追加录音。编辑功能也仅限于文字修改，不支持追加新的语音片段。此外录音过程中没有暂停按钮，用户思考时只能停止重录。

这三个能力（暂停录音、追加录音、编辑文本）是语音日记的核心编辑体验，多个用户 Issue 反复提及。

## What Changes

- **录音暂停/继续**：在录音 UI 中增加暂停按钮，允许用户暂停后继续录音，最终生成一段完整音频
- **Memo 追加录音**：在已有 memo 的操作菜单中增加"继续录音"入口，新录音片段追加到 memo，音频文件合并，转写文本拼接
- **Memo 文本编辑增强**：已有 MemoEditView 支持编辑 content，需确保追加录音后的编辑体验一致，编辑后清除旧的 polishedContent 和 title 以保持一致性

**Non-goals:**
- 不做音频裁剪/剪辑功能
- 不做多段音频分别管理（合并为单一文件）
- 不做 Watch 端的追加录音
- 不做录音中途的实时转写重置

## Capabilities

### New Capabilities
- `recording-pause-resume`: 录音过程中的暂停和继续功能
- `memo-append-recording`: 在已有 memo 上追加新的录音片段，包括音频合并和内容拼接

### Modified Capabilities
- `ai-text-polish`: 追加录音或编辑文本后，旧的 polishedContent 需要被清除（内容已变更，旧润色不再适用）

## Impact

| Area | Impact |
|------|--------|
| `Shared/Recorder/AudioRecorder.swift` | 增加 pause/resume 支持 |
| `Sources/Modules/Recording/RecordingView.swift` | 暂停按钮 UI |
| `Sources/Modules/Recording/RecordingViewModel.swift` | 暂停状态管理 |
| `Sources/Modules/Timeline/TimelineEntryView.swift` | 追加录音菜单入口 |
| `Sources/Modules/Timeline/TimelineViewModel.swift` | 追加录音逻辑（音频合并、内容拼接） |
| `Sources/Persistence/MemoEntity.swift` | 可能需要更新 duration 计算 |
| `Shared/Helpers/FileHelper.swift` | 音频文件合并工具方法 |
| `Localizable.csv` | 新增本地化字符串 |
