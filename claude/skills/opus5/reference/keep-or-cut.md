# KEEP-OR-CUT RUBRIC

## PURPOSE

CLASSIFY BEFORE TOUCHING ANYTHING. The bucket decides whether a rule is even eligible for ablation.

ADVISORY ONLY. This rubric produces a verdict and a proposal. It never applies one.

## STEP 0, THE ORIGIN TEST, RUN THIS FIRST

WAS THE RULE WRITTEN AFTER A REAL INCIDENT? If yes, STOP. It is KEEP. Do not classify it into D and do not propose ablation.

| Origin | Verdict |
|---|---|
| Created in response to a recorded failure | KEEP. The evidence already exists |
| Created from a general style preference | Continue to the buckets below |
| Origin unknown or undocumented | Treat as incident-derived. Ask the operator before proposing anything |

WHY THIS OUTRANKS EVERYTHING BELOW: D2 says a rule earns its place by surviving a documented repeated failure. A hook built after a real incident HAS ALREADY PASSED THAT TEST. Removing it because it looks like style is re-running an experiment whose result is already recorded, and paying for the answer a second time in production.

A CUSTOM-BUILT HARNESS IS NOT A DEFAULT HARNESS. Generic advice about deleting hooks is calibrated on generic, vendor-shipped configuration. Hooks written by an operator to stop a specific recurring failure are the opposite case. In such a harness, expect to find little or nothing worth cutting, and report that honestly rather than manufacturing candidates.

## THE EMPIRICAL BASIS

The rubric is not invented. It reproduces what actually survived an 80% cut of Claude Code's own system prompt: safety, permissions, static analysis, and UI code [caption, 00:06:26].

Safety and permissions map to bucket A. Static analysis maps to bucket C. What did not survive was style and behaviour correction, which is bucket D.

## THE FOUR BUCKETS

| Bucket | Definition | Test question | Default |
|---|---|---|---|
| A. IRREVERSIBLE-ACTION GUARD | A wrong output reaches the real world | If this fails silently, can I undo it? | KEEP unconditionally |
| B. GROUND TRUTH | A fact the model cannot derive | Could a perfect reasoner infer this? | KEEP, store as an on-demand file |
| C. STATIC ANALYSIS | A deterministic check a script does better | Can a script decide this without judgment? | KEEP as a script, delete the prose twin |
| D. MODEL BABYSITTING | Style, tone, ordering, quality nags | Would a competent model do this anyway? | ABLATION CANDIDATE |

## BUCKET A, THE UNTOUCHABLE SET

Qualifies only if a failure escapes the system and cannot be recalled.

| Example | Escape route |
|---|---|
| Fabricated credential or certification | Reaches a real employer |
| Wrong personal data in a form | Submitted, not retractable |
| Sending a message or email | Delivered |
| Deleting a file | Data loss |
| Financial or legal commitment | Binding |
| Fabricated domain experience | Misrepresentation to a third party |

RULES:
1. NEVER ABLATE. The experiment's downside is real harm.
2. Exempt from the repeated-failure threshold. One occurrence justifies the guard.
3. Capability improvements do not retire these. A better model does not make a wrong submission recoverable.
4. When in doubt between A and D, it is A.

## BUCKET B, GROUND TRUTH

The model cannot derive these by reasoning. They are facts about the world or about the operator.

| Example | Why underivable |
|---|---|
| Approved title list | An arbitrary local decision |
| Company blacklist | Private experience |
| Canonical personal data file | Only the source file is authoritative |
| Immutable field values | Defined externally |
| Country and portal policy | Operator's strategy |

CORRECT PLACEMENT: a file the model READS ON DEMAND, not always-on prose. Ground truth in always-on context is a common and expensive misfiling. A blacklist is needed by one workflow, not by every session.

## BUCKET C, STATIC ANALYSIS

A deterministic rule with an unambiguous pass or fail.

| Example | Better as |
|---|---|
| Character or byte limits | Script check |
| Required sections present | Structural validator |
| Forbidden characters | Linter |
| Numeric threshold | Scorer with a non-zero exit |
| File naming convention | Script check |
| Syntax validity | Compiler |

RULES:
1. THE SCRIPT IS THE RULE. Delete the prose that restates it.
2. THE SCRIPT MUST EXIT NON-ZERO ON FAILURE. A gate that only prints is not a gate. D4.
3. THE SCRIPT MUST BE WIRED to a hook, test, or pipeline step. Prose saying "run this" is not wiring.
4. DOC AND CODE MUST AGREE. A documented detector that the script does not implement is worse than no rule, because it produces false confidence.

## BUCKET D, CANDIDATES ONLY IF THE ORIGIN TEST PASSED

Style, tone, ordering, formatting preference, and reminders that a competent model would honour unprompted, AND that no recorded incident produced.

IF THE ORIGIN TEST WAS NOT RUN, NOTHING BELONGS IN THIS BUCKET YET.

| Example | Ablation question |
|---|---|
| Weak-verb avoidance | Does the model write weak verbs under `--bare`? |
| Bullet length preference | Does it overrun unprompted? |
| Emphasis and bold counts | Does it overuse them unprompted? |
| Section ordering | Does it order sensibly unprompted? |
| Document house style | Does it drift unprompted? |
| "Remember to X" reminders | Does it forget X unprompted? |

RULE: D is a CANDIDATE list, not a removal list. Each item still needs an ablation result before anything happens to it.

## DISAMBIGUATION

| Confusion | Resolution |
|---|---|
| Style rule that prevents a real-world harm | A, not D. The consequence decides, not the form |
| Ground truth written as always-on prose | B, and relocate it to an on-demand file |
| Prose restating a rule a script enforces | C, delete the prose, keep the script |
| Guard whose hook is broken | Repair the hook FIRST, then classify |
| Rule nobody can explain the origin of | Ablate it, that is what the experiment is for |
| Style rule the model violates under `--bare` | Still D, but it has earned its keep. Record the evidence |

## THE CLASSIFICATION RECORD

One line per item. Anything less and the next audit repeats the work.

| Field | Content |
|---|---|
| ITEM | File or rule identifier |
| BUCKET | A, B, C, or D |
| JUSTIFICATION | One sentence naming the consequence of failure |
| EVIDENCE | Ablation result, or NONE YET |
| ACTION | KEEP, RELOCATE, FOLD INTO SCRIPT, ABLATE, or REPAIR FIRST |

## THE THREE GATES, APPLIED TO EVERY REMOVAL

1. PROVE BETTER, NOT JUST SMALLER. A byte reduction that degrades quality is a regression.
2. BACK UP BEFORE MUTATING. Commit or timestamped copy. Soft-delete beats delete.
3. THE OPERATOR REVIEWS RISK. Producing a candidate list is free. Acting on it is not.
