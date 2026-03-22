---
name: "Trident: Status"
description: "Show active and completed Trident tasks — what's in progress and what's done"
category: Design
tags: [design, status, trident]
---

Show a dashboard of all Trident Design Review tasks.

---

**Rules**: Output MUST match the user's language.

**Steps**

1. **Load the Trident skill**

   Use the Skill tool to load `trident` — follow Section 9 (Status Workflow) exactly.

2. **Scan `.trident/`**

   List all directories (exclude `archive/`).
   For each, read `generator.md` Meta section to extract: Task, Status, Version, Task Type.
   If `tasks.md` exists, count complete vs total tasks.
   Group by: In Progress (iterating/ready/implementing) vs Completed (done).

3. **Scan archive**

   List `.trident/archive/` directories if it exists. Extract one-line summary from each `generator.md`.

4. **Display dashboard**

   Show In Progress tasks with current progress context.
   Show Completed tasks with one-line summary.
   Show Archived tasks with date and summary.
