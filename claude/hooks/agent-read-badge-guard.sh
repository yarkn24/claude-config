#!/bin/bash
# agent-read-badge-guard (PreToolUse, Read|Bash): per-subagent deny list for what an agent may read.
# Turns "agent X must never read file Y" statements from an agent's own definition into an enforced rule.
# Manifest (JSON), default ~/.claude/agent_read_badges.json, override with AGENT_BADGE_MANIFEST:
#   {"<agent_type>": {"deny": [{"match": "<path substring>", "tool": "Read", "bash": false,
#                               "quote": "<the rule being enforced>", "instead": "<what to do>"}]}}
# "bash": true also applies the rule to whole-file readers in Bash (cat, less, more, nl, strings, xxd, od, pr);
# grep/rg/sed/awk/head/tail stay allowed. Deny list only: unknown paths pass. The main session is never gated.
# No manifest, a broken manifest, or no python3: exit 0 silently.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
OUT=$(INPUT="$INPUT" python3 <<'PYEOF'
import json, os, re, sys
MANIFEST = os.environ.get("AGENT_BADGE_MANIFEST") or os.path.expanduser("~/.claude/agent_read_badges.json")
try:
    d = json.loads(os.environ.get("INPUT", ""))
    badges = json.load(open(MANIFEST, encoding="utf-8"))
except Exception:
    sys.exit(0)
agent = d.get("agent_type")
if not agent:
    sys.exit(0)
tool = d.get("tool_name", "")
ti = d.get("tool_input") or {}
subject = (ti.get("command") or "") if tool == "Bash" else (ti.get("file_path") or "")
if not subject or tool not in ("Read", "Bash"):
    sys.exit(0)
READER = re.compile(r"(?:^|[|;&\x60]|[$]\()\s*(?:sudo\s+)?(?:cat|bat|less|more|nl|strings|xxd|od|pr)\s+((?:[^\s;|&>]+\s*)+)")
def bash_targets(cmd):
    return [t for m in READER.finditer(cmd) for t in m.group(1).split() if not t.startswith("-")]
norm = subject.replace(os.sep, "/")
targets = bash_targets(norm) if tool == "Bash" else [norm]
for r in (badges.get(agent) or {}).get("deny") or []:
    if tool == "Bash" and not r.get("bash"):
        continue
    if tool == "Read" and r.get("tool") not in (None, "", "Read"):
        continue
    if not r.get("match"):
        continue
    hit = next((t for t in targets if r["match"] in t), None)
    if hit:
        print(json.dumps({"agent": agent, "tool": tool, "path": hit, "quote": r.get("quote", ""), "instead": r.get("instead", "")}))
        sys.exit(0)
PYEOF
)
[ -z "$OUT" ] && exit 0
printf '%s' "$OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
sys.stderr.write('[agent-read-badge-guard] BLOCKED: outside this agent area\n  agent : %s\n  tool  : %s\n  target: %s\n  rule  : %s\n  instead: %s\n' % (d['agent'],d['tool'],d['path'],d['quote'],d['instead']))
" 
exit 2
