# Discriminator Session Recovery

When D's session_id expires (context compaction, platform restart, etc.):

## Steps

1. Start a FRESH Discriminator session (no session_id)
2. Include `discriminator.md` content in the prompt
3. Summarize all previous version scores from `generator.md`
4. Discriminator rebuilds context from files — session loss is recoverable

## Recovery Prompt

```python
task(subagent_type="oracle", load_skills=["{domain-skill}"],
     description="Trident Discriminator v{N} (session recovery)",
     prompt="""
You are a DISCRIMINATOR resuming after session loss. Your previous
knowledge is preserved in discriminator.md (included below).

## Your Previous Knowledge
{paste full content of discriminator.md}

## Score History
{paste score table from generator.md}

## Current Design (v{N})
{latest design}

Continue from where you left off. Do NOT re-verify facts already
marked as verified in your knowledge base.
""",
     run_in_background=true)
# Store NEW session_id for future rounds
```
