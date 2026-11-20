#!/bin/bash
# Unlazy Approve Guard (PreToolUse, Bash; dormant, ships with the unlazy skill).
# gate-check.mjs's approve flag runs arbitrary shell commands. Two conditions, both required, else ask:
#   1. gate-check.mjs --status was run for the SAME ledger earlier in this session (this hook records each run)
#   2. the description field starts with [UNLAZY-APPROVED] "<the user's exact words this session>"
# The status flag and a bare run are never intercepted. Heredoc bodies are data, not commands.
set -u
INPUT=$(cat)

UNLAZY_GUARD_INPUT="$INPUT" python3 - << 'PYEOF'
import hashlib
import json
import os
import re
import shlex
import sys
import time

RAW = os.environ.get("UNLAZY_GUARD_INPUT", "")
try:
    payload = json.loads(RAW) if RAW else {}
except Exception:
    sys.exit(0)

if payload.get("tool_name") != "Bash":
    sys.exit(0)

tool_input = payload.get("tool_input", {}) or {}
CMD = tool_input.get("command", "") or ""
DESC = tool_input.get("description", "") or ""
SESSION = str(payload.get("session_id") or payload.get("sessionId") or "anon")

STATE = os.path.expanduser("~/.claude/.unlazy_inspections.json")
LOGDIR = os.path.expanduser("~/.claude/logs")
LOG = os.path.join(LOGDIR, "unlazy_approvals.log")
TTL = 3600
APPROVE_FLAG = "--" + "approve"
STATUS_FLAG = "--" + "status"


def allow():
    sys.exit(0)


def ask(msg):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask",
                                             "permissionDecisionReason": msg}}))
    sys.exit(0)


def strip_heredocs(cmd):
    """A heredoc body is data, not a command; drop it before analysis."""
    lines = cmd.split("\n")
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = re.search(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?\s*$", line)
        if m:
            term = m.group(1)
            i += 1
            while i < len(lines) and lines[i].strip() != term:
                i += 1
        i += 1
    return "\n".join(out)


CMD_CODE = strip_heredocs(CMD)

if "gate-check.mjs" not in CMD_CODE:
    allow()

try:
    tokens = shlex.split(CMD_CODE)
except ValueError:
    tokens = CMD_CODE.split()

FLAGS_WITH_VALUE = {"--timeout", "--jobs", "--shell", "--scope"}


def ledger_key(tokens):
    """The .md arguments after gate-check.mjs are the ledger files."""
    seen_script = False
    ledgers = []
    skip_next = False
    for tok in tokens:
        if skip_next:
            skip_next = False
            continue
        if "gate-check.mjs" in tok:
            seen_script = True
            continue
        if not seen_script:
            continue
        if tok in FLAGS_WITH_VALUE:
            skip_next = True
            continue
        if tok.startswith("-"):
            continue
        if not tok.lower().endswith(".md"):
            continue
        ledgers.append(os.path.basename(tok))
    return "|".join(sorted(set(ledgers))) or "<default>"


def load_state():
    try:
        with open(STATE, encoding="utf8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def save_state(data):
    now = time.time()
    pruned = {k: v for k, v in data.items() if now - float(v.get("at", 0)) < TTL}
    tmp = STATE + ".tmp"
    with open(tmp, "w", encoding="utf8") as fh:
        json.dump(pruned, fh)
    os.replace(tmp, STATE)


key = ledger_key(tokens)
is_status = STATUS_FLAG in tokens
is_approve = APPROVE_FLAG in tokens

# Record every inspection run so a later approval can prove it.
if is_status:
    state = load_state()
    state[SESSION + "\x00" + key] = {"at": time.time()}
    try:
        save_state(state)
    except Exception:
        pass
    allow()

if not is_approve:
    allow()

# --- from here on the command wants to run arbitrary shell code ---

state = load_state()
entry = state.get(SESSION + "\x00" + key)
inspected = bool(entry) and (time.time() - float(entry.get("at", 0))) < TTL

consent = re.match(r'^\[UNLAZY-APPROVED\]\s*"([^"]+)"', DESC.strip())

problems = []
if not inspected:
    problems.append("no inspection of '" + key + "' in this session (or older than " + str(TTL // 60) + " minutes)")
if not consent:
    problems.append('description does not start with [UNLAZY-APPROVED] "<the user\'s exact words this session>"')

if problems:
    ask(
        "UNLAZY APPROVE GUARD: this flag runs arbitrary shell commands.\n\n"
        "Ledger: " + key + "\n\nMissing:\n  - " + "\n  - ".join(problems) + "\n\n"
        "Correct order:\n"
        "  1. run gate-check.mjs with the status flag (runs nothing); read every CHECK: line and each script it calls\n"
        "  2. show the CHECK: lines to the user and get their approval\n"
        "  3. rerun with the description set to [UNLAZY-APPROVED] \"<the user's exact words>\""
    )

# The audit-trail write must never crash the hook or swallow a validated approval.
try:
    os.makedirs(LOGDIR, exist_ok=True)
    with open(LOG, "a", encoding="utf8") as fh:
        fh.write(json.dumps({
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
            "session": SESSION[:12],
            "ledger": key,
            "consent": consent.group(1)[:200],
            "cmd_sha256": hashlib.sha256(CMD.encode("utf-8", "replace")).hexdigest()[:16],
        }) + "\n")
except Exception:
    pass

allow()
PYEOF
