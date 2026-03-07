---
name: adhoc-plan
description: "Write a detailed implementation plan to plan.md. Use this when the user wants to plan a feature, design an implementation approach, or prepare for coding. Trigger on phrases like 'plan the feature', 'design the implementation', 'write a plan for X', 'how should we implement X'. This is the planning phase — code must NOT be written yet."
---

# Phase 2: Implementation Plan

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Every decision in this phase must align with the SOUL.**

You are writing a detailed implementation plan. This plan will be reviewed and annotated by a human before any code is written.

## Feature

Extract the feature name and description from the user's request.

## Pre-requisites

Before writing the plan:
1. Check if `.adhoc-planning/research.md` exists. If it does, read it thoroughly — it contains critical context about the codebase.
2. If no research file exists, read the relevant source files yourself before proposing changes. **Base the plan on the actual codebase, not assumptions.**
3. If a reference implementation was mentioned, study it before designing the approach.

## Write `plan.md`

Create `.adhoc-planning/plan.md`. Create the directory if it doesn't exist (`mkdir -p .adhoc-planning`).

The plan MUST include ALL of the following:

### 1. Goal
What this feature achieves, in 1-2 sentences. Business outcome, not technical description.

### 2. Approach
Detailed explanation of the implementation strategy. Why this approach over alternatives. What trade-offs are being made.

### 3. Changes
For EACH file that will be modified or created:
- **File path**
- **What changes** — specific description of what's being added/modified/removed
- **Code snippets** — show the actual code that will be written, not pseudocode. Include function signatures, key logic, type definitions.

### 4. Dependencies
What this feature depends on (existing code, libraries, infra). What depends on this feature.

### 5. Considerations
- What could go wrong
- What edge cases exist
- What existing behavior might be affected
- What the migration path looks like (if applicable)

## Rules

- **Do NOT implement anything.** Writing code in source files is forbidden during this phase.
- **Do NOT be vague.** "Update the API" is not acceptable. "Add a PATCH endpoint at `/api/lists/:id` that accepts `{ visibility: 'public' | 'private' }` and updates the list record" is.
- **Include code snippets.** The human reviewer needs to see what will actually be written to evaluate whether it's correct.
- **Be opinionated.** Pick a specific approach and justify it. Don't present 3 options and ask the human to choose — that's your job.
- **Flag uncertainties.** If you're not sure about something (a convention, a constraint), say so explicitly rather than guessing silently.
- **Never use `>>` in the plan.** Lines starting with `>>` are reserved for human annotations. Use other formatting for emphasis.
