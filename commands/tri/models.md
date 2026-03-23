---
name: "Trident: Models"
description: "Show and configure models for Generator, Discriminator, and Arbiter"
category: Design
tags: [trident, models, config]
---

Show current model configuration for all three Trident roles, and let the user change them.

---

**Steps**

1. **Detect platform and read current models:**

   Check which agent files exist:
   - OpenCode: `~/.config/opencode/agents/trident-{generator,discriminator,arbiter}.md`
   - Claude Code: `~/.claude/agents/trident-{generator,discriminator,arbiter}.md`

   Read only from the platform where files exist. If both exist, show both.
   If no agent files found, tell the user to run install.sh first.

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

3. **Ask the user** if they want to change:
   - "Keep current" → done
   - "Same model for all" → ask which model, update all three
   - "Different per role" → ask for each role separately

4. **Get available models when user wants to change:**
   - OpenCode: run `opencode models` to get the full list
   - Claude Code: no model list command — ask the user to type their model name

   Model format differs per platform. When writing to both, auto-convert:
   - OpenCode format: `provider/model-name` (e.g. `minimax/MiniMax-M2.7`)
   - Claude Code format: model name without provider prefix (e.g. `claude-opus-4-6`)
   
   Conversion: `anthropic/claude-opus-4-6` → strip provider → `claude-opus-4-6` for Claude Code
   If model has no provider prefix, use as-is for both platforms

5. **Update agent files** by editing the `model:` line in frontmatter.
   If no `model:` line exists, add it after `mode: subagent`.
   Update files for ALL detected platforms (OpenCode AND Claude Code).
   When user changes a model, apply to BOTH platforms — do NOT skip one because
   it uses a "different model ecosystem." They should stay in sync.

6. **Verify** by re-reading the files and confirming the change was saved.
   Display the updated table.

7. **Remind user** to restart OpenCode/Claude Code for changes to take effect.

**Rules:**
- Output MUST match the user's language
- Show the ACTUAL model from the file, not a guess
- Do NOT guess or hardcode model names in the available models list
