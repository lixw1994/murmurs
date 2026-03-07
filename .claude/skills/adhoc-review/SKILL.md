---
name: adhoc-review
description: "Process human annotations in plan.md and update the plan. Use this after the user has added >> notes to .adhoc-planning/plan.md. Trigger when the user says 'review my notes', 'process annotations', 'I added notes to the plan', 'review the plan', or mentions >> annotations."
---

# Annotation Cycle: Process Human Notes

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Every decision in this phase must align with the SOUL.**

The human has added inline notes to `.adhoc-planning/plan.md`. Your job is to find every note, address it, and update the plan.

## Annotation syntax

Lines starting with `>>` are human annotations. The plan itself never uses `>>`, so any `>>` line is a note.

### Basic form

```
>> your note here
```

### Optional semantic prefixes

| Prefix | Meaning | Example |
|--------|---------|---------|
| `>>` | General note (correction, direction, info) | `>> PATCH not PUT` |
| `>>!` | Hard constraint — must not be violated | `>>! must keep backward compat` |
| `>>?` | Question — needs an answer before proceeding | `>>? is Redis actually needed here?` |
| `>>-` | Cut scope — remove this from the plan | `>>- remove bulk delete endpoint` |

The prefix is optional. Plain `>>` works for everything — Claude infers intent from content when no prefix is given.

## How to process each note

For EACH note found:

1. **Understand the intent** — is it a correction, a constraint, a question, a scope cut, or domain knowledge?
2. **Apply it to the plan** — restructure, rewrite, add, or remove content as directed
3. **Remove the note** — delete the `>>` line and update the surrounding plan section to incorporate the feedback
4. **For `>>?` questions** — answer inline in the plan (not in chat) and adjust the approach if needed

## How to handle each type

| Type | Detected by | Action |
|------|-------------|--------|
| Correction | `>>` with a specific fix | Apply the fix, update code snippets |
| Constraint | `>>!` or language like "must", "never" | Add as hard constraint, restructure approach to respect it |
| Question | `>>?` or language like "should we", "is this" | Answer in the plan, adjust approach if the answer changes things |
| Scope cut | `>>-` or "remove", "don't need", "skip" | Remove from plan, note as future work if relevant |
| Redirect | "should be on X not Y", "move this to" | Rethink and rewrite the affected section |
| Reference | "like the users table", "same pattern as" | Read the referenced code, adapt approach to match |
| Domain knowledge | Factual info about the system | Incorporate into approach, update code snippets |

## After processing all notes

1. Re-read the entire plan for consistency — a note in section 3 might invalidate something in section 5
2. Update code snippets to reflect all changes
3. Ensure no contradictions exist between sections
4. Output a brief summary in chat: "Processed N notes: [one-line summary of each change]"

## Critical guard

**Do NOT implement anything. Do NOT write code in source files. Planning phase only.**

If all notes have been processed and the plan looks complete, say:
"All notes addressed. Review `.adhoc-planning/plan.md` again — add more `>>` notes if anything needs changing, or run `/adhoc-todos` to generate the task list when you're satisfied."
