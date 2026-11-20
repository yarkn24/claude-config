#!/bin/bash
# PreToolUse hook, matcher Agent. Caps concurrent `opus` subagents at CAP.
# Each acquired slot is a marker file named by the call's tool_use_id; opus-concurrency-release.sh
# (SubagentStop) frees exactly that marker. Markers older than TTL_MIN, and markers whose subagent
# transcript ends "[Request interrupted" (killed without SubagentStop), are swept first.
CAP=6
TTL_MIN=20
INPUT=$(cat)
STATE_DIR="$HOME/.claude/state/opus_active"
mkdir -p "$STATE_DIR"

TOOL_USE_ID=$(printf '%s' "$INPUT" | STATE_DIR="$STATE_DIR" CAP="$CAP" TTL_MIN="$TTL_MIN" python3 -c "
import glob, json, os, sys, time
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if d.get('tool_name') != 'Agent' or (d.get('tool_input') or {}).get('model') != 'opus':
    sys.exit(0)
state = os.environ['STATE_DIR']
now = time.time()
def markers():
    return [n for n in os.listdir(state) if os.path.isfile(os.path.join(state, n))]
for n in markers():
    p = os.path.join(state, n)
    try:
        if now - os.path.getmtime(p) > int(os.environ['TTL_MIN']) * 60:
            os.remove(p)
    except OSError:
        pass
live = set(markers())
if live:
    pat = os.path.expanduser('~/.claude/projects/*/*/subagents/agent-*.meta.json')
    for meta in glob.glob(pat):
        try:
            if now - os.path.getmtime(meta) > 86400:
                continue
            tid = json.load(open(meta)).get('toolUseId')
            if tid not in live:
                continue
            with open(meta[:-len('.meta.json')] + '.jsonl', 'rb') as f:
                f.seek(0, 2)
                f.seek(max(0, f.tell() - 65536))
                lines = [l for l in f.read().split(b'\n') if l.strip()]
            if lines and b'[Request interrupted' in lines[-1]:
                os.remove(os.path.join(state, tid))
        except Exception:
            pass
active = len(markers())
if active >= int(os.environ['CAP']):
    print('BLOCK %d' % active)
else:
    print('OK ' + (d.get('tool_use_id') or ''))
" 2>/dev/null)

case "$TOOL_USE_ID" in
  BLOCK*)
    echo "[OPUS-CONCURRENCY-GUARD] BLOCKED: at most $CAP opus agents may run at once, ${TOOL_USE_ID#BLOCK } are active. Wait for one to finish, or run this work on sonnet (model: \"sonnet\")." >&2
    exit 2 ;;
  OK*)
    id=${TOOL_USE_ID#OK }
    if [ -n "$id" ]; then touch "$STATE_DIR/$id"; else touch "$STATE_DIR/$(date +%s)_$$_$RANDOM"; fi ;;
esac
exit 0
