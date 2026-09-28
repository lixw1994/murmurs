## Purpose

Provide a month calendar in the Timeline for spotting days that have memos and jumping directly to a date.

## Requirements

### Requirement: Calendar toggle visibility
The Timeline toolbar SHALL include a calendar toggle button that shows or hides a month calendar view above the timeline list. The calendar SHALL be hidden by default.

#### Scenario: Toggle calendar on
- **WHEN** user taps the calendar button in the toolbar while the calendar is hidden
- **THEN** a month calendar view SHALL appear above the timeline list with an animation

#### Scenario: Toggle calendar off
- **WHEN** user taps the calendar button in the toolbar while the calendar is visible
- **THEN** the calendar view SHALL collapse and disappear with an animation

#### Scenario: Calendar button appearance
- **WHEN** the calendar is hidden
- **THEN** the toolbar button SHALL display the `calendar` SF Symbol
- **WHEN** the calendar is visible
- **THEN** the toolbar button SHALL display the `calendar.circle.fill` SF Symbol

### Requirement: Month calendar displays current month
The calendar view SHALL display a month grid showing all days of the currently displayed month, with localized weekday labels and a month/year header.

#### Scenario: Initial display
- **WHEN** the calendar is first shown
- **THEN** it SHALL display the current month with localized weekday column headers

#### Scenario: Weekday labels respect locale
- **WHEN** the user's locale starts the week on Monday
- **THEN** the weekday labels SHALL begin with Monday
- **WHEN** the user's locale starts the week on Sunday
- **THEN** the weekday labels SHALL begin with Sunday

### Requirement: Month navigation
The calendar SHALL provide left and right arrow buttons to navigate between months.

#### Scenario: Navigate to previous month
- **WHEN** user taps the left arrow button
- **THEN** the calendar SHALL display the previous month

#### Scenario: Navigate to next month
- **WHEN** user taps the right arrow button
- **THEN** the calendar SHALL display the next month

### Requirement: Today highlight
The calendar SHALL visually distinguish the current date from other dates.

#### Scenario: Today is visible
- **WHEN** the displayed month contains today's date
- **THEN** today's date number SHALL be rendered with bold white text on an accent-colored circle background

### Requirement: Memo day indicators
The calendar SHALL display a small dot indicator below each date that has at least one memo. The dot presence MUST be based on `MemoEntity.day` values (which respect `dayStartTime`).

#### Scenario: Day has memos
- **WHEN** a date in the displayed month has one or more memos (based on `MemoEntity.day`)
- **THEN** a small accent-colored dot SHALL appear below that date's number

#### Scenario: Day has no memos
- **WHEN** a date in the displayed month has no memos
- **THEN** no dot SHALL appear below that date's number

### Requirement: Tap date to scroll timeline
Tapping a date that has memos SHALL scroll the timeline list to the corresponding day section.

#### Scenario: Tap day with memos
- **WHEN** user taps a date that has the memo indicator dot
- **THEN** the timeline list SHALL scroll to the section header for that date

#### Scenario: Tap day without memos
- **WHEN** user taps a date that has no memo indicator dot
- **THEN** nothing SHALL happen (the button is disabled)

### Requirement: Calendar hidden when no memos
The calendar toggle button SHALL only appear when there are memos in the timeline.

#### Scenario: Empty timeline
- **WHEN** the timeline has no memos
- **THEN** the calendar toggle button SHALL NOT appear in the toolbar

#### Scenario: Timeline has memos
- **WHEN** the timeline has at least one memo
- **THEN** the calendar toggle button SHALL appear in the toolbar
