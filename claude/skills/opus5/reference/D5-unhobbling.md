# D5: UNHOBBLE, THE MODEL ALREADY DOES MORE THAN YOUR PRODUCT ALLOWS

## DIRECTIVE

THE GAP BETWEEN WHAT THE MODEL CAN DO AND WHAT YOUR HARNESS LETS IT DO IS THE PRODUCT OVERHANG. Find it deliberately, on a schedule.

Source: "you should give the model slightly harder tasks than what you think it can do" [talk transcript].

## WHERE HOBBLING HIDES

| Form | Symptom | Test |
|---|---|---|
| Scope cap | A stage handles N items because an older model degraded past N | Raise N, measure |
| Manual step | A human does one step "because the model cannot" | Hand it the step |
| Narrow tool grant | Agent has read-only where write would finish the job | Widen and observe |
| Pre-chewed input | Pipeline pre-digests context the model could parse itself | Feed the raw form |
| Supervision requirement | A run is never left unattended | Run it once unattended, watched |
| Split-because-weak | Work split into stages because one model could not hold it | Try one stage |

Every one of these is a decision made against a specific past model. None self-expire.

## THE STANDING TEST PROBLEM

Adopt ONE hard task that the harness has never been trusted to do unsupervised. Re-throw it at every model release. Record pass or fail per generation.

| Field | Content |
|---|---|
| TASK | The single hardest end-to-end run in the system |
| WHY IT IS HARD | The specific capability that used to be missing |
| PASS CRITERION | Objective, measurable, decided before the run |
| VERIFICATION | Which rung of the D4 ladder proves the outcome |
| HISTORY | One row per model generation: date, model, result, failure mode |

This answers "can the new model do it now" directly, instead of by argument.

## THE HISTORY TABLE IS THE POINT

A single failed attempt tells you little. The sequence tells you everything: it shows the capability frontier moving, and it names the exact release where a limitation stopped being real.

Without the table, every model upgrade restarts the same debate from priors. D8.

## RULES

1. CHANGE ONE VARIABLE. New model against the same task and same verification, or the result means nothing.
2. DECIDE THE PASS CRITERION FIRST. Deciding afterwards produces a story, not a test.
3. A PASS DOES NOT REMOVE A BUCKET A GUARD. Capability is not permission. The model succeeding unsupervised does not make an irreversible action safe to leave unguarded.
4. RECORD THE FAILURE MODE, not just the verdict. The failure mode is what you re-test next time.
5. KEEP IT CHEAP. One run per release. If it is expensive, it will not get run.

## THE INVERSE ERROR

Unhobbling is not "remove the safety rails and hope". The source's own harness kept safety, permissions, and static analysis through an 80% cut.

| Remove | Keep |
|---|---|
| Capability assumptions from an older model | Guards on irreversible actions |
| Scope caps set by past degradation | Ground truth the model cannot derive |
| Manual steps the model can now do | Deterministic checks that are cheaper than judgment |
