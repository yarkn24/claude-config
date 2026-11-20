# Subagent Context Discipline

Consult before designing any subagent dispatch pattern or multi-agent pipeline, especially a long-running one (many dispatches, iterative review-fix loops, or an owner/orchestrator dispatching further subagents).

## Diagnosis this rule is based on

A real, live 2026-09-09 session bloated MAIN's context badly despite the project's own "MAIN stays thin" rule already existing. Cause: that rule covered hook-emitted diagnostics but was never enforced as a **contract on dispatch prompts themselves**. Dispatches asked for prose ("report what you found"), subagents returned paragraphs, and each round of an iterative review-fix-review loop re-injected the previous round's full findings before the next round started. The gap is structural: nothing in the dispatch prompt enforced a return-value shape.

## Checklist

1. **Every dispatch prompt ends with an explicit return-shape line**, not a request for "a report." Example: "Return exactly one line: STATUS, one-sentence reason, absolute file path to full findings. Do not paste findings into your reply."
2. **Full detail always goes to a file the subagent writes itself**, never into its chat return. MAIN reads the file only if the one-line verdict says it must act on specifics, never to "see what happened."
3. **MAIN relays to the user a summary of the verdict, never the subagent's raw text.** One sentence: what changed, pass/fail, file path.
4. **Iterative review-fix-review loops carry only a pointer forward, never the payload.** Each round's dispatch prompt receives the previous round's file path, not its pasted content.
5. **Detail stays in MAIN's context only when the very next action needs it verbatim AND it is small** (a file path, a short diff hunk, an error string under ~10 lines). Anything longer is a file-push, no exception.
6. **Parallel fan-out raises the stakes on rule 1, it doesn't relax it.** N subagents dispatched together all land in the same turn; if each ignores the shape contract, context cost multiplies by N at once.
7. **A dispatch that returns prose instead of the contracted one-liner is a spec violation**, not "close enough." Re-ask for the file path rather than reading the prose that already landed.
8. **Before writing a status update to the user, self-check: am I pasting a subagent's words, or my own one-line synthesis of a verdict I read from a file?** If the former, rewrite.

## Sources (verbatim quotes, fetched live 2026-09-09)

- **Claude Code docs, subagents**: https://code.claude.com/docs/en/sub-agents
  - "One of the most effective uses for subagents is isolating operations that produce large amounts of output... the verbose output stays in the subagent's context while only the relevant summary returns to your main conversation."
  - "Warning: When subagents complete, their results return to your main conversation. Running many subagents that each return detailed results can consume significant context."
  - "Use subagents when: The task produces verbose output you don't need in your main context... The work is self-contained and can return a summary."
  - "For multi-step workflows, ask Claude to use subagents in sequence. Each subagent completes its task and returns results to Claude, which then passes relevant context to the next subagent."

- **Anthropic Engineering, "Effective context engineering for AI agents"**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
  - "Each subagent might explore extensively, using tens of thousands of tokens or more, but returns only a condensed, distilled summary of its work (often 1,000-2,000 tokens)."
  - "This approach achieves a clear separation of concerns, the detailed search context remains isolated within sub-agents, while the lead agent focuses on synthesizing and analyzing the results."
  - "Context, therefore, must be treated as a finite resource with diminishing marginal returns."

- **Anthropic Engineering, "How we built our multi-agent research system"**: https://www.anthropic.com/engineering/multi-agent-research-system
  - "Subagents facilitate compression by operating in parallel with their own context windows... before condensing the most important tokens for the lead research agent."
  - "The lead agent spins up 3-5 subagents in parallel rather than serially; the subagents use 3+ tools in parallel."
  - "Subagents call tools to store their work in external systems, then pass lightweight references back to the coordinator."

- **Anthropic Engineering, "Building effective agents"**: https://www.anthropic.com/engineering/building-effective-agents
  - "For complex tasks with multiple considerations, LLMs generally perform better when each consideration is handled by a separate LLM call, allowing focused attention on each specific aspect." (supports parallel fan-out for coverage; each call's return still needs its own shape contract)
  - This post does not directly address orchestrator-context-bloat prevention beyond the parallelization point above; nothing further from it is asserted as a context-management claim.
