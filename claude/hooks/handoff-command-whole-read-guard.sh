#!/bin/bash
# PreToolUse hook, matcher Read|Bash. Blocks whole-file reads of HANDOFF_*.md and
# .claude/commands/*.md from the main session (large files re-read every session and after every
# compaction). Replacement: grep -n '^## ' for a section index, then sed -n 'X,Yp' for one section.
# Subagents (agent_type present) are never gated.
INPUT=$(cat)
printf '%s' "$INPUT" | python3 -c "
import json, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get('agent_type'):
    sys.exit(0)
tool = d.get('tool_name', '')
ti = d.get('tool_input') or {}
TARGET = re.compile(r'(HANDOFF_[^/\s\"\']*\.md|\.claude/commands/[^/\s\"\']*\.md)$')
READER = re.compile(r'(?:^|[;&|]\s*)(cat|head)\s+[^|;&]*\.md\b')
path = None
if tool == 'Read':
    fp = ti.get('file_path') or ''
    if TARGET.search(fp):
        path = fp
elif tool == 'Bash':
    cmd = ti.get('command') or ''
    if READER.search(cmd):
        m = re.search(r'(HANDOFF_[^\s\"\']*\.md|\.claude/commands/[^\s\"\']*\.md)', cmd)
        if m:
            path = m.group(1)
if not path:
    sys.exit(0)
sys.stderr.write('HANDOFF/COMMAND FULL-READ BLOCKED: read %s by section instead.\n'
                 '  1) grep -n \"^## \" %s     # section index\n'
                 '  2) sed -n \"X,Yp\" %s      # only the section you need\n' % (path, path, path))
sys.exit(2)
"
exit $?
