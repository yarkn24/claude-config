#!/bin/bash
# PostToolUse (Write|Edit|MultiEdit): fires only when the edited file is under .claude/hooks/.
# Runs verify_hooks.py and surfaces only its FAIL lines; silent on a clean run.
set -u
INPUT=$(cat)
FP=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit()
ti = d.get('tool_input', {}) or {}
print((ti.get('file_path') or ti.get('notebook_path') or '').replace('\\\\', '/'))
" 2>/dev/null)

case "$FP" in
  */.claude/hooks/*)
    OUT=$(python3 "$HOME/.claude/hooks/verify_hooks.py" 2>&1)
    FAILS=$(printf '%s\n' "$OUT" | grep '^FAIL')
    if [ -n "$FAILS" ]; then
      . "$(dirname "$0")/lib/ctx_emit.sh"
      printf '%s\n%s\n' "[hooks-dir-verify-guard] verify_hooks.py found problems after this edit:" "$FAILS" | emit_ctx PostToolUse
    fi
    ;;
esac
exit 0
