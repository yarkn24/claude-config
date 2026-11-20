#!/bin/bash
# emit_ctx EVENT: wrap stdin text as hookSpecificOutput.additionalContext, silent when empty.
# Why: plain stdout/stderr with exit 0 on Pre/PostToolUse never reaches the model.
emit_ctx() {
  python3 -c 'import json,sys
t=sys.stdin.read().strip()
t and print(json.dumps({"hookSpecificOutput":{"hookEventName":sys.argv[1],"additionalContext":t}}))' "$1"
}
