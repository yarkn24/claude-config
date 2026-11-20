#!/bin/bash
# Git Lock Guard (PreToolUse, Bash): asks before rm/mv/unlink of a git *.lock file (.git/index.lock etc.).
# A lock marks a live git process (often a long pre-commit hook); reads (ls, stat, cat) pass.
set -u
INPUT=$(cat)
IFS= read -r -d '' PY <<'PYEOF' || true
import json, os, re, shlex
try:
    d = json.loads(os.environ["INPUT"])
except Exception:
    print("ok"); raise SystemExit
if d.get("tool_name") != "Bash":
    print("ok"); raise SystemExit
cmd = d.get("tool_input", {}).get("command", "")
out, tag = [], None
for line in cmd.split("\n"):
    if tag is not None:
        if line.strip() == tag: tag = None
        continue
    out.append(line)
    m = re.search(r"<<-?\s*([\x27\"]?)([A-Za-z_]\w*)\1", line)
    if m: tag = m.group(2)
LOCK = re.compile(r"(^|/)\.git/(?:[^/\s]+/)*[^/\s]*\.lock$")
WRAP = {"sudo", "command", "env", "exec", "nohup", "time", "xargs"}
for seg in re.split(r"[;&|()`\n]+", "\n".join(out)):
    try:
        toks = shlex.split(seg)
    except ValueError:
        toks = seg.split()
    while toks and (toks[0] in WRAP or re.match(r"\w+=", toks[0]) or toks[0].startswith("-")):
        toks.pop(0)
    if toks and os.path.basename(toks[0]) in ("rm", "mv", "unlink") and any(LOCK.search(t) for t in toks[1:]):
        print("ask"); raise SystemExit
print("ok")
PYEOF
RES=$(printf '%s' "$PY" | INPUT="$INPUT" python3 - 2>/dev/null)
if [ "$RES" = "ask" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"GIT LOCK GUARD: a .git/*.lock file marks a live git process (often a long pre-commit hook). Removing or moving it can corrupt the commit. Wait for the git process to exit (check with ps), then retry."}}'
fi
exit 0
