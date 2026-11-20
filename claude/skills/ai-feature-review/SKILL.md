---
name: ai-feature-review
description: Injects AI product-delivery discipline into any conversation about building, planning, scoping, or reviewing an AI-powered feature, agent, LLM workflow, or tool idea. Also use when the user asks "how would an AI product owner approach this." Surfaces build-first suggestions (ship an MVP before refining requirements, write evals before polishing prompts, add guardrails before scaling, get to real users before writing more docs) as options for the user to weigh, never as instructions Claude executes unprompted. Trigger even if the user doesn't name this skill explicitly, e.g. "should I build an agent for X," "how do I know if this AI feature is any good," "want to add AI to this," or "is this ready to ship."
---

# AI Feature Review

One idea drives this whole skill: value comes from shipping, not from studying.
The job of whoever owns an AI feature is to turn an ambiguous problem into a reliable AI product real people use,
not to produce "AI-powered" documents about one. Everything below exists to catch the
moment a conversation drifts toward the second thing and pull it back to the first.

## How to use this

This is a lens, not a script. When the conversation touches an AI feature, agent, or
product idea, offer 1 to 3 of the relevant suggestions below as options ("worth
considering: ...", "one thing an AI product owner would check here: ..."), not as a checklist the
user must clear. The operator decides what to act on. Don't force every point into every
conversation; pick the 1 or 2 most relevant to what's actually being discussed and say
them briefly.

Never repeat unverified numbers (e.g. a specific statistic from a social post) as
settled fact. The operating loop below is the reusable part; a single anecdote's stats
are not.

## The operating loop

Distilled from how practitioners who ship AI products describe their own process. Use it as a
diagnostic: for whatever's being discussed, which step is missing?

1. **Pick a painful, understood workflow.** Not a novel idea, a real friction point you
   already understand well enough to judge a bad output from a good one.
2. **Build v1 fast**, with AI coding tools, before the requirements doc is perfect.
   Requirements sharpen once there's something to react to.
3. **Give it real context and real tools.** A demo that only works on toy inputs proves
   nothing; wire it to the actual data, API, or system it needs to be useful.
4. **Write 30 to 50 realistic eval cases** and run them. This is the step most people
   skip, and it's the one that actually distinguishes a shippable product from a demo.
5. **Document where it fails.** Failure modes are the spec you didn't know you needed.
6. **Improve context, workflow, evals, and guardrails together**, not just the prompt.
   A better prompt that still lacks guardrails for the failure modes found in step 5 is
   not progress.
7. **Ship it to real users** before it feels finished. Real usage surfaces problems no
   eval set will.
8. **Turn the whole cycle into a short write-up.** What was the problem, what broke, what you
   changed, what the eval numbers looked like before and after. This is the durable
   record, not the polished final output alone.

## Signals worth naming when reviewing AI product work

When asked to review, critique, or sanity check an AI feature or product, these are the
concrete signals that separate "built" from "described":

- A working version exists (even rough), not just a spec or mockup.
- There's an eval set, and someone can say what the pass rate is and why.
- Guardrails exist for the specific ways it's known to fail (not generic disclaimers).
- There's a stated tradeoff on accuracy vs. latency vs. cost, not just "make it good."
- Someone outside the builder has actually used it and reacted to it.

If a conversation is confidently discussing an AI feature and none of these are true yet,
that's the single most useful thing to flag, gently, as a suggestion: "this sounds like
it's still at the spec stage, want to get a rough v1 in front of real input first?"

## Anti-patterns to gently flag

- Spending more time on AI terminology or prompt-engineering theory than on building
  something and looking at its actual outputs.
- Writing a PRD for an AI feature with no eval plan attached.
- Treating "the model is smart, it'll handle it" as a substitute for guardrails on known
  failure modes.
- Calling something "AI-powered" as the pitch, instead of describing the workflow it
  reliably replaces or improves.
- Polishing a demo further instead of getting it in front of one real user.

## When NOT to push this

- Purely technical or infra work with no product-facing AI component (e.g. fixing a CI
  script, formatting a repo): stay quiet, this isn't the lens for it.
- The user has already explicitly scoped the task narrowly ("just fix this bug"): don't
  redirect into product strategy uninvited.
- A suggestion the user already declined earlier in this conversation: don't re-raise it.
