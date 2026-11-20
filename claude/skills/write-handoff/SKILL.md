---
name: write-handoff
description: Write a HANDOFF_*.md file for a fresh session to pick up long-running or complex work. Use whenever the operator asks to write a handoff, or work needs to survive a session break or compaction with zero context loss. Also binding when delivering a plan file: an opus agent scans the file before it reaches the operator.
---

# Write a Handoff

A handoff is read cold by a session with no memory of this conversation. It orients that session in one sentence, then gives it everything needed to act without asking basic questions.

A handoff never contains client or matter data. Reference documents by path or title only.

## Invocation lockdown (BINDING)

Once invoked, write the handoff, nothing else. Stop every other in-flight action; let a near-finished one end, then stop. Open work becomes a handoff line, never a task this session does. Close the session once delivered.

## Non-negotiable structure

1. **Title line:** `# HANDOFF YYYY-MM-DD: <short topic>`. Match the convention of existing `HANDOFF_*.md` files in the project, if any.
2. **First sentence, bolded, assigns a role, chosen with evidence, not by default.** Before any narrative: `You are a **<role matched to the task>**, because this handoff needs <the specific competency>.`
   - Derive the role from what the DELIVERABLE section (item 8) asks the reading session to DO. Never default to a generic noun (engineer, assistant, agent).
   - If the deliverable spans distinct competencies, name several roles, sequential (`in order, a **<role1>**, then a **<role2>**`) or joint. Do not pad the list beyond what the deliverable requires.
   - For a high-complexity handoff it is legitimate to dispatch one subagent to propose candidate roles before finalizing the opening sentence. A simple single-competency handoff does not need it.
3. **Scope boundary in the same paragraph as the role.** Restate what is ACTUALLY being asked, not a paraphrase, then say what may change and what must stay untouched. If the work is research-only, say so.
4. **"WHY THIS HANDOFF EXISTS" section.** Quote the operator's actual words verbatim (bold + quotes) rather than paraphrasing intent. Include the concrete request that triggered the handoff, with dates.
5. **"Ground truth already established" section.** Only facts the reading session cannot get by re-reading the repo: measured numbers, exact commands that worked, failed approaches ruled out, decisions already made. Write out the exact command for any measurement method so it can be reused mechanically.
6. **Explicit constraints section, plus a separate "out of scope" list.** Pull in the standing rules that bind THIS task (evidence-based claims, confidentiality, no destructive actions without approval, deletion approval flow). Then list exactly what must NOT be touched, by named file or directory.
7. **"Common pitfalls to avoid" section.** A short list of the specific mistakes this task invites. Concrete and task-specific.
8. **Deliverable section, ending in a verification step.** State the output format, whether it needs approval before being applied, and close with one concrete, checkable action that proves the reading session understood (rerun a measurement, run a test, produce a before/after diff).
9. **Language: English throughout.** The one carve-out is direct operator quotes: quote exactly as typed, do not translate or correct them.
10. **Escalation clause: when the reading session gets stuck, it spawns ONE `opus` teacher, never stalls waiting for the operator.** State it in every handoff for autonomous or long-running work: ONE agent, not a swarm; a FRESH agent carrying only the question and the evidence; show it REAL command output, not a summary of intent; it audits and rules, it never executes fixes itself. A blank `model` on an Agent call is blocked; pass it explicitly.
11. **Set the floor and the fence, then get out of the way.** A handoff bounds COVERAGE and SAFETY, never METHOD:
    - No ceiling on agent count, rounds, or decomposition; how the work is carved up is the reading session's call.
    - Models are free: the default mapping is a starting point; override any tier with a stated reason.
    - Disagreement is invited: the reading session may reject the handoff's framing with evidence and take the better path.
    - Unanswered questions are LEADS, ranked below anything bigger the reading session finds.
    - **Autonomy clause, verbatim in every handoff and plan file:**
      > **Autonomy:** you choose the scope, method, agent count and model tiers. Do every reversible action (research, measurement, docs, tests, plain defect fixes) without asking. Give every deliverable its own check (a test, script or replay that fails loudly), run it, fix your own work until it passes, and only then report. Only irreversible actions (deletion, sending, publishing, commit, push) and overturning a recorded operator decision wait for the operator: prepare those fully and list each as one yes/no line.

      Enforced: `hooks/plan-detail-gate.sh` blocks a plan without it.
    - The evidence bar never loosens (items 5 and 8). Free the method, keep the evidence bar.
12. **THE FILE ANSWERS EVERY QUESTION IT RAISES.** A handoff is complete only when the reading session can execute it end to end WITHOUT ASKING ANYONE ANYTHING: every path, command, measured number, decision already taken and named fallback is IN THE FILE. Walk the deliverable and write down the answer to every question a cold reader would hit; if a question has no answer yet, say so and name what to do instead of guessing. A file whose reader would have to ask is incomplete, and the final review pass fails it.
13. **Delegation clause: every measurement and every judgment-free unit of work goes to a `sonnet` subagent.** Anything with a self-contained input and a checkable output (counting, timing, log and file sweeps, test and script runs, before/after collection, diff and format checks) is dispatched as `model: "sonnet"`, in parallel when independent. Tier follows the cost of a wrong number, not the shape of the task. MAIN receives the returned number or verdict, never the raw output. Each dispatch opens with a role assignment and states `<agent> -> sonnet, because <property of the task>`.
14. **Completion clause: the reading session works the file to the end before it stops.** Every HANDOFF and every plan file carries this instruction:
    > Work this file to the end. Do not stop at a partial result, a status report, or an open question. Finish every item in the deliverable, verify each with real command output, then report. Stuck, or a question surfaces: spawn ONE fresh `opus` teacher and ask it (item 10).

## Writing discipline

- Dense and imperative: uppercase directive where it matters, short sentences, no preamble, most critical fact first.
- Every claim is evidence-based (a real measured number, a real file path, a real quote).
- Prune ruthlessly: for every line ask "would removing this cause the reading session to make a mistake?" If not, cut it.
- No em dash anywhere in the file. Use commas, semicolons, colons, or parentheses.
- Treat the handoff as if compaction could hit the current session at any moment: anything true and load-bearing goes in the file, written at the first natural checkpoint, not after the fact.
- Constrain the floor, never the method: say what must be covered and what must not break; the reading session picks how. Keep the role assignment, evidence standard, verification commands and incident-derived guards; cut prescribed sequences and anything the reader could derive.

## Final review pass before delivery (BINDING)

NO HANDOFF AND NO PLAN FILE REACHES THE OPERATOR UNTIL A DISPATCHED `opus` AGENT HAS SCANNED IT. Covers every `HANDOFF_*.md` this skill writes and every plan file meant for a fresh session to execute.

- **ONE `opus` agent, dispatched after the file is written, before you name it in chat.** A handoff defect is invisible at write time and unrecoverable at read time.
- **First sentence assigns the role**: `You are a <role>.` Derive it from what THIS file asks its reader to do.
- **Then 2-3 sentences of task, written for this exact scenario.** Name the file path, the work it hands over, who reads it and in what state (cold), and the failure it would invite if wrong. "Review this handoff" is a failed dispatch.
- **It returns** a defect list with line references plus a one-word verdict, DELIVER or FIX FIRST. It checks structure items 1-14 and whether a cold reader can execute the deliverable without asking a single question.
- **The unanswered question is the top defect class** (item 12): FIX FIRST on its own.
- **It rules, it never rewrites.** Read-only; MAIN applies every fix, then re-scans. Deliver only on DELIVER, and state in the chat reply that the pass ran.

## After writing

Report back the exact filename (the literal `HANDOFF_YYYY-MM-DD_slug.md`). Do not summarize its contents unless asked; the file is the deliverable. The chat reply follows the operator's language; the file stays English.

## Where this structure comes from

- Anthropic's Claude Code best practices (`code.claude.com/docs/en/best-practices`): a good spec is "self-contained: they name the files and interfaces involved, state what is out of scope, and end with an end-to-end verification step that proves the feature works"; prune by asking "would removing this cause Claude to make mistakes?"
- Community practice: do the handoff before compaction, not after; persistent markdown files the agent reads before acting so it never guesses at facts that are already known.
