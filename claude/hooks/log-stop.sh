#!/bin/bash
# Stop: appends a session-end marker to ~/.claude/logs/session-recovery.log.
LOG="$HOME/.claude/logs/session-recovery.log"
INPUT=$(cat)
# Loop guard: skip when the stop was triggered by another hook.
printf '%s' "$INPUT" | python3 -c 'import json,sys
d=json.load(sys.stdin)
sys.exit(0 if d.get("stop_hook_active") else 1)' 2>/dev/null && exit 0
mkdir -p "$HOME/.claude/logs"
printf '\n=== SESSION ENDED: %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG"
exit 0
