#!/usr/bin/env python3
"""code_comment_rules.py - reports commented-out code that carries no reason beside it. Report only, never blocks."""
import re

RULES = [("C1", "warn", "Commented-out code carries its reason on the line above.",
          "Add one prose comment saying why it is parked, or delete the block.")]
RULE_TEXT = {r[0]: (r[1], r[2], r[3]) for r in RULES}

_CODE_SHAPE = re.compile(r"[=(]|^\s*(def|if|return|import|from|for|while|class)\b|f_\w+")
# Prose = several real words. A parked line of code has few word tokens and
# reads as syntax; an explanation reads as a sentence.
_WORD = re.compile(r"[A-Za-z]{2,}")


def _is_prose(text):
    return len(_WORD.findall(text)) >= 6


def check(path, content):
    if not path.endswith((".py", ".sh")):
        return []
    lines = content.split("\n")
    v, run, start = [], [], 0
    def mark(block, at):
        if len(block) < 3:
            return
        lo = max(0, at - len(block) - 3)
        for prev in lines[lo:at - len(block)]:
            s = prev.strip()
            if s.startswith("#") and _is_prose(s):
                return
        v.append(("C1", "line %d, %d lines parked with no reason" % (at - len(block) + 1, len(block))))
    for i, l in enumerate(lines, 1):
        s = l.strip()
        if s.startswith("#") and _CODE_SHAPE.search(s[1:]) and not _is_prose(s[1:]):
            if not run:
                start = i
            run.append(s)
        else:
            if run:
                mark(run, i)
                run = []
    if run:
        mark(run, len(lines) + 1)
    return v[:3]
