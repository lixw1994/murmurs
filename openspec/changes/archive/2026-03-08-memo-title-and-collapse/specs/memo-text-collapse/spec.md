## ADDED Requirements

### Requirement: Collapsible text display in timeline entries
Timeline entries SHALL display content text in a collapsed (truncated) form by default, with the ability to expand to show full text.

#### Scenario: Memo with title - default collapsed
- **WHEN** a memo has a title and content text
- **THEN** the content text SHALL be displayed with a maximum of 2 visible lines

#### Scenario: Memo without title - default collapsed
- **WHEN** a memo has no title and content text longer than 3 lines
- **THEN** the content text SHALL be displayed with a maximum of 3 visible lines

#### Scenario: Short content not truncated
- **WHEN** a memo's content text fits within the default line limit (2 lines with title, 3 lines without)
- **THEN** the content text SHALL be displayed in full without any expand/collapse interaction

### Requirement: Tap to expand/collapse content
Users SHALL be able to tap on the content area of a timeline entry to toggle between collapsed and expanded states.

#### Scenario: Tap to expand collapsed content
- **WHEN** user taps on the content area of a collapsed memo entry
- **THEN** the content text SHALL expand to show the full text without line limits

#### Scenario: Tap to collapse expanded content
- **WHEN** user taps on the content area of an expanded memo entry
- **THEN** the content text SHALL collapse back to the default line limit

#### Scenario: Collapse state resets on view reload
- **WHEN** the timeline view is reloaded or re-entered
- **THEN** all memo entries SHALL be in their default collapsed state

#### Scenario: Multi-select mode disables expand/collapse
- **WHEN** multi-select mode is active
- **THEN** tapping a memo SHALL toggle selection instead of expand/collapse
