---
name: council
description: Convene a four-voice council (Architect, Skeptic, Pragmatist, Critic) for ambiguous strategy decisions with no obvious winner, where structured disagreement beats a single opinion. Use for analysis and delivery decisions (scope trade-offs, build vs buy, which approach to recommend, risk acceptance) or any go/no-go with real tradeoffs. Not for execution tasks, factual questions, or output verification.
---

# Council

Convene four advisors for a decision under ambiguity:
- the in-context voice (you, the synthesizer)
- a Skeptic subagent
- a Pragmatist subagent
- a Critic subagent

This is for decision-making under ambiguity, not verification, execution planning, or straightforward tasks.

## When to Use

- A decision has multiple credible paths and no obvious winner.
- You need explicit tradeoff surfacing.
- The user asks for second opinions, dissent, or multiple perspectives.
- Conversational anchoring is a real risk (you have already leaned one way).
- A go/no-go call would benefit from adversarial challenge.

Examples:
- narrow a requirements scope now vs hold for fuller stakeholder input
- recommend a process change vs a tooling change
- which of two analysis approaches to spend the review time on
- accept a known data-quality gap vs delay delivery
- broaden a report's scope vs tighten it for precision

## When NOT to Use

| Instead of council | Do this |
|---|---|
| Checking whether an output is correct or fabricated | verify-before-approve discipline |
| Breaking work into execution steps | just plan and do it |
| A straight factual question | answer directly |
| An obvious execution task | just do the task |

## Roles

| Voice | Lens |
|---|---|
| Architect | long-term implications, coherence with the overall strategy |
| Skeptic | premise challenge, simplification, assumption breaking |
| Pragmatist | speed, real-world execution, cost reality |
| Critic | downside risk, edge cases, failure modes |

The three external voices are launched as fresh subagents with only the question and relevant context, not the full conversation. That isolation is the anti-anchoring mechanism.

## Workflow

### 1. Extract the real question
Reduce the decision to one explicit prompt: what are we deciding, what constraints matter, what counts as success. If vague, ask one clarifying question first.

### 2. Gather only the necessary context
Include only the facts that change the answer (relevant numbers, the source document, the terms, the constraint). Keep it compact.

### 3. Form the Architect position first
Before reading the other voices, write your initial position, the three strongest reasons for it, and the main risk in your preferred path. Do this first so the synthesis does not just mirror the others.

### 4. Launch three independent voices in parallel
Each subagent gets the decision question, compact context, a strict role, and no unnecessary history.

Prompt shape:

```text
You are the [ROLE] on a four-voice decision council.

Question:
[decision question]

Context:
[only the relevant facts or constraints]

Respond with:
1. Position, 1-2 sentences
2. Reasoning, 3 concise bullets
3. Risk, the biggest risk in your recommendation
4. Surprise, one thing the other voices may miss

Be direct. No hedging. Under 300 words.
```

Role emphasis:
- Skeptic: challenge the framing, question assumptions, propose the simplest credible alternative.
- Pragmatist: optimize for speed, cost, and real-world execution.
- Critic: surface downside risk, edge cases, and reasons the plan could fail.

### 5. Synthesize with bias guardrails
- Do not dismiss an external view without explaining why.
- If an external voice changed your recommendation, say so explicitly.
- Always include the strongest dissent, even if you reject it.
- If two voices align against your initial position, treat that as a real signal.
- Keep the raw positions visible before the verdict.

### 6. Present a compact verdict

```markdown
## Council: [short decision title]

**Architect:** [1-2 sentence position]  [1 line on why]
**Skeptic:** [1-2 sentence position]  [1 line on why]
**Pragmatist:** [1-2 sentence position]  [1 line on why]
**Critic:** [1-2 sentence position]  [1 line on why]

### Verdict
- Consensus: [where they align]
- Strongest dissent: [most important disagreement]
- Premise check: [did the Skeptic challenge the question itself?]
- Recommendation: [the synthesized path]
```

Keep it scannable on a phone screen.

## Persistence Rule

Do not write ad-hoc notes to shadow paths. Persist only when the council materially changes the recommendation, and then to the right durable home:
- a convention worth keeping goes to `memory/` (feedback entry) plus a MEMORY.md index line, deduped against existing entries. Never client, matter or personal facts.
- a decision that changes how work is done goes to the relevant project file (for example a CLAUDE.md rule block).
Only persist a decision when it changes something real.

## Multi-Round Follow-up

Default is one round. For another round, keep the new question focused, include the previous verdict only if necessary, and keep the Skeptic clean to preserve anti-anchoring value.

## Anti-Patterns

- Using council for output verification or execution work.
- Feeding the subagents the entire conversation transcript.
- Hiding disagreement in the final verdict.
- Persisting every decision as a note regardless of importance.

## Provenance

Adapted from Everything-Claude-Code (github.com/affaan-m/everything-claude-code, MIT, (c) 2026 Affaan Mustafa), skill `council`. Modified for this setup: examples reframed to analysis decisions, persistence remapped to memory/ and project files, ECC sibling-skill references removed, em-dash-free per global style rule.
