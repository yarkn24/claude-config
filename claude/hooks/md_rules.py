#!/usr/bin/env python3
"""md_rules.py - the one rule table for markdown instruction files.

Both gates import this: md-lovable-preguard.sh (PreToolUse Edit|Write, blocks before the
write) and md-directive-postguard.sh / md-directive-stopgate.sh (catch writes made by Bash).
The rule text a violator is shown and the check that fires come from the same table.
"""
import os
import re
import subprocess

# id | severity | one-line rule | the fix, imperative
# BLOCK = near-zero false positives, measured on the live corpus before shipping.
# WARN  = real concern, but it flagged legitimate text during calibration, and a
#         gate that cries wolf teaches the agent to route around every gate.
RULES = [
    ("R1", "block", "No preamble. Open with the directive.",
     "Delete the lead-in sentence; start at the instruction."),
    ("R2", "block", "No em dash and no ASCII double-hyphen used as a dash.",
     "Use a comma, a colon, or parentheses. CLI flags are fine."),
    ("R3", "block", "No paragraph of 6+ unbroken lines outside a code fence.",
     "Split into bullets or a table; one idea per line."),
    ("R4", "block", "Section headings are UPPERCASE.",
     "Rewrite the heading as ## UPPERCASE TEXT."),
    ("R5", "block", "A rule file states the RULE, never the session that found it.",
     "Cut the process narrative; keep the resulting rule as one line."),
    ("R6", "block", "A directive file does not grow 30%+ in one write with no new heading.",
     "Adding a rule adds a heading. Otherwise you are accreting narrative onto an old rule."),
    ("R7", "warn", "One supersession marker per section, never a chain.",
     "State the current rule. Git history holds what it replaced."),
    ("R9", "warn", "A SKILL.md stays under 400 lines, hard ceiling 500.",
     "Move the detail to references/*.md and leave a one-line pointer: Read references/x.md for Y."),
    ("S1", "block", "Every line is an instruction or a value.",
     "Delete the filler phrase; the sentence carries the same instruction without it."),
    ("S2", "warn", "Imperative, present tense, one idea per line.",
     "Rewrite as an instruction. Git history holds what changed and who changed it."),
    ("S3", "block", "A rule file states the rule, never the story behind it.",
     "Move the narrative to a RECORD file; keep only the resulting rule."),
    ("S4", "warn", "An explanation is exactly ONE <!-- WHY: ... --> line.",
     "Close the WHY comment on the line it opens on, or cut it."),
]
RULE_TEXT = {r[0]: (r[1], r[2], r[3]) for r in RULES}
SEVERITY = {r[0]: r[1] for r in RULES}

# The corpus these rules govern: instruction files under ~/.claude (CLAUDE.md, skills,
# commands, reference). Records are exempt by design, because a record is legitimately narrative.
DIRECTIVE_DIRS = ("/.claude/commands/", "/.claude/reference/")
DIRECTIVE_FILES = ("CLAUDE.md",)
EXEMPT_DIRS = ("/memory/", "/docs/archive/", "/logs/", "/node_modules/", "/.git/",
               "/plugins/cache/", "/plugins/marketplaces/", "/plugins/data/")
SYSTEM_RULE = ("CLAUDE.md",)
RECORD_PATTERNS = ("_changelog.md", "/HANDOFF_")

# The operator's own skills; resolved through symlinks so an installer-linked skill stays out.
SKILL_ROOTS = ("~/.claude/skills",)
VENDOR_MARK = re.compile(r"^(license|author|repository)\s*:", re.I | re.M)


def _real(p):
    """Absolute real path with forward slashes."""
    return os.path.realpath(os.path.expanduser(p)).replace(os.sep, "/")


def own_skill(path):
    """True for a SKILL.md the operator maintains in place.

    The REAL location decides, so a skill symlinked in from an installer's own
    directory resolves outside the roots and stays out. A license/author/repository
    frontmatter key marks a vendored copy sitting inside a root. Unreadable or not
    yet on disk counts as not vendored, so a brand new draft is still checked.
    """
    p = path.replace(os.sep, "/")
    if os.path.basename(p) != "SKILL.md":
        return False
    r = _real(p)
    if not any(r.startswith(_real(s) + "/") for s in SKILL_ROOTS):
        return False
    try:
        with open(p, encoding="utf-8", errors="replace") as f:
            return not VENDOR_MARK.search(f.read(2000))
    except Exception:
        return True


def in_scope(path):
    """True when this path is a directive file the rules govern."""
    if not path.endswith(".md"):
        return False
    p = path.replace(os.sep, "/")
    if any(d in p for d in EXEMPT_DIRS):
        return False
    if any(r in p for r in RECORD_PATTERNS):
        return False
    if own_skill(p):
        return True
    if any(d in p for d in DIRECTIVE_DIRS):
        return True
    return os.path.basename(p) in DIRECTIVE_FILES


def strip_fences(content):
    """Blank out fenced code blocks, keeping line numbers stable.

    Without this, a JSON schema or a shell block reads as a 6-line paragraph.
    Measured on the live corpus: 9 of 12 R3 firings were fenced code.
    """
    out, fence = [], False
    for line in content.split("\n"):
        if line.strip().startswith("```"):
            fence = not fence
            out.append("")
            continue
        out.append("" if fence else line)
    return "\n".join(out)


def _git_old_size(path):
    """Byte size of this file at HEAD, or None when untracked.

    realpath, not abspath: git reports an already-resolved toplevel, so a repo reached
    through a symlink produced a garbage relpath and silently disabled R6.
    """
    d = os.path.dirname(os.path.realpath(path)) or "."
    try:
        root = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True, timeout=5)
        if root.returncode != 0:
            return None
        top = root.stdout.strip()
        rel = os.path.relpath(os.path.realpath(path), top)
        r = subprocess.run(["git", "-C", top, "show", "HEAD:" + rel],
                           capture_output=True, timeout=5)
        return len(r.stdout) if r.returncode == 0 else None
    except Exception:
        return None


def check(path, content):
    """Return [(rule_id, detail)] for every violation in this file."""
    v = []
    prose = strip_fences(content)
    is_system = any(s in path.replace(os.sep, "/") for s in SYSTEM_RULE)

    if re.search(r"^(In this section|This document|We will|Here we)",
                 prose, re.M | re.I):
        v.append(("R1", "preamble sentence"))

    if re.search(r"\u2014|\u2013|(?<=\w) -- (?=\w)", prose):
        v.append(("R2", "dash used as punctuation"))

    block = 0
    for i, line in enumerate(prose.split("\n"), 1):
        s = line.strip()
        if not s or s[0] in "#-*|`>0123456789│├└─":
            block = 0
        else:
            block += 1
        if block > 6:
            v.append(("R3", "line %d" % i))
            break

    if len(re.findall(r"^#{1,3} [a-z]", prose, re.M)) > 2:
        v.append(("R4", "lowercase headings"))

    if is_system and re.search(
            r"\blive[- ]tested\b|\bI (tested|verified|ran|found|checked|confirmed|discovered)\b"
            r"|\b(first|then|after that) I\b|\bmy (test|investigation|research) (found|showed)\b",
            prose, re.I):
        v.append(("R5", "session narrative in a rule file"))

    old = _git_old_size(path)
    if old and len(content.encode()) > old * 1.3:
        n_old = n_new = 0
        try:
            d = os.path.dirname(os.path.realpath(path)) or "."
            top = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                                 capture_output=True, text=True, timeout=5).stdout.strip()
            rel = os.path.relpath(os.path.realpath(path), top)
            prev = subprocess.run(["git", "-C", top, "show", "HEAD:" + rel],
                                  capture_output=True, text=True, timeout=5).stdout
            n_old = len(re.findall(r"^#{1,4} ", prev, re.M))
        except Exception:
            n_old = 0
        n_new = len(re.findall(r"^#{1,4} ", content, re.M))
        if n_new <= n_old:
            v.append(("R6", "grew %d%% with no new heading"
                      % ((len(content.encode()) - old) * 100 // old)))

    chain = re.compile(r"\b(Revised|REPLACED|RETIRED|superseded|renamed to|was drifting"
                       r"|no longer applies|old \w+ (rule|gate) is dead)\b", re.I)
    for sec in re.split(r"^#{1,3} ", prose, flags=re.M)[1:]:
        body = "\n".join(l for l in sec.split("\n") if not l.strip().startswith("|"))
        kinds = {m.group(1).lower() for m in chain.finditer(body)}
        if len(kinds) >= 2:
            v.append(("R7", "revision chain, markers: %s" % ", ".join(sorted(kinds))))
            break

    if S1_FILLER.search(prose):
        v.append(("S1", S1_FILLER.search(prose).group(0)))

    narr = S2_NARRATION.search(_no_why_no_quotes(prose))
    if narr:
        v.append(("S2", narr.group(0)))

    story = S3_STORY.search(prose)
    if story:
        v.append(("S3", story.group(0).strip()[:60]))

    if S4_WHY_UNCLOSED.search(prose):
        v.append(("S4", "WHY comment spans more than one line"))

    if os.path.basename(path) == "SKILL.md":
        n = len(content.splitlines())
        if n > 400:
            v.append(("R9", "%d lines, ceiling 500" % n))
    return v


S1_FILLER = re.compile(
    r"\b(it is important to note|it should be noted|keep in mind that|please note that"
    r"|as mentioned (?:above|earlier|before)|needless to say|it is worth noting"
    r"|bear in mind|simply put|that said,|at the end of the day|as we (?:saw|noted)"
    r"|in order to)\b", re.I)

S2_NARRATION = re.compile(
    r"\bwe (?:added|created|changed|decided|found|moved|removed|renamed|switched|chose"
    r"|discovered|learned|realised|realized)\b"
    r"|\b(?:this was (?:added|changed|introduced|removed)|used to be"
    r"|has been (?:added|changed|renamed|removed)|was previously)\b", re.I)

S3_STORY = re.compile(
    r"^#{1,4} .*\b(?:changelog|history|incident|what happened|timeline|story)\b"
    r"|\b(?:the (?:bug|failure|incident|regression) (?:was|happened)|root cause was"
    r"|this broke when|turned out to be)\b", re.I | re.M)

S4_WHY_UNCLOSED = re.compile(r"<!--\s*WHY\b(?![^\n]*-->)")


def _no_why_no_quotes(text):
    """Drop WHY comments and quoted strings: both legitimately carry past tense."""
    t = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    return re.sub(r'"[^"\n]*"', '""', t)


def blocking(violations):
    """Only the block-severity violations."""
    return [x for x in violations if SEVERITY[x[0]] == "block"]


def render(path, violations):
    """The message. Same table as the checks, so it cannot drift."""
    hard = blocking(violations)
    head = "DIRECTIVE STYLE VIOLATION" if hard else "STYLE WARNING"
    out = ["", "[md-rules] %s: %s" % (head, path), ""]
    for rid, detail in violations:
        rule, fix = RULE_TEXT[rid][1], RULE_TEXT[rid][2]
        out.append("  %s %-5s %s" % (rid, SEVERITY[rid].upper(), rule))
        out.append("      seen: %s" % detail)
        out.append("      fix : %s" % fix)
    out += ["", "  STANDARD: English, Lovable style, instructions only, leanest possible.",
            "  An explanation survives only when the rule reads as arbitrary without it,",
            "  and then as ONE <!-- WHY: ... --> line under the rule.", ""]
    return "\n".join(out)
