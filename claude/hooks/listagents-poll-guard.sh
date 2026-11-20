#!/bin/bash
# listagents-poll-guard (PreToolUse, ListAgents): caps polling of the agent list in the main session.
# A finished agent delivers a completion notification by itself, so a polling loop only burns turns.
# The first ALLOWANCE calls per session pass (default 3, env LISTAGENTS_ALLOWANCE); the next one is blocked.
# Counter: $TMPDIR/claude_listagents_<session_id>. Subagents are not gated. Fails safe: exits 0 on any problem.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
INPUT="$INPUT" python3 <<'PYEOF'
import json, os, re, sys
try:
    d = json.loads(os.environ.get("INPUT", ""))
    allowance = int(os.environ.get("LISTAGENTS_ALLOWANCE", "3"))
except Exception:
    sys.exit(0)
if d.get("tool_name") != "ListAgents" or d.get("agent_type"):
    sys.exit(0)
sid = re.sub(r"[^A-Za-z0-9_-]", "", str(d.get("session_id", "") or "unknown"))[:64]
f = os.path.join(os.environ.get("TMPDIR") or "/tmp", "claude_listagents_" + sid)
try:
    n = int(open(f).read().strip() or 0) + 1
except Exception:
    n = 1
try:
    open(f, "w").write(str(n))
except Exception:
    sys.exit(0)
if n <= allowance:
    sys.exit(0)
sys.stderr.write("[listagents-poll-guard] ListAgents call #%d is past the allowance of %d for this session.\n"
                 "Do not poll: a dispatched agent's completion notification arrives automatically. "
                 "Continue other work or answer the user in the meantime.\n" % (n, allowance))
sys.exit(2)
PYEOF
exit $?
