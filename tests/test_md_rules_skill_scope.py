#!/usr/bin/env python3
"""Pins md_rules.py's scope (own_skill / in_scope) so it cannot silently re-widen.

Run: python3 tests/test_md_rules_skill_scope.py
Probes use a throwaway HOME: only skills under ~/.claude/skills without a vendor marker are in scope.
"""
import os
import sys
import tempfile
from pathlib import Path

_TMP = tempfile.TemporaryDirectory()  # removed automatically at exit
HOME = _TMP.name
os.environ["HOME"] = HOME
os.environ["USERPROFILE"] = HOME
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "claude" / "hooks"))
import md_rules as M  # noqa: E402


def write(rel, text):
    p = Path(HOME) / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")
    return str(p)


own = write(".claude/skills/own/SKILL.md", "---\nname: own\ndescription: x\n---\nBody\n")
vendor = write(".claude/skills/vendor/SKILL.md", "---\nname: v\nrepository: https://example.org/v\n---\nBody\n")
linked_target = write("elsewhere/skills/linked/SKILL.md", "---\nname: l\n---\nBody\n")
try:
    Path(HOME, ".claude/skills/linked").symlink_to(Path(linked_target).parent, target_is_directory=True)
    SYMLINK_OK = True
except (OSError, NotImplementedError):  # Windows without developer mode cannot create symlinks
    SYMLINK_OK = False
other = write("proj/.claude/skills/pricing/SKILL.md", "---\nname: p\n---\nBody\n")
cmd = write(".claude/commands/do.md", "Body\n")
ref = write(".claude/reference/r.md", "Body\n")
claude = write("proj/CLAUDE.md", "Body\n")
mem = write(".claude/memory/m.md", "Body\n")
notes = write("proj/notes.md", "Body\n")

PROBES = [
    (own, True, "own skill, no vendor marker"),
    (vendor, False, "vendor marker exempts a third-party skill"),
    (other, False, "a project's own skill directory is not this guard's business"),
    (cmd, True, "command file"),
    (ref, True, "reference file"),
    (claude, True, "CLAUDE.md"),
    (mem, False, "memory dir is exempt"),
    (notes, False, "ordinary markdown is out of scope"),
]
if SYMLINK_OK:
    PROBES.append((str(Path(HOME, ".claude/skills/linked/SKILL.md")), False, "symlinked skill resolves outside the root"))
else:
    print("SKIP symlink probe: symlinks unavailable on this platform")


def main():
    failed = 0
    for path, expect, note in PROBES:
        got = M.in_scope(path)
        ok = got == expect
        print(("OK  " if ok else "FAIL"), "expect=%-5s got=%-5s  %s" % (expect, got, note))
        failed += not ok

    dash = chr(0x2014)
    v = M.check(cmd, "# TITLE\nUse a%sb.\n" % dash)
    r2 = any(rid == "R2" for rid, _ in v)
    print(("OK  " if r2 else "FAIL"), "R2 fires on a dash used as punctuation:", v)
    failed += not r2

    if failed:
        print("\n%d probe(s) FAILED." % failed)
        sys.exit(1)
    print("\nall probes passed.")


if __name__ == "__main__":
    main()
