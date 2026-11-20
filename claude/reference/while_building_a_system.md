# While Building a System

Read before designing a gate, a validator, a pipeline stage, or any component that records that work happened. Every rule here was paid for by a defect that shipped.

## Doctrine

**RULE 1, ABOVE EVERYTHING ELSE: NEVER BUILD IT COMPLEX. BUILD IT LEAN, SIMPLE AND FAST.**
Operator, 2026-09-04, verbatim: **"Sistem hicbir zaman karmasik kurulmamali her zaman lean basti ve
fast calisacak sekilde kurulmali"**. Every rule below is subordinate to this one. A gate, guard,
record or stage earns its existence only at the smallest, fastest shape that still does the job;
if the lean version cannot be made to work, the answer is a different design, not a heavier one.
Complexity is not a sign of rigour, it is where the lies in the rest of this file come from: the
component nothing calls, the field nobody reads, the second writer of the same record. Cut first,
then verify what survives.

**A deliberate corner cut is marked where it was cut, naming its ceiling and its upgrade trigger.**
Lean shipping accepts known limits (a global lock, an O(n^2) scan, a naive heuristic); unmarked,
they stop being decisions and become invisible design nobody can find again. Leave one greppable
comment per cut so the accepted limits are a list anyone can produce on demand. The marker naming
no trigger is the one that rots.

**A system must not be able to lie about itself, and its most common lie is silence.** Absence reads as success far more often than a false statement does: an empty result, a producer nothing calls, a guard nothing schedules, a field summarizing a check that never ran.

**Build the contradiction before the claim.** For every claim a component will make, build the cheaper thing that could disprove it first; a claim nothing is able to contradict is decoration, and decoration is where fabrication hides.

## Gates

**A gate must be satisfiable by the sanctioned tool.** Before shipping a check, run the approved happy path and watch it turn green. A gate whose evidence store no approved executor can write to is structurally unsatisfiable: correct work still fails it, and the only remaining exits are forging the record or disabling the check. Both are worse than having no gate.

**Prove the gate red, then green.** Trip it deliberately with bad input, then satisfy it with real output. A gate never observed in both states is untested, no matter how carefully it was reviewed.

**Never weaken a gate to make a failure disappear.** If a gate cannot be satisfied, the defect is the missing evidence path, not the gate. Connect the path.

**A gate reports; it does not infer intent.** Distinguish "did not run" from "ran and produced nothing" from "ran, produced, and was filtered." One verdict word for three states hides the one that matters.

**A gate enumerates the expected set, not the recorded set.** A unit that records nothing is absent from the recorded set and escapes, while a unit honestly recording zero trips the gate.

## Records and evidence

**A record is a byproduct, never a claim.** Any file asserting that work happened is derived by re-reading that work's real output. Never from the input list, never from the plan, never from a human summary of what was supposed to happen.

**Producers sign their own records.** Give every generated record fields that only the producer writes: a runs array, a schema version, a semantics key. A record missing them was hand-authored, and every reader must treat it as a to-do list rather than proof. State this in the reader, not only in the convention.

**Every count a record asserts is recomputable from the store it describes, and the query that recomputes it ships in the same change.** A completion record can claim dozens of units and hundreds of rows while the store holds none attributable to any of them, and without that query nothing in the system is able to say so.

**A verdict field is written only by the step that computes the verdict, and its unset value must not look like a pass.** A field pre-populated by an earlier gate carries one constant value on every row and still reads downstream as checked and approved.

**An aggregate never sums backed and unbacked components into one number.** A producer that wraps an unsigned predecessor and signs the merged result launders the predecessor's claim: the per-component signature still tells them apart, while the total silently does not, and the total is the field readers reach for. Report the backed figure, or report both and label them.

**A signature proves who wrote the record, never that the record is true.** Verify the component a signed record ingested, not just the envelope around it.

**Name the clock.** Every recorded event carries two timestamps: when it executed, and which subject period it belongs to. A repair run executing today for a run declared last week has to say both. Leaving that undefined creates the exact ambiguity where a fabricated date hides.

**Label derived data with its provenance.** Anything inferred rather than observed carries a marker saying so. Downstream consumers, human or model, cannot weigh a claim whose origin was erased.

**An allow-list derived from observed data is not the emittable vocabulary.** A corpus shows what has happened, never what can happen, so deriving a validator from one silently outlaws every legitimate branch that has not fired yet. Read what the producers can emit; if any of them passes a runtime variable through, the set is not enumerable and an allow-list will reject honest work.

**Where a forged record bypassed the writer, no write-side rule can stop it.** Establish how the bad value actually got in before designing the guard, or the guard defends a door the intruder never used.

## Wiring

**Supply must be invoked, not just written.** A capability that exists but nothing calls is not shipped, it is inventory. The most expensive form of this bug is a correct, tested helper sitting beside a pipeline that never references it.

**Every new component ships with its caller in the same change, plus a test that asserts the caller runs it.** Not a test that the component works. A test that it gets called.

**Prove reachability by running the caller, not by matching text.** Zero inbound references is a defect, and so is the single reference that turns out to be a comment, a string, or a branch nothing takes.

**A guard or maintenance job ships with its trigger and a visible last-run time.** One that nothing invokes announces nothing, so the symptom arrives later and elsewhere, as a store that grew without limit or as two things nobody compared.

## Boundaries

**Make the wrong call impossible to express before making it loud.** Two adjacent parameters of the same primitive type accept a transposed call, pass every shape check, and return a clean empty result, so distinguish them by keyword or type first, then validate shape at the entry point and name the expected shape in the error.

**Every stage declares the input fields it requires, and one test asserts the upstream stage emits them.** A missing input does not raise: the stage finds nothing to judge and reports success, so a mandatory judgment can be unreachable on every real row while every run looks green.

**Pin a dependency at both ends, and keep the component runnable outside its transport.** An open upper bound is an unreviewed change to your system scheduled for whenever someone else ships one, and it lands as a startup death that crosses the boundary as nothing but a generic connection error.

**Two files that must agree get one generator or one test, never two hand-maintained copies.** An id list beside an object list drifts the moment either is edited.

## Verification

**Exit 0 is not proof of completion. Verify by artifact.** Check that the output file exists, has the expected row count, and was written in this run's time window.

**A run that finishes far faster than expected is a stall until proven otherwise.** Investigate before celebrating; the fast path and the dead path look identical from the outside.

**A detached process is not running until you have seen its output.** Confirm liveness with the process table and the job's own progress lines, not with the launcher's return code.

**Build a long job to emit that progress unbuffered, and never read quiet as dead.** A filter anywhere in the output path holds every line until exit, and a supervisor sits idle while its child does the work, so the empty log and the idle parent are the two cheapest ways to misjudge a healthy run.

**Launch a long job through the runner's own detach, never a shell `&`.** A backgrounded child dies with the wrapper shell the moment the call returns, and it leaves the same empty log a healthy slow start leaves, so the two are indistinguishable at exactly the moment you decide whether to launch a second one.

**One writer per destination, enforced by a check and not by memory.** Before starting a job that writes a shared file, prove no peer is already writing it; a job wrongly believed dead is the usual way a second writer gets started.

**Measure before and after on real data.** Predicting what a change will fix is a hypothesis. Only the two measurements are evidence.

## Concurrency

**Measure against a snapshot nothing else can write.** A test run over state a peer can touch mid-run does not produce a weak result, it produces one indistinguishable from a real finding.

**A destructive write re-reads its destination at execution time and refuses to run if it changed since the plan was formed.** A peer can add real decisions to that destination between planning and execution, and the overwrite destroys them with no error raised on either side.

## Documentation

**Bind the architecture document to a test.** Have a test import every symbol the document names, so the document cannot drift from the code. A doc nothing verifies decays into a plausible lie, and a plausible lie costs more than no doc.

**Document the pipeline as one line of stage names,** then one table row per stage giving its entry point and its input to output shape. Verify that table backwards from the delivered artifacts: every artifact is the output of exactly one row, and the row that goes missing is a producer, because consumers are the steps people notice.

## Artifacts

**One authoritative artifact per stage, versioned by a real mechanism.** A directory holding several near-identical backups with hand-typed suffixes has no authoritative file, only candidates and a guess.

**Keep the deletion decision with a human,** and make staleness visible instead: stamp every artifact with its producing run so an orphan is obvious without anyone having to remember.

## Ordering

**Fix at the choke point every caller routes through, not at the path the report names.** A report
names a symptom; grep the callers of the function you are about to touch before editing. One guard
in the shared function is both the smaller diff and the complete fix, while patching only the named
path leaves every sibling caller broken.

**Fix causes in dependency order, not in the order the report lists them.** When an upstream repair can change the input to a downstream step, run the upstream one first. Budgeted or irreversible work spent on a set that is about to change is spent twice.

## While making an optimisation

Read before proposing to make anything cheaper or faster. Every rule here was paid for by an optimisation programme that spent weeks on the wrong lever.

**Decompose the bill into quantity times price before choosing a lever.** Vendor, tier and model choice all move price per unit. When consumption is the anomaly, price shopping answers a question nobody asked, and it answers it well enough to absorb weeks. Establish which factor is out of line first, then optimise that one.

**Write the cost formula before measuring anything.** Where each iteration re-sends accumulated state, the total grows with the square of the iteration count, so iteration LENGTH dominates iteration COUNT and both dominate per-unit price. Deriving that takes minutes, needs no instrumentation, and names the lever measurement will later confirm.

**Measure at the resolution of the thing you intend to change.** A per-run log cannot show a per-iteration effect; the defect's shape is simply absent at that granularity. An analysis is bounded by its log's resolution and looks complete anyway. If the log cannot answer "what did one unit cost, and why", fixing the log is the first optimisation, not a side task.

**Read one real trace end to end before proposing anything.** Aggregates report totals and hide shape. The most expensive omission is the trace nobody opened, because one read of it usually answers what summaries spend weeks approximating.

**Rank by the billed unit, never by a proxy for it.** Counting operations while being billed for iterations overstates every saving, because operations chain and iterations do not. Convert to the billed unit before ranking, or the ranking is fiction.

**Rank levers by measured share times achievable reduction,** never by how easy the change is to describe. The one-word change gets proposed first and re-proposed for weeks; being small to state says nothing about being large to land.

**Prove the target is loaded at runtime before designing its removal.** A file present in the repository is not a file the runtime reads. Trimming what was never loaded costs full effort and returns nothing.

**Prove the lever is operable from where you will pull it.** A parameter can be correct, current and documented, and still be unreachable from the mode actually in use. Verify reachability before costing the saving.

**Read the rulebook for the component before optimising it.** A change a binding rule forbids is not a cheap change with an approval step; it is a different design decision, and it belongs to whoever owns the rule.

**A change you cannot prove landed is not a change.** Before swapping an implementation, confirm the run record captures which one served. Where it does not, adding that field is the first task, not a follow-up.

**Prove a guard by tripping it, and prove the trip actually landed.** A mutation that silently fails to mutate looks exactly like a guard that fails to fire: both show green. Before reading a red-then-green result, confirm the file really changed, by hash or by diff. Guess the stored format wrong and you will conclude a working guard is broken, or worse, that a broken one works.

**A new component must be registered everywhere components are enumerated, and every registry is its own silent failure.** A build manifest, a permission or scope allow-list, a guard's membership set, a documentation table: each omission fails quietly and separately, and exact-membership sets never match a longer sibling name. When adding a component, grep for the existing siblings by name and add yours beside every hit.

**Where an iteration's own output re-enters its next input, output volume IS the growth rate,** so the cheapest large win is usually producing less per step rather than taking fewer steps. Measure what the produced volume is actually made of before assuming it is the visible payload; the invisible part is often nearly all of it, and it is often reachable by a single existing setting.

**An inherited number is unverified.** A figure re-stated across documents accumulates authority without accumulating evidence. Re-derive it where it decides something, and expect the figures nobody re-derived to be the ones that fail.
