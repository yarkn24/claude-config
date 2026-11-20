# D1: DELETE FIRST, MEASURE SECOND

## DIRECTIVE

DELETE THE INSTRUCTION LAYER, THEN MEASURE WHAT BREAKS. Reasoning about which rules are needed produces a prior, not evidence.

## WHAT AN ABLATION IS

An ablation is an eval where you remove things to find out what each one contributes. Source wording: "ablation essentially it's an eval, but you delete things to figure out the impact" [official transcript].

Two directions, both valid:

| Direction | Method | Best for |
|---|---|---|
| Subtractive | Remove everything, add back line by line | A whole layer of unknown value |
| Targeted | Remove one rule, hold the rest fixed | A single disputed rule |

## THE SAFE MECHANISM HERE

`claude --bare` is the upstream ablation switch. It deletes nothing on disk, but the run it starts has no hooks and no CLAUDE.md, so it is not run on a firm machine. Use it only in a throwaway sandbox that holds no firm or client data, with IT approval.

| Flag | Effect |
|---|---|
| `--bare` | Skips hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, and CLAUDE.md auto-discovery. Sets `CLAUDE_CODE_SIMPLE=1` |
| `--system-prompt <p>` | Replaces the system prompt entirely |
| `--append-system-prompt <p>` | Adds without replacing, useful for re-adding one rule at a time |
| `--settings <file>` | Points at an alternate settings file, so a hook subset can be tested without editing the real one |

The source calls `CLAUDE_CODE_SIMPLE=1` undocumented. In 2.1.221 it is a first-class documented flag. Verify against `claude --help` before assuming either way.

## PROCEDURE

1. FIX MISFIRING HOOKS FIRST. A hook that false-positives tells you nothing about its rule.
2. RECORD THE BASELINE. Token counts, file counts, registration counts, current quality metric.
3. PICK ONE TASK with an objective quality metric already attached.
4. RUN IT BOTH WAYS. Full harness, then `--bare`. Same prompt, same inputs.
5. DIFF THE OUTPUTS, not the summaries.
6. CLASSIFY EACH DIFFERENCE against `keep-or-cut.md`.

## READING THE RESULT

| Observation | Meaning | Action |
|---|---|---|
| Rule honoured under `--bare` | The model does this unprompted | ABLATION CANDIDATE, bucket D |
| Rule violated under `--bare` | The rule is load-bearing | KEEP, and record this evidence next to it |
| Output better under `--bare` | The instruction is actively harmful | REMOVE, highest priority |
| Output worse under `--bare` | Something in the harness is earning its keep | Find which part, keep only that |

## THE COUNTERWEIGHT

The same source that says the model is smarter without prompts also says a PRODUCT still needs some of them. Smarter is not the same as better-behaved. Full quote: `00-source.md`, D1 COUNTERWEIGHT.

A rule can be simultaneously unnecessary for intelligence and necessary for safety. Bucket A exists for exactly this case.

## WHAT NOT TO DO

- Do not apply anything. This skill proposes; the operator decides.
- Do not ablate a rule that exists because of a recorded incident. That answer is already known.
- Do not treat "I found nothing to cut" as a failed audit. In an incident-built harness it is the expected result.
- Do not delete files to run an ablation. `--bare` is non-destructive and gives the same answer.
- Do not ablate bucket A to "be thorough". The result is known and the downside is real.
- Do not conclude from one run. Model output varies; use repetitions.
- Do not count bytes and call it a result. Bytes are not a quality metric.
