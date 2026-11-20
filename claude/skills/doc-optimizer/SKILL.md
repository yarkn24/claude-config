---
name: doc-optimizer
description: Write, edit, or optimize any Claude Code configuration document (CLAUDE.md, RULES.md, skill/agent/command/hook files, settings.json) or tighten a bloated document's prose while preserving every constraint and incident. Grounds every change in code.claude.com/docs official guidance plus this environment's own verified Claude Code mechanics. Use whenever writing new config, editing existing config, or asked to de-bloat/optimize/shorten/tighten a document or prompt.
---

# Doc Optimizer

READ FIRST, ALWAYS: `~/.claude/reference/claude_code_config_lessons.md`. Verified Claude-Code-specific mechanics (hooks, settings.json, subagents, plugins, ExitPlanMode, context injection), each with a citation you can re-check. Never re-derive a mechanic that file already answers. When you verify something NEW during this skill's use, append it there (with a citation) instead of losing it in a chat transcript.

## THE PRUNE TEST (official, code.claude.com/docs/en/best-practices, fetched 2026-07-31)

FOR EVERY LINE, ASK: "Would removing this cause Claude to make a mistake?" IF NOT: cut it.

BLOATED CONFIG CAUSES CLAUDE TO IGNORE INSTRUCTIONS. Verbatim from the official docs: **"Keep it concise... If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise."** A file with 50 load-bearing lines and 250 filler lines performs worse than 50 tight lines alone, because the filler buries the signal.

| KEEP | CUT |
|---|---|
| Bash commands Claude can't guess | Anything Claude can figure out by reading code |
| Style rules that differ from defaults | Standard conventions Claude already knows |
| Testing/workflow instructions | Detailed API docs (link instead) |
| Repo etiquette, architectural decisions | Information that changes frequently |
| Non-obvious gotchas, real incidents | Long explanations, tutorials, self-evident advice |

## NO CEILING WHEN YOU AUTHOR A PROMPT OR BRIEF

WRITE THE FLOOR AND THE FENCE, THEN GET OUT OF THE WAY. A prompt names what must be covered and what must not break; it does not prescribe method, agent count, rounds, or decomposition.

| WRITE THIS | NOT THIS |
|---|---|
| The coverage floor: files, systems, questions that must be looked at | A fixed agent roster with per-agent scopes |
| The fence: what must not break, what is out of bounds | Step-by-step method for work the model can plan itself |
| "Models are free, override the default tier with a stated reason" | A locked model per task |
| "Reject this framing with evidence if it is wrong" | An unquestionable premise |
| Open questions as LEADS, ranked below anything bigger found | Leads written as mandatory tasks |

Opus 5 self-verifies, so legacy "double-check your answer" scaffolding is cuttable. THIS ENVIRONMENT'S EVIDENCE RULES ARE NOT: they are incident-derived and survive the prune test by origin. Free the method, keep the evidence bar. Sources, quotes, dates: `~/.claude/reference/no_ceiling_prompting.md`.

## NEVER DROP A JUSTIFIED RULE

Tightening prose is not the same as dropping a constraint. If a rule exists because of a real incident (a date, a wrong outcome, a name), keep the rule AND the incident; shorten the SENTENCES, not the SUBSTANCE. Move deep "why, when, superseded-by" narrative to a linked changelog/reference doc; leave a terse present-tense instruction plus a pointer inline. This is the same pattern this repo already uses for `docs/rules/*.md` pointers from `CLAUDE.md`.

## WORKFLOW

1. READ the target document in full, current state. Files in an active repo move between sessions; never trust a memory or a prior measurement without a fresh Read.
2. READ `~/.claude/reference/claude_code_config_lessons.md` for any mechanic relevant to this file type (hook, settings.json, skill, subagent, plugin).
3. RUN THE PRUNE TEST line by line. Flag three kinds of cut: pure duplication (same rule stated twice, quote both passages verbatim), verbosity that drops no constraint (draft a before/after, confirm nothing substantive is lost), historical narrative better relocated to a changelog than repeated inline.
4. FOR EVERY PROPOSED CUT, state the evidence it is safe. "This looks long" is not evidence. A duplication needs both quotes side by side. A verbosity cut needs the before/after pair.
5. APPLY, keeping every incident and constraint. Convert deep rationale into a short pointer plus a linked doc, never a silent deletion.
6. MEASURE before and after. Use `wc -c` / `wc -l` for a single file; use the token-baseline subprocess method documented in `claude_code_config_lessons.md` when the file is session-always-on (CLAUDE.md, MEMORY.md, a skill/agent description). A claimed improvement without a rerun is a guess, not a finding.
7. WRITE the result in LOVABLE STYLE (below). Re-read the diff once more and confirm no rule, incident, or constraint silently disappeared.

## LOVABLE STYLE (this project's binding MD convention, memory: `feedback_md_concise_lovable_style`)

UPPERCASE DIRECTIVE, then one-line explanation. Imperative mood, short sentences. NO preamble, NO emoji. Most critical information FIRST (inverted pyramid, not narrative order). Numbered workflows; short bullets, not paragraphs.

## COMMON PITFALL (official, same source)

Do not force-fit a generic best practice onto a repo it does not match, e.g. a test-runner hook onto a repo with no test suite. Verify the practice actually applies to THIS project before applying it.

## Provenance

Grounded in `code.claude.com/docs/en/best-practices` (fetched 2026-07-31) and `~/.claude/reference/claude_code_config_lessons.md` (this environment's own verified Claude Code mechanics, updated as new lessons are confirmed). Style rule from this project's `feedback_md_concise_lovable_style` memory.
