#!/bin/bash
# PostToolUse advisory: when a CLAUDE.md is edited and exceeds 200 lines, nudge.
# Longer files reduce instruction adherence. Never blocks.
. "$(dirname "$0")/lib/ctx_emit.sh"
FILE_PATH=$(python3 -c 'import json,sys
try: print((json.load(sys.stdin).get("tool_input") or {}).get("file_path","").replace("\\","/"))
except Exception: print("")' 2>/dev/null)
RESOLVED="${FILE_PATH/#\~/$HOME}"

case "$RESOLVED" in
  */CLAUDE.md) ;;
  *) exit 0 ;;
esac

[ -f "$RESOLVED" ] || exit 0
LINES=$(wc -l < "$RESOLVED" | tr -d ' ')

if [ "$LINES" -gt 200 ]; then
  printf '%s\n' "CLAUDE.MD SIZE NUDGE: '$RESOLVED' now has $LINES lines (keep under 200; longer files reduce instruction adherence)." \
    "  Not a block. Next pass: split into path-scoped files under .claude/rules/, or trim content Claude can re-derive from the code." | emit_ctx PostToolUse
fi
exit 0
