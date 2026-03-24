---
name: "Trident: Models"
description: "Show and configure models for Generator, Discriminator, and Arbiter"
category: Design
tags: [trident, models, config]
---

Show current model configuration for all three Trident roles, and let the user change them.

---

**Steps**

1. **Detect CURRENT platform and read current models:**

   Detect which platform you are running on RIGHT NOW — only manage that platform's files:
   - **If running on OpenCode:** ONLY read/write `~/.config/opencode/agents/trident-{generator,discriminator,arbiter}.md`
   - **If running on Claude Code:** ONLY read/write `~/.claude/agents/trident-{generator,discriminator,arbiter}.md`

   Do NOT show or modify the other platform's files. Each platform manages its own config independently.
   If no agent files found for the current platform, tell the user to run install.sh first.

   Look for `model:` line in the frontmatter. If absent, show "platform default".

   If the model is a short alias, display the full name:
   - `opus` → `claude-opus-4-6`
   - `sonnet` → `claude-sonnet-4-6`
   - `haiku` → `claude-haiku-4-5`

2. **Display current configuration:**

   ```
   Trident Model Configuration:

   | Role          | Job                                         | Model                      |
   |---------------|---------------------------------------------|----------------------------|
   | Generator     | designs and implements code                 | {read from agent .md file} |
   | Discriminator | scores and reviews (the critic)             | {read from agent .md file} |
   | Arbiter       | independent final check (prevents collusion) | {read from agent .md file} |
   ```

   Read the ACTUAL `model:` value from each file. Do NOT hardcode or guess.

3. **Ask the user** if they want to change (use the question tool to present options):
   - "Keep current" → done
   - "Same model for all" → go to step 4, apply chosen model to all three roles
   - "Different per role" → go to step 4 three times, once per role

4. **Present model selection menu (MANDATORY — do NOT ask user to type model names):**

   **OpenCode:** Run `opencode models` to get the full list. Parse the output into selectable options.
   Present as a question tool menu with options the user can click — NOT a text prompt.

   If the model list is long (20+ models), group by provider:
   ```
   Anthropic:
     1. anthropic/claude-opus-4-6
     2. anthropic/claude-sonnet-4-6
     3. anthropic/claude-haiku-4-5
   OpenAI:
     4. openai/gpt-5.4
     ...
   MiniMax:
     7. minimax-coding-plan/MiniMax-M2.7
     ...
   ```

   Use the question tool with all models as selectable options. Add the current model as the first option
   with "(current)" suffix so the user can easily keep it.

   **Claude Code:** No model list command available — use the question tool with common models
   (claude-opus-4-6, claude-sonnet-4-6, claude-haiku-4-5) as options, plus allow custom input.

   **Model format** differs per platform. When writing to both, auto-convert:
   - OpenCode format: `provider/model-name` (e.g. `minimax/MiniMax-M2.7`)
   - Claude Code format: model name without provider prefix (e.g. `claude-opus-4-6`)

   Conversion: `anthropic/claude-opus-4-6` → strip provider → `claude-opus-4-6` for Claude Code
   If model has no provider prefix, use as-is for both platforms

5. **Update agent files** by editing the `model:` line in frontmatter.
   If no `model:` line exists, add it after `mode: subagent`.
   Update files ONLY for the current platform — do NOT touch the other platform's files.

6. **oh-my-opencode Model Guard** (OpenCode only):

   After updating agent files, check `~/.config/opencode/oh-my-opencode.json`:

   - If file does NOT exist → skip (agent .md models work directly)
   - If file exists:
     a. Read `agents.sisyphus-junior.model`
     b. Compare with the Discriminator/Arbiter models just configured
     c. If MATCH → no action needed
     d. If MISMATCH → warn:

   ```
   ⚠️ oh-my-opencode detected — model override required

   oh-my-opencode ignores custom agent model fields (Zod schema limitation).
   Discriminator and Arbiter will actually use: {sisyphus-junior model}
   You configured: {Discriminator model}

   Fix: Update sisyphus-junior model in oh-my-opencode.json?
   (⚠️ This affects ALL subagents — oracle, explore, librarian, etc.)

   1. Yes — set sisyphus-junior to {Discriminator model}
   2. No — keep current, Discriminator/Arbiter will use {sisyphus-junior model}
   ```

   If user says Yes:
   - Edit `~/.config/opencode/oh-my-opencode.json` → `agents.sisyphus-junior.model` = Discriminator's model
   - Display updated config
   - Warn: "Restart OpenCode for changes to take effect."

7. **Verify** by re-reading the files and confirming the change was saved.
   Display the updated table.

8. **Remind user** to restart OpenCode/Claude Code for changes to take effect.

**Rules:**
- Output MUST match the user's language
- Show the ACTUAL model from the file, not a guess
- Do NOT guess or hardcode model names in the available models list
