#!/bin/bash
# PreToolUse hook, matcher Edit|Write. Blocks a write to an instruction file that breaks the
# style rules in md_rules.py (the rule text shown comes from the same table as the check).
# Sibling layers: md-directive-postguard.sh (PostToolUse Bash, reports) and
# md-directive-stopgate.sh (Stop, enforces).
set -u
INPUT=$(cat)
HOOK_DIR=$(cd "$(dirname "$0")" && pwd)

OUT=$(INPUT="$INPUT" HOOK_DIR="$HOOK_DIR" python3 << 'PYEOF'
import json, os, sys
sys.path.insert(0, os.environ["HOOK_DIR"])
try:
    import md_rules as M
except Exception:
    sys.exit(0)

try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)

ti = d.get("tool_input", {}) or {}
path = ti.get("file_path", "") or ""
if not path or not M.in_scope(path):
    sys.exit(0)

content = ti.get("content")
if content is None:
    new = ti.get("new_string")
    if new is None:
        edits = ti.get("edits") or []
        new = "\n".join(e.get("new_string", "") for e in edits)
    try:
        base = open(path, encoding="utf-8").read()
    except Exception:
        base = ""
    old = ti.get("old_string")
    content = base.replace(old, new) if (old and old in base) else (base + "\n" + (new or ""))

v = M.check(path, content)
hard = M.blocking(v)
if not v:
    sys.exit(0)
print(json.dumps({"block": bool(hard), "text": M.render(path, v)}))
PYEOF
)

[ -z "$OUT" ] && exit 0
BLOCK=$(echo "$OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['block'])" 2>/dev/null)
echo "$OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['text'])" >&2
[ "$BLOCK" = "True" ] && exit 2
exit 0
