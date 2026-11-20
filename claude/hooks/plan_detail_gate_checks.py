import re
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    text = f.read()
lines = text.splitlines()
low = text.lower()

# Clause text matches claude/skills/write-handoff/plan_skeleton.md.
if "<!-- plan-detail-gate: skip -->" in "\n".join(lines[:20]):
    # Skip covers detail only; the execution-contract clauses below always apply.
    detail = False
else:
    detail = True

h1 = next((i for i, l in enumerate(lines) if l.strip().startswith("# ")), None)
role_ok = False
if h1 is not None:
    nonempty = [l for l in lines[h1 + 1:] if l.strip()]
    role_ok = any(re.match(r"^\*{0,2}You are ", l.strip()) for l in nonempty[:5])

results = [
    ("AUTONOMY CLAUSE (must contain 'reversible' and 'without asking')",
     "reversible" in low and "without asking" in low, False),
    ("COMPLETION CLAUSE (must contain 'do not stop')",
     "do not stop" in low, False),
    ("ROLE ASSIGNMENT (first 5 non-empty lines after H1 open with 'You are')", role_ok, True),
    (f"LINE COUNT >= 80 (actual: {len(lines)})", len(lines) >= 80, True),
    ("CONTEXT SECTION ('## Context' or '## 1. Context')",
     bool(re.search(r"^##\s*(1\.\s*)?Context\b", text, re.M)), True),
    ("VERIFICATION SECTION (contains 'verif')", "verif" in low, True),
    ("CONCRETE FILE PATHS >= 3",
     len(set(re.findall(r"[\w.\-]+/[\w.\-/]+", text)) | set(re.findall(r"[\w.\-/]+\.(?:md|py|sh|json)\b", text))) >= 3, True),
    ("BEFORE/AFTER CLAIM ('baseline'/'before'/'goes X to Y')",
     bool(re.search(r"baseline|before|goes .* to", text, re.I)), True),
]

failed = False
for label, ok, is_detail in results:
    if is_detail and not detail:
        continue
    print(("PASS: " if ok else "FAIL: ") + label, file=sys.stderr)
    failed = failed or not ok
if failed:
    print("\nPlan rejected: fix every FAIL above before ExitPlanMode. A trivial plan may add "
          "'<!-- plan-detail-gate: skip -->' in its first 20 lines (detail checks only).", file=sys.stderr)
    sys.exit(2)
