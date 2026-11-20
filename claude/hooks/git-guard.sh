#!/bin/bash
# git-guard (PreToolUse, Bash): ASKS before commit, push, send-pack, remote, any gh command,
# and any git command naming --no-verify, core.hooksPath or alias.
# Local-only machine: these run only if the operator asked for that exact action in the current message.
# bash + grep + sed only; no writes, no network. Mentions inside echo text also ask (errs safe).
# Residual: git aliases the operator defined outside Claude are not seen here; shared/git-hooks is the second layer.
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | sed -e 's/\\[ntr]/ /g')
OPT='(([[:space:]]+(-[Cc]|--git-dir|--work-tree|--namespace)[[:space:]]+[^[:space:]]+)|([[:space:]]+--[A-Za-z-]+(=[^[:space:]]+)?)|([[:space:]]+-[A-Za-z]))*'
B='(^|[^[:alnum:]_.-])'
ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Local-only machine: %s runs only if the operator asked for this exact action in the current message."}}\n' "$1"
  exit 0
}
printf '%s' "$CMD" | grep -Eq "${B}git(\.exe)?${OPT}[[:space:]]+(push|send-pack|commit|remote)([^[:alnum:]_-]|\$)" && ask "a git commit, push or remote action"
printf '%s' "$CMD" | grep -Eq "${B}gh(\.exe)?[[:space:]]" && ask "a gh command"
printf '%s' "$CMD" | grep -Eq "${B}git(\.exe)?[[:space:]].*(--no-verify|core\.hooksPath|alias\.)" && ask "a git command that skips or redefines hooks or aliases"
exit 0
