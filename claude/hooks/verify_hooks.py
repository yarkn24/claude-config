#!/usr/bin/env python3
"""
verify_hooks.py - permanent control net for ~/.claude/hooks/.

WHY: 16 hooks were found emitting {"decision":"allow"} on their
pass path. That value was never valid (schema only accepts "approve"/"block"); every
firing on a pass dumped a schema-validation error into the session context. This script is the permanent,
automatic check that a hook file can never regress into that state silently again.

Checks, per file:
  1. bash -n on every *.sh (syntax).
  2. ast.parse on every standalone *.py, AND on every python heredoc embedded in a
     *.sh file (block opened by a line matching <<-?\s*'?"?PYEOF'?"?\s*$, closed by a
     line that is exactly PYEOF). This is the specific check that catches a dangling
     `else:` with no body before the PYEOF marker; bash -n cannot see inside a
     heredoc, so this check exists specifically because that failure mode happened.
  3. Grep every file for a "decision" key whose literal JSON value is anything other
     than "approve" or "block" (not just "allow"; ANY other invalid literal is
     caught the same way, so a new copy-paste mistake trips this too).

Prints one line per file: "PASS <file>" or "FAIL <file>: <reason>", then a summary.
Exit 0 if clean, exit 1 if anything failed.

Usage: python3 ~/.claude/hooks/verify_hooks.py
Wired as an automatic PostToolUse safety net (Write|Edit|MultiEdit on .claude/hooks/*)
via hooks-dir-verify-guard.sh.
"""
import ast
import glob
import os
import re
import subprocess
import sys

HOOKS_DIR = os.path.dirname(os.path.abspath(__file__))

HEREDOC_START_RE = re.compile(r"<<-?\s*'?\"?PYEOF'?\"?\s*$")
# Catches "decision": "<anything that is not approve or block>" as a JSON-ish literal.
INVALID_DECISION_RE = re.compile(
    r'"decision"\s*:\s*"(?!approve"|block")([^"]*)"'
)


def check_bash_syntax(path):
    try:
        r = subprocess.run(["bash", "-n", path], capture_output=True, text=True, timeout=15)
    except Exception as e:
        return f"bash -n could not run: {e}"
    if r.returncode != 0:
        return f"bash -n syntax error: {r.stderr.strip()}"
    return None


def check_python_syntax(text, label):
    try:
        ast.parse(text)
    except SyntaxError as e:
        return f"python syntax error in {label}: {e}"
    return None


def extract_heredocs(text):
    """Yield (start_line, end_line, block_text) for every <<'PYEOF' ... PYEOF block."""
    lines = text.split("\n")
    n = len(lines)
    i = 0
    while i < n:
        if HEREDOC_START_RE.search(lines[i]):
            start = i + 1
            j = start
            while j < n and lines[j].strip() != "PYEOF":
                j += 1
            if j < n:
                yield (start + 1, j, "\n".join(lines[start:j]))
                i = j + 1
                continue
        i += 1


def check_invalid_decision(text):
    hits = []
    for m in INVALID_DECISION_RE.finditer(text):
        val = m.group(1)
        line_no = text.count("\n", 0, m.start()) + 1
        hits.append(f'line {line_no}: "decision":"{val}"')
    return hits


def check_file(path):
    """Return list of failure reason strings (empty list = PASS)."""
    reasons = []
    text = open(path, encoding="utf-8", errors="replace").read()
    is_self = os.path.abspath(path) == os.path.abspath(__file__)

    if path.endswith(".sh"):
        err = check_bash_syntax(path)
        if err:
            reasons.append(err)
        for start, end, block in extract_heredocs(text):
            err = check_python_syntax(block, f"heredoc lines {start}-{end}")
            if err:
                reasons.append(err)
    elif path.endswith(".py"):
        err = check_python_syntax(text, "file")
        if err:
            reasons.append(err)

    # This script's own docstring/comments legitimately quote the banned literal as
    # documentation (that is the whole point of the tool); it never emits a
    # PreToolUse "decision" payload itself, so it is exempt from the literal-scan,
    # while still getting the syntax check above like every other file.
    if not is_self:
        for hit in check_invalid_decision(text):
            reasons.append(f"invalid decision literal ({hit})")

    return reasons


def main():
    files = sorted(
        glob.glob(os.path.join(HOOKS_DIR, "*.sh"))
        + glob.glob(os.path.join(HOOKS_DIR, "*.py"))
    )
    n_fail = 0
    for path in files:
        reasons = check_file(path)
        name = os.path.basename(path)
        if reasons:
            n_fail += 1
            print(f"FAIL {name}: " + " | ".join(reasons))
        else:
            print(f"PASS {name}")

    print(f"--- SUMMARY: {len(files)} files checked, {n_fail} failed ---")
    sys.exit(1 if n_fail else 0)


if __name__ == "__main__":
    main()
