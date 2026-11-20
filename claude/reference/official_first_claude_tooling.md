# Official-First for Claude Code Tooling

Referenced from `~/.claude/CLAUDE.md` section "Official-First for Claude Code Tooling". Full original detail below.

BEFORE INSTALLING OR IMPROVISING ANYTHING FOR CLAUDE CODE ITSELF (a skill, an MCP server, a plugin, a workaround for a tool gap), CHECK THE OFFICIAL ANTHROPIC SOURCE FIRST. The official path beats a self-written or improvised one, even when the improvised one works.

- **Check in this order:** `code.claude.com/docs/*` (official docs) and `github.com/anthropics/*` (`skills`, `claude-plugins-official`, `knowledge-work-plugins`, `claude-agent-sdk-*`), then built-in discovery (`/help`, `claude --help`, `claude plugin list --available`), before searching the open web or writing a custom skill.
- **Before improvising a workaround** (a subprocess trick, a manual file edit, a custom script) for a Claude Code behavior gap, check whether the official docs already document a built-in fix (a slash command, a flag, a settings key). A documented one-liner beats a self-built multi-step workaround.
- **Measure before installing:** `claude plugin details <name>@<marketplace>` prints the real always-on token cost. Confirm the official mechanism does not reintroduce the problem it is meant to solve (for example, context bloat) before adopting it.

**Why:** 2026-07-31 incident. Several skills/plugins were installed by guesswork instead of checking `anthropics/skills` first, and had to be corrected and removed afterward. Separately, when Claude in Chrome tools were missing from a running session, a heavy workaround (spawning a whole new `claude --chrome -p "..."` process) was used instead of the officially documented fix: run `/chrome` and select "Reconnect extension" (`code.claude.com/docs/en/chrome`). The workaround worked but cost a fresh session, real tokens, and several minutes for something a slash command likely solves instantly.

Memory: `feedback_official_first_claude_tooling`.
