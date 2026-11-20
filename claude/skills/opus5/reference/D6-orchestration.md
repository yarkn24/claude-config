# D6: SCALE WITH ORCHESTRATION, NOT INSTRUCTIONS

## DIRECTIVE

WHEN A TASK IS TOO BIG, ADD STRUCTURE, NOT SENTENCES. More prompt text does not buy more capacity; more context windows do.

Source describes the design as "an algebra for agents" [talk transcript]: agents composed in sequence and in parallel, with a verification stage between fan-outs.

## THE COMPOSITION PRIMITIVES

| Primitive | Shape | Use when |
|---|---|---|
| SEQUENCE | A then B then C | Each stage needs the previous result |
| PARALLEL | A, B, C at once, barrier, then merge | Stages are independent AND you need all results together |
| PIPELINE | Each item flows through all stages independently | Items are independent; no cross-item dependency |
| FAN-OUT then VERIFY | Many producers, then a checking stage | Output quality varies and errors are costly |
| LOOP UNTIL DRY | Repeat until N rounds add nothing new | Discovery of unknown size |

DEFAULT TO PIPELINE. A barrier is justified only when a stage genuinely needs every prior result at once, for example deduplication across the full set.

## THE VERIFY STAGE IS NOT OPTIONAL

The described pattern is fan out, verify or summarize, fan out again. The middle stage is what keeps a large run from compounding its own errors.

Fan-out without verification multiplies mistakes at the same rate it multiplies throughput. D4.

## WHEN ORCHESTRATION IS THE WRONG ANSWER

| Situation | Better answer |
|---|---|
| One long file to edit | One agent, no orchestration |
| Stages share mutable state | Sequence, or isolate the state |
| The task is unclear | Clarify first; parallel confusion is still confusion |
| Verification does not exist yet | Build the verifier first |
| Budget is the binding constraint | Fewer, better-scoped agents |

## THE COST CAVEAT, BINDING HERE

The source recommends orchestration at a scale not validated for this environment. Validate cost and benefit on a small scope first.

SEPARATE THE LESSON FROM THE SALES PITCH:

| Free lesson, adopt | Expensive lesson, budget first |
|---|---|
| Compose in sequence and parallel deliberately | Thousands of agents |
| Put a verify stage between fan-outs | Multi-week unattended frontier runs |
| Let independent work run independently | Frontier model for mechanical stages |

## LOCAL RULING, 2026-08-06

| Decision | Status |
|---|---|
| Opus plans, Sonnet executes | UNCHANGED |
| Multi-day unattended frontier runs | NOT ADOPTED |
| Parallel dispatch within a batch | ALREADY IN USE, keep |
| Model tier per stage | Match tier to judgment required, not to prestige |

## SIZING A FAN-OUT

| Question | If no |
|---|---|
| Is each unit genuinely independent? | Use sequence |
| Does a verifier exist for the merged output? | Build it first |
| Is the token cost bounded and acceptable? | Reduce the fan-out |
| Would a single agent finish sooner than the coordination costs? | Do not orchestrate |

Orchestration has real overhead: coordination, merge logic, and partial-failure handling. It pays only above a threshold of genuine parallelism.
