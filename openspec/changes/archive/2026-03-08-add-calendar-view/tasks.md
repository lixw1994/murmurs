## 1. Calendar Component

- [x] 1.1 Create `Sources/Modules/Timeline/CalendarView.swift` with the month calendar grid: month header with navigation arrows, localized weekday labels, day cells with today highlight and memo indicator dots. Accepts `daysWithMemos: Set<Int>` and `onSelectDay: (Int) -> Void` callback. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 2. Timeline Integration

- [x] 2.1 Modify `Sources/Modules/Timeline/TimelineView.swift`: add `@State showCalendar` and `@State scrollProxy`, add `daysWithMemos` computed property, insert `CalendarView` in a VStack above the ScrollView (only when `showCalendar` is true and memos exist), pass scroll callback that uses `scrollProxy?.scrollTo(dayId, anchor: .top)`. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

- [x] 2.2 Modify `timelineList` in `TimelineView.swift`: add `.id(Int(section.day))` to `TimelineHeaderView`, capture `ScrollViewProxy` via `.onAppear { scrollProxy = scroll }`. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

- [x] 2.3 Modify toolbar in `TimelineView.swift`: add calendar toggle button (SF Symbol `calendar`/`calendar.circle.fill`) alongside the existing quick memo button in the trailing toolbar area. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 3. Verification

- [x] 3.1 Run full test suite to confirm no regressions. Verify: `xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20`
