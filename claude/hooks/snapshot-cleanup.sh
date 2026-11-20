#!/bin/bash
# SessionStart: delete browser-MCP snapshot files older than 1 day from .playwright-mcp folders
# in $HOME and the current project. Only the named snapshot/console/screenshot patterns; silent; exits 0 always.
cat >/dev/null 2>&1
for d in "$HOME/.playwright-mcp" "${CLAUDE_PROJECT_DIR:-$PWD}/.playwright-mcp"; do
  [ -d "$d" ] && find "$d" -type f \( -name '*.yml' -o -name 'page-*' -o -name 'console-*' -o -name '*.png' \) -mtime +1 -delete 2>/dev/null
done
exit 0
