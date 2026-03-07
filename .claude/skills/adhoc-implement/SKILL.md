---
name: adhoc-implement
description: "Execute the approved plan. Implements all tasks, marks progress, runs typechecks. Use this when the user says 'implement', 'execute the plan', 'start coding', 'build it', or is ready to turn the approved plan into code. The plan must already exist in .adhoc-planning/plan.md with a Tasks section."
---

# Phase 3: Implementation

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Every line of code you write must align with the SOUL.**

The plan has been reviewed, annotated, and approved. The task list is finalized. Now implement everything.

## Rules of execution

1. **Implement ALL tasks in the plan.** Do not cherry-pick. Do not skip tasks you think are unimportant. The human already decided what's in scope.

2. **Mark tasks as completed.** After finishing each task, update `.adhoc-planning/plan.md` — change `- [ ]` to `- [x]`. The plan document is the source of truth for progress.

3. **Do not stop until all tasks and phases are completed.** Do not pause for confirmation mid-flow. Do not ask "should I continue?" — the answer is yes. Keep going until every checkbox is checked.

4. **Code quality standards:**
   - Do not add unnecessary comments or JSDoc unless the plan explicitly calls for it
   - Do not use `any` or `unknown` types (TypeScript projects)
   - Follow the conventions documented in `.adhoc-planning/research.md`
   - Match the patterns and idioms already used in the codebase

5. **Continuous verification:** After each phase (group of tasks), run the project's typecheck/lint/test command to catch issues early. Do not wait until the end to discover problems.

6. **If something is ambiguous,** re-read `.adhoc-planning/plan.md`. The plan contains the decisions. If the plan is genuinely silent on something, make a reasonable choice consistent with the codebase conventions — do not stop to ask.

7. **Commit per logical unit.** If git is being used, make atomic commits per task or per phase — not one massive commit at the end.

## After completion

When all tasks are marked `[x]`, say:
"All tasks complete. Review the changes — send corrections if anything needs fixing."
