### Requirement: Search entry point in Timeline
The Timeline view SHALL provide a search bar that allows users to search memo content by keyword.

#### Scenario: Search bar visibility
- **WHEN** the Timeline has memos
- **THEN** a search bar SHALL be accessible via the standard iOS pull-to-reveal or `.searchable()` interaction

#### Scenario: Search bar on empty timeline
- **WHEN** the Timeline has no memos
- **THEN** the search bar SHALL NOT be displayed

### Requirement: Full-text search across memo fields
The search SHALL match against the memo's `title`, `content`, and `polishedContent` fields using case-insensitive, locale-aware matching.

#### Scenario: Search matches title
- **WHEN** user enters a search query that matches a memo's title
- **THEN** that memo SHALL appear in the search results

#### Scenario: Search matches content
- **WHEN** user enters a search query that matches a memo's content (raw transcription)
- **THEN** that memo SHALL appear in the search results

#### Scenario: Search matches polished content
- **WHEN** user enters a search query that matches a memo's polished content
- **THEN** that memo SHALL appear in the search results

#### Scenario: Search is case-insensitive
- **WHEN** user searches for "hello" and a memo contains "Hello"
- **THEN** that memo SHALL appear in the search results

#### Scenario: No matching results
- **WHEN** user enters a query that matches no memo content
- **THEN** the system SHALL display an empty state message indicating no results were found

### Requirement: Search results display
Search results SHALL be displayed as a flat list (not grouped by date) with each result showing the memo's time information and content.

#### Scenario: Search results layout
- **WHEN** search results are displayed
- **THEN** each result SHALL show the memo entry in the same format as timeline entries, including time, title, and content

#### Scenario: Search results show creation date
- **WHEN** search results are displayed
- **THEN** each result SHALL display the full creation date and time (not just time) to help distinguish memos from different days

### Requirement: Real-time search filtering
The search results SHALL update in real-time as the user types.

#### Scenario: Incremental search
- **WHEN** user types additional characters in the search bar
- **THEN** the results SHALL immediately filter to show only matching memos

#### Scenario: Clear search
- **WHEN** user clears the search text
- **THEN** the view SHALL return to the normal timeline display

### Requirement: Search mode UI behavior
When search is active, the UI SHALL hide non-search elements to focus on search results.

#### Scenario: Calendar hidden during search
- **WHEN** search is active (search text is non-empty)
- **THEN** the calendar view (if visible) SHALL be hidden

#### Scenario: Record button hidden during search
- **WHEN** search is active
- **THEN** the recording button SHALL be hidden

#### Scenario: Exit search mode
- **WHEN** user cancels the search (via Cancel button or clearing text)
- **THEN** the timeline SHALL return to its normal display with calendar and record button restored

### Requirement: Hidden memos excluded from search
Memos marked as hidden SHALL NOT appear in search results.

#### Scenario: Hidden memo not in search results
- **WHEN** a memo is marked as hidden (`isHidden = true`) and user searches for content that matches that memo
- **THEN** the hidden memo SHALL NOT appear in search results
