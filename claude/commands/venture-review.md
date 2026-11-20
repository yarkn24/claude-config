---
description: Candid investor-lens review of a product or startup idea by the venture-reviewer subagent.
argument-hint: <idea, plan, or question>
---

Start the `venture-reviewer` subagent (Agent tool, subagent_type: "venture-reviewer") and ask it to review the idea below. All rules (checklist, evidence discipline, tone) live in `~/.claude/agents/venture-reviewer.md`; do not restate them here.

Do not include confidential material (customer names, internal figures) in the prompt; describe it generically.

Idea:
$ARGUMENTS

If empty, ask the user in one line what they want reviewed, then dispatch.
