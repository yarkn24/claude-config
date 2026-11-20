#!/bin/bash
# PreToolUse hook, matcher Write|Edit|MultiEdit, scoped to .claude/agents/*.md.
#   1. BLOCK: the agent definition has no `model:` line or a blank value (an omitted model
#      resolves to the parent session's model, so the tier becomes an accident).
#   2. WARN (non-blocking): description+body reads like it runs a test suite or writes a
#      handoff but no `skills:` field names a skill, so the agent may reimplement ad hoc.
# Note: bash 3.2 scans inside $( ... ) even for a quoted heredoc, so avoid a literal \' in the
# python body (use \x27). Re-run `bash -n` after any edit.
set -u
INPUT=$(cat)

# Cheap scope short-circuit: this hook is on every Write|Edit|MultiEdit, so do not pay a
# python startup for the overwhelming majority of writes that cannot be an agent definition.
case "$INPUT" in
  *'.claude/agents/'*) ;;
  *) exit 0 ;;
esac

OUT=$(INPUT="$INPUT" python3 << 'PYEOF'
import json, os, re, sys

try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)

ti = d.get("tool_input", {}) or {}
path = ti.get("file_path", "") or ""
if not path or not re.search(r'(^|/)\.claude/agents/[^/]+\.md$', path):
    sys.exit(0)

FIX = ("Add model: opus | sonnet | haiku to the frontmatter before writing this file. "
       "`inherit` resolves through CLAUDE_CODE_SUBAGENT_MODEL (if set) down to the parent "
       "session's model, so only use it with a stated reason, not as a default.")

content = ti.get("content")
full_write = content is not None
if not full_write:
    try:
        base = open(path, encoding="utf-8").read()
    except Exception:
        base = ""
    # Each edit is applied in order, so a MultiEdit that DELETES the model line is seen as a
    # deletion. Appending the new_strings instead (the Write|Edit-only shape) would leave the
    # old frontmatter intact and let that deletion through.
    edits = ti.get("edits")
    if not edits:
        edits = [{"old_string": ti.get("old_string"), "new_string": ti.get("new_string")}]
    content = base
    for e in edits:
        o = e.get("old_string") or ""
        n = e.get("new_string") or ""
        content = content.replace(o, n) if (o and o in content) else (content + "\n" + n)

m = re.match(r'^---\n(.*?)\n---\n?(.*)$', content, re.S)
if not m:
    if full_write:
        print(json.dumps({
            "block": True,
            "text": ("[AGENT-MODEL-SKILLS-GUARD] BLOCKED: %s has no YAML frontmatter, so it has "
                     "no `model:` line and is not a loadable agent definition (`name:` and "
                     "`description:` are required fields). %s" % (path, FIX)),
        }))
    sys.exit(0)
front, body = m.group(1), m.group(2)

mm = re.search(r'^model:\s*(.*)$', front, re.M)
val = mm.group(1).strip().strip("\"'") if mm else ""
if not val:
    print(json.dumps({
        "block": True,
        "text": ("[AGENT-MODEL-SKILLS-GUARD] BLOCKED: %s has no `model:` line in its "
                 "frontmatter, or its value is blank. An omitted model resolves through "
                 "CLAUDE_CODE_SUBAGENT_MODEL (if set) down to the parent session's model, so "
                 "the tier becomes an accident (agent-model-gate.sh blocks the same failure "
                 "mode on live Agent calls). %s" % (path, FIX)),
    }))
    sys.exit(0)

if re.search(r'^skills:\s*\S', front, re.M):
    sys.exit(0)

desc_m = re.search(r'^description:\s*(.*)$', front, re.M)
scan_text = (desc_m.group(1) if desc_m else "") + "\n" + body

ACTION_PATTERNS = [
    (r'\b(run|running|runs|execute|executing|executes)\b[^.,;\n]{0,30}'
     r'\b(test suite|pytest|unit test|unit tests|regression test|regression tests)\b',
     "running tests"),
    (r'\b(write|writing|writes|produce|producing|produces|draft|drafting|drafts|'
     r'generate|generating|generates)\b[^.,;\n]{0,30}\bhandoff\b',
     "writing a session handoff doc"),
]

def negated(text, start):
    window = text[max(0, start - 30):start]
    return bool(re.search(r'\b(not|never|n\x27t|do not|does not|no longer|if)\s*$', window, re.I))

hit = None
for pat, label in ACTION_PATTERNS:
    for mo in re.finditer(pat, scan_text, re.I):
        if negated(scan_text, mo.start()):
            continue
        hit = label
        break
    if hit:
        break

if hit:
    print(json.dumps({
        "block": False,
        "text": ("[AGENT-MODEL-SKILLS-GUARD] WARN: %s reads like it performs a skill-covered "
                 "action (%s) but its frontmatter has no `skills:` field. If a skill already "
                 "covers this action, name it in `skills:` so the agent loads it instead of "
                 "reimplementing the action ad hoc. If no skill covers it, ignore this."
                 % (path, hit)),
    }))
PYEOF
)

[ -z "$OUT" ] && exit 0
BLOCK=$(echo "$OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['block'])" 2>/dev/null)
echo "$OUT" | python3 -c "import json,sys; print(json.load(sys.stdin)['text'])" >&2
[ "$BLOCK" = "True" ] && exit 2
exit 0
