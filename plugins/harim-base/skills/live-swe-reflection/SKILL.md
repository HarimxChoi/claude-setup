---
name: live-swe-reflection
description: 'Inject a single reflection sentence to break repeated-failure loops or amplify strong-LLM problem-solving. USE WHEN agent has tried similar approach 2+ times without progress, before declaring task complete on a non-trivial fix, or after every observation in a long-running session. Implements the +22.6 pp lift (Claude 4.5 Sonnet on SWE-Bench Verified) from Live-SWE-agent (arxiv 2511.13646). WARNING for weak models — -68 pp on GPT-5-Nano per paper Table 5.'
---

# Live-SWE-agent reflection sentence

A single sentence appended to the agent's observation context. Strong-LLM amplifier with brittle floor on weak models.

## When to invoke

- Agent has executed 2+ similar tool calls without making real progress
- Long-horizon task (≥10 turns) and the agent hasn't paused to assess
- Before declaring a fix "done" on a non-trivial bug
- After every observation in an exploratory session

## When NOT to invoke

- Small-tier models (GPT-5-Nano-class). Causes infinite tool-creation loops.
- Single-step tasks (waste of latency).
- When you already have a structured planning step (e.g., explicit Plan tool) — adding reflection on top creates noise.

## The sentence (verbatim)

> Reflect on the previous trajectories and decide if there are any tools you can create to help you with the current task. If so, write the tool to /tmp and re-invoke via bash.

## Variants by domain

- **Coding (Live-SWE-agent original)**: above sentence as-is.
- **Research / paper writing**: "Reflect on what's been tried; identify one assumption that, if false, would change the approach. Test it before continuing."
- **Debugging**: "Reflect on the last 3 attempts. If they share an assumption, name it and verify it before the next attempt."
- **Stuck on a search**: "Reflect on what query patterns failed. Generate one fundamentally different angle before the next search."

## Operational form

Inject into the system prompt or as a hook on PostToolUse for long sessions:

```bash
# PostToolUse hook example (settings.json)
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "echo '<reflection>Reflect on the previous trajectories...</reflection>' >> /tmp/inject.txt"
      }]
    }]
  }
}
```

Or as a conversational injection: "Now: <the sentence>". Both work.

## Diagnostic: when it's helping vs hurting

- **Helping**: agent pauses, names a different approach, executes new path, succeeds.
- **Hurting**: agent writes 3+ throwaway tools to /tmp without using them; agent generates verbose self-reports without action.

If hurting: stop injecting. Don't add a second reflection sentence on top.

## Reference

- Paper: arxiv 2511.13646
- Repo: `OpenAutoCoder/live-swe-agent` (3 YAML files; reflection is the entire mechanism)
- Headline: 77.4% SWE-Bench Verified (Gemini 3 Pro), 75.4% (Claude 4.5 Sonnet), 45.8% SWE-Bench Pro
