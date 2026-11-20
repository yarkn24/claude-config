#!/bin/bash
# Mail Read-only Guard (PreToolUse, dormant: wire it only when a mail connector is approved).
# Asks before any mail-connector tool call whose name looks like send, reply, forward or draft-send. Read-only calls pass.
set -u
INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
case "$TOOL" in
  mcp__*) ;;
  *) exit 0 ;;
esac
if printf '%s' "$TOOL" | grep -Eiq '(mail|gmail|outlook|imap|smtp|inbox)'; then
  if printf '%s' "$TOOL" | grep -Eiq '(send|reply|forward|draft.*send|send.*draft)'; then
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"MAIL GUARD: this mail tool would send, reply or forward a message. Confirm the recipient and content first."}}'
  fi
fi
exit 0
