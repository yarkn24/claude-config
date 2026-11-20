#!/bin/bash
# SubagentStop hook. Frees the opus-concurrency slot this subagent acquired.
# opus-concurrency-guard.sh names each marker by the Agent call's tool_use_id; SubagentStop only
# gives agent_id, so the id is resolved from the harness-written, read-only file
# ~/.claude/projects/*/<session_id>/subagents/agent-<agent_id>.meta.json (cwd is never used).
INPUT=$(cat)
STATE_DIR="$HOME/.claude/state/opus_active"

TOOL_USE_ID=$(printf '%s' "$INPUT" | python3 -c "
import glob, json, os, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
agent_id = d.get('agent_id') or ''
session_id = d.get('session_id') or ''
# Harness-issued ids only; never build a path from anything else.
if not re.fullmatch(r'[A-Za-z0-9_-]+', agent_id) or not re.fullmatch(r'[A-Za-z0-9_-]+', session_id):
    sys.exit(0)
hits = glob.glob(os.path.expanduser('~/.claude/projects/*/%s/subagents/agent-%s.meta.json' % (session_id, agent_id)))
if not hits:
    sys.exit(0)
try:
    meta = json.load(open(hits[0]))
except Exception:
    sys.exit(0)
if meta.get('model') == 'opus' and meta.get('toolUseId'):
    print(meta['toolUseId'])
" 2>/dev/null)

[ -z "$TOOL_USE_ID" ] && exit 0
rm -f "$STATE_DIR/$TOOL_USE_ID"
exit 0
