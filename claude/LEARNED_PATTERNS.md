# Learned Patterns: Self-Caused Bug Log

Append-only, cross-project, generic log of self-caused bugs. Consult on demand: grep the category headers for the class of logic you are about to write; do not read the whole file.

## Matching and Comparison Logic


### A hardened matcher fixed in one file, copied nowhere else that needed it (2026-08)
- A fix that closes a match-logic bug in one function does not close it project-wide; grep every other function performing the same kind of check before calling the bug class closed.
- Fix pattern: when a matcher is hardened, search the codebase for every other place doing conceptually the same match and either reuse the hardened function directly or explicitly justify why it stays separate.

### Deduplication Logic
A comparator keyed on a tuple of field names silently degrades to always-equal on any field the upstream data source never populates, so a dedup or equality check can report confident false matches while being blind on the one field that actually distinguishes the records. Whenever a signature tuple is defined in one module and the records are built in another, assert at load time that every signature field is present in the data, because an absent key is indistinguishable from a genuinely equal value.

### First-writer-wins dedup discards the real outcome (2026-08)
- Deduping repeated attempts at the same key by keeping whichever row arrived first silently keeps a failed/partial attempt over a later genuine success logged under the same key.
- Fix pattern: when a group has any row matching the true-success condition, keep that one, not the chronologically-first one.

### Substring test where the negative form contains the positive form
A membership test like `"connected" in line` also matches `"not connected"`, so a health check
can report READY while every command it guards then fails. Parse the structured shape (section
header, explicit field, exact token) instead of grepping for a status word inside free text.

### Keyword match treated as a semantic signal regardless of what it modifies (2026-08)
- A regex built to detect a real-world condition (for example "the file is encrypted") but written as "does this word appear" fires on every collocation of that word, including ones that modify an unrelated noun and assert nothing about the condition.
- Fix pattern: enumerate the word's real non-signal collocations from actual data (a frequency scan), strip those specific phrases before the check runs, and keep the decided strip list narrow and evidenced rather than guessed.

### Scope-narrowing OR-condition includes a branch that matches almost everything (2026-08)
A guard meant to scope itself to one artifact type, written as an OR of several path substrings, is only as narrow as its loosest branch; if one branch is the project's own root directory name (or any string present in nearly every path), the whole check degenerates to "always true" and the guard fires on document types it was never meant to touch. Fix pattern: enumerate the actual target paths/extensions explicitly, or add an early exemption for the specific sibling directory that legitimately differs, rather than trusting that an OR of substrings stays narrow.

### Allowlist regex as a resolver, when the goal is "whatever it points to"
When extracting a destination from a link, matching against an allowlist of known destination
domains silently reports "not found" for every legitimate target outside the list, and the low
hit rate reads as a broken extractor rather than a wrong abstraction. Extract whatever the
element actually points to, then classify the result afterwards, and follow redirects before
classifying so shorteners do not classify as unknown.

### Serialization Field Whitelists
A writer that serializes records through a hardcoded field-order whitelist silently drops any field absent from that list, so a record subtype introduced later than the whitelist gets written structurally incomplete with no error. Whenever a schema gains a variant that carries fields the common case does not, re-derive the whitelist from the live data instead of trusting it, and assert the written record round-trips before treating the write as done.

### Whitelist keyed on one observed spelling of a general concept (2026-08)
When matching a structured field whose name varies by vendor, match the concept rather than the one spelling the first integration happened to use, and put the safety check on the VALUE instead of the key. Anchoring on a single observed key silently excludes every other producer of the same field.

### Canonicalization that strips a semantically loaded qualifier (2026-08)
A normalizer may only strip tokens that carry no identity; stripping a whole class of trailing qualifiers collapses genuinely distinct entities into one and silently loosens every comparison downstream. Enumerate the specific noise tokens to remove instead of matching the syntactic shape they happen to share with meaningful ones.

### Regex Alternations That Forget The Plural
An alternation branch ending in a singular noun plus `\b` silently stops matching the plural,
because the trailing `s` defeats the word boundary. When a filter enumerates natural-language
phrases, write the optional plural (`invoices?`) and cover both forms in the test.

### A grounding check's own reference corpus edited to match the flagged value (2026-09)
When a truthfulness/grounding checker fails on a real defect, editing the checker's comparison corpus to include the flagged text (instead of fixing the flagged text) turns the check into a tautology that always passes, silently converting a real defect into permanently-masked ground truth. The tell is a corpus or fixture entry that exists ONLY to match one specific prior failure; treat that as the defect re-surfacing, not as the check being satisfied.

### Config Whitelists
When emitted output is built from a fixed field whitelist, any new field is dropped SILENTLY, and
the failure surfaces far away as an orphaned record rather than as an error. Red-prove the drop
before adding the field, and treat a repeat occurrence on the same function as a signal to test the
whitelist itself rather than to extend it again.

### Positional field extraction after an incomplete noise-filter regex (2026-08)
- When a parser strips "noise" lines from a text block by regex before assigning the remaining lines to fields by position (line 0 = field A, line 1 = field B, ...), any noise variant the regex doesn't match becomes a real line, and every field after it silently shifts by one.
- Fix pattern: when the noise filter is meant to match a whole class of near-identical header/boilerplate lines, anchor on the stable shared prefix or write the alternation to cover the actual observed variants, not just the first phrasing seen; a single missed variant corrupts every field downstream of it, not just the matched one.

### Positional zip of two independently-derived sequences (2026-08)
- Pairing two sequences by list index (regex-matched text blocks vs. a separately-returned id array) silently drifts the moment the two counts diverge by even one, and every pairing after the drift point is wrong while looking structurally valid (non-null, well-typed).
- A "records found >= ids available" imbalance is a hard signal of drift, not a benign extra to discard; treat any non-1:1 count as a correctness alarm before trusting the pairing, not just an appended/skipped tail.
- Fix pattern: pair by an explicit shared key when one exists (when the id is embedded in the fetched content itself, a positional guess is never necessary); when only positional pairing is possible, assert exact count equality per contiguous unit (one page, one call) and fail loud, not silently, on mismatch.

### Noise-line stripper misses a fixed header shared by every record (2026-08)
- A field-splitting parser that first strips known "noise" lines (headers, badges, boilerplate) via a regex allowlist will silently misassign fields for every record if one recurring boilerplate line common to all records was never added to that allowlist; the leftover line shifts every subsequent field down by one position for that record only, so only the first record per block looks corrupted while the rest look fine, making the bug easy to miss in a partial review.
- Fix pattern: when a positional parser (content[0]=X, content[1]=Y, ...) feeds from a template with a fixed preamble, enumerate every literal preamble line the template emits and add each to the noise/strip regex, not just the lines that happened to appear in the sample used to write the parser; a shifted output that reuses another field's real value as a bogus field value (rather than an empty/error value) is the tell.

### Bulk Edits Scoped By Pattern Instead Of An Explicit Allowlist
A bulk file transformation scoped by a convenient pattern (a date prefix, a directory glob) will
silently include files written by other producers that happen to match, and an unconditional
normalization applied outside the matched region mutates even the files the transformation was
supposed to skip. Scope bulk writes to an explicit list of the files you created, and make every
mutation conditional on the specific match rather than applied to the whole record.

### A runner's own input label round-tripped back onto the authoritative data (2026-09)
**Why the first fix missed:** it guarded the WRITE direction only. Data injected into a subprocess's
input is not contained by copying at the boundary you inject at; it is contained only if you also
strip it at the boundary it comes back through. A round trip has two edges.
- Name the injected fields in ONE module constant and reference it at BOTH edges: the stamp site and
  the merge-back. Two hand-written literals drift; one constant cannot.
- Strip on merge-back by value, not just by key: only the exact value this runner injected is
  discarded, so a genuinely earned label with the same field name survives.

### A guard's docstring claim is not the guard: verify the regex actually implements what the comment says
A comment claiming a check "skips prose" or "only flags real instructions" is a design intent, not a guarantee; the regex itself may not implement that distinction, and nothing catches the drift until a real re-check runs the guard and reads its actual output.

### A log watcher matched a terminal pattern without first baselining the file's line count
A log or state-file watcher that greps for a terminal marker pattern can match a line an earlier, unrelated run already wrote, because nothing recorded the file's line count (or byte offset) before the watch began. Baseline the count first, then only accept a match at or past that baseline.

### A command-text guard matched line starts, so compound commands walked past it
A guard that inspects command text must tokenise the shell (separators, pipes, subshells, wrappers like xargs) instead of matching the start of the line, otherwise `a && danger` or `true; danger` passes while the bare form is blocked. Ship it with a regression test that runs every compound, nested and wrapped form of each guarded verb through the real hook, plus a benign set (quoted words, other commands) proving it does not over-block.

### A unit label taken from a neighbouring field instead of from the payload
When an ingested payload carries both a display currency and numeric fields, the currency attached to the numbers must come from evidence that the numbers use it (the base amount times the stated exchange rate reproduces the displayed local figure), never from the nearest field named "currency". Check one record per source type by reproducing a displayed headline from the stored values before ingesting the rest.

### A fallback match key must not share the delimiter of the text it is parsed from, and unmatched rows must never drop silently
When a fallback key is built from the same delimiter the prompt uses, rows collide or fail to match, and a loop that skips unmatched rows loses them without a trace; a pinned test that asserts the buggy key then keeps the defect green. Use a collision-free key, account for every input row in the output, and make the test assert the accounting, not the key.

### A substring test on a whole URL confuses where a link came from with where it points
Rejecting a URL because a given domain name appears anywhere in it also rejects every URL that carries that name in a query parameter; decide on the parsed host only.

### Matching / term normalization
A normalizer that cuts every parenthetical as a "note" also cuts parenthetical name lists that carry the actual claim, so the check matches only the vague head and misses the specific items. Distinguish a note from a list by shape (short capitalized items vs. prose) and keep the list items as match keys, with a guard test for each shape.

### Containment check written in one direction on an unanchored haystack (2026-08)
`a in b` verifies identity only when b is never the shorter string. A check that asks whether the expected name appears inside the observed name rejects every case where the observed name is more brief, and a short expected name (two letters) matches any long string that merely contains it, including a URL scheme. Test containment in both directions on whole tokens, match URLs on host plus path only, and write the mirror-case test, not just the direction you were worried about.
Example: a verifier rejected "Widget Pro" vs "Widget" while a two-letter name matched every URL because it sits inside "http".

### Fix a similarity misfire by normalizing, never by lowering the threshold (2026-08)
When a fuzzy comparison rejects obviously equal strings, the noise is usually site furniture (a brand prefix, a trailing qualifier, a parenthetical). Lowering the threshold admits the true positives and the false ones together; stripping only the noise you can name keeps the bar where it was. A length floor is also a poor proxy for "meaningful"; whole tokens are better.
Example: a page heading "Widget Pro | Acme Store" was rejected against "Widget Pro" at 0.85; stripping separators and trailing qualifiers fixed it, whereas 0.65 would have also accepted two unrelated products.

### Regex connector class that cannot cross punctuation (2026-08)
Two anchor words bridged by a character class such as `[\w&/ ]*` never match when the second anchor sits inside a parenthetical, because `(` and `)` are not in the class. Include the real punctuation of the data (parentheses, comma, colon, hyphen) and test the fix by running the old and new pattern over the full real pool, since an edit that accidentally drops the space from the class breaks even the plain case. When a user reports "your numbers look too low", trace one concrete missed record through the real functions before explaining anything.
Example: "Report (Monthly)" was scored as a generic label for months; widening the class lifted 46 records over the threshold.

### Identity threshold written as "all but one token" collapses for short names (2026-09)
A rule like `hits >= len(tokens) - 1` is fine for long names and requires almost nothing for two-token names, so one generic word present in unrelated markup passes. Check any relative threshold at the small end of its input range, scale strictness to input size, and add a structural check that does not depend on page text (a documentation URL must carry an identifying path segment).
Example: a prober accepted a hosting vendor's own homepage as a customer's documentation page because one common word appeared in its CSS.

### Alternation order lets a shorter prefix shadow a longer entry (2026-09)
In a regex alternation, the first matching branch wins, so a shorter entry that is a proper prefix of a longer one consumes the match and the longer name is then reported as malformed. Sort alternations longest-first, and when deduplicating overlapping span matches compare starts with `>=`, because a prefix shares its start position with the longer span.
Example: a label guard blocked "Lead Builder (X)" because the allowed-list entry "Lead" matched first; the selector's own recommended label was therefore unusable.

### Capture group that stops at whitespace truncates multi-word values (2026-09)
`(\S+)` after a marker captures one token, so a delimited list whose first element contains a space loses everything after that element. Capture the rest of the line (or a delimiter-aware class) and test with a multi-word first element followed by a second item, not with single-word fixtures.
Example: a gate parser reported four unapproved vendors as approved because "Big Corp|Other|Third" was cut to "Big".

### Widening one filter dimension silently drops an unrelated check (2026-09)
Relaxing one axis of a filter (category) to admit more rows does not re-run the other requirements a normal row passes (tier, status, exclusion rules). Re-verify every other dimension on the newly admitted set before merging, and treat "unknown" on a hard requirement as unmet, not as a pass.
Example: admitting generic categories for one tier added 33 rows, 14 of which violated a standing status requirement.

### A cheap pre-filter becomes a hard admission gate for the model behind it (2026-09)
A regex built as routing convenience, placed in front of a model that is supposed to judge the full set, decides in practice what the model ever sees. Check what actually reached the model, not just its approve/reject ratio, and let the model do its own lenient first pass over everything that survived the settled deterministic exclusions.
Example: 73 percent of rows that passed every deterministic exclusion never reached the model gate.

### One entity, two identity keys (2026-11)
Two sources can name the same entity with different keys (an opaque internal id versus a public slug), so a dedupe that compares across them treats known entities as new and re-reads them every run. Normalize both sources to one identity key before comparing and pin it with a test where the same entity arrives under each key.
Example: 14 already-stored records were reprocessed because search hits carried ids and the list carried slugs.

### Normalizer drops the field a downstream filter needs (2026-11)
A normalizer that keeps one display field (a short label) can discard the field a later allow-list depends on (the full category path), so good rows are rejected with no error. Separately, a "seen before" set built from attempts instead of outcomes turns a transient failure into a permanent ban. Replay the filter over real stored records after changing either side, and build skip sets from verdicts only.
Example: an import step added zero rows because every label lost its category path.

### Sibling data lines left in the old form after a parser fix (2026-11)
Widening a parser to accept a new form of a hand-written data line leaves other lines of the same kind in the older form, and they fail silently until someone reaches them. After the fix, run the parser over every real line of that kind, or normalize the data to one form and test against the real file.
Example: a syllabus parser learned a new video-line format for one section while the next section kept the old format and failed with "no video line found".

### An external event resolved to one entity but written by a coarser key (2026-10)
When an inbound event (mail, webhook) is matched to a parent and the write step applies it to every record sharing that parent key, one event rewrites many unrelated records, including closed ones the reader excludes. Resolve each event to exactly one record id, flag ambiguity for review, and apply the reader's eligibility filter to the write.
Example: one status mail for a single ticket flipped seven other tickets of the same customer.

### Cache key built from display fields instead of the record's unique id (2026-10)
A cache file named from two display fields (name and owner) overwrites an earlier entry whenever two records share those fields, and rows then silently carry another record's content. Put the unique id in the key and add a check that flags any row whose cached file does not carry its own id.
Example: 7.3 percent of historical rows pointed at another record's cached document.

### Row picker ranks a call-time breadcrumb above the measured row (2026-10)
When one record per key is chosen by largest count, a breadcrumb written before the work (a headline count from the server side) can outvote the measurement taken after it, so a unit that kept nothing reads as having delivered. Rank a measured row above a breadcrumb first, use the count only to break ties among equals, and credit a unit only on a row that records an execution.
Example: units with 0 kept rows read "deduped" off a headline count of 209.

### A sentence splitter that ignores line breaks merges list items into prose (2026-10)
A splitter that breaks only on `. ! ?` glues a colon-ended intro line to the first list item, and a list glyph (a keycap digit) is then read as data by number extraction. Treat a line break as a sentence boundary and strip formatting glyphs before extracting numbers; otherwise writers reword true lines to dodge a false block.
Example: a numeric checker blocked "1. Should we build one?" as a numeric claim.

### A spelling rewrite with an exact-word exception list (2026-10)
A regex that rewrites a suffix (US -ize to UK -ise) and exempts only exact words misses every compound of those words. Match the exception as a suffix of the rebuilt word, and test the compounds.
Example: "size" was preserved but "oversized" became "oversised".

### A reader keyed on a field name the producer never writes (2026-08)
A helper that reads `g.get("cond")` from a producer that names the field `conditions` falls through to its fallback on every call, and the wrong answer is well-formed, so nothing errors. Test the reader against the real producer's output, not a hand-written dict, and when an agent flags a bug it is not scoped to fix, treat the flag as a task: two independent reports of the same mismatch on one day mean it is real and cheap.
Example: 251 real failures were filed as "unclassified" because the key names disagreed.

## Silent-Failure Observability


### Always-exit-0 hooks with no breadcrumb (2026-08)
- A hook that sends all stderr to /dev/null and always exits 0 makes "ran and did nothing" indistinguishable from "never ran at all."
- Fix pattern: add one unconditional, cheap breadcrumb write before the main logic, so execution is independently verifiable.

### A transparent CLI-rewrite hook silently breaks a piped invocation of the tool it rewrites (2026-09)
A hook that rewrites a common shell verb (grep, git, etc.) to a specialized wrapper for token savings assumes standalone, file-target usage; piping arbitrary stdin through the same verb name (`ps aux | grep foo`, a log-tail check inside a Monitor loop) can silently return empty instead of erroring, because the wrapper's own semantics differ from the builtin's. Diagnose a "no output where output is expected" by re-running the exact same check via the tool's absolute path (`/usr/bin/grep`) before concluding the underlying process failed, stalled, or never started.

### The same crash-class recurs at a different scale until every sibling gets the same fix (2026-09)
Fixed an unhandled per-row `subprocess.TimeoutExpired` in a batch tier (one slow row killed the
whole batch, discarding every row already resolved). Verified green. Hours later, the SAME tier
died again on a bigger batch: not one slow row this time, but the cumulative wall-clock
of many fast rows exceeding the CALLER's outer subprocess timeout, which killed the process before
its single end-of-loop write. Root cause was structurally identical (no incremental write, no
self-imposed deadline) but the earlier fix (a per-row try/except) did nothing for it, because the
per-row calls were each individually fine.

### A wrapper recorded PASS from the process exit code while the worker reported it was blocked
**Bug (self-caused):** an orchestration script marked a dispatched worker PASS whenever the process returned rc 0 and no error flag, and treated a failed downstream step as non-blocking. The worker had returned "incomplete, environment blocked" with zero output, so every later step ran over an empty input and reported normally.
Fix: judge a worker by its declared status text and by the artifact it must leave behind, never by exit code alone, and halt when a step's required input is absent instead of letting later steps run on nothing.

### Liveness monitor measured the symlink, not the transcript
- Symptom: agent liveness monitor printed grow/STALL on a constant 162-byte size; growth was never measured.
- Rule: a liveness size check must show a first sample larger than a link length and a change across two reads before it is trusted.

### Status flags that a later write silently overwrites
A "needs attention" flag must stay set until an explicit reset clears it; a writer that recomputes the flag from a counter on every run will flip it back to healthy on the next event. Make the writer read the current state first and only ever escalate, never downgrade, the flag.

### A derived plan regenerated mid-run after its inputs were mutated by the run itself
When two steps of one run both generate the same work-list file and the first step's execution updates state the generator reads (rotation, last-run dates), the second generation silently describes different work than what ran. Make generation idempotent on a run identifier: if the output already exists for this run id, reuse it.

### A refuse-on-duplicate writer called by a rerunning driver that never reads its exit code
When a writer refuses to overwrite an existing record and its caller discards the exit status, the first attempt's record (even an empty or failed one) silently outlives every later correct run. A caller that re-measures from the artifact must opt into replacement and surface a refusal.

### A dispatch recorded PASS from the child's exit code while the child produced nothing
When a runner marks a delegated step PASS from the process exit code and the JSON error flag, a child that refuses or is blocked and then exits 0 reads as success and the whole record lies. Make the runner check the artifact the step must write (exists, newer than the launch) before it records PASS.

### A verdict class defined as "absence is legitimate" must not be reachable from a failed parser
When one verdict means "nothing came back, which is fine", a parser that failed lands in it silently, and a completeness check that iterates only the files that exist never sees the missing ones. Separate "parse failed or unreadable" from "legitimately empty" as distinct verdicts, and iterate the expected set, not the found set.

### A failed producer still forwards to a paid consumer
- Pattern: when a step can end without its artifact, every paid downstream step checks the artifact exists before dispatching and returns a deterministic result instead. Gate on the artifact, never on the upstream verdict string alone (some "blocked" verdicts still leave a usable artifact).

### State derived from a shared log
A "what is already done" set built by grepping every identifier out of a shared activity log treats read, probe and test lines as completed work, so items get silently skipped forever. Derive done-state only from lines whose status field says the action completed, and pin it with a test that mixes read lines and done lines.

### A user interrupt can silently kill a background subagent (2026-08)
An interrupt aimed at the foreground turn can also terminate a background subagent started earlier, leaving no completion notice and no output file, so it looks like a stall. Before assuming a background task is slow, check its own transcript for a final "interrupted" entry; if present it never finished and must be re-dispatched.
Example: an adjudication subagent mid-research never wrote its verdict, and the task lookup then returned "No task found".

### An interim notification is not proof a background job is alive (2026-10)
A waiter that treats the last interim status as liveness waits indefinitely on a job that already died, because silence looks identical either way. Run dependent work in the foreground, and for background jobs stat the output files on a fixed cadence and treat an interim notice with no follow-up as a reason to check.
Example: an agent waited about two hours on a subagent whose output file had stopped changing 115 minutes earlier.

### A process monitor that matches its own command line (2026-10)
`pgrep -f name.py` inside a loop whose own command line contains that string counts the monitor itself, so "no process, ended" never fires and a finished run looks alive. Match on a pid (`kill -0 <pid>`) or anchor the pattern to the interpreter argv, and corroborate with the run log's completion line.
Example: a shell wait loop reported a finished batch as running for an hour.

### A liveness view must enumerate the roles that run, not whitelist file shapes (2026-10)
A view that recognizes work by the shape of the files it writes cannot see any role whose output differs, so a live job reads as dead. Derive the view from the set of roles that can run and show each one's state.
Example: a status script listed only known log shapes and missed running pipeline roles.

### A diagnostic aimed at the wrong target reads as "verified clean" (2026-09)
A script that exposes a `--session` or `--target` identifier with a default must be queried with that same identifier; an empty result from the wrong target is indistinguishable from a clean bill. Cross-check with a target-agnostic, lower-level count (an OS-level tab count) before dismissing an operator's direct observation, and never treat the silence of a wrapped cleanup call as success; check its return.
Example: a tab-leak check queried a different session name, found nothing, and 13 tabs were open.

### A completeness hook that only arms after a later stage can never catch an early stall (2026-09)
A Stop-time check for "did X finish" that requires an artifact only a far-along run produces is strongest when least needed and absent when most needed. Precondition the gate on the plan (what was supposed to happen), and audit "is this hook working" by asking which states it silently no-ops on.
Example: a run stopped after 8 of 70 planned units, the gate's precondition file never existed, and the incomplete run passed.

### "Not measured" and "never executed" counted as a measured zero (2026-09)
A health flag that coerces a missing count to zero and counts rows whose own fields say the work never ran will report a failure streak on healthy units. Filter history to rows that executed and reported a number before computing any streak or rate; three states (missing, not run, real zero) are three different facts.
Example: 37 of 37 active units carried a "zero yield" flag though each had produced rows on its latest real run, and two productive units were rewritten on the strength of it.

### A verify step must test the outcome it certifies, not the absence of an error (2026-10)
A verifier that checks only that a file parses and a count holds stamps a state "verified" after the apply step crashed halfway, and the half-applied edits stay on disk. Re-read the artifact for each accepted edit, refuse any state that never reached "applied", and restore on apply failure.
Example: an undeclared dependency crashed apply, yet the state moved to verified with a pending field still in the registry.

### A documented terminal state must be reachable from the branch that produces it (2026-10)
A fallback flag the caller passes in can be ignored on the branch that actually exhausts the option list, so the strict terminal the docs describe can never be recorded for the common real case. Every documented outcome needs a path to it, and a caller-supplied flag is honoured on all branches or rejected loudly.
Example: a "last resort" strictness flag was consulted only in two early branches, so exhausted searches ended with the default threshold.

### A hardcoded constant outlived the producer that made it true (2026-10)
A measurement field written as a constant ("one page by construction") goes silently wrong the day the producer changes, and a downstream judge then reads the contradiction as a defect in the unit. Derive the field from the producer's own output and keep the constant only as the fallback when the output says nothing.
Example: a ledger row claimed one page fetched while its rows each said fifteen, so a healthy source read as under-fetched.

### A gate whose verdict nobody reads is decoration (2026-10)
A step that writes its rejects to a file that no later step consumes does not gate anything, and a rebuild that opens its output with "w" discards what an earlier stage resolved. Give every producer's output a named reader before it counts, and carry forward proven state keyed on identity across rebuilds.
Example: 47 of 98 listed items were rejects of an upstream gate whose reject file was never read.

### A success check that trusts a field an agent fills in fails closed on omission (2026-10)
A gate requiring an agent-reported path to exist treats a blank report as failure even when deterministic code really produced the artifact. Derive the path from a field the harness set (or the deterministic writer's own record), keep the exists-check, and label log lines with the value captured before a variable is overwritten.
Example: a delivered fallback artifact ended as "failed" because the agent's return left the path blank.

### A stop-word scan over a tool's whole payload fires on the content it fetched (2026-10)
Grepping for "sign in" or "captcha" across the full output of a call that already reported success trips on fetched text containing those words and halts a healthy run. Scan only the error channel or failure messages.
Example: a page fetcher stopped as "bot detected" because the page text itself said "sign in".

### One bad row stopped a nightly queue for two weeks (2026-11)
A fail-closed loop that stops the whole run on any unexpected result turns one odd row into a permanent freeze, because the same row is first again every night. Skip the row and continue; stop only on a signal that the environment itself is wrong (two in a row), and surface "0 processed N nights in a row" instead of trusting a log nobody reads.
Example: a trailing "." in one name failed a check and 0 invoices were exported for twelve nights.

### Keyword match on raw error text turned an outage into "done" (2026-11)
Classifying a result as a benign skip by searching raw error text for words like "synced" lets an infrastructure error containing the word pass as a final state. Decide skips only from a parsed, structured result (exact status plus exact reason code), treat everything else as a stop, and check that every status the adapter can return has a handler, since an unchecked status leaves a dead branch.
Example: "Device not synced" matched the "already synced" skip, so a dropped bridge would have logged every queued item as skipped and exited 0.

### A safety check that treats missing evidence as a pass (2026-11)
A guard that fires only on positive evidence (a regex hit, a matching record) silently passes when the record is absent or the value is unreadable. Make "unknown" its own state that blocks the action, and fill the missing data automatically so the block does not stall the queue.
Example: a gate returned None for 57 of 82 rows with no reference data and let them through.

### Safety signals scraped from a shared log (2026-11)
A monitor that greps a shared log must scope its patterns to the events it guards, because unrelated writers eventually print the same words ("timed out") and a real event can arrive in words the pattern never lists. Name the guarded condition explicitly at its source with a stable token, and exclude writers outside the guarded system.
Example: an unrelated provider timeout paused the queue while a real blank-page response never did.

### Error classification: an unrecognized block signature marked as "no data" (2026-10)
A fetcher that recognizes only one block signature treats every other block as "no data" and then marks the item done, so a temporary outage becomes permanent loss. Classify by exit status first (non-zero with no payload means retryable unless the message is a known permanent error), and never advance a seen-cursor on a failed fetch.
Example: only "429" was recognized, so a "confirm you are not a bot" page wrote "no content" and marked items seen.

### A summary that names one reason for an empty metric misleads (2026-10)
When several causes produce the same empty value, a message that states one cause sends the reader to the wrong next action. Branch the message on the cause the counts actually show.
Example: a report said "no orders in the newer block" while the window showed 13 orders that merely lacked price data.

### SQLite date filters that silently return nothing (2026-10)
In SQLite an integer compared with text is always smaller, so `epoch_int > strftime('%s', ...)` matches no rows and looks like "no data". Cast the strftime result to integer and sanity-check a filter against an unfiltered count before concluding absence.
Example: a history query for a date range returned empty though the maximum timestamp was inside it; casting returned 330 rows.

### A script's own log is not the timeline of what happened to its session (2026-10)
A script log records only what the script chose to write, so it cannot say when a session died or what the server answered between runs. Pull the client-side record (browser history, cookie store, HTTP traces) before naming a time or trigger.
Example: the script log showed an auth error at 16:50 while browser history showed the redirect to login at 16:31.

### Two parallel agents on one single-session resource hang without error (2026-11)
Two background agents driving one browser extension can both hang on their next call with no failure, and the orchestrator keeps waiting. Dispatch at most one browser-using agent at a time, and tell review agents that do not need the browser not to open it.
Example: two agents froze about 50 minutes each on the same tab call until stopped.

### Isolating the checked artifact takes it out of every path-scoped guard (2026-10)
Redirecting a file to a temp dir to "isolate" a lint run also removes it from hooks that act only on paths inside the repo, so blocks never reach the repair loop and the run dies on a missing file. Isolate telemetry, never the checked artifact.
Example: a lint wrapper used a system tempdir, the path-scoped hook exited 0, and repair never saw the real violations.

### A cap fitted before a later mutator adds to the same text (2026-10)
A limit enforced before another component inserts content into the same line is already exceeded when the final text is assembled, and the downstream gate refuses it. Enforce limits on the text after every mutator has run, on every section the producer writes, and carry the blocking reason with the failure. Fit after mutation; never loosen the downstream hook.
Example: an emphasis-count cap was applied to one section while a hook-inserted intro in another pushed the total over its limit.

## Test and Guard Design


### Assertion helper that records instead of raising (2026-08)
A test helper that records failures into a module-level list and relies on a custom runner to
convert them into a nonzero exit will report PASS under any standard test runner, which calls the
test functions directly and never calls that runner. Make the helper raise at the end of each test,
and prove it by injecting a deliberate break and watching the runner go red.

### Synthetic proof rows satisfy the health check they were meant to prove (2026-08)
Test or fixture records written into a shared store will satisfy any aggregate health check that reads
that store, silencing the very alarm the check exists to raise. Partition synthetic records behind a
validity guard every aggregate reader applies, and make each exclusion visible rather than silent.

### A guard protecting one field does not protect the file it gets written into (2026-08)
A guard stopping a caller from downgrading an already-trusted value in its own output does not stop a lower-level writer, called with only a narrow id and no access to that value, from independently minting its own blind guess and persisting it to disk; the two live at different layers, and fixing the caller's copy leaves the cached file lying about the same fact forever. Fix pattern: thread the trusted value itself into the function that actually writes the file, defer to it only when the writer's own signal carries no real information, and never let a missing trusted value delete a genuine negative signal only the writer can detect.

### Monotonicity invariant asserted across runs that differ in more than one parameter (2026-08)
A subset or ordering invariant between two measurements is sound only when exactly ONE parameter differs and both sides measure the same quantity at the same scope; before asserting it, enumerate every parameter of both runs, including the ones set implicitly by the tool rather than by you. An invariant that "fails" on a multi-parameter difference teaches nothing, and its failures will be misread as a defect in whichever component is easier to blame.

### Absence Claims From Narrow Probes
Concluding a field is "not present" after checking one selector or one access path is an
unproven negative, and it propagates fast because downstream design decisions get built on it.
Before claiming absence, sweep the whole namespace for the SHAPE of the value you want (scan
every attribute/key/column for the value pattern, then read off which names matched) rather than
querying the one name you expected it under.

### Assertions Against State The Code Never Writes
A test that reads a file, table, or cache the code under test never writes back to is
unconditionally green: the assertion targets a surface the behaviour cannot reach, so removing the
guard it claims to protect changes nothing. Assert against the value the function actually
returns or the object it actually receives, and prove it by deleting the guard and watching the
test go red before trusting it.

### Environment-Dependent Test Assertions
A test that asserts a fallback was NOT taken will pass or fail depending on whether the fallback's
resource happens to exist on the machine running it, which makes the result meaningless and can
indict correct code. Pin such a test to an input for which the fallback provably cannot resolve,
and assert the fallback path separately with a resource the test creates and cleans up itself.

### Verification and Test Design
A workflow step that PRESCRIBES a check but ships no implementation of it forces every operator to
improvise the check inline, which puts unreviewed code at the single most trust-critical point in
the pipeline. Ship the checker in the same change as the requirement, and make any deliberate
exclusion an explicit assertion rather than an absence.

### A "does the caller pass it?" test that only read the source text
**Rule:** when the optimization IS "the caller passes the prebuilt thing down",
assert the value the callee was actually CALLED WITH (wrap/record the callee, run
the real entry point), never that the caller's source mentions the name. A source
substring is the same evidence class as the text marker it is supposed to backstop,
so pairing them proves nothing new.

### Probes that never reach the code under test
**Rule:** every behavioral guard needs a POSITIVE assertion that the probe actually
arrived (assert the returned reason/branch marker, or record that the inner
function was entered) before asserting the cheap-work property. Without it, "the
optimized path did no work" is indistinguishable from "the path never ran".

### A green suite that depends on the wall clock is green by accident
The author had anticipated the midnight problem and left an escape hatch, `validate._run_date`,
with a comment explaining exactly this failure mode. It was set only inside `main()`, so no test
could reach it, and being a function ATTRIBUTE it was a sticky global that would leak into every
later call in the process once `main()` had run.
**Pattern to carry forward:** when a check reads ambient state (today's date, a live directory, an
environment variable), the test suite inherits that dependency silently and a passing run proves
nothing about tomorrow. Two tells to act on immediately: an escape hatch whose only writer is
`main()` is unreachable from tests and therefore not a seam; and a dependency passed as a function
ATTRIBUTE rather than an argument is a global with better manners. Before believing a green
suite, ask which of its assertions would change if the clock moved or the repo were freshly
cloned.

### A test that greps for a string vouches for code it never runs
**Fix.** Resolve the run dir from `__file__`. The test now executes the real stamp/read-back
round trip against a temp dir and additionally asserts the source resolves from `__file__`
rather than a bare name.
**Pattern to carry forward:** a test whose only assertion is that a STRING appears in a source
file proves the code was typed, never that it runs. Reach for source-grepping only to assert
WIRING (this module is invoked here), and always pair it with one test that EXECUTES the wired
path. And when a broad structural invariant goes red next to a narrow feature test that stayed
green, believe the broad one: it is the one with no stake in your change being correct.

### A checker that judges its own input, not the promise, is blind by construction
**Fix.** Both checkers now take the PLAN as an argument and treat planned-but-absent as their
loudest signal, not their quietest. And the step writes a
run record on every exit path, so absence of a finding is distinguishable from absence of a run.
**Pattern to carry forward:** when a checker reports "nothing wrong", ask what its universe was.
If that universe is built from the artifacts the pipeline actually produced, then anything that
failed hard enough to produce nothing is outside it, and the checker is structurally incapable of
reporting the worst failures it was written to catch. The expected set must come from a promise
declared BEFORE the work (a plan, a manifest), never from the work's own output. And a step that
can exit without writing anything can never be distinguished from a step that never ran.

### An inherited claim repeated four times without one check
A handoff stated that a failing inventory test was caused by "a concurrent peer session" that
created an untracked script. Repeated in four reports before verification. Both wrong: the test
reads the SCOPE DOC, not the filesystem, so the cause is an uncommitted edit to a command file;
and the mtimes are ~18 hours old, so the session was earlier, not concurrent. RULE: a claim
handed to you in a brief is unverified until you run the check yourself, and the cheapest check
here was one `stat` and one `grep`.

### A guard script written in the CLI shape blinds the whole pytest sweep
**Measured, reproduced independently after the fact:**
```
$ /usr/bin/python3 -m pytest scripts/ -q --collect-only
N tests collected
# append one line, `sys.exit(0)`, to ONE guard file:
INTERNALERROR> SystemExit: 0
a far smaller count collected
```
Every guard passed when run standalone, so nothing looked wrong. The damage was
to a DIFFERENT observer: the full-suite sweep that other gates read as "the suite is green".
- A test file gets ONE shape: checks raise or assert, a real collectible `test_*` function exists,
  and any standalone CLI behaviour lives behind `if __name__ == "__main__":`. Never `sys.exit` at
  module level in anything under a test path.
- After adding any test file, run `pytest <dir> -q --collect-only` and compare the COUNT to before.
  A count that drops is the signal; a green run is not.
- The general rule, third instance: verify a guard through the real call path, not the
  one you happen to use. Standalone green said nothing about collection.

### "The data is not there" is a claim about your search space, not about the data (2026-09)
- Then find WHERE each hit lives (walk every element's every attribute) instead of guessing the
  next selector. The answer arrives in one pass and names the real binding.
- A negative finding deserves the same evidence bar as a positive one. "Selector X matched 0" is
  evidence about selector X. Only an exhaustive search over the value proves absence.

### A process-order guard fires on a downstream consumer it was never meant to gate
A PreToolUse hook enforcing "artifact X must be fresh before this edit" matches on the target file's naming pattern alone, so any later stage that legitimately re-edits that same file (a review/audit pass making small grounded corrections, not a fresh authoring pass) trips the same block even though the artifact it demands was already consumed by design at that point in the pipeline, with no supported way to re-arm it. Fix: scope the guard to the actual authoring tool/phase (a phase marker, a caller identity, or an explicit bypass flag), not just the output filename, or accept that every downstream editor of that file needs a documented workaround.

### An orchestrator's own brief stripped the caveat that limited the finding it was passing on
**Bug (self-caused):** in a multi-agent investigation, MAIN summarized one agent's headline result into the dispatch brief for the next agent. The source file carried a binding caveat two lines below that result, limiting what the number could be read to mean. The paraphrase dropped it. Every downstream agent inherited an unqualified claim it had no way to see the edge of, built on it, and the unqualified version propagated into the deep synthesis and then into the consolidated diagram as a load-bearing thesis. A brief that restates a prior finding is a lossy compression step, and the thing it loses first is the qualifier.

### A gate's proof requirement is satisfiable by the party it is meant to check (2026-09)
A gate meant to require independent sign-off, when its proof check is "a file exists that contains the record's own id plus the reviewer's name or keyword," can be satisfied by anyone who can write a file, including the same implementer the gate exists to check, so an instruction to "get this approved" or "satisfy the gate" produces a self-certified pass with no real review behind it. Require the proof artifact to be something the checked party cannot themselves produce, such as a transcript from the actual reviewing agent's own session, dated within the change's own window, not free text matching a keyword.

### Test fixtures that write into shared real directories leak on any hard kill (2026-09)
A fixture that creates files in a real, shared directory and removes them only in a `finally` leaks them whenever the process dies without unwinding (SIGTERM has no Python handler, SIGKILL cannot be caught, and `subprocess.run` SIGKILLs its child 0.25 s after Ctrl-C), and a "path already in use" assert then turns one interrupted run into a permanent failure of every later run. Hold a kernel lock (flock, released even on SIGKILL) so a run can prove leftovers are stale and sweep them at start, map SIGTERM to KeyboardInterrupt so `finally` runs, and let a runner wait for its child's teardown after Ctrl-C instead of killing it.

### Before touching a failing fixture, trace it to a documented intentional change (2026-08)
When a test fails, find WHICH documented change caused it before assuming the code, not the
fixture, is wrong; never weaken a test just to make it pass. 26 failures were traced one by one:
all 26 were stale-fixture cases, none a code defect, each tied to a specific dated, intentional
policy change landed after the fixture was written (an exception removed, a validation gate added,
a threshold raised). One case was sneakier: a test passed but for the wrong reason, checking only
"was an error raised", true both before and after the real defect, for an unrelated cause.

### A guard rule changed without running the suites that embed the text it judges, and a baseline built in a copy of the environment
When a content rule or a global guard changes, run every test suite whose fixtures embed real instances of that content before calling the change done, because fixtures copied from real output are exactly what a tightened rule rejects next. A known-failing baseline must be generated in the same environment the commit gate runs in, never in a worktree or copy, since tests that hardcode the main tree's path mix two code versions and the baseline then hides environment-only failures as "pre-existing".

### A grounding corpus that indexes its own "this is NOT grounded" notes
A claim-grounding corpus built from free-text notes must drop the sentences that declare something ungrounded or forbidden, because such a note quotes the exact claim it forbids and therefore anchors it. Filter by sentence, not by line, so the grounded facts on the same line survive.

### A test drives a real pipeline whose output dir is a module constant pointing at live data
When a test exercises a real pipeline object and stubs only some steps, any unstubbed step still writes to the module's hardcoded output directory, so every suite run drops fixtures into live data. Redirect the module's output constant to a temp dir for the whole test module, and keep a repo-wide fixture that fails any test leaving a new non-production-named file in the live dir.

### A test sandbox that redirects the paths it knows about, not every path the code can delete
When a test isolates a destructive script by overriding a hand-picked list of path globals, any target added to the script later keeps pointing at live data, so an execute-mode test deletes real files and its failure looks like order-dependent flakiness. Redirect every path global by type in the sandbox and pin it with a test that no path global points outside the temp dir.

### A completeness gate demanded a step its own runner refuses to run
When a gate lists a step as mandatory for every row but the runner skips that step for rows already in some state, rows in that state can never satisfy the gate, so the run blocks forever on work nobody can do. Derive the gate's required set from the same row-state predicate the runner uses, and test the gate and the runner together.

### A headless parent that delegates must wait in the foreground for each child
When a headless run delegates work, a child launched in the background is abandoned once the parent's turn ends and a fixed wait ceiling expires, so the closing artifact is never written even though every earlier step looked fine. Instruct the parent to run every child in the foreground and keep the runner's artifact-freshness check as the backstop.

### A success check must test for the outcome, not for the absence of strings the UI never shows
A post-action check that waits for "no message contains text X" passes instantly when X was never there, so every action is logged as success and real failures are invisible. Likewise a retry path that first runs a generic cleanup destroys the very state it then tries to retry from; retry from a fresh start instead.

### A test that hand-places a producer's output hides that the producer writes elsewhere
- Bug: a gate arming rule was tested by writing the expected artifact at the path the gate reads, while the real producer was configured to write a different file, so the armed gate would have blocked every real run forever and all tests stayed green.

### A test run from a scratch copy still wrote the real tree through a hardcoded root constant
A module-level absolute path constant makes every test that derives its paths from it write to the real tree even when run from a copy. Rewrite the constant in the copy (or run in a container) before running any test suite that was not written for isolation.

### A side-effect logger bound to one hardcoded root records every caller, including test and overlay runs (2026-10)
A hook or helper that appends to a log under a hardcoded absolute root writes the real log for any input it is handed, so scratch copies and tests pollute production data and nothing fails. Resolve the log location from the input being processed (nearest enclosing project root), skip logging when none exists, and ship a test that runs the helper on a temp file and on a fake project and asserts the real log is untouched.

### Tests that reach paid or account-bound code
When a function's backend is swapped, every existing test that called the old top-level entry point now runs the new backend for real, and a red-phase run does the same before the code exists. Give each test class a default guard that makes the external call raise, and let only the tests that need data patch it.

### Checkers that pass on silence
A check that passes on empty output also passes when the command never ran: an unsupported flag, a missing file, or an unsplit file-list variable all print nothing to stdout and read as clean. Make every absence check fail on a non-zero tool error, and trip it once with a planted defect before trusting a PASS.

### A test sandbox that redirects a safety guard also disables it
Pointing a guard's state (pause flag, budget log) at a temp dir for tests means any test that leaks into the real side-effect path is no longer stopped by the production guard. When sandboxing a guard, also cut the real channel itself (point the external binary or endpoint at a nonexistent path) and keep one test that proves a real call fails.

### Widening a guard's scope is a behaviour change until measured (2026-09)
A guard correct on a finished artifact can be a false-positive machine on a half-written one. Before widening a guard to a new path, run it on real artifacts from that path, classify each finding as genuine or an artefact of incompleteness, and ship only if the artefact-block count is zero. Also, a populated field (fill rate) is a completeness signal; measure agreement between a producer's value and an independent read before treating it as authoritative.
Example: seven guards silent on one directory had one hard-block an honest transient write order.

### A fixture written from the docstring validates the assumption, not the world (2026-08)
A test built from the code's own comment or from the author's mental model of an external format can pass while the real format differs, and the next real run still shows the original symptom. Build the first fixture from one real captured sample of the unversioned source. When a data-loss fix ships and the next real run still shows the symptom, treat it as a second incident and re-diagnose from fresh evidence.
Example: a marker the parser expected on the header line actually lived in the HTML body, so coverage stayed at 0 of 741 until re-fixed.

### A guard's gate and its assertion must read the same text (2026-08)
A guard that gates on "the flag appears on the same line as the command" and then asserts with a multi-line regex skips every file whose invocation was rewritten to multi-line, and deleting the flag stays green. Print what the guard actually sees on one real case, and refuse any mutation that will not go red.
Example: four of five playbooks were skipped before the check ran.

### One test of every new check must reach it through the public entry point (2026-08)
A private function with five direct unit tests stays green when its single call site is commented out, and a new parameter no caller passes is a branch with coverage and no effect. Route at least one test through the entry point the gate actually uses. When a shared function gains a parameter that changes its verdict, grep every call site in the same change, shell hooks included, and test the hook, not only the API.
Example: a library dropped a fallback, but the Stop hook called it without the new argument and kept the old branch.

### A content move needs a conservation test, a caller sweep and a placement review (2026-09)
Splitting a large directive file into two passes a "every line landed somewhere" test while a binding rule moves into the half the executing reader is never told to read. Conservation answers "is it still here", never "is it where the reader will be"; also sweep cross-references to the moved sections and re-run the sweep after every later move, fixes included.
Example: a mandatory "always run in a subagent" rule landed in the reference half.

### A test file without a main block exits 0 while running nothing (2026-09)
A pytest-style file with no `__main__` block exits 0 when invoked as a plain script, so a verification command that "runs" it reports green with zero tests executed. Give every test file a `__main__` that calls the runner, or verify only through the runner.
Example: a script printed nothing and exited 0 while the runner executed 8 tests on the same file.

### A green test asserting the defect protects it (2026-09)
A passing test that encodes the defective behaviour turns red when the code is fixed, which reads as "the fix broke something" and invites a revert. When a fix changes a behaviour, grep tests and rule documents for the old behaviour and count them in the blast radius; a test that goes red because the bug is fixed gets corrected, never reverted. Sweep the file that defines the rule, not only the files that reference it.
Example: two tests asserted the destructive quarantine as correct while 274 of 437 rows were being removed.

### A named replacement must be measured capable, not merely reachable (2026-09)
When a check is moved out of a component, run the named replacement as a pure function over the real rows it must fix and report "rows the consumer rejects today that this producer fixes: N"; N of 0 means the replacement is wrong. A capability that made a tool call (authenticated fetch, browser) cannot be replaced by a pure module and has to be relocated.
Example: the named resolver fixed 0 of 33 unknown values on real data.

### A guard's real coverage is its settings matcher, not its internal logic (2026-09)
A correct, registered guard never fires on a tool surface its matcher omits, and teams argue about the script while one matcher token is missing. For every guard run two probes per surface (a payload that must block, a real value that must pass) and confirm the surface is in the matcher.
Example: a secrets guard had Bash absent from its PreToolUse matcher, so every shell write ran unguarded.

### A transcript measures the definition version that was live when it ran (2026-08)
Before drawing conclusions from agent transcripts, compare the newest transcript date against the version history of the definition under judgment. A rule newer than the corpus cannot be judged by it; the honest verdict is "unmeasured", and the next step is one live run.
Example: 77 measured dispatches all predated a rewrite, so eleven turn-cutting commits had never executed once.

### A comment line can be a test's parsed contract (2026-09)
Before trimming a hook's header comments, grep the test suite for the hook's name: a test may regex-parse a header line as a machine-readable contract, and deleting it as stale prose turns the guard red.
Example: a header line "ACTUAL LIVE REGISTRATION" was parsed by a test that pinned header against settings.

### A shell write to a file guarded only on the edit tools skips the guard (2026-10)
A guard's reach is its matcher: a write made through a shell or script to a file whose guard matches only the edit tools is never adjudicated, even if the approving record exists, and a brief saying "use the edit tool" is not enforcement. Add an independent test that fails when any guarded file changes without an approved record, whatever wrote it.
Example: a subagent edited a gated script via Python; later a lander did it again; a ledger-reach test closed the gap.

### A best-effort side-effect write hides test leakage (2026-09)
A write wrapped to never fail (so production is safe) also makes its test-time version invisible: a subprocess test that exercises the real path to a clean exit silently appends rows to the production journal. Give every script that writes a shared, measured log an env or flag override for that path before the first subprocess test is written, and diff the real log's row count before and after the suite.
Example: five fixture rows polluted a journal used for a metric.

### An "untracked, harmless" file can be a load-bearing fixture (2026-09)
"Untracked in version control" and "no docstring mentions it" are necessary but not sufficient evidence a file is unused; a test can depend on a fixture purely by hardcoded path. Before approving a deletion, grep the exact basename across every test and agent definition in the repo; zero hits is the bar.
Example: a deleted fixture took a suite from 10 of 10 to a setup error, found only by a later baseline run.

### A test pinned to a prunable file rots silently (2026-11)
A test that reads a file under a directory that is pruned on a schedule fails after the prune with an unrelated-looking value mismatch. Keep fixtures in tracked directories outside any pruned path.
Example: a test read a generated report from a 15-day-pruned folder and failed 75 != 70.

### An edit guard must mirror every downstream gate (2026-10)
A guard that accepts a rewrite on the headline metrics only passes texts a later gate rejects, and a documentation claim that a mode "removes" a class of hits is untrue until the gate has been run. Build the guard from the downstream gate's own checks and run that gate on real stored inputs before writing the claim.
Example: a one-shot guard checked score and one count; 17 of 40 rows would still have failed the real lint gates.

### A prompt that rewards a metric makes a generator break another gate's rule (2026-10)
Telling a generator to "add content" or that a score is "low" pushes it to emit text a later grounding gate rejects, and a repair that checks only one gate's rule accepts values the other gates forbid. Put the constraint in the instruction, run every checker that will later see the output (or reuse the downstream predicate) at the point of insertion, and fall back to a known-good verbatim value rather than deleting.
Example: a repair step validated grounding only and let through a value two other guards blocked.

### A gate keyed on a field absent in some modes misclassifies those modes (2026-09)
A guard that exempts subagents by checking one field (present "only inside a subagent call") also blocks every top-level headless session that never sets it. Use a signal the omission cannot fake (the parent process's argv, immune to env inheritance), and check it after any self-protection logic so those guards still bind headless sessions.
Example: a main-session gate blocked every print-mode launcher with exit 2.

### A regex-on-free-text gate ignores the structured field that identifies the dispatch (2026-09)
A hook meant to gate one dispatch shape by regex over prompt text instead of the structured field (subagent type, tool name, model) both false-positives on unrelated text and can never be reliably unblocked. When such a hook is imported without reconciling it against another file's binding contract for the same workflow, the two require mutually exclusive things of the same call.
Example: a guard blocked the very subagent call a workflow document required.

### An unpinned global CLI upgraded its grammar and reply shape (2026-10)
A dependency installed outside the repo can change its argument grammar and output format on upgrade; a fixture that hand-writes the old reply keeps passing, and a driver that never returns non-zero reports success. Fake the dependency with a strict stand-in that rejects the old grammar, keep grammar and reply parsing in one shared module, run a zero-cost call through the real binary before spending any work, and fail the status when every unit shares one failure class.
Example: every browser unit failed after an upgrade while the spine marked the step PASS.

### A "--help" probe on a hand-parsed script ran it live and spent money (2026-10)
Scripts that read flags with `"--x" in argv` treat any unknown flag, `--help` included, as "use the defaults", so a harmless usage probe becomes a real paid run. Read the docstring or source for usage, and make every spending script reject unknown flags before it touches a credential.
Example: `--help` ran a paid actor with the default cap and spent 0.205 USD of the last 0.26.

### A spend cap checked after launching the run overshoots (2026-10)
Stopping when the running total passes the cap always overshoots by the run already in flight. Check the worst-case cost of the next run against what is left before starting it.
Example: a 0.50 USD cap ended at 0.515 because the last of 15 runs started before the check.

## Data Provenance and Field Contracts


### Derived report ignores an exclusion list the primary pipeline already enforces (2026-08)
- A secondary read-only view (a summary, a dashboard, a "needs follow-up" report) built straight from a raw data source can resurface entities the main pipeline has since decided to exclude, if the view was never wired to the same exclusion list.

### Pipeline output re-ingested by the same pipeline as input (2026-08)
- Writing a step's own verdict or annotation into a document that a later step also reads as source data lets the later step confirm its own earlier conclusion instead of checking anything new.
- Fix pattern: strip or quarantine self-authored annotation blocks, using a marker set derived from real occurrences, before any classifier reads the cached document; also check heading lines and other non-block locations the same authoring step may have touched.

### Default value fabricated and then cited as a real read (2026-08)
- A `value or DEFAULT` fallback that also gets logged or labeled with a real field-parsing name misattributes a placeholder guess as a genuine structured read, so nothing downstream can tell "the source said X" from "we found nothing and guessed X". Fix pattern: default the field to empty/unresolved rather than a placeholder, and only ever attach a provenance label to a value that was actually parsed from somewhere.

### Coarse derived boolean read as a standalone primary signal (2026-08)
- A boolean a source derives FROM a richer enum (e.g. "is_active" derived from a 3-way active/paused/closed status field) collapses two distinct categories together, so reading it alone whenever the richer field is absent silently merges those categories back into one wrong answer. Fix pattern: never fall back to the derived boolean alone; skip past it to the next real signal, and measure live whether the two fields are ever null independently, since the vulnerable fallback path may already be dead code in practice today even though the field-level risk is real.

### Text scanner blind to the encoding its input actually arrives in (2026-08)
A scanner that extracts URLs or identifiers from a fetched document must normalize the transport encodings first (JSON backslash escapes, HTML named and numeric entities), because the same link is often present in several escaped forms at once and a raw regex sees none of them. Unescape before matching, and remember that a value carried forward still-escaped is not merely ugly, it is wrong: an entity-escaped ampersand turns the next query parameter's name into a different name.

### Human-readable note concatenated onto the same field an external call consumes (2026-08)
- A field built to serve both a log-friendly label and the literal value handed to an external API/search/query call lets debug text (a bracketed note, a fallback marker) get sent as part of the real request and stored as if it were the real value, because nothing keeps the two purposes separate.
- Fix pattern: keep the literal value clean and put the annotation in a sibling field (`value` plus `value_note`/`value_original`), never format them into one string.

### Unstable Chunk Boundaries Across Incremental Reads
When paging a large result out of an external store in size-bounded chunks, re-chunking over the
whole accumulated set on every call makes chunk indices meaningless: data appended between two
reads re-flows every boundary, so reading chunks 0-2 early and 3-5 later silently drops rows
while the totals still look plausible. Chunk within a unit that never changes after capture (one
page, one batch, one file), and have the reader emit that unit's own row count so the caller can
verify it reassembled everything before persisting.

### Derived Numbers Typed Into Durable Docs Mid-Run
A number computed partway through a long run and typed into a permanent document goes stale the
moment the run continues, and nothing ever reconciles the prose against the final state. Compute
durable claims only after the run's last step, or add a close-time gate that recomputes ground
truth from the artifacts and fails when any document disagrees.

### Auxiliary signal field dropped by an intermediate stage that only preserves its own known schema (2026-08)
When a pipeline has multiple sequential stages (filter, dedup, score) and only the FIRST stage's writer is checked for field preservation, an auxiliary field attached at capture time can silently vanish by the time a LATER stage reads it, even though nothing downstream ever explicitly deletes it; verify a custom field survives the FULL chain end to end, not just the first hop, before relying on a downstream reader to see it.

### Field Type Contracts
A field a downstream consumer treats as strictly numeric (for comparison, summation, or a threshold check) must never be given human-readable descriptive text instead, even when the raw source value itself is fuzzy (e.g. a platform reporting "99+" instead of an exact count) or a note about method feels useful to preserve inline. Put the numeric best-estimate in the typed field and move any qualifying description into a separate free-text field the consumer does not do arithmetic on.

### Batch LLM classification collapses into templated output at scale (2026-08)
A delegated model asked to classify many items in one batch can produce a well-formed but degenerate result: valid JSON, correct item count, yet the same boilerplate reason repeated across unrelated items instead of genuine per-item judgment. Spot-check a sample of any batch classifier's positive/flagged outputs for reason-text diversity before merging downstream, and treat a flag rate far above that task's historical norm as a re-verify signal, not just a number to report.

### Text-Extraction Ordering: Unescape Before Stripping Markup
When source text arrives entity-escaped, stripping markup before unescaping is a no-op that
silently re-creates the markup, because the unescape step turns the escaped entities back into
real tags after the stripper has already run. Always unescape first, then strip tags, then
unescape once more for residual entities, and assert zero tag matches on the result rather than
trusting the pipeline.

### Durable State
Work-in-progress artifacts that a later step must consume belong inside the project tree, never in a session scratch directory, because a session restart or a tmp sweep deletes them and the producing step has to be paid for twice. Treat any file another dispatch will read as pipeline state, not as a temp file, even when it is explicitly labeled a draft.

### Two-value contract collapsed into one variable at the call site (2026-08)
A parameter that legitimately needs two different values for two different consumers (the literal string an external API must receive vs. the canonical short label a downstream classifier's own whitelist recognizes) breaks silently when a caller reuses one variable for both, because nothing forces the two call sites to diverge. Fix pattern: keep the canonical/API-safe form and the classifier-facing label as two named values from the point they first diverge, not one variable threaded through both calls.

### A network-failure path overwrites an already-resolved trusted field with its own "unknown" default (2026-08)
- A downstream enrichment step that fetches a page to confirm or add a field, on a fetch error/timeout, wrote its own failure placeholder into that field unconditionally, silently downgrading a value an earlier, more authoritative step had already resolved. Fix pattern: on a fetch failure, leave a field that already carries a value untouched (merge/preserve, never blanket-overwrite), and only write the failure placeholder into a field that was genuinely still empty.

### Reused a whole classify() function instead of its pieces
**Pattern to carry forward:** when a gap's real logic has real interdependencies (a carve-out,
an ordering requirement, cross-module state), call the ORIGINAL function wholesale and filter
its output to the one signal you need, rather than re-deriving the logic piecemeal. Reuse the
behavior, not just the shape of it; a re-derived copy is a second place the original can drift
from, which is the same failure class this whole investigation started by uncovering.

### A driver checked its own "am I done" state before writing the final value
**Bug (self-caused):** a driver process wrote its own completion state incrementally (an early "not done" write for OTHER concurrent readers, a final "done" write as its last action), then called its own downstream check BEFORE that final write landed, so the check always read the pre-completion value and silently no-op'd on every run regardless of what actually happened. A same-process, same-session mid-run read of self-reported state must be strictly ordered AFTER the final state write, never before it, no matter how correct the check's own logic is.

### Durable State: whole-document write from a stale client cache (2026-09)
A client that caches a shared document once at load and later saves the whole document with a replace call silently erases every change another view made in between, in any last-writer-wins store. Write only the changed field with a merge/update call, so concurrent writers touch disjoint keys.
- Seen: a checkbox tracker page saved its full tick map with set(); the store held one key after 51 saves, so whether earlier ticks were lost is undeterminable.
- Guard: persist per-field updates, never a full replace of a map built from a load-time snapshot.

### Asymmetric scoring in a classifier (2026-09)
- A detector that counts every occurrence for one class but only distinct markers for the others, or whose markers are stored in a normalised form the input never gets normalised to, will crown the favoured class on almost any mixed input. Score every class with the same unit on the same normalisation, and pin a test on a real mixed document from the losing class.

### A broad pattern run over noisy text before a narrow structured check misclassifies the clear cases (2026-10)
When a classifier tests a field that is clean and authoritative (country code) and a noisy free-text field (notes) together, run the narrow check on the clean field first, and give short tokens an explicit match instead of relying on a broad word list. Otherwise a broad bucket swallows rows the clean field already answers, and downstream rules keyed on the narrow class never fire.

### A subagent hand-transcribed structured data and silently dropped a field (2026-08)
When a dispatch lets the subagent choose its extraction method, it may bypass the repo script that already produces the data and normalize away a field (a parenthetical marker) that the schema never named; the output matches the schema field for field and passes count, uniqueness and blank checks. Name the script in the dispatch and require its output, and spot-check extracted values against the raw source, not just against the schema.
Example: "Order 4412 (Draft)" became "Order 4412" on 336 rows.

### A boolean verdict and its reason string disagreed (2026-09)
When a producer returns `(verdict, reason)`, storing the reason without the verdict is worse than storing neither, because the reason looks like provenance and reads as corroboration during review. A field a downstream gate trusts must be written by a committed script with a test pinning the false case, never by ad hoc assembly code; grep for the field name in committed code first, since a field no script writes is a field nothing tested.
Example: 17 rows paired "confirmed: true" with a reason string that exists only on the false branch.

### A narrow verdict stamped over a record's lifecycle status (2026-09)
A check answering one narrow question (is the page still reachable) must not overwrite a broader status (in progress, completed) without reading it. Gate the write on the current status and put the narrow verdict in its own field.
Example: a liveness sweep marked an order "closed" while the underlying process was in live progress.

### A fail-open authenticity check is not a presence check (2026-09)
A validator that judges "does this look fake" and fails open on short input returns True for the empty string, so reusing it as a "did we get anything" guard caches empty responses. Read what a validator returns on empty and degenerate input before reuse, gate presence with a length floor first, delete the artifact if it lands under the floor, and derive success counts from the artifact on disk.
Example: the run reported 363 fetched while 324 files were empty.

### A per-instance review misattributes a shared-template defect (2026-09)
A review that compares one generated document to ground truth can flag claims as unsupported that are byte-identical boilerplate in the shared template every output is built from. Diff flagged passages against the template, and against an independently generated instance, before attributing a defect to one instance's authorship; otherwise the defect returns as a "new" finding every time.
Example: six of seven flagged items were template text.

### A shared-folder export filed under the requested owner, never checked for authorship (2026-10)
An export returns everything visible in a folder, including forwarded and co-authored items by others, and a build step that files every item under the requested owner mixes other people's content into per-author statistics. Compare each item's author to the requested owner at build time, keep matches only, and report the drop count.
Example: 30 of 1,166 rows were someone else's documents.

### A parser reused on a file shape it was not written for (2026-10)
A prose parser that splits on sentence boundaries turns a structured record (claim line followed by verdict line) into fragments, so a downstream judge receives the label instead of the claim. Before feeding a new file shape through an existing parser, print one parsed record and check its fields.
Example: items reached a verifier as "PARTLY." with no hypothesis text.

### Report files named by input stem collide across artifact kinds (2026-10)
A tool that names output after the input's bare stem overwrites one report with another whenever two kinds of input share a stem. Derive the output name from enough of the path to be unique per kind and pin it with a test that runs both kinds.
Example: a section and its lesson both wrote `S4.1.json`.

### A producer derives its own path while every consumer reads a fixed one (2026-10)
When a producer builds a record path from its working directory and consumers read a canonical path, the two drift apart silently and the gap gets closed by manual appends. One helper owns the path, and the writer, the per-unit check and any override all call it.
Example: rows were written to a per-date progress folder while the stop gates read a ledger folder.

### An approval stored without a date becomes a standing permission (2026-11)
When the owner says "ask me right before running", an approval is valid for one run window, not forever. A plain list of approved ids turns a one-time yes into a standing one; store the date with the approval and honour it only that day.
Example: an id approved on 10-29 was acted on without a fresh check on 11-16.

### A corrected constant duplicated across files stays wrong everywhere it was copied (2026-08)
A factual constant hardcoded in several files (a threshold, a limit) corrected in the canonical source stays wrong in every copy unless the correction greps for the old value. Fixing the rule or memory file alone is not fixing the bug when an agent definition or hook still hardcodes the old number.
Example: a limit changed from 2 to 3, but two agent definitions kept "exactly 2" for two weeks and an audit flagged a correct output.

### Re-invoking a "w"-mode script at a shared output path destroys prior rows (2026-09)
A script that opens its `--out` with "w" is safe behind a wrapper that writes a fresh file per call, and destructive when called directly twice at the same path. Before calling any wrapper-only script directly, check how the wrapper accumulates results, or write to a new path every time and merge explicitly.
Example: two direct calls overwrote about 690 rows across 9 units; found when a tally showed 12 units instead of 21.

## Process, Orchestration and Safe Writes


### Exact-string correlation across independently-authored text (2026-08)
- Correlating two independently-authored strings via exact match after light normalization fails silently on any phrasing drift.
- No error surfaces; it just looks like empty data.
- Fix pattern: use token-set/fuzzy matching with a fallback, and record HOW a match resolved (exact/fuzzy/unresolved).

### Bare word co-occurrence used as a phrase ban (2026-08)
- A regex meant to ban one specific phrase, written as "word A present AND word B present anywhere in the string," bans every text containing both words in any relationship, not just that phrase.
- Fix pattern: anchor the words adjacent to each other (or to a small set of real phrasings), not merely co-present.

### Form validator mistaken for a truth validator (2026-08)
A guard that checks whether a value is well-FORMED (has a unit, a denominator, a required field) does not check whether the value is TRUE, yet its presence makes the surface feel covered and blocks nobody from inventing the value. When the authoritative source exists on disk, add a second guard that resolves the value against that source deterministically instead of trusting the generating model's self-check.

### Identifier stored in a form the consumer re-expands (2026-08)
When a stored value is fed to a builder that re-appends context around it, store the minimal component the builder expects, not the fully-qualified form, or the builder produces a doubled address. Assert on the builder's OUTPUT rather than on the stored token, because the output is the only thing that is actually used.

### A documented "third net" was actually the only net
**Pattern to carry forward:** a comment that says "X already happens upstream, this is just a
backstop" is a claim, not a guarantee. When investigating a suspected gap, check whether the
docstring's OWN "should already be handled elsewhere" claim is actually true, the same way you
would check any other unverified assumption; a defensive backstop's comment can be the exact
place a real gap hides, because everyone who reads it assumes the real check exists elsewhere.

### Open(p,'w') truncates before the nested read runs
**Symptom:** a Markdown record file silently became 0 bytes after what looked like a normal
in-place edit. No error was raised; the next grep returned 0 matches and that was the only signal.
**Fix:** always read fully into a variable first, then open for writing.
    s = open(p).read()
    assert s.count(a) == 1
    open(p, 'w').write(s.replace(a, b))
**Guard:** after any scripted in-place edit, assert the result is non-empty and that the expected
marker is present, in the same command. `wc -c` returning 0, or a grep for text you just inserted
returning 0, means the write destroyed the file rather than edited it. The first edit in that same
session used the safe order and was fine; the failure appeared only when a second edit was chained
onto the same file in one statement.

### A documented cross-phase retry existed only as prose, never as code
An agent-definition doc described a multi-phase pipeline's orchestrator as automatically re-running an earlier phase whenever a later phase's review flagged a problem ("respawn phase X once verdict Y is seen"). The actual driver code recorded that verdict and always forwarded the item to the next phase regardless of its value, with zero branching on the verdict content and no mechanism anywhere to feed one phase's findings back into an earlier phase's input. The described safety behavior only ever existed for an interactive mode where a live human-directed orchestrator manually performed the respawn by hand; a fully automated/headless run of the same pipeline had no such actor and silently skipped the safeguard every time, with the flagged verdict just sitting unused in a log.

### Destructive git command in a dirty shared tree (2026-09)
`git checkout -- <path>` restores the working tree from the INDEX, not from HEAD, so running it over a list of paths copy-pasted from an earlier narrower command silently discards uncommitted working-tree edits on any path whose index already matched HEAD. Scope the path list to exactly the files that need resetting, or `git stash push -- <paths>` first so a wrong scope is recoverable instead of destructive.

### A target-shape check applied to the whole command line instead of the targets
A safety check that judges what a dangerous verb acts on (glob, recursive, path root) must run over that verb's resolved arguments, or must first neutralise shell syntax that only looks like the danger signal (`$?` is an exit status, not a `?` glob), otherwise a harmless neighbour on the same line trips an unoverridable floor. Pin it with a test pair: the benign lookalike passes, and the real danger in the same characters (`x?`, `\$?`, `$$?`) still trips.

### One ban kept in two stores that nothing keeps equal
When one rule is enforced by two independent stores (a code list and a config consumed by a hook), adding a value to one leaves the other silently open for a different caller. Write the value to every store in the same change and add a test that fails when the two lists differ.

### The deleter and its audit write lived in different functions, so any direct caller deleted with no trail
When a destructive routine unlinks files itself while its audit record is written by a separate caller, every other caller (a test, an import) deletes with no trail, so the loss can be neither counted nor restored afterwards. Write the audit row inside the deleting function, before the unlink.

### A shared mutable working tree must not be touched by agent actions that rewrite it wholesale
Agents that need a clean tree must work in an isolated copy, never run commands that temporarily revert the shared tree, because concurrent readers see the intermediate state. A prose rule did not stop it; a PreToolUse guard on the command did.

### Never touch git lock files; commit from a clean worktree when the shared tree is dirty
An agent moved .git/index.lock aside while a commit (pre-commit suite) was still running, so the commit recorded an empty tree. A lock file marks a live writer; removing it lets a second writer corrupt the result.
Rule: never move or remove any .git lock file; when the shared tree is dirty or the hook suite fails on foreign files, `git worktree add <scratch>/wt -b <branch> <sha>`, copy the keep-list in, and commit there.

### File I/O / format preservation
A rewrite helper that writes with the platform default line ending silently converts a file's CRLF to LF, which breaks byte-identical header checks and produces whole-file diffs. Detect and reuse the file's own newline when rewriting.

### An absolute rule is only as absolute as its weakest enforcement path (2026-08)
A rule stated as absolute in the docs can have zero enforcement in one of several entry points into a pipeline, and the first line of defense can be a soft "third net" that was in fact the only net. Verify each entry point enforces it, check that a docstring's "already handled upstream" is true, and when adding a new terminal decision value grep every place the old values are enumerated (buckets, reports, totals), because a value missing from an enumeration silently vanishes.
Example: an export path never called the exclusion check kept in another module, and 44 excluded rows were exported.

### Close a gap by adding only the part the existing system does not handle (2026-08)
When a legacy system and a newly found gap cover overlapping ground, the fix is not "add the missing system" but "add only what the existing one does not do", verified empirically tag by tag; wiring in the whole rule set can downgrade a nuanced review path to a hard exclusion. A test that starts failing after a fix may be depending incidentally on the old behaviour; check which before touching either. When the logic has real interdependencies, call the original function wholesale and filter its output to the signal needed instead of re-deriving it.
Example: six of twelve category tags overlapped an existing verdict system and were deliberately left routed through it.

### A precondition check verified a narrower invariant than the guard it protects (2026-09)
Before mutating a shared config, confirming "the specific consumer named X is not active" is weaker than the invariant a downstream guard enforces ("no active process that snapshotted this file is still relying on it"). Derive the precondition from what the guard itself compares, not from an intuitive proxy that happens to be true when you look.
Example: checking one stage's process was empty while a multi-phase run in flight aborted at its next phase transition.

### A subagent's report was relayed as fact without opening the primary source (2026-09)
Repeating an agent's summary line into a user-facing document, without opening the cited source, launders an overstatement through every hand-off, because each hop trusts the previous summary. Before a claim about a third party enters an artifact, open the cited line or label it "reported by a subagent, unverified". A summary from an agent is a lead, not a source.
Example: a transcript showed the app used for something unrelated to the claim.

### Spot-checking by ease of fetch lets the load-bearing claim through (2026-09)
When sampling claims for verification, people pick the checkable but peripheral ones (prices, availability) and skip the causal sentence the whole explanation rests on. Rank claims by how much reasoning hangs on them, and check an explanatory sentence before a price.
Example: a "sorted by first name by default" claim was read, not checked, and the vendor page named no default.

### A file imported by global config was free for a later agent to move (2026-09)
A config file that imports another file silently loses the import every session if an agent allowed to restructure folders moves or dissolves the target. Name every imported file as a pinned path in the brief of any agent allowed to restructure its folder, and re-verify the import with a fresh session after that agent finishes.
Example: a symlink target folder was dissolved and the global import broke.

### A confirm-framed brief produces a confirmed wrong claim (2026-09)
Asking an agent to "confirm" a claim returns the claim: it reads one agreeing file and stops, while the measured evidence sits in a sibling file. Ask the open question and require each surviving claim to cite file and line.
Example: an unsupported marketing line was written into an imported config file.

### A secret-scrub was verified against the remote only (2026-09)
Declaring a leaked key removed after re-cloning the remote proves only that the remote is clean; a local-only branch still held it. Verify with `git rev-list --all` across every local ref, then expire the reflog, prune, and check `git fsck --unreachable`.
Example: a never-pushed backup branch still held the key in plaintext.

### Deleting notes without checking inbound links (2026-09)
Bulk-deleting approved notes broke links from other notes, and the vault check went red. After any deletion run the link checker and require exit 0, repointing links to the superseding note.
Example: 115 notes deleted; 2 were still linked from log notes.

### A brief's fence does not fence the producer it runs (2026-10)
A measurement subagent told which output paths to use still ran the real producer, whose default write targets ignore the scratch dir, so it wrote new artifacts and overwrote an untracked file with no backup. Before running a real producer for measurement, redirect or sandbox all of its write targets (env or root override, or a scratch copy of the repo) and snapshot the target directories before and after.
Example: effort probes created a new pack and replaced an untracked sections file.

### A brief without a deletion fence lets a subagent delete (2026-10)
Subagents do not reliably inherit instruction-file fences, so a brief that lists write targets but not "no deletion" can end with the agent deleting its own scratch file without approval. Every dispatch that can write files states "no deletion; list candidates instead".
Example: an orchestrator removed its scratch note after merging it.

### A coordinator brief restated a field's meaning from memory and swapped two columns (2026-10)
Before briefing a schema change, read the spec line that defines the field and cite it in the brief; never restate a field's meaning from memory.
Example: two columns, `owner` and `team`, were swapped in a brief and caught one wave later.

### A slot released on one lifecycle event leaks on every other exit path (2026-10)
A concurrency marker freed only by a normal-exit event stays held when an agent is killed, and a release lookup keyed on the mutable working directory misses when the directory changed. Add a liveness check at the acquire point for every other exit path, and key identity on stable ids (session id, transcript directory), never on ambient state.
Example: dead agents held 4 of 6 slots until the TTL.

### A prescribed command was not verified against the selector it runs under (2026-10)
A handoff that prescribes a command with a filter flag must be checked against the scheduler's own batch selection, or the run silently selects nothing and tests nothing.
Example: `--only X` filters inside today's batch, and X was in the other batch, so the dry run did nothing.

### A second component re-implements a decision an older component owns (2026-10)
A new writer that picks a value by its own selector while the stored agent follows another rule produces output the downstream gate rejects by design. Call the same rule (or run the same gate on the output before hand-off), and pin it with a test.
Example: a new slot writer's picked label was flagged in 25 of 38 replay attempts.

### Per-unit health signals cannot show an account-level quota (2026-10)
Falling error rates and zero declines per group say nothing about a service's cumulative account-level limit. When the operator questions volume against a service with undisclosed limits, weight the account-level cumulative count and add an automatic pause on the first rate-limit signal.
Example: 63 identical requests over eight days triggered a throttle despite healthy per-group signals.

### Rate limits that reset on restart protect nothing (2026-10)
A per-process load cap hands out a fresh allowance on every restart, and agents that read freezes or blank responses as "not a block" retry in a loop. Keep the counter in shared durable state read on every call, count anomalies as stop signals, and pin it with a test where two instances together must stop at one cap.
Example: a per-run cap of 45 was restarted about 35 times, producing roughly 1,500 requests and a temporary block.

### Budgets counted in calls understate the real footprint (2026-10)
One automation call can trigger several requests (pre-fetch, redirects, retries), so a cap counted in calls understates what the server sees. Calibrate the cap against the client's own record of real requests on a normal day and set it inside that range.
Example: one call triggered three requests; the cap was reset to 15 calls (about 45 requests).

### Several consumers on one capped credit without a priority (2026-10)
When several scheduled jobs draw on one monthly credit, the first to run can starve the ones that matter, and per-run caps never add up to the monthly limit. Sum worst-case monthly cost before enabling them and give lower-priority jobs a reserve threshold they must leave untouched.
Example: four consumers totalled 6.48 against a 5.00 plan.

### Concurrency blamed for corruption without evidence (2026-10)
A plausible root cause (parallel agents on one index) was recorded as fact, then contradicted by a second occurrence with a single searcher; the real cause was a false positive in a health check of the library. State a diagnosis as a hypothesis until a reproduction or upstream source confirms it, and add a consistency check (two stores compared) to the rebuild step.
Example: a "drift" quarantine of a never-flushed index segment was misread as corruption.

### Generated reply text invents first-person claims a checker cannot see (2026-10)
A deterministic checker that tests length and phrase overlap passes replies claiming the writer read or did something it never did. The brief must state the truth sources and ban unverifiable first-person claims, a human-grade review must read the text before it reaches a file an automatic sender consumes, and flawed text stays out of the live file until the fixed version passes.
Example: support replies claiming "I reviewed your invoice" passed the length check.

### A diagnosed automation gap was routed to the operator instead of fixed (2026-10)
When a probe already shows why automation misses a case, fix the automation; sending that case to a "hand" list returns the exact work the operator delegated. A tool's success signal ("no error dialog, treat as done") is not completion: trust only the independent check.
Example: one document class was logged as "needs manual review" until a local override fixed the scoping.

### A viewer's undocumented child-count limit appears only at publish time (2026-11)
A rendering host may hide a whole page when it holds too many absolutely positioned children, with only a generic error. Count children per host against the known limit (24 here) before publishing, and restructure (fold labels into band elements) rather than nesting wrappers.
Example: a slide with 26 positioned children failed to render until reduced to 23.
