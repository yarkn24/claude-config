#!/bin/bash
# OPTIONAL, not wired by default. PreToolUse hook for the main session only: blocks work tools
# (Bash, Read, Edit, Write, Grep, Glob, web tools, MCP tools) so the main session dispatches
# work to subagents and reads their one-line verdicts. Fail-open on unparseable input.
# Passes: dispatch/control tools, any call made inside a subagent (agent_id present),
# Read in plan mode, and Write/Edit of files under ~/.claude/plans in plan mode.
# Wire with matcher: ^(Bash|Read|Edit|Write|MultiEdit|Grep|Glob|WebFetch|WebSearch|NotebookEdit)$|^mcp__
INPUT=$(cat)
DECISION=$(printf '%s' "$INPUT" | python3 -c "
import json, os, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print('PASS'); sys.exit(0)
tool = d.get('tool_name', '')
ti = d.get('tool_input') or {}
if tool in ('Agent', 'Task', 'SendMessage', 'ListAgents', 'SubagentHandback') or d.get('agent_id'):
    print('PASS'); sys.exit(0)
if d.get('permission_mode') == 'plan':
    if tool == 'Read':
        print('PASS'); sys.exit(0)
    if tool in ('Write', 'Edit', 'MultiEdit') and ti.get('file_path'):
        plans = os.path.realpath(os.path.expanduser('~/.claude/plans'))
        target = os.path.realpath(os.path.expanduser(ti['file_path']))
        if target == plans or target.startswith(plans + os.sep):
            print('PASS'); sys.exit(0)
print('BLOCK')
" 2>/dev/null)
if [ "$DECISION" = "BLOCK" ]; then
  echo "The main session only plans and reads verdicts: dispatch this work to a subagent (Agent, model stated)." >&2
  exit 2
fi
exit 0
