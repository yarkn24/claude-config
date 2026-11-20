#!/bin/bash
# PostToolUse (WebSearch and search MCP tools): counts web searches per session.
# Silent, never blocks. research-multi-source-gate.sh (Stop) reads the count.
INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try:
    print(json.load(sys.stdin).get('session_id','unknown'))
except Exception:
    print('unknown')" 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="unknown"
STATE_DIR="$HOME/.claude/hooks/.research_state"
mkdir -p "$STATE_DIR"
echo "search" >> "$STATE_DIR/$SESSION_ID.state"
exit 0
