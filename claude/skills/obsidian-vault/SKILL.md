---
name: obsidian-vault
description: Search, create, and manage notes in the user's Obsidian vault. Use when the user wants to find, create, link, or organize notes in Obsidian, asks for a vault health check, or a new project needs a place in the vault.
---

# Obsidian vault

Set `VAULT` to the vault folder the user names (ask once if unknown, then reuse). Prefer a single vault; do not create a new vault per project.

## Layout conventions
- One hub note at the root (for example `Home.md`) that links to one note per area folder.
- A new note goes in the area folder it belongs to and gets a link from that area note. A project with no area goes in an archive note as one table row.
- Never create notes inside folders that are symlinks to live repository folders; the owner edits those directly. Link to the repository path instead of copying documents into the vault.
- Generated notes (topic indexes, logs) are never hand-edited; change the generator.

## Rules
- Link with `[[wikilinks]]`; use a vault-relative path (`[[Area/Note|label]]`) when a base name could repeat.
- Quit Obsidian before editing anything in `.obsidian/` (settings are rewritten on exit).
- Keep notes plain markdown. No em dash.
- Do not put secrets, credentials or customer data in notes.

## Topic folders (optional)
- `$VAULT/Library/<topic>/` with a `README.md` (summary, status, next step, pointers) and dated notes `YYYY-MM-DD_<slug>.md`; one line per topic in `Library/_INDEX.md` (topic, status, last updated, tags, folder).
- When the user resumes a topic: read `_INDEX.md`, then that topic's `README.md`, then only the dated notes needed.
- After meaningful work: append a dated note, update the README and the `_INDEX` line.

## Tools
- Obsidian CLI against a running app, if installed: `obsidian search query=...`, `obsidian backlinks file=...`, `obsidian unresolved total`.
- Otherwise use plain file tools (find, grep) inside `$VAULT`.

## Weekly check (when asked)
List notes changed in the last 7 days, notes with no inbound link, unresolved wikilinks, and any new top-level folder that breaks the layout above. Report; fix only what the user approves.
