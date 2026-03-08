## 1. Data Model

- [x] 1.1 Add `title: String?` field to `MemoEntity` in `Sources/Persistence/MemoEntity.swift`. Add computed properties `viewTitle: String` (returns `title ?? ""`) and `hasTitle: Bool`. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 2. AI Client

- [x] 2.1 Add `func generateTitle(_ text: String, model: ChatModel) async throws -> String` to `AIClientProtocol` in `Sources/Services/Protocols/AIClientProtocol.swift`. Verify: build

- [x] 2.2 Implement `generateTitle` in `OpenAIClient` (`Sources/Services/OpenAI/OpenAIClient.swift`): add a `titleSystemPrompt` static constant, make a non-streaming chat completion request (`stream: false`), parse `choices[0].message.content` from JSON response. Temperature 0.3. Verify: build

- [x] 2.3 Add `generateTitle` mock to `Tests/Mocks/MockAIClient.swift` following the existing pattern (result var, error var, called flag). Verify: build

## 3. ViewModel Logic

- [x] 3.1 Add title generation state to `TimelineViewModel`: `titleGeneratingMemos: Set<MemoEntity>`, `titleFailedMemos: [MemoEntity: Error]`. Add `func generateTitle(_ memo: MemoEntity)` following the polish pattern (guard server set, guard content non-empty, guard not already generating, call `aiClient.generateTitle`, save result to `memo.title`). Add `func deleteTitle(_ memo: MemoEntity)`. Verify: build

- [x] 3.2 Wire automatic title generation: in the `transcribe()` success callback, after content is saved, call `generateTitle(memo)` if `config.isServerSet` and `memo.title == nil`. In the `polish()` success callback, call `generateTitle(memo)` unconditionally (to update title based on polished content). Verify: build + test

## 4. Localization

- [x] 4.1 Add localization keys to `Localizable.csv`: `generate_title` / "Generate Title" / "生成标题", `regenerate_title` / "Re-generate Title" / "重新生成标题", `delete_title` / "Delete Title" / "删除标题", `generating_title` / "Generating Title ..." / "正在生成标题 ...". Run `rake l10n` then verify build.

## 5. Timeline Entry UI

- [x] 5.1 Modify `TimelineEntryView` content display: add `@State private var expanded = false`. When memo has title, show title in bold above content. Apply `.lineLimit(expanded ? nil : (memo.hasTitle ? 2 : 3))` to content text. Add `.onTapGesture` on the content VStack to toggle `expanded` (only when not in multi-select mode). Show title generation progress when `vm.titleGeneratingMemos.contains(memo)`. Verify: build

- [x] 5.2 Add menu actions in `TimelineEntryView`: "Generate Title" button (when `Config.shared.isServerSet && !memo.viewContent.isEmpty && !memo.hasTitle`), "Re-generate Title" button (when `Config.shared.isServerSet && !memo.viewContent.isEmpty && memo.hasTitle`), "Delete Title" button (when `memo.hasTitle`). Add error display for `vm.titleFailedMemos[memo]`. Verify: build

## 6. Verification

- [x] 6.1 Run full test suite to confirm no regressions. Verify: `xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20`
