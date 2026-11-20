---
description: Dormant. Check a browser tool and its send guard (run only if one is installed)
---

# verify-browser-mcp

Run only if a browser MCP server is installed. Report PASS/FAIL per test with evidence. Read-only except where stated.

## TEST 1: Tool is registered

List the connected browsers through the approved browser tool.
- PASS: returns a device list with no unexpected permission prompt.
- FAIL: "unknown tool" error (not registered).

## TEST 2: Read-only tab context

Read the current tabs with no arguments that create anything.
- PASS: returns the tab list or "no tab groups"; no state created.
- FAIL: creates a tab or errors.

## TEST 3: Send guard asks

Attempt a navigation to a webmail or messaging domain.
- PASS: the guard hook asks for approval (answer Deny); the tool does not execute.
- FAIL: navigation proceeds without a prompt (guard not wired in `settings.json`).

## SUMMARY TABLE

| # | Test | Result | Evidence |
|---|---|---|---|
| 1 | tool registered | PASS/FAIL | device id or error |
| 2 | read-only tab context | PASS/FAIL | response message |
| 3 | send guard asks | PASS/FAIL | prompt text |

## FIXES ON FAIL

- Test 1: ask the operator before registering any server.
- Test 3: confirm `browser-send-guard.sh` is wired under `hooks.PreToolUse` for the browser tool's matcher in `~/.claude/settings.json` (the operator edits that file).
