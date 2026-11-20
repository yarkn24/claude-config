#!/bin/bash
# PreToolUse (Edit|Write|MultiEdit|NotebookEdit and Bash): blocks the FIRST system-file
# write of a session with the build doctrine, then stays silent. Bash is covered because
# heredoc writes are the main path into protected dirs.
set -uo pipefail

DOC="$HOME/.claude/reference/while_building_a_system.md"
[ -r "$DOC" ] || exit 0

INPUT=$(cat)

OUT=$(printf '%s' "$INPUT" | python3 -c '
import json,re,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit()
print("SID=" + str(d.get("session_id") or "nosession"))
ti=d.get("tool_input") or {}
fp=ti.get("file_path")
if fp:
    print(fp.replace("\\", "/")); sys.exit()
cmd=ti.get("command") or ""
if not re.search(r">|\btee\b", cmd):
    sys.exit()
pats=[r"(?<![-<>])>>?\s*([^\s;|&<>\"\x27]+)", r"\btee\s+(?:-a\s+)?([^\s;|&<>\"\x27]+)"]
seen=set()
for p in pats:
    for m in re.findall(p,cmd):
        m=m.strip("\"\x27")
        # A write target is a PATH: it has a separator or a file extension.
        if not m or m.startswith("&") or m in seen:
            continue
        if "/" not in m and not re.search(r"\.[A-Za-z0-9]{1,6}$", m):
            continue
        seen.add(m); print(m)
' 2>/dev/null)

SID=$(printf '%s\n' "$OUT" | sed -n 's/^SID=//p' | head -1)
TARGETS=$(printf '%s\n' "$OUT" | grep -v '^SID=')
[ -n "$TARGETS" ] || exit 0

FLAGDIR="$HOME/.claude/hooks/.state"
FLAG="$FLAGDIR/doctrine_shown_${SID:-nosession}"
[ -f "$FLAG" ] && exit 0

RELEVANT=0
while IFS= read -r FP; do
  [ -n "$FP" ] || continue
  case "$FP" in
    /dev/*|/tmp/*|/private/tmp/*|*.log|*.tmp) continue ;;
    *.pdf|*.png|*.jpg|*.jpeg|*.svg|*.docx|*.xlsx|*.pptx) continue ;;
  esac
  RELEVANT=1; break
done <<< "$TARGETS"

[ "$RELEVANT" -eq 1 ] || exit 0

mkdir -p "$FLAGDIR" 2>/dev/null
: > "$FLAG"

{
  echo "BUILD DOCTRINE (shown once per session, before your first system-file write)."
  echo "Re-issue this call after reading. Later writes are not interrupted."
  echo
  cat "$DOC"
} >&2
exit 2
