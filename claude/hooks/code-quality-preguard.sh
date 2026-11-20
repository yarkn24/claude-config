#!/bin/bash
# code-quality-preguard (PreToolUse, Edit|Write|MultiEdit|NotebookEdit): file-writing hygiene for any file type.
# BLOCKS: (1) debug leftovers (pdb, breakpoint(), debugger;, DEBUG-tagged prints), (2) unresolved placeholders
# ("your code here", "... existing code ...", lorem ipsum), (3) literal secrets (key/token shapes, private key headers).
# WARNS (context note, never an allow): Write over an existing non-trivial file where Edit is usually the better fit.
# Fails safe: unparseable input or a missing python3 exits 0 silently.
INPUT=$(cat)
command -v python3 >/dev/null 2>&1 || exit 0
INPUT="$INPUT" python3 <<'PYEOF'
import os, json, sys, re

try:
    data = json.loads(os.environ.get("INPUT", ""))
except Exception:
    sys.exit(0)

tool = data.get("tool_name", "")
ti = data.get("tool_input", {}) or {}

NON_TEXT_PATH_RE = re.compile(
    r"\.(lock|min\.js|map|png|jpe?g|gif|pdf|zip|woff2?|ico|gz|tar|whl|pyc|so|dylib|dll)$"
    r"|(^|/)(package-lock\.json|pnpm-lock\.yaml|composer\.lock)$", re.I)
NON_TEXT_DIR_RE = re.compile(r"(^|/)(node_modules|\.git)(/|$)")
DEBUG_RE = re.compile(
    r"\bimport\s+pdb\b|\bpdb\.set_trace\(\)|\bbreakpoint\(\)|(?<![\w.])debugger\s*;"
    r"|console\.log\([^)]*\[(?:DEBUG|TEMP|TEST|REMOVE)\b"
    r"|print\(\s*[\"'](?:DEBUG|TEMP|REMOVE ME)\b", re.I)
PLACEHOLDER_RE = re.compile(
    r"your code here|insert your logic here|implement this (?:function|method)\b"
    r"|\.\.\.\s*(?:rest of the|existing)\s+code(?:\s+(?:here|goes here))?"
    r"|//\s*\.\.\.\s*existing code\s*\.\.\.|lorem ipsum", re.I)
SECRET_RE = re.compile(
    r"sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}"
    r"|xox[baprs]-[0-9a-zA-Z-]{10,}|-----BEGIN (?:RSA |EC |OPENSSH |)PRIVATE KEY-----"
    r"|\b(?:password|api_key|apikey|secret_key|access_token)\s*[:=]\s*[\"'][^\"'\s]{8,}[\"']", re.I)
# env-var and placeholder-style reads are not leaked secrets
SECRET_EXEMPT_RE = re.compile(
    r"os\.environ|process\.env|getenv|ENV\[|<[A-Z_]+>|\$\{|your[-_ ]?api[-_ ]?key|xxxx|\*{4,}", re.I)

def exempt(path):
    return isinstance(path, str) and bool(path) and (
        bool(NON_TEXT_PATH_RE.search(path)) or bool(NON_TEXT_DIR_RE.search(path)))

def scan(val, label, out):
    if not isinstance(val, str) or not val:
        return
    for rx, tag in ((DEBUG_RE, "debug/dead-code leftover"),
                    (PLACEHOLDER_RE, "unresolved placeholder"),
                    (SECRET_RE, "possible secret or API key")):
        m = rx.search(val)
        if not m:
            continue
        if rx is SECRET_RE and SECRET_EXEMPT_RE.search(val[max(0, m.start() - 30):m.end() + 10]):
            continue
        # never echo a secret back: show only the tag and the position label
        ctx = "" if rx is SECRET_RE else ": '..." + val[max(0, m.start() - 40):m.start() + 60].replace("\n", " ") + "...'"
        out.append("%s (%s)%s" % (tag, label, ctx))

violations, warnings = [], []
if tool in ("Edit", "Write", "NotebookEdit"):
    fp = ti.get("file_path") or ti.get("notebook_path") or ""
    if exempt(fp):
        sys.exit(0)
    for k in ("content", "new_string", "text", "file_text"):
        scan(ti.get(k), k, violations)
    if tool == "Write" and isinstance(fp, str) and fp:
        try:
            size = os.path.getsize(fp)
        except OSError:
            size = 0
        if size > 1500 and len(ti.get("content") or "") > 0:
            warnings.append("Write targets an existing %d-byte file (%s); a targeted Edit is usually the better fit "
                            "unless this is a deliberate rewrite." % (size, fp))
elif tool == "MultiEdit":
    if exempt(ti.get("file_path") or ""):
        sys.exit(0)
    for i, e in enumerate(ti.get("edits", []) or []):
        scan((e or {}).get("new_string"), "edits[%d].new_string" % i, violations)
else:
    sys.exit(0)

if violations:
    msg = ("[code-quality-preguard] write refused:\n" + "\n".join(violations) +
           "\nRemove debug leftovers, replace every placeholder with real content, and never embed a literal "
           "secret (use an environment variable).")
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                             "permissionDecision": "deny",
                                             "permissionDecisionReason": msg}}))
elif warnings:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                             "additionalContext": "[code-quality-preguard] " + " | ".join(warnings)}}))
PYEOF
exit 0
