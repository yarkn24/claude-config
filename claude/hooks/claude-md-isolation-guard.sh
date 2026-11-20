#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit): ~/.claude/CLAUDE.md loads into every project session,
# so project-specific names must not be written into it. Blocks an edit whose new text
# contains the name of a project folder under $CLAUDE_PROJECTS_ROOT.
# CLAUDE_PROJECTS_ROOT unset or not a directory: the guard does nothing.
set -u
INPUT=$(cat)
[ -n "${CLAUDE_PROJECTS_ROOT:-}" ] && [ -d "$CLAUDE_PROJECTS_ROOT" ] || exit 0

RESULT=$(INPUT="$INPUT" python3 <<'PYEOF'
import os, json, re, sys

try:
    data = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)

tool = data.get("tool_name", "")
ti = data.get("tool_input", {}) or {}
guarded = os.path.abspath(os.path.expanduser("~/.claude/CLAUDE.md"))
p = ti.get("file_path") or ""
path = os.path.abspath(os.path.expanduser(p)) if p else ""
if path != guarded:
    sys.exit(0)

if tool == "Edit":
    texts = [ti.get("new_string", "")]
elif tool == "Write":
    texts = [ti.get("content", "")]
elif tool == "MultiEdit":
    texts = [e.get("new_string", "") for e in ti.get("edits", []) or []]
else:
    sys.exit(0)

root = os.environ.get("CLAUDE_PROJECTS_ROOT", "")
try:
    names = [n for n in os.listdir(root)
             if len(n) >= 4 and not n.startswith(".") and os.path.isdir(os.path.join(root, n))]
except OSError:
    sys.exit(0)
if not names:
    sys.exit(0)
pattern = re.compile("|".join(re.escape(n) for n in names), re.IGNORECASE)

hits = []
for text in texts:
    if not isinstance(text, str):
        continue
    for m in pattern.finditer(text):
        ctx = text[max(0, m.start() - 40):m.start() + 40].replace("\n", " ")
        hits.append("'%s' -> '...%s...'" % (m.group(0), ctx))

if hits:
    msg = ("[CLAUDE.MD ISOLATION GUARD] " + path + " loads in EVERY project. "
           "Project-specific names do not belong here.\n\nFound:\n- " + "\n- ".join(hits) +
           "\n\nFix: move the detail into that project's own CLAUDE.md and leave only a generic "
           "pointer here. Then retry.")
    print(json.dumps({"decision": "block", "reason": msg}))
PYEOF
)
[ -n "$RESULT" ] && echo "$RESULT"
exit 0
