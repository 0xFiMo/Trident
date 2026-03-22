# Heartbeat — Background Agent Completion Detection

Platform-agnostic file-based signaling. Zero token cost during wait.

## How It Works

1. Generator clears `.done` signal file
2. Generator fires background agent (D or A)
3. Generator runs heartbeat script (blocks, polls every 3 seconds)
4. Background agent creates `.done` when finished
5. Heartbeat detects `.done`, returns
6. Generator collects results

## Invocation

```bash
# Auto-detect: if bash exists use .sh, otherwise use .ps1
if command -v bash &>/dev/null; then
  HEARTBEAT="$(find . ~/.config ~/.claude -name heartbeat.sh -path '*/trident/*' 2>/dev/null | head -1)"
  bash "$HEARTBEAT" {task-slug} 300
else
  powershell -File "$(Get-ChildItem -Recurse -Filter heartbeat.ps1 | Select -First 1)" -TaskSlug "{task-slug}" -Timeout 300
fi
```

Known paths:
- `.opencode/skills/trident/scripts/heartbeat.sh`
- `.claude/skills/trident/scripts/heartbeat.sh`
- `~/.config/opencode/skills/trident/scripts/heartbeat.sh`
- `~/.claude/skills/trident/scripts/heartbeat.sh`

## Timeout Recovery

If heartbeat exits with code 1 (timeout — `.done` not created within 5 min):

1. Check if the background task is still running via `background_output(task_id, block=false)`
2. If still running → increase timeout and retry with 600 seconds
3. If task completed but forgot `.done` → collect results directly via `background_output()`
4. If task failed/crashed → report error to user, suggest re-firing the background agent
