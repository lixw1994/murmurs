---
name: adhoc-help
description: "Show ad-hoc workflow commands and usage guide. Use this when the user asks about the adhoc workflow, wants to see available adhoc commands, or is confused about the planning workflow steps. Also trigger when the user mentions 'adhoc', 'planning workflow', or asks how to plan before implementing."
---

# Ad-Hoc Task Workflow — Command Reference

Plan-first workflow for one-time implementation tasks. Core principle: **never let Claude write code until you've reviewed and approved a written plan.**

All artifacts are written to `.adhoc-planning/` directory. After completion, knowledge can be extracted and archived.

## Workflow

```
/adhoc-research <target>     Research phase — deep-read, output .adhoc-planning/research.md
        ↓
/adhoc-plan <feature>        Plan phase — detailed .adhoc-planning/plan.md with code snippets
        ↓
  [you add >> notes]          Annotate — open plan.md in editor, add inline notes
        ↓
/adhoc-review                Review cycle — process notes, update plan (repeat 1-6x)
        ↓
/adhoc-todos                 Task list — append granular checklist to plan.md
        ↓
/adhoc-implement             Execute — implement everything, mark progress, typecheck
        ↓
/adhoc-memory               Memorize — extract learnings to .adhoc-planning/memory/
```

## Directory Structure

```
.adhoc-planning/
├── SOUL.md                  # Identity & values — the mirror (created by /adhoc-soul)
├── research.md              # Deep research findings (temporary)
├── plan.md                  # Implementation plan + task checklist (temporary)
└── memory/                  # Permanent learnings (created by /adhoc-memory)
    └── 2025-01-15/
        └── add-auth.md
    └── 2025-02-03/
        └── refactor-api.md
```

## Annotation Convention

In `.adhoc-planning/plan.md`, add your notes using `>>` prefix:

```markdown
## Database Schema

Users table with email, password_hash, created_at fields.

>> add a role column, enum admin | user, default user

The API will expose CRUD endpoints...

>> PATCH not PUT for updates
>>- remove the bulk delete endpoint
>>! user table schema must not change
>>? do we need rate limiting here?
```

| Prefix | Meaning |
|--------|---------|
| `>>` | General note (correction, direction, info) |
| `>>!` | Hard constraint — must not be violated |
| `>>?` | Question — needs an answer |
| `>>-` | Cut scope — remove from plan |

Prefixes are optional — plain `>>` works for everything.

Then run `/adhoc-review` — Claude will process each note and update the plan.

## Quick Reference

| Command | Phase | Creates/Updates |
|---------|-------|----------------|
| `/adhoc-research <target>` | Research | `.adhoc-planning/research.md` |
| `/adhoc-plan <feature>` | Planning | `.adhoc-planning/plan.md` |
| `/adhoc-review` | Annotation | updates `.adhoc-planning/plan.md` |
| `/adhoc-todos` | Task breakdown | appends to `.adhoc-planning/plan.md` |
| `/adhoc-implement` | Execution | source code |
| `/adhoc-memory` | Memorize | `.adhoc-planning/memory/<date>/<name>.md` |
| `/adhoc-soul` | Setup | `.adhoc-planning/SOUL.md` |
| `/adhoc-help` | — | shows this guide |
