---
name: adhoc-todos
description: "Generate a detailed task checklist from the approved plan. Use this after annotation cycles are complete, when the user wants to break the plan into tasks, or says 'generate todos', 'create task list', 'break this into tasks'. This is the last step before implementation."
---

# Generate Todo List

**Before you begin: read `.adhoc-planning/SOUL.md` and internalize it. Every decision in this phase must align with the SOUL.**

The plan has been reviewed and approved by the human. Generate a granular task breakdown.

## Instructions

1. Read `.adhoc-planning/plan.md` thoroughly.

2. **Append** a todo section to the END of the plan document. Do not create a separate file — the plan and todos must live together.

3. Format:

```markdown
---

## Tasks

### Phase 1: [logical grouping name]
- [ ] 1.1 [specific task description]
- [ ] 1.2 [specific task description]
- [ ] 1.3 [specific task description]

### Phase 2: [logical grouping name]
- [ ] 2.1 [specific task description]
- [ ] 2.2 [specific task description]

### Phase 3: [logical grouping name]
- [ ] 3.1 [specific task description]
```

4. **Task granularity rules:**
   - Each task should be completable in one focused action (create a file, modify a function, add a test)
   - Each task should be independently verifiable (you can check if it's done without looking at other tasks)
   - Tasks within a phase can depend on each other, but the dependency should be clear from the ordering
   - Include testing tasks — "write tests for X" is a task, not implied

5. **Order tasks by dependency** — things that must exist first come first.

6. Group into phases by logical unit of work, not by file type. "User authentication" is a good phase. "All model files" is a bad phase.

## Critical guard

**Do NOT implement anything. Do NOT write code in source files. This is the last planning step.**

After generating the todo list, say:
"Task list added to `.adhoc-planning/plan.md`. Review it — when ready, run `/adhoc-implement` to execute."
