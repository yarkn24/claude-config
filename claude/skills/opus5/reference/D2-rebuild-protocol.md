# D2: RE-ADD ONLY ON REPEATED FAILURE

## DIRECTIVE

AN INSTRUCTION EARNS ITS PLACE BY SURVIVING A DOCUMENTED, REPEATED FAILURE. One bad output is noise.

## THE FOUR STEPS

| Step | Action | Source |
|---|---|---|
| 1 | DELETE | "the first step is you delete" [talk transcript] |
| 2 | USE IT | "The next step is you use it" [talk transcript] |
| 3 | OBSERVE REPEATED FAILURE | "only when you see it repeatedly stumble on the same thing" [caption, 00:08:14] |
| 4 | ADD IT BACK | "that's when you add it back" [caption, 00:08:14] |

Step 2 is the one people skip. Deleting and then reasoning about what to restore is guessing.

## THE RULE THAT ALREADY PASSED THIS TEST

A HOOK BUILT AFTER A REAL INCIDENT HAS ALREADY COMPLETED ALL FOUR STEPS. The failure was observed, it recurred, and the rule is the recorded response.

Proposing to delete such a rule is proposing to re-run step 3 in production, on a system that already paid for that answer once.

| Situation | Correct action |
|---|---|
| Rule has a recorded incident behind it | KEEP. Attach the incident as its evidence |
| Rule's origin is undocumented | Ask the operator. Do not assume it is decorative |
| Rule looks like style but prevented a real failure | KEEP. Form does not decide the bucket, consequence does |

DELETING AN INCIDENT-DERIVED RULE IS NOT AN ABLATION. It is discarding an eval result.

## WHY GUESSING FAILS

> "you don't wanna guess what's the instruction that the model needs because you might not predict it correctly" [talk transcript]

Static heuristics are guessing in disguise. "Over 200 lines equals heavy" and "this rule looks obvious" are both priors, not observations.

## THE COST OF A WRONG RE-ADD

The model reads the instruction every single time you use it. A needless line is not a one-off cost; it is a permanent tax that also dilutes the lines that matter.

## THE THRESHOLD

Define "repeated" before you start, not after. Suggested floor:

| Signal | Threshold |
|---|---|
| Same failure, same task type | 3 occurrences |
| Failure reaches the real world (bucket A) | 1 occurrence, add immediately |
| Failure is cosmetic | 5 occurrences, or leave it out |

Bucket A is exempt from the repetition requirement. Do not wait for a second leaked phone number.

## RECORD THE EVIDENCE NEXT TO THE RULE

Every re-added rule carries its own receipt. Without it the next audit cannot tell a load-bearing rule from a superstition.

```
# EVIDENCE: model omitted the compile step in 3/3 bare runs, 2026-08-06.
# Ablation: docs/harness_audit/ablation_2026-08-06/
# REVALIDATE: next model release.
```

## PREFER A HOOK OVER A SENTENCE

Official guidance: if the model already does it right, delete it; if it must be enforced, convert it to a hook.

| Enforcement | Context cost | Reliability |
|---|---|---|
| Prose in CLAUDE.md | Every session, forever | Probabilistic |
| Hook or script | Zero context | Deterministic |

A rule that can be checked mechanically belongs in bucket C, not in always-on prose.

## RED FLAGS

| Thought | Reality |
|---|---|
| "I will add this so it never happens again" | Did it happen more than once? |
| "Better safe than sorry, keep it" | Then say which failure it prevents, with a date |
| "It is only a sentence" | Multiply by every session for the next year |
| "I know this model needs this" | You knew that about the previous model |
