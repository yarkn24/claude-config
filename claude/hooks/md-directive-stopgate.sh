#!/bin/bash
# Stop hook, the enforcing layer: scans files git reports as modified this session and blocks
# the stop when an instruction file still breaks a block-severity rule in md_rules.py.
# Honours stop_hook_active so a turn is never blocked twice in a row.
set -u
INPUT=$(cat)
HOOK_DIR=$(cd "$(dirname "$0")" && pwd)

OUT=$(INPUT="$INPUT" HOOK_DIR="$HOOK_DIR" python3 << 'PYEOF'
import json, os, subprocess, sys
sys.path.insert(0, os.environ["HOOK_DIR"])
try:
    import md_rules as M
except Exception:
    sys.exit(0)

try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)

# Documented loop guard: never block a turn we already blocked.
if d.get("stop_hook_active"):
    sys.exit(0)

cwd = d.get("cwd") or os.getcwd()
# Scope: files modified since this session's transcript was created (standing violators stay out).
try:
    t0 = os.stat(d.get("transcript_path") or "").st_birthtime
except Exception:
    sys.exit(0)  # no birth time on this platform: skip, never judge pre-existing files
try:
    # -uall: git collapses a wholly untracked directory to one "?? dir/" entry, and
    # the files inside it would never be scanned.
    r = subprocess.run(["git", "-C", cwd, "status", "--porcelain", "-uall"],
                       capture_output=True, text=True, timeout=10)
    if r.returncode != 0:
        sys.exit(0)
except Exception:
    sys.exit(0)

hard = []
for line in r.stdout.split("\n"):
    if len(line) < 4:
        continue
    path = line[3:].strip().strip('"')
    if " -> " in path:
        path = path.split(" -> ")[-1]
    full = os.path.join(cwd, path)
    if not M.in_scope(full) or not os.path.isfile(full) or os.path.getmtime(full) < t0:
        continue
    try:
        v = M.blocking(M.check(full, open(full, encoding="utf-8").read()))
    except Exception:
        continue
    if v:
        hard.append((path, v))

if not hard:
    sys.exit(0)

msg = ["DIRECTIVE STYLE GATE: %d uncommitted file(s) violate the standard. "
       "Fix them now, then finish." % len(hard)]
for path, v in hard[:8]:
    msg.append("  %s" % path)
    for rid, det in v:
        msg.append("    %s %s (%s)" % (rid, M.RULE_TEXT[rid][1], det))
        msg.append("       fix: %s" % M.RULE_TEXT[rid][2])
msg.append("STANDARD: English, Lovable style, instructions only, leanest possible. "
           "An explanation survives only as ONE <!-- WHY: ... --> line under the rule.")
print(json.dumps({"continue": False, "reason": "\n".join(msg)}))
PYEOF
)

[ -n "$OUT" ] && echo "$OUT"
exit 0
