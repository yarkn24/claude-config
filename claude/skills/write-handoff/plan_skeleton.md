<!-- Copy everything from the next line down into `~/.claude/plans/<slug>.md`,
     fill every bracket, delete nothing structural. Built to satisfy
     `hooks/plan-detail-gate.sh` (checked live by `plan_detail_gate_checks.py`)
     by construction, so a plan started here passes on the first submission
     instead of failing on ROLE ASSIGNMENT or LINE COUNT, the two most
     common blocks.
     Each `<!-- gate: X -->` marker below names the exact check that section
     satisfies; keep the marked content shape even while rewriting the words
     around it. Do not copy this comment block itself, the gate reads the
     first `# ` line as the plan's H1. -->

# PLAN: <short topic, matches the ExitPlanMode summary>

<!-- gate: ROLE ASSIGNMENT (first 5 non-empty lines after the H1 must open
     with "You are"). Bold, one sentence, name the competency this plan
     actually needs, not a generic noun. -->
**You are a <role matched to the task>**, because this plan needs
<the specific competency, e.g. "measured before/after numbers on a live
hook" or "a multi-file rename with every caller swept">.

Scope: <restate exactly what is being asked, not a paraphrase>. May change:
<files/areas>. Must stay untouched: <named files/directories, or "none">.

<!-- gate: CONTEXT SECTION ('## Context' or '## 1. Context') -->
## Context

<What exists today, what is broken or missing, why this plan is needed.
Cite the real evidence: a file, a measured number, an audit doc.>

- `<path/to/file_or_dir_1>`
- `<path/to/file_or_dir_2>`
- `<path/to/file_or_dir_3>`

<!-- gate: CONCRETE FILE PATHS >= 3 (counted across the whole file, the three
     above already clear it; keep every real path you name in backticks so it
     counts and so the reading session can open it directly). -->

## Steps

<Ordered, each step names the exact file(s) it touches and how it is
verified. No step without both.>

1. <step one>. Touches `<file path>`. Verify: `<exact command>`.
2. <step two>. Touches `<file path>`. Verify: `<exact command>`.
3. <step three>. Touches `<file path>`. Verify: `<exact command>`.

<!-- gate: VERIFICATION SECTION (must contain 'Verif'/'verif') and
     BEFORE/AFTER MEASURABLE CLAIM ('baseline'/'before'/'goes X to Y').
     State the real number, not a placeholder adjective. -->
## Verification

Baseline before this plan: <measured state, e.g. "hook fires 2,159 times in
30 days" or "0 tests cover this path">. Target: goes <X> to <Y>.

- `<verification command 1>` (expected: <result>)
- `<verification command 2>` (expected: <result>)
- Re-run the same measurement method the baseline used, not a different one,
  so before and after are comparable.

## Autonomy

<!-- gate: AUTONOMY CLAUSE (must contain both 'reversible' and
     'without asking'). Paste verbatim, do not paraphrase: paraphrasing has
     dropped the exact words the checker matches on before. -->
> **Autonomy:** you choose the scope, method, agent count and model tiers. Do
> every reversible action (research, measurement, docs, tests, plain defect
> fixes) without asking. Give every deliverable its own check (a test,
> script or replay that fails loudly), run it, fix your own work until it
> passes, and only then report. Only
> irreversible actions (deletion, sending, publishing, commit, push) and
> overturning a recorded operator decision wait for the operator: prepare those
> fully and list each as one yes/no line.

## Completion

<!-- gate: COMPLETION CLAUSE (must contain 'do not stop').
     Paste verbatim. -->
> Work this file to the end. Do not stop at a partial result, a status
> report, or an open question. Finish every item in the deliverable, verify
> each with real command output, then report. Stuck, or a question surfaces:
> spawn ONE fresh, stronger-tier teacher agent and ask it.

<!-- gate: LINE COUNT >= 80. A plan this short is rare; if the real content
     genuinely fits under 80 lines, that is a signal the task did not need
     ExitPlanMode at all (CLAUDE.md "MORE THAN 3 STEPS MEANS STOP AND PLAN
     FIRST"), not a reason to pad. Pad only with real Context or real Steps,
     never filler sentences (global CLAUDE.md "Leanest, Lightest, Fastest"
     forbids filler regardless of what a counter wants to see). -->
