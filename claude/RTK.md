# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

`rtk` misbehaving or freshly installed: `~/.claude/reference/rtk_install_check.md`.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)
**Summarized output** (e.g. "N matches in 0 files", lines missing): rerun with `rtk proxy <cmd>`.

Refer to CLAUDE.md for full command reference.
