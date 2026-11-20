> On this machine `~/.claude/WORK_MACHINE.md` wins: every deletion and every protected-path change is approved by the operator at the prompt (`rm`, `git rm`, `sudo` are `ask` rules).

# Protected Paths: Current State (2026-10-03)

Referenced from `~/.claude/CLAUDE.md`. Sources: code.claude.com/docs/en/permission-modes; anthropics/claude-code#37029 (closed 2026-05-12).

## Behavior

- Edit/Write on `.claude/hooks/*.sh`, `.claude/settings*.json`, `.git/`, `.vscode/`, `.husky/` may still prompt. `.claude/commands/`, `agents/`, `skills/` are fine.
- Auto mode routes protected-path writes to the auto-mode classifier and suspends a broad `Bash(*)`.
- A Bash heredoc or `python3 -c` write to a protected path is NOT a bypass. Using one as a detour around a denial counts as "Auto-Mode Bypass". Never do it.

## Allowed (`~/.claude/settings.json`, verified 2026-10-03)

- `autoMode.allow` "Guard Hardening": edits that ADD or TIGHTEN a guard (new block/ask-only hook, new deny/ask rule, narrowed allow, wider matcher, extra check with no fail-open path, new soft_deny/hard_deny), while every existing guard stays present and at least as strict, and the full diff is visible.
- `permissions.ask` (this machine): `Bash(rm *)`, `Bash(git rm *)`. `delete-guard.sh` is the judge, the "tamam sil" rule still applies.

## Not allowed

- `autoMode.soft_deny` "Guard Loosening": removing, disabling, renaming, moving, symlinking, emptying or chmod -x a guard; removing a hook entry or narrowing its matcher; `disableAllHooks`; raising timeouts; deleting a deny/ask rule; widening an allow, `additionalDirectories` or bypass entry; flipping `defaultMode` toward bypass; weakening a hook; editing the autoMode rules themselves.
- Whole-file overwrites that hide what was dropped.

## When something is denied

`/permissions`, then Recently denied, then `r` to retry. Never route around the denial; ask the operator.

## Decision matrix

- `.claude/commands|agents|skills/` -> Edit/Write.
- Hooks, `settings*.json`, `.git/`, `.vscode/`, `.husky/` -> Edit/Write or Bash, only as a Guard Hardening change or with operator approval. A denial is final until the operator approves.
- Everything else -> Edit/Write.
