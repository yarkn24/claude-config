# Browser Automation (DORMANT: only if a browser tool is installed)

Nothing here is active on a fresh install. No browser MCP server or plugin is installed unless the operator asks for it. Referenced from `~/.claude/CLAUDE.md` section "Browser Automation (Dormant)".

- Start every browser automation session by reading the current tabs without creating any.
- Sending is FORBIDDEN: mail compose or send, chat or messaging posts, social posts, ticket creation. `hooks/browser-send-guard.sh` (wired only when a browser tool is installed) asks before any tool call that touches a messaging surface; treat every such prompt as high-risk and default to Deny unless the operator is confirming in the moment. Never route around the hook.
- Irreversible actions (purchase, account change, deletion, final submission) require the operator's explicit approval for that exact action, even in `/afk`.
- One browser automation at a time. Never run two in parallel.
- Login walls and CAPTCHAs pause for the operator; the tool cannot complete them.
- Firm and client data is never typed or pasted into a web page the operator has not approved for it.
