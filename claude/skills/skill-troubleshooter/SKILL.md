---
name: skill-troubleshooter
description: Diagnose an installed Claude Code skill that is not working: it never triggers, it does not load, the wrong skill wins, a plugin skill is missing from the list, or it fails partway through. Repairing an existing skill only; creating one is skill-creator or write-a-skill, and trimming a document's prose is doc-optimizer. Use for "skill not triggering", "skill does not work", "my skill is being ignored", "skill will not load", "SKILL.md not found", "wrong skill got used", "two skills conflict", "skill precedence", "plugin skill missing", "skill is disabled", "skillOverrides", "shell command failed for pattern", "skill-doctor".
---

# Skill Troubleshooter

Route by symptom. Every mechanic below is from code.claude.com/docs/en/skills, verified 2026-09-15.

## 0. Two checks before anything else

1. `/skills`: is it listed? Not listed goes to section 2. Listed but never picked goes to section 1.
2. Edited it this session? `SKILL.md` text changes load live. A newly created `.claude/skills/` directory needs a restart. Plugin changes need `/reload-plugins`.

## 1. Never triggers

Check the config gates first. They mute a skill silently and no amount of rewriting fixes them.

- `skillOverrides` in `.claude/settings.json`: `"off"` hides it from Claude and the menu, `"name-only"` gives Claude the name alone, `"user-invocable-only"` hides it from Claude.
- `disable-model-invocation: true`: only you can invoke it.
- `user-invocable: false`: only Claude can.
- A `/permissions` deny rule matching `Skill(<name> *)`.
- A `paths` glob in frontmatter: the skill activates only for matching files.

Gates clear, so it is the description. Claude matches the user's phrasing against `description` plus `when_to_use`, never against the body or the directory name. The combined text truncates at 1,536 characters in the listing, so the key use case goes first.

- Diagnostic: put the exact user phrasing next to the description line. Look for missing synonyms and wording written for the author's mental model instead of the user's.
- Fix: add the phrasings a real user types, then test with 2-3 differently worded prompts, not the original test case.

Triggered earlier in the session and then stopped: the content is usually still in context and the model chose another path. Re-invoke it, or strengthen the description and instructions.

## 2. Does not load

- Structure: `<skills root>/<skill-name>/SKILL.md`. A `SKILL.md` sitting directly at the skills root never loads.
- Filename exactly `SKILL.md`, capitals included.
- The opening `---` must be the file's first line.
- `name` is optional and defaults to the directory name, so a missing `name` is not the cause.
- Newly created `.claude/skills/` directory: restart Claude Code.
- Still nothing: `claude --debug` (it takes an optional category filter) or `--debug-file <path>` to capture output. Skill-load logging is not documented, so treat whatever it prints as a lead.

## 3. Wrong skill wins on similar wording

Two descriptions overlap. Read both side by side. Generic phrasing ("helps with documents") both over-claims and loses.

- Fix: narrow each description to its own scope and move the shared language out of one of them. Before adding any new skill, check it against the descriptions already installed.

## 4. Same name in two locations

- Enterprise over personal (`~/.claude/skills/`), personal over project (`.claude/skills/`).
- Your skill replaces a bundled skill of the same name, but NOT that bundled skill's aliases. A project `code-review` skill takes `/code-review`; the bundled alias `/review` still runs the bundled one.
- A skill beats a `.claude/commands/<name>.md` file.
- A plugin skill always coexists, namespaced `/plugin-name:skill-name`, so a plugin is never what overrode you.
- A claude.ai-synced skill loses and stays reachable as `/anthropic-skills:<name>`.
- A project-root skill and a nested one sharing a name both load: `/name` is the root, `/apps/web:name` the nested.
- Fix: rename the lower-precedence copy. If the winner is enterprise-managed, that is an admin decision, not something to route around locally.

## 5. Plugin skill missing from the list

1. `/reload-plugins`. Plugin hooks, agents and MCP changes need it even though `SKILL.md` text reloads on its own.
2. Confirm it is installed: `claude plugin list`.
3. Restart, then reinstall.
4. Still missing: the plugin's own layout is wrong. Apply section 2's rules to it directly.

Never delete a plugin cache path to fix this. No official doc names one.

## 6. Loads and triggers, then fails partway

- An injected `` !`command` `` aborts the ENTIRE invocation with `Shell command failed for pattern`. Causes: non-zero exit (search and comparison commands are tolerated at exit 1), a permission check that did not return allow, the 2-minute timeout, or output over the size limit. Fix: append `|| true` where a non-zero exit is expected, or pre-approve the tool with `allowed-tools`.
- Bundled script not executable: `chmod +x`. This fails at run time, not load time.
- Missing dependency: confirm it on THIS machine rather than trusting the skill's own docs, then name it in the skill so the next run finds it.
- Paths: forward slashes everywhere, Windows targets included.
- Synced skill running on a local machine: `!` commands do not execute, `@` references do not attach, and `${CLAUDE_PROJECT_DIR}` / `${CLAUDE_SESSION_ID}` arrive as literal text.

## 7. Size

Keep `SKILL.md` under 500 lines and push detail into `reference.md`, `examples.md` or `scripts/`. The cost is recurring: an invoked skill's content stays in context across later turns.

Length does not affect triggering. Only `description` and `when_to_use` are in the matching listing. A long body's real risk is auto-compaction, which re-attaches each skill's most recent invocation within a 25,000-token combined budget and keeps only the first 5,000 tokens of each, dropping the oldest entirely. A skill that worked early in a long session and quietly stopped is this, not a matching problem. Measure before restructuring.

## 8. Diagnostic tools

- `/skills`: is it listed at all.
- `/skill-doctor`: per-skill context cost, invocation frequency, unused skills. Requires Claude Code v2.1.252 or later, so check `claude --version` first; it is also unavailable in sessions that skip feature-flag fetching, and over Remote Control it answers `Skill usage reports are not available on this connection.` Run it in the terminal on the machine hosting the session.
- `claude --debug`, `--debug-file <path>`: load-time errors (section 2).
