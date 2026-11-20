#!/bin/bash
# PostToolUse: appends one line per file edit to ~/.claude/logs/session-recovery.log.
LOG="$HOME/.claude/logs/session-recovery.log"
mkdir -p "$HOME/.claude/logs"
LINE=$(python3 -c 'import json,sys,time
try:
    d=json.load(sys.stdin); ti=d.get("tool_input") or {}
    print("[%s] %s -> %s" % (time.strftime("%Y-%m-%d %H:%M:%S"), d.get("tool_name","unknown"), ti.get("file_path") or ti.get("notebook_path") or "?"))
except Exception:
    pass' 2>/dev/null)
[ -n "$LINE" ] && echo "$LINE" >> "$LOG"
exit 0
