#!/bin/bash
# Em Dash Guard (PostToolUse, Edit|Write|MultiEdit): warns, never blocks, when a written file holds an em or en dash.
# The warning names the file and line so the dash can be replaced with a comma, colon, parentheses or a hyphen.
set -u
INPUT=$(cat)
IFS= read -r -d '' PY <<'PYEOF' || true
import json, os, re
try:
    d = json.loads(os.environ["INPUT"])
except Exception:
    raise SystemExit
ti = d.get("tool_input") or {}
if d.get("tool_name") not in ("Edit", "Write", "MultiEdit"):
    raise SystemExit
path = ti.get("file_path") or ""
if not path or re.search(r"\.(lock|png|jpe?g|gif|pdf|zip|ico|gz|tar|pyc|so|dylib|dll)$|(^|/)(node_modules|\.git)/", path, re.I):
    raise SystemExit
DASH = re.compile("[" + chr(0x2014) + chr(0x2013) + "]")
try:
    with open(os.path.expanduser(path), encoding="utf-8") as fh:
        lines = fh.read().splitlines()
except (OSError, UnicodeDecodeError):
    raise SystemExit
hits = [i for i, l in enumerate(lines, 1) if DASH.search(l)]
if hits:
    shown = ", ".join(str(i) for i in hits[:10]) + (" ..." if len(hits) > 10 else "")
    msg = "EM DASH WARNING: {} has an em/en dash on line(s) {}. Replace with a comma, colon, parentheses or a plain hyphen.".format(path, shown)
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
PYEOF
printf '%s' "$PY" | INPUT="$INPUT" python3 - 2>/dev/null
exit 0
