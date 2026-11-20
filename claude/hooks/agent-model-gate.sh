#!/bin/bash
# PreToolUse hook, matcher Agent. Denies an Agent call whose `model` is blank or missing:
# a blank model silently inherits the parent session's model.
INPUT=$(cat)
REASON=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get('tool_name') != 'Agent':
    sys.exit(0)
if not ((d.get('tool_input') or {}).get('model') or '').strip():
    print('Agent call has no model. Pass model explicitly (opus|sonnet|haiku) and state: <agent> -> <model>, because <reason>.')
" 2>/dev/null)
[ -z "$REASON" ] && exit 0
python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': sys.argv[1]}}))
" "$REASON"
exit 0
