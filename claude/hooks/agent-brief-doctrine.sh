#!/bin/bash
# PreToolUse hook, matcher Agent. Never blocks; adds one line of dispatch doctrine as context.
INPUT=$(cat)
printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get('tool_name') != 'Agent':
    sys.exit(0)
line = ('[BRIEF DOCTRINE] The first sentence of the prompt assigns the subagent a role. '
        'Tight on targets and verification, never on method: say what must be covered and what '
        'must not break, then get out of the way. Treat a method instruction as a patch for one '
        'past failure, not a fixture. Cite file and line for any prior finding instead of '
        'paraphrasing it, because a paraphrase drops the caveat that limited it. Ask the open '
        'question, never the claim: a brief that says \"confirm X\" gets X back.')
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'additionalContext': line}}))
" 2>/dev/null
exit 0
