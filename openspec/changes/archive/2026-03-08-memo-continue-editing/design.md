## Context

当前 `AudioRecorder` 只支持 start → stop → done 的线性流程，没有暂停能力。`AVAudioRecorder` 原生支持 `pause()`/`record()` 恢复，但 `AVAudioEngine` 模式（用于实时转写）不支持原生暂停。

Memo 创建后，用户可以通过 `MemoEditView` 编辑文字内容和创建时间，但无法追加新的录音。每次录音都创建新 memo。

音频文件以单一 `.m4a` 存储在 `Documents/audio/`，MemoEntity 只保存文件名。

## Goals / Non-Goals

**Goals:**
- 录音过程中支持暂停/继续
- 已有 memo 支持追加新录音（音频合并、转写拼接）
- 追加录音或编辑文本后自动清除旧的 polishedContent 和 title

**Non-Goals:**
- 不做音频裁剪/剪辑
- 不做多段音频分别存储（最终合并为单一文件）
- 不做 AVAudioEngine 模式的暂停（实时转写场景）
- 不做 Watch 端追加录音

## Decisions

### 1. 暂停录音仅支持 AVAudioRecorder 模式

`AVAudioRecorder` 原生支持 `pause()` + `record()` 恢复。`AVAudioEngine` 模式（用于 Apple Speech 实时转写）不支持原生暂停——engine 的 tap 无法暂停后恢复到同一文件。

**方案**：在 `AudioRecorder` 中添加 `pauseRecording()` / `resumeRecording()` 方法，仅在非 engine 模式下生效。Engine 模式下隐藏暂停按钮。

**理由**：AVAudioRecorder 暂停是零成本的原生 API。强行在 engine 模式实现暂停需要复杂的文件拼接逻辑，收益不大——实时转写场景下用户通常不会暂停。

**替代方案**：两种模式都支持暂停，engine 模式通过停止 tap + 重新创建文件 + 后续合并实现。缺点：复杂度高，实时转写暂停后恢复的边界情况多。

### 2. 追加录音通过 AVFoundation 音频合并实现

追加录音后，使用 `AVMutableComposition` 将原有音频和新录音合并为单一 `.m4a` 文件，替换原文件。

**方案**：在 `FileHelper` 中新增 `mergeAudioFiles(original:append:) -> URL` 方法。使用 `AVMutableComposition` 创建合并 track，通过 `AVAssetExportSession` 导出为 AAC `.m4a`。合并完成后删除临时文件，更新 `MemoEntity.duration`。

**理由**：`AVMutableComposition` 是 Apple 推荐的音频合并方式，支持不同采样率的音频混合。合并后保持单一文件架构，不需要改变 `MemoEntity` 的数据模型。

**替代方案**：存储多个音频文件（如 `file` 改为 JSON 数组）。缺点：需要大幅修改数据模型、播放器、导出逻辑，影响面过大。

### 3. 追加录音入口放在 TimelineEntryView 的上下文菜单

在 memo 的 context menu 中添加"继续录音"选项，点击后打开 `RecordingView`，录音完成后将新音频合并到原 memo。

**方案**：通过 `appState.activeSheet = .appendRecording(memo)` 打开录音页面。录音完成后，`TimelineViewModel` 负责合并音频、拼接文本、更新 memo。

**理由**：复用现有 `RecordingView` UI，减少重复代码。使用 sheet 模式保持与现有录音流程一致的交互体验。

**替代方案**：在 `MemoEditView` 中内嵌录音功能。缺点：`MemoEditView` 是轻量编辑页面，嵌入完整录音 UI 会使其过于复杂。

### 4. 追加录音后清除 polishedContent 和 title

追加录音后内容发生实质变化，旧的 AI 润色和标题不再适用。

**方案**：在合并完成后，设置 `memo.polishedContent = nil`、`memo.title = nil`。随后通过 `.memoInserted` 通知触发重新转写（如果启用了自动转写），转写完成后自动重新生成标题。

**理由**：保持数据一致性。用户可以手动重新触发润色和标题生成。自动清除比保留过时内容更安全。

### 5. 转写文本采用追加拼接而非完整重新转写

追加录音后，将新录音片段单独转写，结果拼接到原有 `content` 末尾（用换行分隔），而非对合并后的完整音频重新转写。

**方案**：追加录音完成后，对新片段调用转写服务，将结果 append 到 `memo.content`。同时将合并后的音频替换原文件。

**理由**：避免对可能很长的完整音频重新转写（耗时且消耗 API 额度）。原有转写已经是正确的，只需追加新内容。

**替代方案**：重新转写整个合并音频。缺点：浪费资源，长音频转写可能超时，且可能导致转写结果与之前不一致。

## Risks / Trade-offs

**[音频格式兼容]** → `AVMutableComposition` 要求音频 track 格式兼容。当前录音统一使用 AAC `.m4a`，合并不会有格式问题。如果未来支持导入外部音频，需要额外处理格式转换。

**[大文件合并性能]** → 长录音文件的合并可能需要几秒钟。需要在 UI 上显示合并进度或 loading 状态。

**[暂停按钮对 Engine 模式的限制]** → 开启实时转写（Apple Speech + AVAudioEngine）时不支持暂停。需要在 UI 上清晰说明，或在实时转写开启时隐藏暂停按钮。

**[追加后的数据一致性]** → 清除 polishedContent 和 title 是破坏性操作。如果用户手动精心编辑过润色内容，追加录音会丢失。可以考虑弹窗确认，但当前先选择静默清除以保持简单。

## Affected Files

| File | Change |
|------|--------|
| `Shared/Recorder/AudioRecorder.swift` | 添加 `isPaused` 状态、`pauseRecording()`、`resumeRecording()` |
| `Sources/Modules/Recording/RecordingView.swift` | 暂停按钮 UI（非 engine 模式） |
| `Sources/Modules/Recording/RecordingViewModel.swift` | 暂停状态管理、追加模式支持 |
| `Sources/Modules/Timeline/TimelineEntryView.swift` | "继续录音"菜单项 |
| `Sources/Modules/Timeline/TimelineViewModel.swift` | 追加录音后的合并、转写、清理逻辑 |
| `Sources/App/AppState.swift` | 新增 `.appendRecording(MemoEntity)` sheet case |
| `Shared/Helpers/FileHelper.swift` | `mergeAudioFiles(original:append:)` 工具方法 |
| `Localizable.csv` | 新增本地化字符串 |
