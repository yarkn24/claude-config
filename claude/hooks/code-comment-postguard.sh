#!/usr/bin/env bash
# code-comment-postguard.sh - PostToolUse(Edit|Write), .py and .sh, REPORT ONLY.
# Code corpora are deliberately outside the directive-style gate. The reasoning
# and the measurement are in the sibling code_comment_rules.py. This carries
# the ONE check that survived review, and it never blocks: a false positive on a
# markdown file costs a reword, one that blocks a .py write stalls a live run.
set -u
INPUT=$(cat)

OUT=$(INPUT="$INPUT" python3 << 'PYEOF'
import json, os, sys
sys.path.insert(0, os.path.expanduser("~/.claude/hooks"))
try:
    import code_comment_rules as C
except Exception:
    sys.exit(0)
try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)
path = (d.get("tool_input", {}) or {}).get("file_path", "") or ""
if not path.endswith((".py", ".sh")) or not os.path.isfile(path):
    sys.exit(0)
try:
    v = C.check(path, open(path, encoding="utf-8", errors="ignore").read())
except Exception:
    sys.exit(0)
if not v:
    sys.exit(0)
msg = ["CODE COMMENT: %s" % os.path.basename(path)]
for rid, det in v:
    msg.append("  %s %s (%s)" % (rid, C.RULE_TEXT[rid][1], det))
    msg.append("     fix: %s" % C.RULE_TEXT[rid][2])
print(json.dumps({"systemMessage": "\n".join(msg)}))
PYEOF
)
[ -n "$OUT" ] && echo "$OUT"
exit 0
