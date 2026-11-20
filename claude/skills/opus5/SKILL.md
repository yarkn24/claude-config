---
name: opus5
description: Use when a new Claude model ships and the harness needs re-validation; when auditing whether CLAUDE.md, skills, hooks, or agent prompts still earn their context; when a prompt or command file is suspected of over-specification; when designing a long-running or multi-agent task and deciding what verification to give it. Do NOT use for ordinary coding, debugging, pipeline runs, or any task that merely happens to involve Opus.
---

# OPUS5 HARNESS DOCTRINE

## THIS SKILL IS ADVISORY ONLY, ASK BEFORE APPLY

NEVER CHANGE, DISABLE, OR DELETE ANYTHING. This skill produces ADVICE and EVIDENCE. The operator decides and applies.

| Allowed | Forbidden |
|---|---|
| Measure, classify, ablate in memory, report | Edit or delete a hook, rule, or config |
| Propose a change with gain and risk | Apply a proposed change |
| Say "this looks removable, here is the evidence" | Remove it |

Every output ends as a PROPOSAL awaiting approval. If a proposal is approved, the operator or a separate explicit task applies it, not this skill.

## CORE PRINCIPLE

LESS INSTRUCTION, MORE VERIFICATION. Instructions written for an older model are a tax on every session; verification is what actually raises output quality.

## THE ORIGIN TEST, RUN IT BEFORE THE ONE-LINE TEST

WAS THIS RULE WRITTEN AFTER A REAL INCIDENT? If yes, it is KEEP by default, whatever its surface form looks like.

A hook created because something actually went wrong has ALREADY satisfied D2. The repeated failure was observed, and the rule is the recorded response. Re-litigating it from priors is exactly the guessing D2 forbids.

| Origin | Default |
|---|---|
| Written after a real, recorded incident | KEEP. Do not propose removal |
| Written from a general style preference | Candidate, needs ablation evidence |
| Origin unknown | Treat as incident-derived until proven otherwise |

IN A HARNESS OF INCIDENT-DERIVED HOOKS, THE CORRECT OUTPUT IS ALMOST ALWAYS "KEEP, AND HERE IS WHY". Finding little to cut is a valid and common result.

## THE ONE-LINE TEST

Apply ONLY after the origin test passes. If the model already does it right without the instruction, AND no incident motivated it, the instruction may be costing you and buying nothing.

## PICK A MODE

| Mode | Use when | Load |
|---|---|---|
| DOCTRINE | "how should I use Opus 5", a new model shipped, someone cites the video | `reference/00-source.md` plus the relevant D-doc |
| AUDIT | "audit my harness", "are my hooks still needed", context feels heavy | `reference/audit-playbook.md`, `reference/keep-or-cut.md` |
| ABLATE | "run the ablation", post-upgrade validation, a rule's value is disputed | `reference/D1-delete-first.md`, `reference/D2-rebuild-protocol.md` (reasoning only; see HOW TO RUN THE ABLATION) |

Load only the mode you need. Loading all of `reference/` defeats the point of this skill.

## THE EIGHT DIRECTIVES

| ID | Directive | Doc |
|---|---|---|
| D1 | DELETE FIRST, MEASURE SECOND | `reference/D1-delete-first.md` |
| D2 | RE-ADD ONLY ON REPEATED FAILURE | `reference/D2-rebuild-protocol.md` |
| D3 | TASK, GUARDRAILS, EXIT CRITERIA, THEN STOP TALKING | `reference/D3-task-framing.md` |
| D4 | VERIFICATION IS THE WHOLE GAME | `reference/D4-verification.md` |
| D5 | UNHOBBLE: THE MODEL ALREADY DOES MORE THAN YOUR PRODUCT ALLOWS | `reference/D5-unhobbling.md` |
| D6 | SCALE WITH ORCHESTRATION, NOT INSTRUCTIONS | `reference/D6-orchestration.md` |
| D7 | EVALS OUTLIVE PROMPTS, BUT SATURATE | `reference/D7-evals.md` |
| D8 | BE EMPIRICAL, FORGET YOUR PRIORS | `reference/D8-empirical-mindset.md` |

## THE KEEP-OR-CUT RUBRIC

Classify before touching anything. Full definitions and edge cases: `reference/keep-or-cut.md`.

| Bucket | What it is | Default |
|---|---|---|
| A. Irreversible-action guard | A wrong output reaches the real world | KEEP unconditionally, never ablate |
| B. Ground truth | A fact the model cannot derive | KEEP, but store as a file it reads on demand |
| C. Static analysis | A deterministic check a script does better | KEEP as a script, delete the prose twin |
| D. Model babysitting | Style, tone, ordering, quality nags | Candidate ONLY if the origin test also passes |

Only bucket D is ever a removal candidate, only with evidence, and only if no incident produced it. A style-shaped rule born from a real incident is bucket A wearing bucket D's clothes.

## HARD CONSTRAINTS

1. ADVISORY ONLY. Propose, never apply. The operator decides.
2. INCIDENT-DERIVED RULES ARE KEEP BY DEFAULT. A hook written after a real failure has already earned its place.
3. NEVER ABLATE BUCKET A. A guard that stops a fabricated credential or a wrong phone number reaching an employer is not context bloat.
4. PROVE BETTER, NOT JUST SMALLER. A byte reduction that degrades output is a regression. Removal needs an A/B with a quality metric.
5. BACK UP BEFORE MUTATING. Git commit or timestamped copy first. Soft-delete beats delete.
6. NEVER DELETE FILES UNPROMPTED. Deletion needs the operator's explicit go-ahead, and is forbidden entirely under `/afk`.
7. A MISFIRING RULE IS NOT A DISPROVEN RULE. Repair the hook, then judge its rule.
8. HOOKS COST RUNTIME, NOT CONTEXT. Deleting hooks to save context trades real safety for nothing.

## COST CAVEAT, BINDING

The source advises large-scale orchestration and multi-week unattended runs. Validate cost and benefit on a small scope before adopting it.

ADOPT the free lessons: verification, de-specification, deletion-first.
DO NOT ADOPT unattended multi-day frontier-model runs as a default.

## HOW TO RUN THE ABLATION

Do not run the agent with its hooks or CLAUDE.md switched off on this machine: that removes every guard the firm configuration installs. Judge a rule by reasoning against `reference/keep-or-cut.md` and the evidence in the repo. A live with/without comparison runs only in a throwaway sandbox that holds no firm or client data, and only with IT approval.

## WHAT THIS SKILL DELEGATES

Do not build a third auditor. Two skills already own parts of this.

| Step | Owner |
|---|---|
| MEASURE token overhead | `context-budget` skill |
| CLASSIFY into A/B/C/D | this skill, `reference/keep-or-cut.md` |
| ABLATE for evidence | this skill, sandbox only, with the operator's approval |
| REMOVE with approval and undo | `config-gc` skill |

## RED FLAGS

| Thought | Reality |
|---|---|
| "This rule looks obviously useless" | That is a prior, not evidence. Ablate it. D8. |
| "It is only 3 lines, leave it" | The model reads it every session forever. D2. |
| "Smaller context, so it is better" | Prove the quality metric held. Gate 2. |
| "The hook blocked me, the rule is wrong" | Repair the hook first. Constraint 5. |
| "I will add an instruction so it stops doing that" | Have you seen it fail repeatedly, or once? D2. |
| "More steps in the prompt means more reliable" | Over-specification degrades modern models. D3. |
