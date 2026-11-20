#!/bin/bash
# PostToolUse hook, matcher Bash. Edit|Write gates cannot see heredoc, cp or python writes, so
# this scans files git reports as modified since the previous Bash call and REPORTS violations
# (PostToolUse cannot block; md-directive-stopgate.sh enforces).
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
cwd = d.get("cwd") or os.getcwd()
# Scope: files modified since this session's previous Bash call (first call: session start).
mark = os.path.expanduser("~/.claude/state/md_postguard/%s" % (d.get("session_id") or "nosession"))
try:
    t0 = os.path.getmtime(mark)
except Exception:
    try:
        t0 = os.stat(d.get("transcript_path") or "").st_birthtime
    except Exception:
        # No birth time (Linux, older Windows Python): skip, never judge pre-existing files.
        t0 = None
try:
    os.makedirs(os.path.dirname(mark), exist_ok=True)
    open(mark, "a").close()
    os.utime(mark)
except Exception:
    pass
if t0 is None:
    sys.exit(0)

try:
    # -uall: git collapses a wholly untracked directory to one "?? dir/" entry, and
    # the files inside it would never be scanned.
    r = subprocess.run(["git", "-C", cwd, "status", "--porcelain", "-uall"],
                       capture_output=True, text=True, timeout=10)
    if r.returncode != 0:
        sys.exit(0)
except Exception:
    sys.exit(0)

hits = []
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
        v = M.check(full, open(full, encoding="utf-8").read())
    except Exception:
        continue
    if v:
        hits.append((path, v))

if not hits:
    sys.exit(0)

lines = ["DIRECTIVE STYLE: %d file(s) written outside the Edit/Write gate still "
         "violate the standard. Fix before the turn ends; the Stop hook blocks on these."
         % len(hits)]
for path, v in hits[:6]:
    ids = ", ".join("%s(%s)" % (rid, det) for rid, det in v)
    lines.append("  %s: %s" % (path, ids))
    for rid, _ in v[:2]:
        lines.append("      %s -> %s" % (M.RULE_TEXT[rid][1], M.RULE_TEXT[rid][2]))
print(json.dumps({"systemMessage": "\n".join(lines)}))
PYEOF
)

[ -n "$OUT" ] && echo "$OUT"
exit 0
