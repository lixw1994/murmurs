## 1. Localization

- [x] 1.1 Add localization keys to `Localizable.csv`: `search_placeholder` / "Search memos..." / "搜索备忘录...", `search_no_results` / "No results" / "无结果". Run `rake l10n` then verify build.

## 2. Search UI

- [x] 2.1 Add search state to `TimelineView`: `@State private var searchText = ""`. Add `.searchable(text: $searchText, prompt: L(.search_placeholder))` to the NavigationStack. Verify: build

- [x] 2.2 Add `searchResults` computed property to `TimelineView`: filter `allMemos` where `!memo.isHidden` and (`title`, `content`, or `polishedContent`) `localizedStandardContains` searchText. Return empty array when searchText is empty. Verify: build

- [x] 2.3 Add `isSearching` computed property (`!searchText.isEmpty`). When `isSearching`, hide CalendarView and recording button. Show search results list instead of normal timeline sections. Verify: build

- [x] 2.4 Create search results view: show flat list of `TimelineEntryView` for each result. Replace time label with full `viewCreatedAt` (date + time) instead of just `viewTime` for search result items. Show empty state with `L(.search_no_results)` when searchResults is empty and searchText is non-empty. Verify: build

## 3. Verification

- [x] 3.1 Run full test suite to confirm no regressions. Verify: `xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20`
