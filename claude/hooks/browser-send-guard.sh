#!/bin/bash
# Browser Send Guard (PreToolUse, dormant: wire it only when a browser MCP is approved).
# Asks before a browser tool call that looks like sending a mail, message, DM, invite or reply, or clicks a Send button.
set -u
INPUT=$(cat)
IFS= read -r -d '' PY <<'PYEOF' || true
import json, os, re
d = json.loads(os.environ["INPUT"])
tool = d.get("tool_name", "")
if not (tool.startswith("mcp__") and re.search(r"browser|playwright|chrome", tool, re.I)):
    raise SystemExit
blob = json.dumps(d.get("tool_input", {})).lower()
reason = ""
if re.search(r"(send|submit)[^a-z]{0,40}(mail|email|message|dm|inmail|invite|reply)", blob):
    reason = "send-intent pattern in tool_input"
else:
    for label in ('"send"', '"send message"', '"send invitation"', '"reply"'):
        if label in blob:
            reason = "send-labeled element: " + label
            break
if reason:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask",
        "permissionDecisionReason": "BROWSER SEND GUARD: " + reason + ". Confirm before sending anything from the browser."}}))
PYEOF
printf '%s' "$PY" | INPUT="$INPUT" python3 - 2>/dev/null
exit 0
