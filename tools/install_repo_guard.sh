#!/bin/bash
# Installs the for-work local-only git guard (pre-commit, pre-push) into ONE repository, on the operator's request.
# Never sets any core.hooksPath. Refuses (exit 3, changes nothing) when ANY config scope already sets core.hooksPath.
# An existing hook of the same name is kept as <name>.local and still runs after the guard passes (chained).
# Usage: install_repo_guard.sh <repo-path>            install
#        install_repo_guard.sh --remove <repo-path>   restore the saved hooks
# Exit: 0 done, 2 usage or not a repository, 3 hooksPath set somewhere (reported, nothing changed).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; SRC="$HERE/../shared/git-hooks"; MARK="for-work local-only guard"
MODE=install; [ "${1:-}" = "--remove" ] && { MODE=remove; shift; }
[ $# -eq 1 ] || { echo "usage: $0 [--remove] <repo-path>" >&2; exit 2; }
git -C "$1" rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository: $1" >&2; exit 2; }
HP="$(git -C "$1" config --show-origin --get-all core.hooksPath 2>/dev/null)"
if [ -n "$HP" ]; then
  echo "core.hooksPath is already set; nothing changed. The git-level guard is NOT installed here (rely on the agent-level guards). Origins:" >&2
  echo "$HP" >&2; exit 3
fi
HD="$(cd "$1" && git rev-parse --git-path hooks)"; case "$HD" in /*) ;; *) HD="$1/$HD" ;; esac
mkdir -p "$HD" || exit 2
for n in pre-commit pre-push; do
  f="$HD/$n"
  if [ "$MODE" = remove ]; then
    if [ -f "$f" ] && grep -q "$MARK" "$f"; then rm -f "$f"; [ -e "$f.local" ] && mv "$f.local" "$f"; echo "removed guard: $n"; fi
    continue
  fi
  if [ -f "$f" ] && grep -q "$MARK" "$f"; then echo "already installed: $n"; continue; fi
  [ -e "$f.local" ] && { echo "refusing: $f.local already exists, move it first" >&2; exit 2; }
  [ -e "$f" ] && mv "$f" "$f.local"
  cp "$SRC/$n" "$f" && chmod +x "$f" && echo "installed: $n$([ -e "$f.local" ] && echo ' (previous hook chained as '"$n"'.local)')"
done
