---
name: config-gc
description: Garbage collection for your Claude Code configuration. Scans ~/.claude (skills, memory, hooks, permissions, MCP servers, caches, project history) for redundant, stale, orphaned, or low-value items, then walks you through a confirm-each cleanup with an undo path. Use when the user says "clean up my config", "config GC", "too many skills", "audit my setup", "my .claude is bloated", "prune hooks", or asks for a periodic config review.
---

# Config GC: Garbage Collection for Claude Code Setups

Borrowed from runtime garbage collection: periodically scan for items that are no longer referenced, redundant, expired, or low-value, and reclaim the space. Critical difference: here, collection requires a human in the loop. Never delete autonomously.

## DELETE SAFETY (BINDING, overrides the generic workflow)

This is a law-firm work machine where records retention matters. Every delete or move goes through the permission prompt (`ask` rules plus `hooks/delete-guard.sh`). Enforce it:

1. DEFAULT ACTION IS REPORT-ONLY. A config-gc run produces a ranked candidate list. It does not move or delete anything until the user confirms per item.
2. AFK / NON-INTERACTIVE MODE: never move, disable, or delete. Only write the candidate report and hand it to the operator when they return.
3. HARD-DELETE (`rm` / `git rm` / `unlink`) requires, for each item: (a) full path, (b) reason, (c) what happens if kept, (d) backup/undo. Then the operator approves that exact deletion at the permission prompt. No exceptions.
4. Soft-delete (rename to `.disabled` or move to `~/.claude/_gc_trash/<date>/`) is reversible and preferred, but still only on a per-item `[y/n/skip]` confirmation in an interactive session.
5. PROTECTED, NEVER A CANDIDATE: `hooks/*guard*`, `hooks/hook-selftest.sh`, every hook wired in `settings.json`, and the `permissions.deny` and `permissions.ask` entries of `settings.json`. Removing any of them needs IT sign-off, not a cleanup run.

## When to Activate

- The user asks to clean up, audit, or slim down their Claude Code configuration.
- The user complains about too many skills, noisy hooks, `.bak` clutter, or slow startup.
- A periodic (roughly monthly) config review is due.
- Right after installing a skill pack, to reconcile overlaps with the existing setup.

Do NOT activate for: cleaning project source code (that is refactoring), clearing chat history, or uninstalling Claude Code.

## Design Philosophy

1. Append-only configs leak. Skills, memory files, hooks, and permission entries only ever get added; without review they rot.
2. Regular small audits beat one-time purges. Scan roughly every 30 days, propose a small batch each time.
3. Per-channel strategies. Each accumulation type has its own staleness signals; do not apply one rule everywhere.
4. Soft-delete first. Rename to `.disabled`, then move to `~/.claude/_gc_trash/`, then (only on explicit request) real deletion. Always keep an undo path.
5. Forced human-in-the-loop. Every candidate gets its own `[y/n/skip]`. No "yes to all".
6. Keep a log. Every run appends to `~/.claude/gc_log.md`: what was touched, why, and how to undo.

## Scan Channels

| # | Channel | Path | Staleness / redundancy signals |
|---|---|---|---|
| 1 | Skills | `~/.claude/skills/*/` | Overlapping names; never triggered in recent transcripts; domain mismatch; broken or empty SKILL.md |
| 2 | Memory | `~/.claude/**/memory/*.md` + `MEMORY.md` index | Two index lines for one topic; contents contradicting newer entries; passed dates; orphan files missing from the index; sub-100-word fragments that should merge (compare entries side by side before merging) |
| 3 | Hooks | `~/.claude/hooks/` + `settings.json` hooks block | Scripts on disk referenced by no hook config; superseded `.bak` / `.bak2` / `.post-bak` versions; oversized `.log` files (for example a hook's own `.log`) |
| 4 | Permissions | `permissions.allow` in `settings.json` / `settings.local.json` | Duplicate entries; specific entries shadowed by a wildcard (`Bash(git push)` under `Bash(*)`); one-off grants from past experiments |
| 5 | MCP servers | `~/.claude.json` or project `.mcp.json` | Servers that fail to connect; functional duplicates; long-unused |
| 6 | Scheduled jobs | launchd plists, crons | Fired one-shots older than 30 days; jobs whose target scripts no longer exist |
| 7 | Project history | `~/.claude/projects/*/` | Stale handoff snapshots; session records superseded by newer state |
| 8 | Runtime caches | `cache/`, `file-history/`, `logs/`, `shell-snapshots/` | Sort by size and mtime; propose large items over 30 days old |

## Workflow

1. Scan the requested channels. For each candidate collect: path, channel, the signal that flagged it, size, last-modified.
2. Rank by confidence (broken or orphaned is high; merely old is low). Present a numbered table. Cap each run at about 20 candidates; GC is periodic, not exhaustive.
3. Confirm one by one. Show the evidence, then ask `[y/n/skip]`. The user can stop at any point. (Skip this step and the whole run entirely in AFK mode; report only.)
4. On confirmation, soft-delete: prefer `.disabled` rename for skills/hooks and `_gc_trash/<date>/` move for files. Permission entries live in JSON with no comments, so back up the settings file, record each removed entry verbatim in `gc_log.md`, then remove it with `jq`. Hard-delete only via the approval flow above.
5. Log the run to `~/.claude/gc_log.md`: timestamp, items actioned, undo instructions.
6. Report: reclaimed size, healthy channels, suggested next review date.

## Example Scan Commands

Orphaned hook scripts (channel 3), scripts on disk that no hook config references:

```bash
for f in ~/.claude/hooks/*.sh; do
  name=$(basename "$f")
  grep -rq "$name" ~/.claude/settings.json ~/.claude/settings.local.json 2>/dev/null \
    || echo "ORPHAN: $f"
done
```

Superseded hook backups and oversized logs (channel 3):

```bash
ls -lh ~/.claude/hooks/*.bak* ~/.claude/hooks/*.post-bak 2>/dev/null
find ~/.claude/hooks -name '*.log' -size +1M -exec ls -lh {} +
```

Redundant permission entries (channel 4), duplicates and grants shadowed by a wildcard:

```bash
jq -r '.permissions.allow[]' ~/.claude/settings.local.json | sort | uniq -d
if jq -e '.permissions.allow | index("Bash(*)")' ~/.claude/settings.local.json >/dev/null; then
  jq -r '.permissions.allow[]' ~/.claude/settings.local.json | grep '^Bash(' | grep -vF 'Bash(*)'
fi
```

Largest stale caches (channel 8), `du -k` so it works on macOS/BSD:

```bash
find ~/.claude/file-history ~/.claude/shell-snapshots -type f -mtime +30 \
  -exec du -k {} + 2>/dev/null | sort -rn | head -20
```

Soft-delete with undo path (capture the date once so the log matches the directory):

```bash
gc_date=$(date +%Y-%m-%d)
mkdir -p ~/.claude/_gc_trash/$gc_date
mv ~/.claude/skills/dead-skill ~/.claude/_gc_trash/$gc_date/
echo "$(date -Iseconds) moved skills/dead-skill -> _gc_trash/$gc_date/ (undo: mv back)" >> ~/.claude/gc_log.md
```

## Anti-Patterns

- Bulk approval. "Delete all 15? [y/n]" defeats the design. One item, one decision.
- Hard-deleting on first pass. If there is no `_gc_trash/` copy or `.disabled` rename, you did it wrong.
- Treating "old" as "dead". A skill untouched for 60 days may be seasonal. Age is a signal, not a verdict; a human confirms.
- Cleaning memory by truncation. Merging two contradicting memory files means reading both and keeping the newer truth, not deleting the longer one.
- Touching anything outside `~/.claude` or the project `.claude/`. Config-gc never wanders into source trees.

## Related Tools In This Setup

- `context-budget` (skill): the read-only auditor; run it first to see what costs the most, then use config-gc to reclaim.
- Config-gc covers the `~/.claude` config surface only, never project artifacts.

## Provenance

Adapted from Everything-Claude-Code (github.com/affaan-m/everything-claude-code, MIT, (c) 2026 Affaan Mustafa), skill `config-gc`. Modified for this setup: hardened to a report-only default with per-item approval at the permission prompt, channels retargeted to real paths, ECC cross-links removed, em-dash-free per global style rule.
