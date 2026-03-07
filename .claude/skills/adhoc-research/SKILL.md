---
name: adhoc-research
description: "Deep-read a folder or system, write findings to research.md. Use this when the user wants to understand a codebase area before making changes, needs deep research on a system or module, or says things like 'research the auth system', 'understand how X works', 'read through the API layer'. Always use this before planning implementation of unfamiliar code areas."
---

# Phase 1: Deep Research

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Every decision in this phase must align with the SOUL.**

You are conducting deep research before any planning or implementation begins.

## Target

The user's request describes the target system or folder to research. Extract the target from their message.

## Instructions

1. **Read deeply** — not at the signature level, not skimming. Read every file in the target area. Understand:
   - What each function/module does and WHY it exists
   - How data flows through the system end-to-end
   - What conventions, patterns, and idioms the codebase uses
   - What implicit assumptions exist (caching layers, ORM conventions, retry logic, error handling patterns)
   - What existing utilities/helpers already exist that a new feature might reuse or conflict with
   - Edge cases and potential gotchas

2. **Go through everything** — do not stop after reading 3-4 files. Follow the dependency chain. If a function calls another function, read that too. If a module imports a utility, understand that utility. Trace the full path.

3. **Look for specificities and intricacies** — the details that would cause a naive implementation to break. Examples:
   - A caching layer that new code must respect
   - An ORM convention that migrations must follow
   - A message queue that already handles retries
   - An auth middleware that affects all routes
   - A shared state or singleton that new code must coordinate with

4. **Write everything to `.adhoc-planning/research.md`**. Create the directory if it doesn't exist (`mkdir -p .adhoc-planning`). Structure:

```markdown
# Research: [target name]

## Overview
[What this system/folder does, in 2-3 sentences]

## Architecture
[How the pieces fit together, data flow, key abstractions]

## Key Files
[List of important files with brief role descriptions]

## Patterns & Conventions
[Coding patterns, naming conventions, architectural idioms used]

## Existing Utilities
[Helpers, shared functions, libraries already in use that are relevant]

## Gotchas & Constraints
[Things that would break if ignored: caching, auth, rate limits, conventions, implicit dependencies]

## Potential Risks
[Areas where a new feature could conflict with existing behavior — describe the risk factually, do NOT suggest how to solve it]
```

5. **Do NOT plan or suggest solutions.** This phase is purely about understanding what exists. No implementation ideas, no "we could do X", no "first version could skip Y", no "interface should leave room for Z". The Potential Risks section describes risks as facts ("X and Y are tightly coupled"), never as recommendations. Just document what IS.

6. **Do NOT summarize in chat.** All findings go into the markdown file. The file IS the deliverable.
