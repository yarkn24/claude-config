#!/bin/bash
# heavy-script-output-gate (PreToolUse, Bash): scripts known to print huge reports must run quiet or redirected.
# Config: ~/.claude/heavy-scripts.txt, one script substring per line (# comments allowed). Optional flag line:
#   quiet_flag=--quiet   (default --quiet)
# No config file, no match, a redirect (>) or the quiet flag already present: exit 0 silently. Subagents are not gated.
INPUT=$(cat)
CONF="$HOME/.claude/heavy-scripts.txt"
[ -f "$CONF" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
INPUT="$INPUT" CONF="$CONF" python3 <<'PYEOF'
import json, os, sys
try:
    d = json.loads(os.environ.get("INPUT", ""))
    lines = open(os.environ["CONF"], encoding="utf-8").read().splitlines()
except Exception:
    sys.exit(0)
if d.get("agent_type") or d.get("tool_name") != "Bash":
    sys.exit(0)
cmd = (d.get("tool_input") or {}).get("command") or ""
flag, heavy = "--quiet", []
for ln in lines:
    ln = ln.strip()
    if not ln or ln.startswith("#"):
        continue
    if ln.startswith("quiet_flag="):
        flag = ln.split("=", 1)[1].strip() or flag
    else:
        heavy.append(ln)
hit = next((h for h in heavy if h in cmd), None)
if not hit or flag in cmd or ">" in cmd:
    sys.exit(0)
sys.stderr.write("[heavy-script-output-gate] %s prints a large report straight into the session without %s or a redirect.\n"
                 "Use: %s %s\n" % (hit, flag, cmd.rstrip(), flag))
sys.exit(2)
PYEOF
exit $?
