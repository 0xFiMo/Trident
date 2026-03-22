---
name: "Trident: Archive"
description: "Archive a completed Trident task"
category: Design
tags: [design, archive, trident]
---

Archive a completed Trident Design Review task.

---

**Input**: Optionally specify a task-slug. If omitted, auto-select if only one task has `Status: done`.

**Rules**: Output MUST match the user's language.

**Steps**

1. **Load the Trident skill**

   Use the Skill tool to load `trident` — follow Section 10 (Archive Workflow) exactly.

2. **Verify precondition**

   Read `generator.md`. Status should be `done`.
   If `ready` (not implemented), warn but allow.
   If `iterating`, reject: "Design not converged yet."

3. **Check task completion**

   If `tasks.md` exists, count incomplete tasks. Warn if any remain.

4. **Move to archive**

   ```bash
   mkdir -p .trident/archive
   mv .trident/{task-slug} .trident/archive/YYYY-MM-DD-{task-slug}
   ```

5. **Report**

   Show final scores, iteration count, Three Strikes round results, and archive location.

6. **Suggest skill extraction**

   Ask the user if they want to extract domain knowledge from this review into a reusable agent skill.
