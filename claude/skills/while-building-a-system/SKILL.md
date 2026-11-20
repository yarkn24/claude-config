---
name: while-building-a-system
description: Construction-time engineering discipline for anything that verifies or records work. Read before writing or editing a gate, guard, validator, precommit or CI check, hook, pipeline stage, audit trail, ledger, run manifest, or any artifact asserting that work happened; when wiring a new component into an existing pipeline; when two files or stores describe the same event; when a check cannot be satisfied, keeps failing after correct work, or someone proposes relaxing it; when a peer session or another agent may write the same file or store you are measuring or about to overwrite; and when a background or long-running job reports success. Triggers on add a gate, add a guard, write a validator, record that this ran, prove the run happened, mark it complete, and why is this check still failing.
---

# While Building a System

CANONICAL SOURCE: `~/.claude/reference/while_building_a_system.md`. Read that file now; it holds the full rule set and is the only copy that is maintained. This page carries the frame, never a second copy of the rules.

## Doctrine

**RULE 1, ABOVE EVERYTHING ELSE: NEVER BUILD IT COMPLEX. BUILD IT LEAN, SIMPLE AND FAST.**
Every rule below is subordinate to this one. A gate, guard, record or stage earns its existence
only at the smallest, fastest shape that still does the job; if the lean version cannot be made
to work, the answer is a different design, not a heavier one. Complexity is not a sign of rigour,
it is where the lies in the rest of this file come from: the component nothing calls, the field
nobody reads, the second writer of the same record. Cut first, then verify what survives.

**A system must not be able to lie about itself, and its most common lie is silence.** Absence reads as success far more often than a false statement does: an empty result, a producer nothing calls, a guard nothing schedules, a field summarizing a check that never ran.

**Build the contradiction before the claim.** For every claim a component will make, build the cheaper thing that could disprove it first. A claim nothing is able to contradict is decoration, and decoration is where fabrication hides.

## Sections in the canonical file

Gates, Records and evidence, Wiring, Boundaries, Verification, Concurrency, Documentation, Artifacts, Ordering.

The same file is what `hooks/system-file-doctrine-gate.sh` prints on the first system-file edit of a session, so the enforced text and the taught text cannot drift.
