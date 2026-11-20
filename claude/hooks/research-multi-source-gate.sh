#!/bin/bash
# Stop hook: non-blocking nudge, at most once per session, never exit 2.
# After 3+ web searches, reminds that a recommendation needs independent sources.
INPUT=$(cat)

# Loop guard: never re-fire when the stop was already triggered by a hook.
printf '%s' "$INPUT" | python3 -c 'import json,sys
d=json.load(sys.stdin)
sys.exit(0 if d.get("stop_hook_active") else 1)' 2>/dev/null && exit 0

SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try:
    print(json.load(sys.stdin).get('session_id','unknown'))
except Exception:
    print('unknown')" 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"

STATE_DIR="$HOME/.claude/hooks/.research_state"
STATE_FILE="$STATE_DIR/$SESSION_ID.state"
NUDGED_FILE="$STATE_DIR/$SESSION_ID.nudged"

[ -f "$NUDGED_FILE" ] && exit 0
[ -f "$STATE_FILE" ] || exit 0

COUNT=$(grep -c "search" "$STATE_FILE" 2>/dev/null)
[ "${COUNT:-0}" -lt 3 ] && exit 0

: > "$NUDGED_FILE"
cat <<MSG
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "RESEARCH NOTE (automatic, not a block, once per session): $COUNT web searches ran. If you are recommending something, check it against at least two independent sources and cite each URL and date. Optional otherwise."
  }
}
MSG
exit 0
