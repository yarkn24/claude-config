#!/bin/bash
# parallel-playwright-guard (PreToolUse, Playwright MCP tools): blocks a second session from driving the browser
# while another session used it within the last 90 seconds (parallel sessions contaminate each other's tabs).
# Mechanism: a lock file holding "<session_id> <epoch>". Same session: always allowed. Different session inside the
# TTL: blocked. Limit: a subagent sharing the parent's session_id is not detected. Fails safe: exits 0 on any problem.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
INPUT="$INPUT" python3 <<'PYEOF'
import json, os, sys, time
try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)
if "playwright" not in str(d.get("tool_name", "")).lower():
    sys.exit(0)
LOCK = os.path.join(os.environ.get("TMPDIR") or "/tmp", "claude_playwright_session.lock")
TTL = 90
sid = str(d.get("session_id", "") or "unknown")
now = time.time()
other = None
if os.path.exists(LOCK):
    try:
        parts = open(LOCK).read().split()
        if (now - float(parts[1])) < TTL and parts[0] != sid:
            other = parts[0]
    except Exception:
        other = None
if other:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
        "permissionDecisionReason": "[parallel-playwright-guard] Another active session (%s) used Playwright within the last %ds. "
        "Parallel browser sessions contaminate each other's tabs. Wait for the other session to finish; the lock expires by itself." % (other[:12], TTL)}}))
else:
    try:
        open(LOCK, "w").write("%s %s" % (sid, now))
    except Exception:
        pass
PYEOF
exit 0
