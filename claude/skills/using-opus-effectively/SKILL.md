---
name: using-opus-effectively
description: Use when choosing which model to run a task on, when a task keeps failing or producing plausible-but-wrong output, when deciding whether to plan first or code directly, when a session feels slow or Claude starts ignoring instructions, when scoping a long or unattended run, or when deciding whether to delegate to subagents or run work in parallel. Do NOT use for harness auditing or deciding whether a hook earns its context, which is the opus5 skill.
---

# USING OPUS EFFECTIVELY

## CORE PRINCIPLE

DESCRIBE THE OUTCOME, GIVE A WAY TO CHECK IT, THEN GET OUT OF THE WAY. Capability is rarely the limit. Task framing and verification are.

## THE ONE THING MOST PEOPLE GET WRONG

VERIFICATION, NOT PROMPTING.

Official guidance states it directly: "Claude stops when the work looks done. Without a check it can run, 'looks done' is the only signal available, and you become the verification loop" [source: code.claude.com/docs/en/best-practices].

Before adding another instruction, ask whether a check would work better. Usually it would.

## MODEL SELECTION, LOCAL BINDING RULE

PLANNING GOES TO OPUS. EVERYTHING ELSE GOES TO SONNET. Unchanged default.

| Work | Model | Why |
|---|---|---|
| Planning, architecture, design review | Opus | Judgment over a wide solution space |
| Complex debugging STRATEGY | Opus | Deciding what to investigate |
| Writing code, editing files, running tests | Sonnet | Execution against a decided plan |
| Search, parsing, summarizing, mechanical edits | Sonnet | No judgment required |
| Narrow pre-classification inside a pipeline | Haiku | Cheap and bounded |

HARD CONSTRAINTS:

1. Subagent `model` accepts ONLY `sonnet`, `opus`, `haiku`.
2. Once planning ends and execution starts, SWITCH BACK to Sonnet.
3. Model tier is chosen by JUDGMENT REQUIRED, never by task importance or prestige.

Full decision table and edge cases: `reference/model-selection.md`.

## THE FOUR-PART TASK FRAME

State these four, then stop talking.

| Part | Answers | If missing |
|---|---|---|
| TASK | What outcome do I want? | Solves the wrong problem |
| GUARDRAILS | What must never happen? | Takes a forbidden shortcut |
| EXIT CRITERIA | How do I know it is done? | Stops early, or never stops |
| VERIFICATION | How does it check itself? | Declares success while wrong |

OVER-SPECIFYING THE STEPS MAKES MODERN MODELS WORSE, not better. Doctrine and quotes: `opus5` skill, `reference/D3-task-framing.md`.

CAVEAT THAT APPLIES HERE: de-specification is calibrated on frontier models. If the executor is Sonnet or Haiku, treat looser framing as a hypothesis to test on one task, not a rule to roll out.

## PLAN FIRST, OR NOT

| Situation | Do |
|---|---|
| Could describe the diff in one sentence | Skip the plan, just ask |
| Multi-file change | Plan first |
| Unfamiliar code | Explore, then plan |
| Approach genuinely uncertain | Plan, and have it question you |

Official wording: "If you could describe the diff in one sentence, skip the plan" [source: code.claude.com/docs/en/best-practices].

For a large feature, ask to be questioned first, then start a FRESH session to execute the resulting spec. Clean context beats accumulated context.

## GIVE IT A CHECK IT CAN RUN

Climb as high as the task allows.

| Rung | Mechanism |
|---|---|
| 0 | Model asserts success. Where most work actually sits |
| 1 | Model re-reads its own output |
| 2 | Deterministic check: test, build, linter, script |
| 3 | Test suite asserting behaviour |
| 4 | Oracle comparison against a known-good reference |
| 5 | Independent auditor in a FRESH context trying to refute the result |

DEMAND EVIDENCE, NOT ASSERTION. Ask for the command and its output, not the word "fixed".

Escalation options, by how hard they gate: in-prompt check, a `/goal` condition re-evaluated every turn, a Stop hook that blocks the turn until the check passes, or a verification subagent.

## CONTEXT IS THE BINDING CONSTRAINT

Performance degrades as context fills, and a bloated instruction file makes it worse, not better.

| Symptom | Fix |
|---|---|
| Instructions being ignored | Instruction file is too long, the rule is lost in noise |
| Corrected the same thing twice | `/clear` and rewrite the prompt with what you learned |
| Unrelated task started | `/clear` first |
| Investigation ballooning | Scope it, or delegate to a subagent |

THE TWO-CORRECTION RULE: after two failed corrections, the context is polluted with failed approaches. A clean session with a better prompt beats a long session with accumulated corrections.

Session hygiene, compaction, rewind: `reference/session-hygiene.md`.

## SCALING, WITH THE COST CAVEAT

DELEGATE READING, KEEP DECIDING. Subagents run in their own context and report back, so exploration does not consume the main conversation.

| Pattern | Use for |
|---|---|
| Investigation subagent | Reading many files without polluting main context |
| Writer and reviewer, separate sessions | Fresh context reviews better, it is not biased toward code it just wrote |
| Adversarial review before done | An independent check on unattended work |
| Headless fan-out | Large mechanical migrations across many files |

COST CAVEAT. Validate cost and benefit on a small scope before scaling orchestration. Adopt the free lessons: verification, task framing, context hygiene. Do not adopt multi-day unattended frontier runs.

WARNING ON ADVERSARIAL REVIEW: a reviewer asked to find gaps will find some even when the work is sound. Instruct it to flag only what affects correctness or the stated requirements, otherwise it drives over-engineering.

Full patterns: `reference/scaling.md`.

## ANTI-PATTERNS

| Pattern | Fix |
|---|---|
| Kitchen-sink session | `/clear` between unrelated tasks |
| Correcting over and over | After two, clear and rewrite the prompt |
| Over-specified instruction file | Prune. If it already does it right, delete the rule or make it a hook |
| Trust-then-verify gap | If you cannot verify it, do not ship it |
| Infinite exploration | Scope it, or use a subagent |
| Adding an instruction after ONE bad output | One failure is noise. Wait for a repeat |
| Opus for mechanical work | Tier follows judgment required, not importance |

## RED FLAGS

| Thought | Reality |
|---|---|
| "I will add a rule so it stops doing that" | Would a check work better? Has it happened more than once? |
| "More steps means more reliable" | Over-specification degrades modern models |
| "It said it fixed it" | Ask for the command output |
| "It cannot do this, I tried before" | When, and on which model? Re-test |
| "Use Opus, this task matters" | Importance is not judgment complexity |
| "Let it run unattended for days" | Not without rung 2 verification |

## SOURCES

- Official: `https://code.claude.com/docs/en/best-practices`
- Boris Cherny, Y Combinator, 2026-07-27. Doctrine, quotes, and provenance: `opus5` skill, `reference/00-source.md`
- Local rulings: global `CLAUDE.md` model selection, `RULES.md` sec.10 model tiering
