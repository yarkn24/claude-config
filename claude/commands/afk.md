---
description: Operator is away; autonomous mode inside the fence, no questions for reversible local work
---

# AFK Mode Active

The operator is away from the computer. Operate autonomously INSIDE THE FENCE of `CLAUDE.md`: Work Machine, Confidentiality First, Local by Default. Autonomy never widens the fence.

## Rules

1. **Ask no questions about reversible local work.** Decide yourself, pick the safest sensible option, log the reason.
2. **Compare 2-3 approaches first** (cost, speed, reliability, reversibility, side effects) and take the best one, not merely one that works. If uncertainty is high, research (generic, de-identified queries only) or delegate.
3. **Every action is reversible or queued.** Before changing state, ask "how does the operator undo this?" Take a copy of any config or document before editing it (`cp file file.bak-<date>`), and prefer a working branch to the main one.
4. **Solve blockers by finding another in-scope path** (3 to 4 approaches). A permission prompt, a hook denial or a missing approval is final: never route around it. A blocker that needs the operator is queued, not guessed.
5. **Queue, never do, these** (prepare each fully and list it as one yes/no line in the report):
   - deletions of any file (list path, reason, risk)
   - installs, plugin or MCP changes
   - commit, push, pull request, repository or remote actions
   - anything outward-facing: send, post, publish, share, upload, open a ticket
   - anything outside the task's own working files
6. **Use background processes for long work.** Wait for the automatic completion notice; do not poll in a loop and do not sleep.
7. **Set up the hourly self-continue cron as the first step of every `/afk`** (a session self-chain breaks on quota exhaustion; a session cron survives it). Call `CronList` first; if a job with `cron="7 * * * *"` whose prompt starts with "CHECK FIRST" exists, skip. Otherwise `CronCreate` with `cron="7 * * * *"`, `recurring=true`, and this prompt (`<EXPIRY_DATE>` = today plus 1 day):
   ```
   CHECK FIRST: if today's date is <EXPIRY_DATE> or later, call CronList, find the job whose cron is "7 * * * *" and whose prompt carries this text, delete it with CronDelete, then do nothing else and stop. Otherwise tokens have refreshed: resume where you left off inside the AFK fence, never ask a question. /afk
   ```
   The cron is session-scoped (lost when the session closes; the session must stay open overnight). Say so in the report.
8. **Write the return report when the task is done** (below). Stop at the first action that needs the operator's approval and queue it; do not message the operator before they write.

## Forbidden

- Asking "should I do this?", "which do you prefer?", "should I continue?"
- Waiting for the operator on reversible work
- Deleting files, even your own, except temporary files you created this session
- Any commit, push or outward action

## Task loop

1. Plan: what to do, alternatives, best path.
2. Copy: snapshot state that will change.
3. Act: apply the best path.
4. Verify: check the output with a real command, not a guess.
5. Log: what, why, and why the alternatives were dropped.

## Return report (first reply when the operator writes)

- **A. Actions taken** (chronological): what, why this option, how to undo (file or command), result and how it was verified.
- **B. Blockers met**: the problem, how it was overcome, or why the operator is needed.
- **C. Deferred actions**: everything queued under rule 5, as yes/no lines.
- **D. Rollback commands**: one per significant action (for example `git revert <hash>`, `mv file.bak-<date> file`).
- **E. Suggested next steps**: options and what is expected from the operator.

If the operator rejects a decision, run its rollback first, confirm the old state, then act on the new decision.

AFK mode stays on until the operator writes back.
