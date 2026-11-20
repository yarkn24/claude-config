#!/bin/bash
# SessionStart: when a project has CLAUDE.md and no AGENTS.md (file or symlink), link AGENTS.md -> CLAUDE.md.
# Gives other coding agents the same instructions with one source of truth. Never overwrites an existing AGENTS.md. Silent.
cat >/dev/null 2>&1
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
if [ -f "$dir/CLAUDE.md" ] && [ ! -e "$dir/AGENTS.md" ] && [ ! -L "$dir/AGENTS.md" ]; then
  ln -s CLAUDE.md "$dir/AGENTS.md" 2>/dev/null
fi
exit 0
