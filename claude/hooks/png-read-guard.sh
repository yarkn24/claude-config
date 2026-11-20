#!/bin/bash
# png-read-guard (PreToolUse, Read): blocks reading an image file into context (an image costs tens of thousands
# of tokens). Reference images by path instead. Escape hatch for a deliberate look at one image:
#   mkdir -p ~/.claude/state && touch ~/.claude/state/png_read_allow     (opens a 15 minute window, then expires)
# Fails safe: anything unparseable or a non-image path exits 0.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
OUT=$(INPUT="$INPUT" python3 <<'PYEOF'
import json, os, sys, time
try:
    d = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)
path = (d.get("tool_input") or {}).get("file_path") or ""
if os.path.splitext(path)[1].lower() not in (".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff"):
    sys.exit(0)
hatch = os.path.expanduser("~/.claude/state/png_read_allow")
try:
    if os.path.exists(hatch) and (time.time() - os.path.getmtime(hatch)) < 15 * 60:
        sys.exit(0)
except Exception:
    pass
size = ""
try:
    n = os.path.getsize(path)
    size = " (%s bytes on disk, roughly %s tokens once attached)" % (format(n, ","), format(n // 4, ","))
except Exception:
    pass
print("[png-read-guard] BLOCKED: Read on an image puts the whole image into context%s.\n  file: %s\n"
      "  Reference the image by path, or extract the fact you need as text.\n"
      "  If the operator explicitly asked you to look at it: mkdir -p ~/.claude/state && touch ~/.claude/state/png_read_allow\n"
      "  (15 minute window, expires by itself)." % (size, path))
PYEOF
)
if [ -n "$OUT" ]; then echo "$OUT" >&2; exit 2; fi
exit 0
