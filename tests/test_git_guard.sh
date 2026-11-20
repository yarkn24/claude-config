#!/bin/bash
# Feeds sample Bash tool events to claude/hooks/git-guard.sh. Expects "ask" or empty output; exits non-zero on any FAIL.
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="${GIT_GUARD_HOOK:-$HERE/../claude/hooks/git-guard.sh}"
fail=0
check() { # expect cmd
  local expect="$1" cmd="$2" json out
  json=$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd")
  out=$(printf '%s' "$json" | bash "$HOOK")
  if [ "$expect" = ask ]; then
    case "$out" in *'"permissionDecision":"ask"'*) echo "PASS ask    : $cmd";; *) echo "FAIL (wanted ask, got '${out:0:40}'): $cmd"; fail=1;; esac
  else
    [ -z "$out" ] && echo "PASS empty  : $cmd" || { echo "FAIL (wanted empty, got ask): $cmd"; fail=1; }
  fi
}
for c in 'git push' 'git push origin main' 'git -C . push origin main' 'git -c push.default=current push' \
  'git --no-pager push' 'cd repo && git push' '/usr/bin/git push' 'echo a\ngit push' \
  'git commit -m x' 'git commit --no-verify -m x' 'git -c core.hooksPath=/dev/null commit -m x' \
  'git remote add origin u' 'gh pr create --fill' 'gh repo create x' 'git config alias.p push'; do check ask "$c"; done
for c in 'git status' 'git log --grep push' 'git diff' 'ls gh-pages'; do check empty "$c"; done
[ "$fail" = 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
