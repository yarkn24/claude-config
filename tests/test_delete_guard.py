#!/usr/bin/env python3
"""Pins delete-guard.sh: every delete anywhere in a command gets an ask, indirect deletes included.

Run: python3 tests/test_delete_guard.py [hook_path]
Feeds hook JSON on stdin only; the only files written are two throwaway scripts in /tmp.
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HOOK = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else
                       Path(__file__).resolve().parent.parent / "claude" / "hooks" / "delete-guard.sh")
A, F, OK = "ASK", "ASK+ATTENTION", "ALLOW"  # F: ask whose reason carries an ATTENTION note

CASES = [
    # leading forms (blocked before the fix too)
    (A, "rm /tmp/zz_probe"),
    (A, "git rm zz_probe"),
    (A, "unlink /tmp/zz_probe"),
    (F, "rm -rf /tmp/zz_dir"),
    (F, "rm /etc/zz_probe"),
    (F, "rm ~"),
    (A, "echo hi\nrm /tmp/zz_probe"),
    # compound / nested / wrapped forms: same decision as the leading form
    (A, "cd /tmp && rm /tmp/zz_probe"),
    (A, "true || rm /tmp/zz_probe"),
    (A, "true; rm /tmp/zz_probe"),
    (A, "sleep 0 & rm /tmp/zz_probe"),
    (A, "ls /tmp | rm /tmp/zz_probe"),
    (A, "ls /tmp/zz_dir | xargs rm"),
    (A, "ls /tmp/zz_dir | xargs -I{} rm {}"),
    (A, "ls /tmp/zz_dir | xargs -n 1 rm"),
    (A, "sudo bash -c 'rm /tmp/zz_probe'"),
    (A, 'env -S "rm /tmp/zz_probe"'),
    (A, "exec 3>&1; rm /tmp/zz_probe 2>/dev/null"),
    (A, "echo $(rm /tmp/zz_probe)"),
    (A, 'echo "$(rm /tmp/zz_probe)"'),
    (A, "echo `rm /tmp/zz_probe`"),
    (A, "(rm /tmp/zz_probe)"),
    (A, "{ rm /tmp/zz_probe; }"),
    (A, "if true; then rm /tmp/zz_probe; fi"),
    (A, "f() { rm /tmp/zz_probe; }; f"),
    (A, "FOO=1 rm /tmp/zz_probe"),
    (A, "env FOO=1 rm /tmp/zz_probe"),
    (A, "sudo -u root rm /tmp/zz_probe"),
    (A, "command rm /tmp/zz_probe"),
    (A, "exec rm /tmp/zz_probe"),
    (A, "time rm /tmp/zz_probe"),
    (A, "nohup rm /tmp/zz_probe"),
    (A, "nice -n 5 rm /tmp/zz_probe"),
    (A, "timeout 5 rm /tmp/zz_probe"),
    (A, "noglob rm /tmp/zz_probe"),
    (A, "/bin/rm /tmp/zz_probe"),
    (A, "\\rm /tmp/zz_probe"),
    (A, '"rm" /tmp/zz_probe'),
    (A, "r''m /tmp/zz_probe"),
    (A, "RM /tmp/zz_probe"),
    (A, 'bash -c "rm /tmp/zz_probe"'),
    (A, "sh -c 'rm /tmp/zz_probe'"),
    (A, "zsh -lc 'cd /tmp; rm /tmp/zz_probe'"),
    (A, 'eval "rm /tmp/zz_probe"'),
    (A, "git -C /tmp rm zz_probe"),
    (A, "find /tmp/zz_dir -name x -exec rm {} \\;"),
    (A, "find /tmp/zz_dir -name x -exec sh -c 'rm {}' \\;"),
    (A, "find /tmp/zz_dir -name '*.pyc' -delete"),
    (A, "bash <<'EOF'\nrm /tmp/zz_probe\nEOF"),
    (A, "cat <<EOF\n$(rm /tmp/zz_probe)\nEOF"),
    (A, 'bash <<< "rm /tmp/zz_probe"'),
    (A, "python3 scripts/tidy.py && rm /tmp/zz_probe"),
    # hard floor holds inside compounds
    (F, "cd /tmp && rm -rf /tmp/zz_dir"),
    (F, "true && rm ~"),
    (F, "true && rm /tmp/zz*"),
    # 2026-10-03c: `$?` is an exit status, not a glob (incident: `rm <path>; echo rc=$?` hit the floor)
    (A, "rm /tmp/zz_probe; echo rc=$?"),
    (A, "rm /tmp/zz_probe; echo rc=${?}"),
    (F, "rm /tmp/zz_probe?"),
    (F, "rm /tmp/zz_probe$$?"),
    (F, "rm /tmp/zz_probe\\$?"),
    (F, "cd /etc && rm zz_probe"),
    (F, 'cd "$HOME" && rm zz_probe'),
    (F, "true; git rm -r zz_dir"),
    (F, "find ~ -delete"),
    (F, "python3 scripts/tidy.py; rm -rf ~"),
    (F, "rm /tmp/zz_probe && ls ~"),  # pre-fix line-scan floor is kept
    # parse doubt with a delete word: fail closed
    (F, 'echo "rm /tmp/zz_probe" | bash'),
    (F, "X=$(echo rm); $X /tmp/zz_probe"),
    (F, "$(echo rm) /tmp/zz_probe"),
    (A, "cd ~/.claude && git rm zz_probe"),
    # in-command literal variables resolve (no false floor)
    (A, "X=rm; $X /tmp/zz_probe"),
    (A, "CMD='rm /tmp/zz_probe'; eval \"$CMD\""),
    (A, "S=/tmp/zz_s; cd $S && rm zz_probe"),
    (F, "S=/etc; cd $S && rm zz_probe"),
    (A, "echo $(( $(date +%s)+1 )) > /tmp/zz_u; rm -f /tmp/zz_u"),
    (A, 'for p in a b; do case "$p" in a|b) continue;; esac; rm /tmp/zz_$p; done'),
    (F, 'echo "unterminated rm /tmp/zz_probe'),
    # verbs added 2026-10-03b: rmdir, shred, git clean, rsync --del*
    (A, "rmdir /tmp/zz_dir"),
    (A, "cd /tmp && rmdir zz_dir"),
    (F, "rmdir /etc/zz_dir"),
    (A, "shred -u /tmp/zz_probe"),
    (F, "true; shred ~/zz_probe"),
    (A, "git clean -fdx zz_dir"),
    (A, "true && git clean -f /tmp/zz_repo"),
    (F, "git -C /etc clean -fd"),
    (A, "rsync -a --delete /tmp/zz_src/ /tmp/zz_dst/"),
    (F, "rsync -a --delete-after /tmp/zz_src/ ~/zz_dst/"),
    (A, "sudo rsync -a --del /tmp/zz_src/ /tmp/zz_dst/"),
    (OK, "git clean -n"),
    (OK, "git clean -nd"),
    (A, "git clean -fd -enothing /tmp/zz_repo"),
    (A, "git clean -fd -e -n /tmp/zz_repo"),
    (OK, "git clean --dry-run -d"),
    (OK, "rsync -a /tmp/zz_src/ /tmp/zz_dst/"),
    (OK, 'git commit -m "rmdir and shred old files"'),
    (OK, "echo rmdir shred"),
    # indirect deletes ask
    (A, "find /tmp/zz_dir -type f -delete"),
    (A, "ls /tmp/zz_dir | xargs rm"),
    (F, "python3 -c 'import shutil; shutil.rmtree(\"/tmp/zz_dir\")'"),
    (F, "python3 -c 'import os; os.remove(\"/tmp/zz_probe\")'"),
    (F, "python3 - <<'PY'\nfrom pathlib import Path\nPath('/tmp/zz_probe').unlink()\nPY"),
    (F, "python3 /tmp/zz_del_script.py"),
    (A, "unlink /tmp/zz_probe"),
    # not deletes: must stay allowed
    (OK, "git status"),
    (OK, "ls -la /tmp"),
    (OK, "grep -r 'rm ' /tmp/zz_file"),
    (OK, 'echo "rm is a word"'),
    (OK, 'git commit -m "rm old files"'),
    (OK, "ls | grep rm"),
    (OK, "docker rm zz_container"),
    (OK, "command -v rm"),
    (OK, "which rm && man rm"),
    (OK, "git log --grep=rm"),
    (OK, "git push origin --delete zz_branch"),
    (OK, "find /tmp -name '*.py'"),
    (OK, "ls # rm /tmp/zz_probe"),
    (OK, "python3 scripts/tidy.py"),
    (OK, "python3 scripts/tidy.py --execute"),
    (OK, "cat > /tmp/zz.py <<'EOF'\nprint(\"don't rm it\")\nEOF"),
    (OK, "python3 - <<'PY'\nx = \"it's rm\"\nPY"),
    (OK, 'git commit -m "$(cat <<\'EOF\'\nDrop unused (old) files, don\'t rm\nEOF\n)"'),
    (OK, "echo \"$(date)\" && npm run build 2>&1 | tail -5"),
    (OK, "for f in a b; do echo $f; done"),
    (OK, 'echo "unterminated'),
    (OK, "python3 -c 'print(1)'"),
    (OK, "python3 /tmp/zz_clean_script.py"),
    (OK, "curl -fsSL https://example.invalid/x.sh | bash"),
]


# python3 broken: a delete word must still ask (rc 0), anything else keeps the crash rc 1.
FAKEPY = "/tmp/delete_guard_test_fakepy"
CRASH_CASES = [(A, "rm /tmp/zz_probe"), (A, "rmdir /tmp/zz_dir"), (A, "cd /tmp && rm /tmp/zz_probe"), ("RC1", "git status")]


def run(cmd, env=None):
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    p = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True, cwd="/tmp", timeout=30, env=env)
    if p.returncode:
        return "RC{}".format(p.returncode)
    out = p.stdout.strip()
    if not out:
        return OK
    h = json.loads(out)["hookSpecificOutput"]
    if h.get("permissionDecision") != "ask":
        return "BAD:" + str(h.get("permissionDecision"))
    return F if "ATTENTION" in h.get("permissionDecisionReason", "") else A


def main():
    if not os.path.isfile(HOOK):
        print("ABORT: hook not found: {}".format(HOOK))
        return 2
    with open("/tmp/zz_del_script.py", "w") as fh:
        fh.write("import os\nos.remove('/tmp/zz_nothing')\n")
    with open("/tmp/zz_clean_script.py", "w") as fh:
        fh.write("print('hello')\n")
    with ThreadPoolExecutor(8) as ex:
        got = list(ex.map(run, [c for _, c in CASES]))
    os.makedirs(FAKEPY, exist_ok=True)
    with open(os.path.join(FAKEPY, "python3"), "w") as fh:
        fh.write("#!/bin/sh\nexit 1\n")
    os.chmod(os.path.join(FAKEPY, "python3"), 0o755)
    env = dict(os.environ, PATH=FAKEPY + ":/usr/bin:/bin")
    got += [run(c, env) for _, c in CRASH_CASES]
    fails = 0
    for (exp, cmd), g in zip(CASES + CRASH_CASES, got):
        ok = exp == g
        fails += not ok
        print("{:4} {:14} {:14} {}".format("PASS" if ok else "FAIL", exp, g, cmd.replace("\n", "\\n")[:80]))
    print("\n{} cases, {} failed  (hook: {})".format(len(CASES) + len(CRASH_CASES), fails, HOOK))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
