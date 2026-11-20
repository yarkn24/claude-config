> On this machine `~/.claude/WORK_MACHINE.md` wins: every deletion and every protected-path change is approved by the operator at the prompt (`rm`, `git rm`, `sudo` are `ask` rules).

# Claude Code Config File-Writing & Efficiency Rules

Verified against official docs and live testing during the 2026-07-31 system-optimization pass
on a personal project. Every rule below has a citation (a doc quote, a command output, or
a live-session reproduction) so it can be re-verified, not just trusted. Any new `.claude/`
config file, hook, or skill written in this environment should follow these rules and reference
this document (see "How to reference this file" at the bottom).

## 1. `claude plugin details <id>@<marketplace>` gives REAL token cost, not an estimate

Use it before disabling/keeping any plugin, instead of guessing from word count.

Evidence: `claude plugin details skill-creator@claude-plugins-official` printed
`Always-on: ~75 tok added to every session` and `Component inventory: Skills (1) skill-creator`,
an exact measured number, not `words * 1.3`. [source: live command output, 2026-07-31]

## 2. `skillOverrides` cannot hide a plugin-provided skill, at ANY key format

Only standalone (`.claude/skills/`, `.claude/commands/`) entries respond to `skillOverrides`.

Evidence, verbatim: **"Plugin skills are not affected by `skillOverrides`. Manage those through
`/plugin` instead."** [source: code.claude.com/docs/en/skills, fetched 2026-07-31]

To remove a plugin-shipped duplicate: (a) `claude plugin details <id>` to confirm it ships
NOTHING unique beyond the duplicate, (b) only then `claude plugin disable <id>@<marketplace>
--scope <user|project|local>`. If the plugin bundles other non-duplicate content, there is no
official per-skill toggle: disabling the whole plugin is not a safe substitute for deduping one
skill inside it, and the duplication has to stay flagged, not "fixed".

## 3. A subdirectory INSIDE `.claude/agents/` or `.claude/commands/` does not hide a file, it renames its namespace

Claude Code scans `.claude/` subdirectories recursively and treats the subdirectory name as a
namespace prefix, exactly like plugin namespacing.

Evidence: moving `daily_report.md`/`research.md` into `.claude/commands/_archive/` produced a
live system-reminder listing them as `_archive:daily_report` / `_archive:research` immediately
afterward, still available, just renamed. [source: live session reproduction, 2026-07-31]

To truly stop a deprecated def from loading while keeping the no-delete rule: move it fully
OUTSIDE any `.claude/` tree (e.g. `docs/pipeline/_archived_definitions/`).

## 4. `ExitPlanMode` carries no plan content in its tool call; the plan lives in a file

Evidence, verbatim, from the tool's own description: **"This tool does NOT take the plan
content as a parameter, it will read the plan from the file you wrote."** [source: ExitPlanMode
tool schema, fetched via ToolSearch, 2026-07-31] Confirmed further: the documented `PreToolUse`
stdin schema (code.claude.com/docs/en/hooks) has no `plan_file`/`planFilePath` field. A hook
gating `ExitPlanMode` must resolve the plan file itself (e.g. newest `~/.claude/plans/*.md` by
mtime); there is no shortcut field to read it from stdin.

## 5. `PostToolUse` hooks DO inject context, via `hookSpecificOutput.additionalContext`, not only via plain stdout

The docs describe plain stdout entering context only for `SessionStart`/`Setup`/
`UserPromptSubmit`/`UserPromptExpansion`, which reads like `PostToolUse` output never reaches
context. In practice it does, through the structured JSON channel.

Evidence: `internet-evidence-guard.sh` (a `PostToolUse:WebFetch|WebSearch|...` hook) prints
`{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "..."}}`, and its
text visibly appeared as a `<system-reminder>` after each WebFetch call this session (observed
twice in one turn, then a third time after a deliberate debug-capture fetch). [source: live
session reproduction, 2026-07-31] Consequence: a `PostToolUse` hook with no per-turn dedup
re-injects its full text once per matched call, a real, repeating context cost, not a one-time
or free one.

## 6. Verify the real stdin schema before writing dedup/keying logic; do not assume a field name

`prompt_id`/`session_id` are real fields on `PostToolUse` hook stdin, but this was confirmed by
temporarily logging raw stdin to a file and triggering one real tool call, not by trusting a doc
example written for a different event. [source: `/tmp/evidence_guard_debug_payload.jsonl`
capture, one real `WebFetch` call, 2026-07-31] Building a marker-file dedup key on an unverified
field name risks either silently never firing (wrong key, always "new") or silently always
suppressing (wrong key, always "same"); verify the literal payload first.

## 7. AFK mode forbids ALL deletion, including your own throwaway test/debug files

The delete-guard hook blocks any `rm` inside a compound Bash command regardless of whether the
target is project data or a disposable test fixture created in the same turn. [source: live
`DELETE GUARD` block triggered twice this session, once on a test plan file, once on a `/tmp`
test marker] Consequence for file-writing efficiency: do not create throwaway fixtures in
directories you cannot leave clutter in (e.g. the live `~/.claude/plans/` dir); prefer the
session scratchpad or point test tooling at existing, real files instead of new disposable ones.

## 8. Protected-file heredoc workaround

Live-test evidence merged into `~/.claude/reference/protected_directories_workaround.md`.

## How to reference this file

Per the operator's instruction (2026-07-31, real-time in chat): any new Claude Code config file
written in this environment (hook, skill, settings edit, agent/command def) should carry a short
footer or header comment pointing here, e.g.:

```
# Config-writing rules verified against official docs: ~/.claude/reference/claude_code_config_lessons.md
```

Purpose: so a fresh session editing these files inherits the verified lessons instead of
re-deriving (or re-breaking) them from scratch.
