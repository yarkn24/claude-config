---
name: context-budget
description: Audits Claude Code context-window consumption across agents, skills, MCP servers, hooks, and CLAUDE.md. Identifies bloat, redundant components, and produces a prioritized token-savings report. Use when the user says "context budget", "token audit", "my .claude is heavy", "how much context am I using", "session feels slow", or before adding more skills/MCP servers.
---

# Context Budget

Statically inventory the token overhead of every loaded component in a Claude Code session and surface actionable optimizations to reclaim context space. Preventive counterpart to session-report (which measures spend after the fact). Advisory only: this skill reports, it never deletes. To act on findings, hand them to config-gc.

## When to Use

- Output quality is degrading or the session feels sluggish.
- You recently added many skills, agents, hooks, or MCP servers.
- You want to know how much context headroom you actually have.
- Planning to add components and need to know if there is room first.

## How It Works

### Phase 1: Inventory

Scan component directories and estimate token consumption.

**Agents** (`~/.claude/agents/*.md`, project `agents/`)
- Estimate tokens per file (words times 1.3).
- Extract `description` frontmatter length.
- Flag: files over 200 lines (heavy), description over 30 words (bloated frontmatter that loads into every Task invocation).

**Skills** (`~/.claude/skills/*/SKILL.md`, plus symlinked `.agents/skills/`)
- Estimate tokens per SKILL.md; only the frontmatter loads at session start, the body loads on invoke.
- Flag: SKILL.md over 400 lines.
- Skip identical copies reached through symlinks to avoid double-counting.

**Hooks** (`~/.claude/hooks/` + the `hooks` block in `settings.json`)
- Count scripts wired into each of the 5 hook events (UserPromptSubmit, PostToolUse, Stop, PreToolUse, SessionStart).
- Flag: SessionStart / UserPromptSubmit hooks that inject large text into every session (these cost context on every turn, not just on invoke).
- Note `.bak`, `.bak2`, `.post-bak`, `.log` files sitting in the hooks dir: they do not cost context but signal cleanup work for config-gc.

**MCP Servers** (`.mcp.json`, `~/.claude.json`, active MCP config)
- Count configured servers and total tool count; estimate schema overhead at ~500 tokens per tool.
- Flag servers with over 20 tools, or servers that merely wrap a CLI (`gh`, `git`, `npm`).
- Do NOT flag domain-essential servers that are not CLI-replaceable (for example the firm's document or ticketing connector): those earn their cost.

**CLAUDE.md chain** (global `~/.claude/CLAUDE.md` + project `CLAUDE.md`)
- Estimate tokens per file in the chain (all of it loads every session).
- Flag: combined total over 300 lines, verbose prose that should be a hook or a memory entry.

### Phase 2: Classify

| Bucket | Criteria | Action |
|---|---|---|
| Always needed | Referenced in CLAUDE.md, backs an active command, matches current work | Keep |
| Sometimes needed | Domain-specific, not referenced in CLAUDE.md | Consider on-demand only |
| Rarely needed | No reference, overlapping content, no obvious match | Candidate for config-gc |

### Phase 3: Detect Issues

- Bloated agent descriptions (over 30 words) that load into every Task invocation.
- Heavy agents (over 200 lines) that inflate Task context on every spawn.
- Redundant components: skills duplicating agent logic, hooks duplicating a CLAUDE.md rule.
- MCP over-subscription: many servers, or servers wrapping free CLI tools.
- CLAUDE.md bloat: outdated sections, prose that should be a rule or hook.
- SessionStart/UserPromptSubmit injectors that push large fixed text every session.

### Phase 4: Report

```
Context Budget Report
=======================================

Total estimated overhead: ~XX,XXX tokens
Context model: Opus 4.8 [1m] (1,000,000 window)  |  Sonnet fallback (200,000)
Effective available context: ~XXX,XXX tokens (XX%)

Component Breakdown:
  Agents      N   ~X,XXX
  Skills      N   ~X,XXX
  Hooks       N   ~X,XXX (of which SessionStart injectors: ~X,XXX)
  MCP tools   N   ~XX,XXX
  CLAUDE.md   N   ~X,XXX

Issues Found (N), ranked by token savings:
Top 3 Optimizations:
1. [action] -> save ~X,XXX tokens
2. [action] -> save ~X,XXX tokens
3. [action] -> save ~X,XXX tokens

Potential savings: ~XX,XXX tokens (XX% of current overhead)
```

Verbose mode adds per-file token counts, the heaviest files line by line, specific redundant lines between overlapping components, and the MCP tool list with per-tool schema estimates.

## Best Practices

- Token estimation: `words times 1.3` for prose, `chars / 4` for code-heavy files.
- MCP is usually the biggest lever: each tool schema costs ~500 tokens; a 30-tool server can outweigh all skills combined.
- Agent descriptions load always, even for agents never invoked.
- The biggest hidden cost in this setup is SessionStart/UserPromptSubmit injectors plus the CLAUDE.md chain, because they load on every session/turn, not on invoke.
- Run after adding any component to catch creep early. This skill only reports; run config-gc to reclaim.

## Bundled Baseline Script

`scripts/config_baseline.sh` runs a real (not estimated) measurement pass: CLAUDE.md line
counts, statusLine/`.claude/rules/` presence, hook counts, DEPRECATED-marked defs still
loaded, `.bak` clutter, real per-plugin always-on token cost via `claude plugin details`,
and a real cross-source duplicate-name detector (user skills/commands + project +
every enabled plugin's `installPath`). Run it from a project root to include that
project's own CLAUDE.md/.claude/ in the count. Known false positive: it reports 2
copies for a name that is genuinely both a skill AND a command inside the SAME plugin
(e.g. `vercel`'s `bootstrap`); that is not redundancy, only a same-plugin dual listing.

## Session-Verified Corrections (2026-07-31)

Learned while auditing a project against `code.claude.com/docs`; fold into
Phase 1/3 above instead of trusting the estimate methods where a real source exists.

1. **Prefer `claude plugin details <id>` over the words*1.3 estimate for any plugin
   component.** It prints the actual measured always-on/on-invoke token cost per
   component, not an estimate (verified output: `skill-creator@claude-plugins-official`
   -> `Always-on: ~75 tok`, `Skills (1) skill-creator`).
2. **`skillOverrides` cannot hide a plugin-provided skill, at any key format.** Docs,
   verbatim: "Plugin skills are not affected by `skillOverrides`. Manage those through
   `/plugin` instead." [source: code.claude.com/docs/en/skills]. To remove a
   plugin-shipped duplicate, first run `claude plugin details <id>` to confirm the
   plugin ships NOTHING unique beyond the duplicate, then
   `claude plugin disable <id> --scope <user|project|local>`. If the plugin bundles
   other, non-duplicate skills alongside the duplicate one (e.g. a multi-skill pack),
   there is no official per-skill toggle: disabling the whole plugin is not a safe
   substitute, and the duplication has to stay flagged, not "fixed".
3. **Moving an agent/command file to a subdirectory INSIDE `.claude/agents/` or
   `.claude/commands/` does not remove it from the loaded listing.** Claude Code scans
   `.claude/` subdirectories recursively and treats the subdirectory name as a
   namespace prefix, the same way it namespaces plugin skills. Verified live: moving
   `daily_auto.md`/`jobresearch.md` into `.claude/commands/_archive/` produced a
   system-reminder listing them as `_archive:daily_auto` / `_archive:jobresearch`,
   still available, just renamed. To truly stop a deprecated def from loading while
   keeping it on disk (no-delete rule), move it fully outside any `.claude/` tree
   (e.g. `docs/pipeline/_archived_definitions/`).

## Provenance

Adapted from Everything-Claude-Code (github.com/affaan-m/everything-claude-code, MIT, (c) 2026 Affaan Mustafa), skill `context-budget`. Modified for a job-application pipeline: retargeted to this setup's dirs (hooks instead of rules), 1M context window, non-CLI-replaceable MCP servers, and em-dash-free per global style rule.

*Config-writing rules verified against official docs: `~/.claude/reference/claude_code_config_lessons.md`*
