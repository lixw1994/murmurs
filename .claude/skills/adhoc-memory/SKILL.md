---
name: adhoc-memory
description: "Memorize learnings from completed ad-hoc task. Use this when the user wants to archive knowledge from a completed task, extract learnings, or says 'save what we learned', 'archive this task', 'memorize'. Cleans up working files after extraction."
---

# Phase 4: Memorize & Clean Up

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Memory extraction must reflect the SOUL's values — selective, honest, useful.**

The task has been implemented and verified. Now extract reusable memory and clean up the working files.

## Input

Extract a short task name from the user's request (e.g., "add-auth", "refactor-api", "fix-webhook"). If not provided, infer from the plan's Goal section or ask the user.

## Steps

### 1. Read the working files

Read `.adhoc-planning/research.md` and `.adhoc-planning/plan.md`. Both may or may not exist.

If neither file exists, inform the user there's nothing to memorize and stop.

### 2. Extract memory

Distill the most valuable learnings from the research and plan into a memory entry. Focus on:

- **Patterns discovered** — coding patterns, architectural conventions, idioms that were uncovered during research
- **Gotchas & pitfalls** — things that would have caused bugs if not caught, non-obvious constraints
- **Key decisions & rationale** — why a specific approach was chosen over alternatives
- **Reusable techniques** — solutions that could apply to future tasks
- **Codebase insights** — understanding of how systems work that isn't obvious from reading code

Do NOT include:
- Task-specific implementation details that won't generalize
- The full plan or task list (that's what the plan file was for)
- Obvious things that any developer would know

### 3. Write the memory file

Create the memory directory using today's date and write the entry:

```bash
mkdir -p .adhoc-planning/memory/YYYY-MM-DD
```

Write to `.adhoc-planning/memory/YYYY-MM-DD/<name>.md`.

Format:

```markdown
# <Task Title>

**Date:** YYYY-MM-DD
**Scope:** Brief description of what was done

## Key Learnings

### <Learning 1 Title>
<Description — what was learned, why it matters>

### <Learning 2 Title>
<Description>

...

## Gotchas

- <Gotcha 1>
- <Gotcha 2>

## Patterns

- <Pattern or convention worth remembering>

## References

- <Key file paths that were central to this work>
```

### 4. Clean up working files

After writing the memory file, remove the working files:

```bash
rm -f .adhoc-planning/research.md .adhoc-planning/plan.md
```

### 5. Display summary

```
## Memory Saved

**Task:** <name>
**Saved to:** .adhoc-planning/memory/YYYY-MM-DD/<name>.md
**Working files cleaned up:** ✓

Key learnings:
- <one-line summary of each learning>
```

## Guardrails

- **Do NOT delete memory files** — they are permanent records
- **If the memory file already exists** (same date + name), append a numeric suffix: `<name>-2.md`
- **Be selective** — extract only genuinely useful insights, not a dump of everything that happened
- **Keep it concise** — each memory entry should be scannable in under 2 minutes
- **Ask before cleaning** — if the plan has incomplete tasks (`- [ ]`), warn the user and ask for confirmation before removing working files
