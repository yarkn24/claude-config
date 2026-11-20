#!/bin/bash
# main-context-diet-guard (PostToolUse, any tool): REPORT ONLY, never blocks.
# The main session context is re-billed every turn, so one oversized tool result is paid for repeatedly.
# When a tool result in the main session exceeds LIMIT bytes (default 25000, env CONTEXT_DIET_LIMIT), add a short
# note with a cheaper alternative. Silent below the limit and for subagents. Fails safe: exits 0 on any problem.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
OUT=$(INPUT="$INPUT" python3 <<'PYEOF'
import json, os, sys
try:
    LIMIT = int(os.environ.get("CONTEXT_DIET_LIMIT", "25000"))
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)
if d.get("agent_type"):
    sys.exit(0)
resp = d.get("tool_response")
if resp is None:
    resp = d.get("tool_result")
if resp is None:
    sys.exit(0)
try:
    n = len(json.dumps(resp))
except Exception:
    sys.exit(0)
if n <= LIMIT:
    sys.exit(0)
tool = d.get("tool_name", "?")
ti = d.get("tool_input") or {}
hints = {
    "Read": 'grep -n "^## " the file for a line number, then Read with offset/limit.',
    "Bash": "Add a quiet/json flag, cap the loop, or write a file and echo its path.",
    "Grep": "Narrow the pattern, add -m N, or use output_mode=count.",
    "Glob": "Narrow the pattern, or pipe through head.",
    "WebFetch": "Ask a narrower prompt so the page comes back summarised, not whole.",
    "WebSearch": "Tighten the query, or fetch only the one result you need.",
}
hint = hints.get(tool) or ("Request fewer rows or fields, or persist the payload to a file and pass its path on."
                           if tool.startswith("mcp__") else "Write it to a file and pass the path instead of the content.")
what = ti.get("file_path") or str(ti.get("command", ""))[:80]
msg = "[main-context-diet] %s returned %s bytes (~%s tokens) into the main context, over the %s byte budget." % (
    tool, format(n, ","), format(n // 4, ","), format(LIMIT, ","))
if what:
    msg += "\n  target : %s" % what
msg += "\n  cheaper: %s" % hint
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
PYEOF
)
[ -n "$OUT" ] && echo "$OUT"
exit 0
