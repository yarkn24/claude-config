# D7: EVALS OUTLIVE PROMPTS, BUT SATURATE

## DIRECTIVE

AN EVAL IS A DEPRECIATING ASSET. It outlives the prompt it was written for, then the model catches up and it stops discriminating.

Source: an eval "might live for maybe one, two, three model generations" [talk transcript], after which "we just saturate the eval and then we have to throw it away" [talk transcript].

## THE LIFECYCLE

| Stage | Signal | Action |
|---|---|---|
| BORN | Written from an observed, repeated failure | Record the failure it encodes |
| USEFUL | Some runs pass, some fail | Keep, it discriminates |
| SATURATING | Pass rate near 100% across several runs | Flag it, look for a harder variant |
| SATURATED | Always passes, and has for a full generation | RETIRE, it now only costs time |
| STALE | Tests behaviour the system no longer has | DELETE |

An eval that always passes is not proof of quality. It is a test that stopped asking a question.

## BUILD FROM OBSERVED FAILURE, NEVER FROM IMAGINATION

Same rule as D2. An eval invented from a hypothetical failure tests your imagination.

| Origin | Verdict |
|---|---|
| A real failure that recurred | Valid |
| A real failure that reached the real world | Valid, highest priority |
| "This could theoretically break" | Not yet, wait for evidence |
| "The rule says so, therefore test it" | Test the rule's effect, not its text |

## WHY EVALS OUTLIVE PROMPTS

A prompt encodes HOW. A model upgrade invalidates it.
An eval encodes WHAT GOOD LOOKS LIKE. That survives the upgrade.

CONSEQUENCE: when a new model ships, delete prompt text freely and keep the evals. The evals are what tell you whether the deletion was safe.

This is why D1 is not reckless. Ablation without evals is guessing; ablation with evals is measurement.

## THE RECORDED BASELINE

A test suite with unrecorded failures cannot serve as an ablation instrument.

| Anti-pattern | Fix |
|---|---|
| Known failures described in handoff notes | Record them in a committed baseline file |
| "11 tests fail, that is normal" | Name which 11, with dates and reasons |
| No runner config, ad hoc entry points | One command that runs everything and reports |
| Pass or fail unknown before a change | Establish the baseline first |

RULE: before any ablation, run the suite and commit the result. A delta against an unknown baseline proves nothing.

## RETIREMENT IS NOT FAILURE

Throwing away a saturated eval is the intended end of its life. Keeping it costs run time and creates false confidence.

RETIRE WHEN: it has passed every run for a full model generation AND the behaviour it guards is now covered by a deterministic check.

KEEP DESPITE SATURATION WHEN: it guards a bucket A irreversible action. There, the cost of the check is trivial against the cost of the failure, and a rare regression is exactly what it exists to catch.
