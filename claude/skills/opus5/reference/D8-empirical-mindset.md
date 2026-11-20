# D8: BE EMPIRICAL, FORGET YOUR PRIORS

## DIRECTIVE

RUN THE EXPERIMENT INSTEAD OF ARGUING FROM MEMORY. What was true of the last model is a hypothesis about this one, not a fact.

Source: "it's not a theoretical science, it's become an empirical science" [talk transcript].

## THE LOOP

| Step | Action |
|---|---|
| 1 | Give the model a task at or past the edge of what you expect |
| 2 | Give it a way to verify its own work |
| 3 | Watch where it actually struggles |
| 4 | Fix that specific gap: better framing, a skill, or missing context |
| 5 | Re-run |

The source describes exactly this and adds that the fix is usually prompting, a skill, or supplying missing context through a tool. Note the order: observe first, then fix.

## PRIORS THAT EXPIRE SILENTLY

| Prior | Written against | Re-test on |
|---|---|---|
| "The model cannot hold this much context" | An older context limit | Every release |
| "It will not write this well unprompted" | An older model's style | Every release |
| "It needs the steps spelled out" | An older instruction-following profile | Every release |
| "It cannot be trusted unsupervised here" | An older reliability level | Every release |
| "This tier is enough for this stage" | An older price and quality curve | Every release |

None of these announce their own expiry. A dated rule with no revalidation is a prior wearing a rule's clothes.

## DATE-STAMP EVERY MODEL-COUPLED RULE

Any rule justified by model behaviour carries the model and the date it was validated against.

```
# RULE: <the rule>
# BASIS: observed failure, <date>, <model>
# EVIDENCE: <path to the run or ablation>
# REVALIDATE: next model release
```

A rule naming a specific model version is a rule with a built-in expiry date. That is a feature. Hardcoded model identifiers rot fastest of all, because they break silently when the alias moves.

## THE COWORKER FRAME, AND ITS LIMIT

Treat the model as a capable colleague: give context, state the goal, let it choose the method.

The frame breaks where a colleague would also fail, and where failure is irreversible. Bucket A guards exist because trust in capability is not the same as tolerance for a bad outcome reaching the real world.

## THE HONEST LIMITS

Quote these when someone claims the problem is solved. Source states coding is solved "for the kind of coding that I do. It's not solved for everyone" [talk transcript], and names the exceptions:

| Still hard | Implication |
|---|---|
| Deep systems code | Verification matters more, not less |
| Distributed systems | Expect wrong answers that look right |
| Pixel-level UI verification | Needs an oracle, rung 4 |

Vision and computer use improved substantially and are still described as imperfect.

## IGNORE SECONDHAND ADVICE, INCLUDING THIS DOCUMENT

The source's own guidance is to distrust influencer advice and look at the model directly [caption, 00:23:18]. There is no single trick.

APPLIED HONESTLY, THAT INCLUDES THIS SKILL. Every directive here is a hypothesis about your harness until your own ablation confirms it. If a measurement here contradicts your evidence, your evidence wins.

## RED FLAGS

| Thought | Reality |
|---|---|
| "We already know this does not work" | When, and against which model? |
| "This rule has always been there" | That is age, not justification |
| "It is obviously needed" | Then it will survive the ablation |
| "The video says so" | The video is one source with a vendor bias |
| "Smaller is better" | Only if the quality metric held |
