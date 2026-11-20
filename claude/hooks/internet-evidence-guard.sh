#!/bin/bash
# PostToolUse (WebFetch|WebSearch): injects an evidence-citation reminder into the
# next turn. Deduped per (session_id, prompt_id) so N fetches in one turn inject once;
# fails open (always fires) when either field is missing.
INPUT=$(cat)
KEY=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    s,p=str(d.get("session_id") or ""),str(d.get("prompt_id") or "")
    print(s+"_"+p if s and p else "")
except Exception:
    print("")' 2>/dev/null)

if [ -n "$KEY" ]; then
  DIR="$HOME/.claude/hooks/.state"
  mkdir -p "$DIR" 2>/dev/null
  MARKER="$DIR/evidence_fired_$KEY"
  [ -f "$MARKER" ] && exit 0
  : > "$MARKER" 2>/dev/null
fi

cat <<'MSG'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "EVIDENCE RULE (automatic): external data was just fetched. Every claim derived from it must cite its source inline (URL, date, document name). Quote verbatim when stating a fact; if you cannot quote it, do not assert it. Never put client data in search queries or fetched URLs."
  }
}
MSG
