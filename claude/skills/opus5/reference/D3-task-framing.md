# D3: TASK, GUARDRAILS, EXIT CRITERIA, THEN STOP TALKING

## DIRECTIVE

DESCRIBE WHAT DONE LOOKS LIKE, NOT WHICH KEYSTROKES TO MAKE. Step-by-step scripting degrades modern models.

## THE FOUR-PART FRAME

| Part | Question it answers | Failure if missing |
|---|---|---|
| TASK | What outcome do I want? | Model solves the wrong problem |
| GUARDRAILS | What must never happen? | Model takes a forbidden shortcut |
| EXIT CRITERIA | How do I know it is done? | Model stops early or never stops |
| VERIFICATION | How does the model check itself? | Model declares success while wrong |

The source names the first three explicitly. The fourth is D4, and it is what makes the other three safe to leave loose.

## OVER-SPECIFICATION SMELLS

| Smell | Why it hurts |
|---|---|
| Numbered micro-steps for work the model already knows | Spends attention on sequencing, not on the problem |
| Two step counters for the same content | Ambiguity; the model must guess which one governs |
| A checklist where most items are mechanical | Buries the few items that need judgment |
| "Remember to X" repeated across files | Dilutes every other instruction |
| Prescribing HOW when only WHAT matters | Blocks a better approach the model could have found |

## THE REWRITE

Convert imperative sequences into outcome plus constraint. Keep every real constraint; drop the choreography.

BEFORE, choreography:

```
1. Open the file.
2. Find the summary section.
3. Rewrite it in the JD's language.
4. Count the characters.
5. If over 697, shorten it.
6. Re-count.
7. Save.
```

AFTER, frame:

```
TASK: rewrite the summary in the JD's language.
GUARDRAILS: only claims evidenced in master_extract; no fabricated domain.
EXIT CRITERIA: 606 to 697 characters, cv_lint.py reports 0 BLOCK.
VERIFY: run cv_lint.py --section summary and fix what it reports.
```

The constraint survives. The step-by-step does not. The character limit moved from a manual count into an exit criterion a script enforces.

## WHAT NEVER GETS DE-SPECIFIED

| Content | Reason |
|---|---|
| Bucket A guards | An irreversible action needs an explicit prohibition |
| Ground-truth values | The model cannot derive an approved title list |
| Exact output paths and filenames | Downstream tooling depends on them |
| Threshold numbers | "About right" is not a threshold |

De-specification means removing choreography, not removing constraints.

## CALIBRATION WARNING

The advice is calibrated on frontier models. If a pipeline stage runs a smaller or older model, de-specification is a HYPOTHESIS to test, not a fact to apply.

RULE: A/B one stage. Same input, both prompt versions, compare the real quality metric. Ship only on a measured improvement.

## MEASURING OVER-SPECIFICATION

Count imperative absolutes per line of prompt.

```
grep -ocE 'BINDING|NEVER|FORBIDDEN|ALWAYS|MUST|MANDATORY' <file>
```

One absolute every 10 lines or fewer signals a prompt that has been patched repeatedly rather than designed. Treat it as a candidate for the frame rewrite, then A/B it.
