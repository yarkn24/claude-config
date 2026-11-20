#!/bin/bash
# Hook Self-test (SessionStart): one alarm line when a wired hook file is missing or not executable, or python3 is missing.
# Silent when everything is in place. Hooks are looked up in ~/.claude/hooks and $CLAUDE_PROJECT_DIR/.claude/hooks.
cat >/dev/null
P="${CLAUDE_PROJECT_DIR:-$PWD}"
bad=""
if ! command -v python3 >/dev/null 2>&1; then
  bad="python3 missing: python hooks inactive;"
fi
for h in git-guard delete-guard git-lock-guard system-file-doctrine-gate md-lovable-preguard claude-md-isolation-guard \
  agent-model-skills-guard agent-model-gate opus-concurrency-guard agent-brief-doctrine plan-detail-gate em-dash-guard \
  code-comment-postguard claude-md-size-nudge hooks-dir-verify-guard log-edit md-directive-postguard \
  internet-evidence-guard research-multi-source-tracker md-directive-stopgate research-multi-source-gate log-stop \
  claude-md-audit-reminder opus-concurrency-release; do
  f=""
  for d in "$HOME/.claude/hooks" "$P/.claude/hooks"; do
    [ -f "$d/$h.sh" ] && f="$d/$h.sh" && break
  done
  if [ -z "$f" ]; then bad="$bad missing $h.sh;"
  elif [ ! -x "$f" ]; then bad="$bad not executable $h.sh;"
  fi
done
[ -z "$bad" ] && exit 0
msg=$(printf 'HOOK SELF-TEST: guards may be inactive:%s' "$bad" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$msg"
exit 0
