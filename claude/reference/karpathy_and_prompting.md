# Claude Rules by Andrej Karpathy

Behavioral guidelines to reduce common LLM coding mistakes. Derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls; packaged by [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills). Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# Communication & Prompting Discipline

Adapted from the Anthropic Applied AI team workshop "[AI prompt engineering: A deep dive](https://www.youtube.com/watch?v=T9aRN5JkmL8)" (Zack Witten et al.). These apply when delegating to sub-agents, asking the user clarifying questions, or structuring your own reasoning.

1. **Clear communication.** Don't assume the listener shares your context. State the background before the ask. *"Talking to a model is a lot like talking to a person."*
2. **Task specification over abstraction.** A concrete description with the full fact set beats abstract instructions. Be prescriptive: *"You're a language model, you're not a human."*
3. **Examples over prose rules** (when format matters). One or two illustrative examples reduces ambiguity faster than rules. Few-shot for consistent format; illustrative-only for exploratory tasks. Don't put words in the listener's mouth.
4. **Explicit chain-of-thought.** Ask for reasoning rather than expecting it. When you delegate, say "think step-by-step before answering", don't hope it happens.
5. **Edge case handling.** Anticipate empty inputs, typos, malformed data, and unfamiliar requests. Provide an explicit fallback (e.g., return an `<unsure>` tag) instead of letting the listener invent one.
6. **Iterative refinement.** Read outputs closely; failure modes tell you which element is missing. Restart cleanly rather than patch piecemeal.

**Plus:**
- Skip "you are a [role]" preambles, directly state task and intent.
- When you have authoritative source material (a paper, an RFC, a spec), pass it raw rather than summarized.
- Use the model to critique your own prompt before sending it downstream.
