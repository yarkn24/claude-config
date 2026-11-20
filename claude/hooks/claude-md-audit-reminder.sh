#!/bin/bash
# SessionStart: at most once every 30 days, reminds to re-read ~/.claude/CLAUDE.md end to end
# for project-specific detail that slipped past claude-md-isolation-guard.sh.
# No-op in headless (claude -p) dispatches.
PCMD=" $(ps -o command= -p "${PPID:-0}" 2>/dev/null) "; case "$PCMD" in *" -p "*|*" --print "*) exit 0 ;; esac

STAMP="$HOME/.claude/.last_claude_md_audit"
if [ -f "$STAMP" ] && [ -z "$(find "$STAMP" -mtime +30 2>/dev/null)" ]; then
  exit 0
fi

cat <<'MSG'
CLAUDE.MD PERIODIC AUDIT (30+ days since the last one, or never done):
Read ~/.claude/CLAUDE.md end to end. For each section ask "does this apply to only one project?".
If so, generalize it and move the detail into that project's own CLAUDE.md. When done:
  touch ~/.claude/.last_claude_md_audit
MSG
exit 0
