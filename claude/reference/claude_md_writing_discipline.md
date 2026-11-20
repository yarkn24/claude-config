# CLAUDE.md Writing Discipline

Read before adding or changing a line in `~/.claude/CLAUDE.md` or `~/.claude/RTK.md`.

DECIDE SCOPE BEFORE ADDING A LINE: true in every project, or only this one? The global CLAUDE.md and `RTK.md` take ONLY the first kind. Everything project-specific, including any illustrative example with a real name, tool, or incident, goes in that project's own CLAUDE.md or its own incident-examples doc.

- **A global rule states itself abstractly.** The concrete example lives in that project's own file; the global file gets an unnamed pointer ("see that project's own CLAUDE.md").
- **A PreToolUse hook (`hooks/claude-md-isolation-guard.sh`) blocks an Edit/Write to the global CLAUDE.md or `RTK.md` when the new text names a live project folder or a known recurring brand/token.** A block means move the content. Never bypass the hook.
- **A new project folder needs no manual step.** The hook rescans the live folder list on every check.
- **Size: official guidance caps a CLAUDE.md around 200 lines for adherence.** `hooks/claude-md-size-nudge.sh` (PostToolUse) warns past that, non-blocking.
- **A SessionStart reminder (`hooks/claude-md-audit-reminder.sh`) prompts a full manual re-read at most every 30 days.** A fixed denylist cannot catch a brand-new name.
