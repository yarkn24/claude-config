# Self-Caused Bug Learning Log (2026-08-10, BINDING, all models)

Referenced from `~/.claude/CLAUDE.md` section "Self-Caused Bug Learning Log". Full original detail below.

WHEN YOU FIX A BUG WHOSE ROOT CAUSE WAS THIS SYSTEM'S OWN PRIOR CODE OR DESIGN (a prior Claude session's assumption, regex, matching logic, dedup logic, state handling, not a user error and not a third-party/external issue), APPEND ONE ENTRY TO `~/.claude/LEARNED_PATTERNS.md` before moving on. This applies to every model tier (Sonnet, Opus, etc.), not just the one that happened to fix it.

- **Format, exactly:** a category header (reuse an existing one if it fits, grep first), then a generic pattern in **2 sentences max** (no file names, no project names, describes the class of mistake and its fix), then one line starting `Example:` with the concrete instance (file/project names allowed here).
- **Generic means transferable.** The 2-sentence pattern must read as true for any codebase, not just this one. If you cannot state it without naming a file, it is not generic enough yet, keep abstracting.
- **Lightweight, by design:** a single append (`cat >> ~/.claude/LEARNED_PATTERNS.md << 'EOF'` or Edit), no full-file read first, no subagent dispatch, no extra verification pass. This must never become its own task; it is one write, done inline with the fix.
- **Not the auto-memory system.** Project `feedback_*` memories capture the operator's preferences for how to work; this file captures the agent's own recurring code-bug patterns, generic and cross-project. Keep them separate.
- **Do not auto-load this file every session.** It is consult-on-demand: before writing matching, dedup, regex, or state/resume logic, grep its category headers for a relevant prior lesson.
