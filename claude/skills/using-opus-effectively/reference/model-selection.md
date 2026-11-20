# MODEL SELECTION

## THE LOCAL RULE, BINDING

PLANNING GOES TO OPUS. EVERYTHING ELSE GOES TO SONNET. Do not run a frontier model for days.

The rule is not a claim that Sonnet writes worse code. It is a budget decision made deliberately.

## THE DECIDING QUESTION

HOW MUCH JUDGMENT DOES THIS STEP REQUIRE, and how wide is the space of acceptable answers?

| Judgment | Space of answers | Tier |
|---|---|---|
| High | Wide, many valid approaches | Opus |
| Medium | Narrow, a plan already exists | Sonnet |
| Low | One correct answer, mechanical | Haiku |

IMPORTANCE IS NOT JUDGMENT. A high-stakes but mechanical step, for example writing a file to an exact path, does not need a bigger model. It needs a check.

## THE TABLE

| Task | Tier | Reason |
|---|---|---|
| Planning, architecture, decision trees | Opus | Wide solution space |
| Multi-step refactor planning | Opus | Ordering and dependency judgment |
| Design review, brainstorming | Opus | Generating and comparing options |
| Debugging STRATEGY, deciding what to investigate | Opus | Hypothesis selection |
| Writing prose that carries real judgment | Opus | Only where the wording itself is the deliverable |
| Writing and editing code | Sonnet | Executing a decided plan |
| Running tests, bash, file operations | Sonnet | Mechanical |
| Search, grep, exploration | Sonnet | Retrieval |
| Summarizing, parsing, format conversion | Sonnet | Transformation |
| Documentation writing | Sonnet | Structured output |
| Narrow classification inside a pipeline | Haiku | Bounded, cheap, repetitive |

## HARD CONSTRAINTS

1. Only `sonnet`, `opus`, `haiku` are permitted as subagent models.
2. NEVER pass a full model identifier string as the `model` parameter. Use the tier alias.
3. SWITCH BACK TO SONNET once planning ends and execution begins. Staying on Opus through execution is the most common way this rule leaks.
4. A MODEL ALIAS IS NOT A MODEL VERSION. Any rule hardcoding a specific version rots silently when the alias moves. Date-stamp such rules and revalidate them at each release.

## WHEN TO ESCALATE A TIER

Escalate ONLY on observed, repeated failure at the lower tier, never in anticipation.

| Signal | Action |
|---|---|
| Same task type fails repeatedly at the lower tier | Escalate that step only, not the whole pipeline |
| Output is plausible but subtly wrong | Add verification FIRST. Escalate only if that does not fix it |
| Task is long and multi-step | Split it, or add verification. Length is not a reason to escalate |
| Task feels important | Not a reason. Add a check instead |

ADDING VERIFICATION IS ALMOST ALWAYS CHEAPER THAN ESCALATING A TIER, and it fixes a wider class of failures.

## WHEN TO DE-ESCALATE

De-escalation is the neglected direction. Look for it deliberately at each model release.

| Signal | Action |
|---|---|
| A step assigned to Opus because an older model failed | Re-test on Sonnet |
| A step whose output is checked by a deterministic gate | Lower tier is safe, the gate catches errors |
| A step that only reads and reports | Lower tier |

A tier assignment made against a superseded model is a prior, not a measurement.

## OFFLOADING OUTSIDE THE FAMILY

For a quota-bound account the binding constraint is usage, not price. Non-judgment bulk work can go to a cheaper external model.

| Offload | Keep |
|---|---|
| Bulk document reading and cleaning | Any truthfulness or fabrication gate |
| Keyword extraction | Final quality review |
| Large log or text summarizing | Planning |
| First-pass classification | Anything touching an irreversible action |

NEVER OFFLOAD A BUCKET A CHECK. A cheaper model guarding an irreversible action is a false economy.

## SOURCES

- Local rulings: global `CLAUDE.md` model selection section, `RULES.md` sec.10 model tiering
- Cost ruling and rationale: `opus5` skill, `reference/00-source.md`, commercial-bias caveat
