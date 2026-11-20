# AUDIT PLAYBOOK

## SCOPE

AUDIT MODE ANSWERS ONE QUESTION: does each piece of this harness still earn the context it costs?

Takes a target directory. Produces a classified inventory and an evidence-backed candidate list. CHANGES NOTHING.

ADVISORY ONLY, ASK BEFORE APPLY. The audit ends at a proposal. It never edits, disables, or deletes. If the operator approves a proposal, applying it is a separate, explicitly requested task.

## RUN THE ORIGIN TEST BEFORE ANYTHING ELSE

ASK THE OPERATOR: were these hooks and rules written in response to real incidents?

| Answer | Consequence for the whole audit |
|---|---|
| Yes | Removal is OFF THE TABLE by default. The audit reports correctness defects, duplication, and verification gaps instead |
| No, mostly generic | Proceed with the normal bucket flow |
| Unknown | Assume yes. Ask before proposing any removal |

A HARNESS BUILT FROM INCIDENTS IS ALREADY THE PRODUCT OF D2. Every hook is a recorded failure with a response attached. Proposing to delete them is proposing to re-run incidents that already happened.

WHAT THE AUDIT IS STILL WORTH IN THAT CASE, and it is a lot:

| Finding type | Still valuable? |
|---|---|
| Contradictions between docs and enforcing code | YES, highest value |
| Gates that cannot fail, tests that exit 0 while failing | YES |
| Validators wired to nothing | YES |
| Duplication of one rule across many files | YES, this is the real context cost |
| Misfiring hooks producing false positives | YES |
| Stale documentation describing dead mechanisms | YES |
| Removal candidates | Usually NONE, and that is a correct result |

## DO NOT BUILD A THIRD AUDITOR

Two skills already own parts of this pipeline. Re-implementing them is the exact duplication this doctrine exists to remove.

| Step | Owner | Why not here |
|---|---|---|
| 1. MEASURE | `context-budget` skill | Already counts tokens across agents, skills, hooks, MCP, and the CLAUDE.md chain |
| 2. CLASSIFY | THIS SKILL, `keep-or-cut.md` | Neither existing skill has an A/B/C/D verdict layer |
| 3. ABLATE | THIS SKILL, sandbox only, with the operator's approval | Neither existing skill produces empirical evidence |
| 4. ACT | `config-gc` skill | Already owns soft-delete, per-item confirmation, undo, and the AFK no-delete rule |

The gap this skill fills is steps 2 and 3: the verdict layer and the empirical layer.

## WHY STEPS 2 AND 3 ARE THE GAP

Both existing skills classify by static heuristic, for example treating size as a proxy for cost. Size is a cost measure, not a value measure. A 400-line file that prevents a wrong submission is cheap; a 12-line style nag the model would honour anyway is expensive.

Deciding value by heuristic is guessing, which D2 forbids explicitly.

## SEQUENCE

### STEP 0: REPAIR MISFIRING GUARDS FIRST

A hook that false-positives, or that reports its reason to the wrong stream, corrupts every later judgment.

| Defect | Consequence if not fixed first |
|---|---|
| False positive on valid input | Rule looks wrong when only the check is wrong |
| Blocking message printed to stdout, not stderr | Operator sees a block with no reason |
| Doc describes a check the code does not implement | Audit trusts a rule that is not enforced |

A MISFIRING RULE IS NOT A DISPROVEN RULE.

### STEP 1: BASELINE

Record before-numbers. Without them no later improvement claim is provable.

| Metric | How |
|---|---|
| Always-on instruction bytes and tokens | Sum the files loaded every session |
| Hook files on disk | Count the scripts |
| Registered invocations | Parse every settings file, count hook entries per event |
| On-demand rule bytes | Sum the second-layer files |
| Command and agent definition bytes | Sum each directory |
| Known test failures | Run the suite, record the result |

Run it twice. Two identical runs prove the measurement is reproducible.

### STEP 2: INVENTORY AND CLASSIFY

Every registered hook, every always-on section, every path-scoped rule file gets a bucket and a one-line justification. Use the classification record in `keep-or-cut.md`.

Expected shape, to VERIFY rather than assume: guards against fabrication, personal data, and immutable fields land in A and B; style guards land in D.

### STEP 3: FIND THE DEAD LAYER

Dead items are free to remove and prove nothing when kept.

| Check | Method |
|---|---|
| ORPHANS | Scripts on disk that no settings file registers |
| UNWIRED VALIDATORS | Verifiers called by no command, hook, test, or schedule |
| FAKE GATES | Scripts framed as gates with no non-zero exit path |
| STALE DOCS | Documented mechanisms that no longer run |
| MODEL-COUPLED RULES | Any rule naming a superseded model version |
| UNREVALIDATED RULES | Rules predating the current model with no revalidation date |

An orphan is maintenance cost with zero effect. Removing it needs no ablation, only confirmation that it is genuinely unreferenced.

### STEP 4: MEASURE DUPLICATION

Count the distinct places each rule is stated. One canonical home, everything else a pointer.

```
grep -ril "<rule phrase>" <target> | wc -l
```

Rank by count and fix the worst first. Duplication is what causes the model to ignore instructions, per official guidance.

### STEP 5: ABLATE BUCKET D

Only bucket D, and only with evidence from a sandbox run the operator approved. See `D1-delete-first.md`.

Output is a RANKED CANDIDATE LIST with evidence per item, not a removal.

### STEP 6: HAND OFF

Survivors go to `config-gc` for soft-delete with per-item confirmation and an undo path. Do not delete here.

## OUTPUT FORMAT

One dated file under a `harness_audit` directory:

| Section | Content |
|---|---|
| BASELINE | The before-table, reproducible |
| CLASSIFICATION | Every item with bucket, justification, action |
| DEAD LAYER | Orphans, unwired validators, fake gates, stale docs |
| DUPLICATION | Rules ranked by number of statement sites |
| CORRECTNESS DEFECTS | Contradictions and doc-versus-code mismatches found while measuring |
| ABLATION EVIDENCE | Per candidate: honoured or violated under `--bare` |
| CANDIDATES | Ranked, each with evidence and a proposed action |
| NOT PROPOSED | What was deliberately left alone, and why |

The NOT PROPOSED section matters. An audit that only lists cuts reads as a recommendation to cut everything.

## STOPPING CONDITIONS

STOP AND REPORT, do not proceed, when:

- A correctness defect could corrupt real output. Fix that first; it outranks any ablation.
- A rule's bucket is genuinely ambiguous between A and D. Default to A and flag it.
- Removal would need a deletion. That belongs to the operator and to `config-gc`.
- Running under an autonomous mode where deletion is forbidden. Produce the list, delete nothing.
