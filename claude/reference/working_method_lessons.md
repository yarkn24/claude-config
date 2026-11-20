Generic working-method lessons distilled from the operator's long-running sessions. Consult on demand; CLAUDE.md wins on any conflict.

## Verification and evidence

- **A report is not a state.** A subagent's "done, row logged" or a tool's "updated" describes intent. After any batch, check the real artifact (file, row, count) against the expected list.
- **Verify before conceding.** When the operator says "you forgot X" or "that is wrong", Read, grep or ls first, then answer from the result. Reflexive "you are right" before looking is a violation, and the claim may be wrong.
- **An absence claim needs a full sweep.** "The field is not there" after one selector or one key is an unproven negative. Scan the whole namespace for the value's shape, then read off which names matched.
- **A note of an intended edit is not proof it landed.** A changelog line, memory entry or ticked task is a claim about the past. grep the target for the thing the note says is there before building on it.
- **An inherited claim is unverified until you check it.** A claim in a brief or handoff repeated four times was still wrong when one `stat` and one `grep` finally tested it.
- **Check the load-bearing claim, not the easy ones.** When spot-checking a document before publishing, verify the sentence the whole conclusion rests on first. Peripheral facts (prices, availability) passing proves nothing about the causal claim.
- **Relay the source, not your summary of it.** A paraphrase in a brief drops the caveat that limited the finding, and every later agent inherits an unqualified claim. Cite file and line; open the primary source before stating an agent's claim as fact to the operator.
- **Quote marks mean byte-verbatim.** Text in quotes must match the primary source exactly. A tightened paraphrase presented as a quote is fabrication even when the meaning survives.
- **A fetch failure is not an unreachable source.** Before writing "403" or dropping a claim, retry with `curl -sL -A "<browser user agent>"`; for PDFs pipe to `pdftotext`. Bot detection often blocks only atypical headers.
- **Exit code 0 is not completion.** Judge a worker by its declared status and by the artifact it was required to leave. Halt when a step's required input is absent instead of letting later steps run over nothing.
- **Suspect a job that finishes too fast.** A run far quicker than its workload allows has probably stopped at a gate or exited early. Pipelines built on interrupt points can return success while paused at the first one.
- **A stored verdict is a claim about a document at a moment.** Nothing binds a stamp to the content it judged; the path stays while the contents change. Re-derive instead of trusting the stamp.
- **A headline number from a gate is a claim to verify.** Reporters misread paths: one read a stale parent file, another counted 1422 where the real figure was 735. Recompute from the underlying artifacts before quoting.
- **Missing, not-run and zero are three different facts.** Only a real zero is evidence about the world. Coercing a missing count to 0 in a streak or health metric manufactures failures; filter to rows that actually executed first.
- **An empty-success status hides engine failure.** A tool that writes `ok` with zero results for both "ran and found nothing" and "never fetched" cannot distinguish a dead engine from an empty source. Compare against a prior successful run of the same query before concluding "nothing there".
- **A valid-looking header can sit on an unfiltered feed.** Very short or very common search terms returned genuine-looking result counts while only a few percent of items matched. Sample the items, never trust the count.
- **Labels must describe what happened.** Two code paths set the same reason string, so investigators hunted a missing file that existed. One failure mode, one label.
- **Validate dates and ids on write and on read.** An impossible date in a test file made a never-run engine look active because the reader globbed every file. Reject bad values at the writer and filter them at the reader.
- **Compute durable numbers after the last step.** A count typed into a permanent document mid-run is stale as soon as the run continues. Write it at close, or add a close-time check that recomputes it.
- **Planning figures need a provenance check.** Turn counts and token figures from an obsolete pipeline overstated a prize about 3.9 times. Confirm a figure comes from the current configuration before sizing work on it.
- **Duplicate transcript rows double count.** Each assistant turn can be written as 2 or 3 rows that repeat the fixed input fields. Deduplicate by message id before summing cost; the uncorrected corpus was inflated about 2.4 times.
- **A command-wrapping proxy can lie.** A token-saving CLI wrapper returned "files identical" on a large real diff, truncated `git log` to 50 entries with no notice, and reported "0 files" for real grep matches. When a result looks wrong, rerun with the raw binary by absolute path.
- **A claim about a guard needs the guard's real output.** A comment saying a regex "skips prose" is design intent. Run it and read what it flags.

## Tests and guards

- **Instruction is advice; enforcement is a guard.** A rule living only in a brief, command file or agent definition is skipped under pressure, compaction or a different route. If losing something is possible, make the bad state impossible or visible with a test or hook. Why: a brief clearly said to save full responses and a run saved a truncated subset anyway.
- **Prove the test can fail.** Remove or revert the thing under test and watch the test go red before trusting it. A test that reads a file the code never writes, or probes an input that short-circuits before the guarded branch, is green by construction.
- **Drive the public entry point.** A unit test on a helper stayed green when the helper's only call site was deleted or re-hardcoded. Route at least the key assertions through the path the defect travels.
- **Assert the probe arrived.** Add a positive assertion that the test input actually reached the branch being guarded, not just that nothing failed.
- **A string-grep test vouches for text, not behavior.** A test checking that a name appears in source passed while the call raised `NameError` inside a swallowing `try/except`. Execute the code.
- **A parameter no caller passes is not a feature.** When adding a parameter, add the test that drives the entry point which must pass it, in the same change. A writer with no caller is a backlog, not a capability.
- **A green test that asserts the defect protects it.** Fixing the code turns it red and invites reverting the fix. Find such tests at every site where the defect lives and update them with the fix.
- **A guard reaches only what its matcher matches.** A hook on `Edit|Write` never saw a Python script writing the protected file through Bash. Close such gaps with a check that inspects the resulting state (a pre-commit test), not a second hook that guesses at commands.
- **Gate and assertion must read the same text.** A check gated on a flag appearing on the same line as a script name skipped four of five files after the invocations became multi-line. Print what the guard actually inspected.
- **Fixtures in shared real directories leak on hard kill.** A `finally` cleanup never runs on SIGKILL. Isolate paths for any test or measurement probe (scratch dir, pre/post hash snapshot) because an instruction to "be careful" is not isolation: a probe overwrote production files that way.
- **A test must not touch production data.** A new suite appended placeholder rows to a real journal that a metric depended on. Check the real files after running a new suite that calls real scripts.
- **A test that depends on the wall clock is green by accident.** It flipped to 4 failures at midnight. Pin dates and inputs the test does not own.
- **A test asserting a fallback was not taken depends on the machine.** Pin it to an input the fallback provably cannot resolve, and test the fallback separately with a resource the test creates.
- **A script-shaped guard can blind the whole test runner.** A module-level `sys.exit(...)` runs at collection time under pytest and aborts the entire sweep. Guard it with `if __name__ == "__main__"`. Also watch for basename collisions between two test files that abort collection.
- **Trace a failing fixture before changing code.** Confirm whether it is stale (the definition moved on) or a real defect. Before deleting an "untracked, harmless" file, grep every test for its exact filename.
- **Duplicated rules drift.** An exception added to one copy of a rule silently does not exist in the other, and the stricter copy wins. Keep one implementation and call it, or pin both copies with the same test case.
- **A gate's proof must be unforgeable by the checked party.** "A file exists containing the record id and the reviewer's keyword" can be written by the implementer. Require an artifact only the real reviewer can produce, such as the reviewing session's transcript.
- **A guard exempting subagents by one field can block top-level headless sessions.** A session started in print mode lacks the field and looks like the main session. Use a signal the omission cannot fake, such as the parent process's argv.
- **Scope a process-order guard to the phase it governs.** An "artifact must be fresh before this edit" hook fired on a later review pass that legitimately re-edits the same file. Match on the authoring phase or caller, not only the filename.
- **Derive a precondition from what the downstream guard compares.** Checking that "the named consumer is inactive" missed the broader invariant "no process that snapshotted this file is still relying on it".
- **A named replacement must be measured capable.** Reachable is not capable: a script named as the replacement check resolved 0 of 33 cases when run as a pure function. Run it over real data before deleting the original.
- **A split document needs a reader-location check.** A conservation test proved every line survived a file split but could not see a binding rule landing in the file the executor never reads. Check where the reader will look.
- **A checker that judges what reaches it is blind.** One audit reported "81 sources" against a plan of 118 because it counted its own input. Compare against what was promised, not what arrived, and never let an artifact choose the scope of its own audit.
- **Verify through the real call path.** A runner that stamps a label onto a temporary input can leak it back onto the authoritative data when a tier passes unknown fields through. Compare input and output records after a real run.
- **Measure before widening a guard.** A form validator mistaken for a truth validator (presence is not correctness) passed an item whose value was wrong. Confirm what the guard actually proves before relaxing or extending it.

## Delegation and context cost

- **Cost is turns times starting prefix.** Per dispatch, cost scales with how many turns it runs and how large its declared prefix is, not with the size of files it reads. Shorten dispatches and keep always-loaded text small.
- **Set effort as well as model on every dispatch.** A blank effort inherits the session level; one silently ran 150 subagents at the highest setting for about double the tokens. Default medium, high for long or quality-critical writing, low for bounded lookups.
- **Subagents filter before they report.** A sweep over logs or data pipes through grep, `head -c` or `wc` and returns counts plus a file path. Raw multi-megabyte output costs a full extra turn for no signal.
- **Subagents do not load the project instruction file.** A rule that exists only as a pointer in it never reaches the agent that must obey it. Put the rule inline in the agent definition or in a file that agent is told to read first.
- **Never edit an agent definition while a dispatch of that type is running.** In-flight dispatches vanished with no notification, no output and no trace. Wait for all of them to end, edit, then start new ones.
- **Isolate heavy transient work in use-and-throw subagents.** Fetching, syncing, scanning and research write results to disk and return a short summary; the main session keeps orchestration, state and dialogue. This beats compaction because no lossy summary or cache miss is involved.
- **Decide subagent versus inline by three questions.** Is the task independent of the current context, is it large enough to repay the roughly 3-4k token dispatch cost, and is it free of a run-read-modify-rerun loop? A feedback loop stays inline because a subagent resets memory every step.
- **During a decision walkthrough the main session only asks.** One plain-language question per item and record the answer; every check, measurement, edit and shell call goes to a background subagent so no tool output scrolls past the operator.
- **A stalled mid-tier subagent is relaunched one tier up.** Confirm the stall with two real timestamped reads showing no change (long runtime alone is not a signal), kill it, and rerun the same task on the stronger model. A task that stalls a smaller model is usually a judgment-complexity signal.
- **Give stronger models outcome and fence, not steps.** For research and exploration state the task, guardrails, exit criteria and verification, and let the model choose the method. For production pipelines run as a machine, keep behavior deterministic and scripted instead.
- **Move a validated block with a file copy.** When a checked block must go verbatim from a draft into the real file, use `cp`. Asked to apply it with one big Edit, the model split it into six small edits because reproducing a large old_string felt error-prone.
- **A mechanical extraction goes through the existing script.** A subagent allowed to choose its method hand-transcribed hundreds of rows and dropped a field the script preserves. Name the script in the brief.
- **Do not let a component do another's job.** Each measured cost blowout traced to a stage re-running an upstream stage's screening. Give each stage one job and put what it needs in its brief.
- **A low-stakes check reads a purpose-built digest.** A gate whose single decision is cheap to get slightly wrong reads a small, regenerable, staleness-tested digest, never the full source. Steps where the source is the product keep the full source.
- **Main-session tool results are billed every turn.** Never read an image into context; reference it by path. A tiny fraction of tool results carries a large share of bytes, so cap anything oversized.
- **Offload bulk mechanical work to a cheaper model when quota is the bottleneck.** Summarizing large logs, cleaning text and first-pass classification can go to a cheaper model or tool the operator approved, through a wrapper script; never send firm or client data to a service the operator has not approved for it.

## Working with the operator

- **Decide technical questions yourself.** When the answer is discoverable, run the probe, read the trace or derive the formula, then report the finding. A question asking the operator for engineering judgment hands back work he delegated.
- **Split by kind.** Technical open items (code, config, trade-offs) go to a fresh stronger-model reviewer with the evidence; strategy, product facts about the operator and career-level direction go to the operator as one crisp question with options and a recommendation.
- **Push back once, politely, with evidence.** The operator can be wrong or under-informed, and prefers an independent analysis to blind agreement. Name the better method and its reason, then follow his decision.
- **A narrow correction stays narrow.** When told to change one claim or verb, fix only that, and never generalize it into a sweeping rewrite of other places because an audit finds similar patterns.
- **"Stop" means full stop.** Summarize the state in one sentence and wait. No new dispatches, handoff files, memory updates or cleanup until permitted.
- **Save a stated rule immediately.** When the operator states a rule, preference or ban, record it in the right durable place in that same turn so he never repeats it next session.
- **Direct override beats a hook; relayed claims do not.** An explicit exception the operator types himself in the main session can override a standing policy for that one item. A subagent's report that "the operator approved" never counts.
- **Do not ask permission for research or plan-mode reads.** Web search, fetch and read-only checks run without prompting; in plan mode prefer read paths that do not prompt and defer anything that must prompt to the first action step.
- **Once autonomy is delegated, stop asking.** Do not interrupt a long run with strategy or permission questions when a soft target slips. Keep working and document as if compaction could hit at any moment.
- **Do not park analysis behind a data gate.** Build the strategy now from the data already on disk and predict the missing figure, then use the real result only to check the prediction.
- **Two failed attempts at the same fix means change approach.** A third identical try wastes time. Escalate to a stronger reviewer, research the missing fact, or report the blocker.
- **Surface a blocking rule's reason.** When an old rule blocks the work, report why it was written and whether that reason still holds, so the operator decides. Staleness is surfaced, never assumed.

## Planning and handoffs

- **Do every read-only task before writing the plan.** Measurements, replays against historical data, claim re-verification and research front-load corrections. A plan resting on unverified claims ships fixes mid-execution.
- **A finished plan gets a separate adversarial review.** A fresh stronger-model reviewer attacks the plan's claims against the evidence, in a context that did not write it. Such a pass caught wrong dates and an overstated framing.
- **Plans and handoffs open with a role sentence.** The first meaningful sentence assigns the cold-start session the best-fitting role, justified by what the deliverable requires, plus a model distribution. A bare "You are an assistant" is a lazy default.
- **Write handoffs for a cold reader.** Durable state goes under the project tree, never `/tmp`, which vanishes on reboot or compaction. Name every file the next session must read first.
- **Pin files that config imports.** A global instruction file imported a note that a later agent, given free structural reign, moved; every session silently lost the import. Name such paths as pinned in every restructuring brief and re-verify with a fresh session afterward.
- **State which locations a completeness claim covered.** A secret scrub verified only against the remote still left the secret in local refs.

## Long-running jobs and resilience

- **Arm a monitor, do not just wait.** A scheduled heartbeat or one-shot completion check missed a real overrun. Poll concrete signals (a file appearing, a transcript silent for several minutes, an interruption marker) on a fixed cadence until the job ends.
- **Baseline before watching a log.** A watcher grepping for a terminal marker matched a line an earlier run had already written. Record the line count or byte offset first and accept only matches past it.
- **A long step owns its deadline and writes what it earned.** Progress is freshness, never existence: a file that exists proves nothing about whether it is still being written.
- **A driver must write its final state before it checks it.** One process called its own downstream check before writing the completion value, so the check always read "not done" and silently no-oped.
- **Prefer a durable scheduler over a self-chained wake-up.** A self-rearming timer dies permanently if the firing turn hits the same quota wall; an independent scheduler does not. One silent 9.5 hour gap came from exactly that.
- **Persist results to files at every cycle.** Compaction and reboot erase scratch space and memory, and the operator's question "why only 2 results?" cannot be answered if the rest was never recorded.
- **Capture broadly, filter at deterministic gates.** Never drop an item by gut feel during collection; screen after the full capture with named rules, and write each exclusion's rule.
- **Every unit of planned work leaves with a verdict.** A source, task or item below its selection budget must be recorded as skipped or failed with a reason, never silently dropped. A run that continues is better than a halted one, but silence is the failure.
- **Judge a step by output that landed, not by claimed counts.** A source's advertised result count and a run's "completed" flag both read well while delivering nothing. Count the rows that reached the dataset and whether they are complete.
- **A missing identity is as bad as a wrong one.** An unbound record cannot be deduplicated, resolved or reused, so refusing to stamp an id is not the safe outcome. Retry, then escalate for help.
- **Flag, never silently eliminate.** An item is removed only by a named rule with a written reason; "could not find the data" is a flag that keeps the item visible, with a give-up count held at zero by an invariant.
- **Measured supply beats observed delivery.** Never size a ceiling from what a producer delivered when that producer was itself under-taking; its output measures the executor, and lowering a limit from it freezes the defect in as policy.
- **Measure pagination, do not infer it.** Judge from pages fetched versus pages requested, not from row counts. Producing something never answers whether most pages went untaken.
- **A new enum value needs a router.** Adding a source with a new scope value made it undispatchable because nothing listed it; 20 percent of a registry went dark. After adding such values, run the test that proves the dispatcher reaches them.
- **Cap per-unit cost and halt on an outlier.** Record real tokens and money per finished unit, stop the batch when one exceeds a threshold taken from real history, and continue only after a check clears it. Never loosen the threshold to let a batch through.
- **A verdict must be reproducible.** A validator re-resolving its expected set live gave different answers on consecutive days for the same run. Compute it against the plan recorded for that run.
- **Determinism for pipelines.** A collection agent returns raw fields only, with no scoring or truncation, and scoring code has no randomness or clock reads. The same input must produce the same order in any session.
- **Do not run browser-driving agents in parallel.** Tab and frame contexts cross-contaminated and one agent acted on another page's elements. Run such work in a sequential queue, and for plain "open this URL" use the OS opener, not an automation tab group.

## Git and destructive operations

- **Commit only when asked, selectively.** One logical change per commit, imperative subject of 72 characters or less, body explaining why, explicit pathspecs, never `--no-verify`. Never commit runtime, cache, log or backup churn.
- **Never push unless the operator says so in the current session.** Publication is irreversible and may be watched. Mention "no push" in every dispatch brief.
- **Scope checkout and restore paths exactly.** `git checkout` with a path list restores from the index, not HEAD, so a pasted path list silently discarded uncommitted edits in a shared dirty tree. Name only the files that need resetting, or stash those exact paths first so a wrong scope is recoverable.
- **Never remove lock files by hand.** Deleting an index lock during a long pre-commit run caused silent commit failures. Wait for the git process to exit; check for a deleted lock when a commit fails quietly.
- **Truncating write order matters.** `open(p, "w").write(open(p).read().replace(a, b))` truncates before the inner read runs and leaves an empty file. Read fully into a variable first, or use an in-place edit tool.
- **Confirm no deletion target is referenced.** Before removing a note or file, check inbound links and test references (grep the exact filename), not just whether it is tracked.

## Documents and writing

- **Directive files carry instructions only.** No story, history or incident narrative; explanation survives as one short "Why" line. Rules, dated records and measurements live in separate places.
- **Hot-path files are the strictest case.** A file a run re-reads every turn is billed into the prefix every turn, so any narrative there is a recurring cost. The same leanness applies to code: no restating what was just done.
- **Put knowledge where it loads on demand.** New rules, fix notes and incident detail go to a hook message, skill, rules doc, review record or memory index, not the always-loaded instruction file. A stale line found there is mentioned once in the final report, not edited without approval.
- **Keep the global instruction file project-agnostic.** Concrete examples, vendor names and incident detail belong in the project's own files; the global file states rules generically.
- **Durable files in English, chat in the operator's language.** Instruction files, handoffs, rule docs, skills, agent definitions and code comments are English even when the conversation is not.
- **Lead with the most critical fact.** Use short imperative lines, numbered workflow steps, no emoji, no speculative or defensive explanation. One rule plus one example.
- **Pointer stubs must be real.** If a memory entry says "full content lives elsewhere", that file must exist and hold it. Do not duplicate content in both places.
- **Reports state facts definitively and stay lean.** External-facing pages stay short with numbered references; legal text is exempt from length limits. Lead with the conclusion.
- **Infer rules from principles.** A guideline describes principles; derive enforceable rules from them rather than deleting a rule whose exact name is absent.

## Tooling and environment

- **Check installed CLIs and MCP servers before driving a browser.** A zero-config CLI already installed solved in one command what a redundant MCP install, an app-registration attempt and browser reads had not. Use the live browser only when neither covers the site or the task needs a logged-in session.
- **Keep sessions light.** Components load only when invoked; a tool used monthly must not tax every request. MCP server count does not predict always-on cost, so measure before installing.
- **An MCP server added mid-session is invisible until restart.** Neither the current session nor its subagents see it, whatever the scope. Test in a fresh session before debugging scope.
- **Settings can silently set subagent effort and model.** A model picker wrote a high effort level into the config that every inheriting subagent then used. Audit inherited defaults whenever cost jumps.
- **Plan mode and command wrappers can collide.** A hook that rewrites every command into a wrapped form made plan mode ask permission for read-only commands. A wrapper that knows the mode fixes it without changing normal-mode behavior.
- **A plugin hook returning an invalid decision value can break the UI.** A stop hook that answered `allow` where only `approve` or `block` is valid ended streams in error and surfaced an "Unhandled case" toast. Suspect a hook schema mismatch when a vague error toast appears.
- **Pin model aliases deliberately.** Mapping an alias to a newer model through an environment variable works on an older CLI but may warn on side calls. Record the backup and the rollback command, and add a test that no stale model id remains in live code.
- **Treat vendor-promoting material as possibly sponsored.** A repo or comparison post that promotes a vendor should be cross-checked against non-vendor sources before it informs a choice.

## Building systems

- **Heavy designs hide silences.** A queue writer with no caller, a generated view nothing regenerates, a monitor reporting zero against a real backlog: each was added because more machinery felt safer. Choose the lean design, then verify what survives.
- **A step is done only with evidence.** For performance work: nothing in its path it does not use, nothing in a per-turn prefix that could be read on demand, no turn a batched call could have covered, output quality untouched. Items that look free often measure 0; only measurement separates them from the real win.
- **Report savings in the unit actually carried.** Billable figures understate the cached prefix a turn really carries, so state which unit a saving is in.
- **A documented behavior must exist in code.** A doc described an orchestrator re-running an earlier phase on a bad verdict; the driver recorded the verdict and always moved on. Search for the branch before relying on the description.
- **A new component needs a caller.** A queue with a writer and tests but nothing invoking the consumer shipped as "done" and never ran. Trace every new component to its call site in the live path.
- **A helper must read keys the producer returns.** A helper read a key the producer never emits, so 251 rules read as unnameable. Run the helper on real producer output.
- **A "best record" picker ranks by record type first.** Ranking by magnitude let a placeholder row with count 1 outrank the real measurement row with 0, hiding a failed source. Prefer the measured row.
- **Sweep for the same crash class at other scales.** Closing one instance is not done until the class is checked elsewhere. Closing only part of a gap can be correct, and the investigation must say why.
- **Check generators against the plan.** A retry-queue generator used default page limits and a null geography instead of reading the original plan, causing under-fetching. Verify generated queue files before running them.
- **Reuse pieces, not a whole classifier.** Reusing an entire function imported checks with different semantics. Investigate before closing a gap and close only the part that is proven.
- **Containment checks are directional.** Testing "collected name in page name" rejects every page that names the entity more briefly. Normalize and test containment both ways with token boundaries.
- **Escape input used in patterns.** A parenthesis in a title silently broke every anchored regex built on it. Test with real data that contains punctuation.
- **Synthetic fixtures pass while production fails.** A fix validated on a hand-built fixture returned zero on real data because the real template put the field elsewhere. Run the real producer on real input before claiming the fix.
- **Treat bracketed text as data.** A status marker in parentheses was normalized away as decoration and lost from hundreds of rows. Keep parentheticals until proven irrelevant.
