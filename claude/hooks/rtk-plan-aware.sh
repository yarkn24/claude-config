#!/bin/bash
# PreToolUse(Bash) wrapper for the optional rtk CLI. No-op (exit 0, no output) when rtk is not installed.
# Skips the rtk rewrite in plan mode (rtk's rewrite is not recognised as read-only there and triggers a prompt),
# for pytest (rtk misreports --collect-only) and for grep -n (rtk drops the matching lines).
command -v rtk >/dev/null 2>&1 || { cat >/dev/null; exit 0; }
input=$(cat)
mode=$(printf '%s' "$input" | python3 -c "import json,sys
try: print(json.load(sys.stdin).get('permission_mode',''))
except Exception: print('')" 2>/dev/null)
[ "$mode" = "plan" ] && exit 0
cmd=$(printf '%s' "$input" | python3 -c "import json,sys
try: print(json.load(sys.stdin).get('tool_input',{}).get('command',''))
except Exception: print('')" 2>/dev/null)
printf '%s' "$cmd" | grep -Eq '(^|[[:space:]/])pytest([[:space:]]|$)' && exit 0
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])grep[[:space:]][^;&|]*(-[[:alpha:]]*n[[:alpha:]]*|--line-number)([[:space:]]|$)' && exit 0
printf '%s' "$input" | rtk hook claude 2>/dev/null
exit 0
