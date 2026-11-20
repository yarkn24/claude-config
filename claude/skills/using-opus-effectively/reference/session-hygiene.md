# SESSION HYGIENE

## WHY THIS MATTERS MORE THAN PROMPT WORDING

Context is the fundamental constraint. Performance degrades as it fills, and a full window makes the model forget earlier instructions and make more mistakes [source: code.claude.com/docs/en/best-practices].

Most sessions that "go bad" are not prompting failures. They are context failures.

## THE DIAGNOSTIC TABLE

| Symptom | Real cause | Fix |
|---|---|---|
| Instructions ignored | Instruction file too long, rule lost in noise | Prune the file, not the prompt |
| Same mistake after two corrections | Context polluted with failed approaches | `/clear`, rewrite the prompt |
| Answers drift off topic | Unrelated earlier task still in context | `/clear` between tasks |
| Slow and vague | Window near full | `/clear` or `/compact` |
| Asks something already in the rules file | Ambiguous phrasing, not a missing rule | Reword the rule |
| Reads hundreds of files | Unscoped investigation | Scope it, or delegate |

## THE TWO-CORRECTION RULE

AFTER TWO FAILED CORRECTIONS ON THE SAME ISSUE, STOP CORRECTING.

Each correction adds the failed approach to context, which makes the next attempt worse. A clean session with a better prompt, written using what the failures taught, almost always beats a long session carrying them.

## THE TOOLS, BY BLUNTNESS

| Tool | Effect | Use when |
|---|---|---|
| `/clear` | Full context reset | Switching tasks, or after two corrections |
| `/compact <focus>` | Summarize, keeping what matters | Long single task, still relevant |
| Rewind, summarize from here | Condense forward from a point | Early context is worth keeping |
| Rewind, summarize up to here | Condense earlier, keep recent | Recent detail is what matters |
| Side-question channel | Answer never enters history | A quick check that must not cost context |
| Checkpoint restore | Conversation and code back to a point | An experiment went wrong |

## COMPACTION IS LOSSY, STEER IT

Compaction decides what survives. Left alone it may drop the thing you needed.

State what must survive, for example the full list of modified files and the exact test commands. A standing compaction instruction in the project instruction file makes this durable across sessions.

## CHECKPOINTS INVITE RISK-TAKING

Because every prompt creates a restorable checkpoint, trying a risky approach is cheap. Try it, and rewind if it fails, instead of over-planning to avoid a mistake that costs one keystroke to undo.

LIMIT: checkpoints track only changes made through file-editing tools. Changes made by bash commands or external processes are NOT captured. Checkpoints are not a substitute for git.

## SESSIONS AS BRANCHES

Name sessions and treat each workstream as its own persistent context. Resuming a named session beats re-explaining a task from scratch, and it keeps unrelated work from colliding in one window.

## WHAT BELONGS IN AN ALWAYS-ON INSTRUCTION FILE

The test for every line: WOULD REMOVING THIS CAUSE A MISTAKE? If not, cut it.

| Include | Exclude |
|---|---|
| Commands that cannot be guessed | Anything derivable by reading the code |
| Style rules that differ from defaults | Standard conventions already known |
| Test runners and how to invoke them | Detailed API docs, link instead |
| Repository etiquette | Information that changes often |
| Architecture decisions specific to this project | File-by-file descriptions |
| Environment quirks and required variables | Self-evident advice |

RULES THAT APPLY ONLY SOMETIMES BELONG IN A SKILL, not in the always-on file. Skills load on demand and cost nothing until used.

IF A RULE KEEPS BEING IGNORED, THE FILE IS PROBABLY TOO LONG. Adding emphasis to the rule treats the symptom. Pruning the file treats the cause.

CONVERT, DO NOT REPEAT. A rule that must hold every time belongs in a hook, which is deterministic, rather than in prose, which is advisory.
