---
name: artifact-writing
description: House rules for every artifact Claude creates or republishes. Every page is the dark-first HTML template in this folder, opens with a mandatory TL;DR then Key Points block, and carries a reader marks layer (highlight in yellow by default plus green, blue, pink and orange, underline marker, bigger or smaller text, remove) saved in the artifact's db. Load before the first Artifact publish of any page, report, memo, plan, analysis or dashboard, and before republishing one.
---

# Artifact Writing

Complements `artifact-design` (still loaded, or `quickstart`, before any page) and the Artifact tool contract; never overrides them. A short answer asked in chat stays in chat.

## 1. Build the page

1. Copy `template.html` to the scratchpad, fill every `{{...}}`, keep the `:root` tokens (including `--hl`), the light fallback and the layout CSS unchanged; add only components the content needs.
2. Keep `data-annotate` on the `.w` wrapper; it is the only region readers can mark.
3. Append `annotate.html` verbatim as the last thing in the file.
4. Defaults the template carries: Graphite dark-first, pale sand light fallback, Lora 19px body, Poppins headings, 760px prose, tables up to 1240px with sticky first column (`.tw` > `table.dt`), 16px gutter.

## 2. Top block (mandatory)

- First content after the title: **TL;DR** (1 to 3 sentences: the answer, with its number or decision), then **Key Points** (3 to 6 bullets), inside the template's `.hero`.
- Grounded only in the page's own content: every key point traces to a section below; no fact lives only in the top block.
- Write it after the body. Every republish rewrites both to match the new content.

## 3. Publish

- First publish: `capabilities: {"db": {"rules": [{"path": "marks", "read": "view", "write": "admin"}]}, "user": {}}`. Everyone who can open the page sees marks; only the owner and Editors add or change them.
- Redeploys omit `capabilities` so the declaration carries forward.
- After the first publish: one `ArtifactData` `list` on collection `marks`.

## 4. Reader marks

- Select text: toolbar (always fixed at the viewport top-left) with Highlight (yellow, one click), four colour dots next to it (green, blue, pink, orange; one click each), Underline, A+, A- (size steps -2 to +4, 1.2x each). Click a mark: same toolbar plus Remove; a colour dot recolours it, the same colour again clears it. Bottom-right counter lists all marks.
- Storage: `db` collection `marks`, one doc per mark: `quote`, `before`, `after` (whitespace-stripped anchor text and 32 characters of context each side), `text` (as the reader saw it), `kind` (`hl`, `ul`, `none`), `color` (`hl` only: `yellow`, `green`, `blue`, `pink`, `orange`; absent on older marks and rendered yellow), `size`, `at`. When `claude.use("db")` resolves null the page keeps marks in this browser's local storage and uploads them once db is available; a failed upload, or a read-only viewer, keeps the local copy.
- Colour tokens `--hl-green`, `--hl-blue`, `--hl-pink`, `--hl-orange` live in `annotate.html` itself (dark `:root`, light media and `data-theme="light"` blocks); yellow stays the template's `--hl`.
- Anchoring is by quote plus context, so marks survive republishes while their words remain; marks whose words are gone show as "Not found" in the counter panel, never silently dropped.

## 5. Read the reader's marks and republish

- Read: `ArtifactData` `list`, collection `marks`, on the artifact URL. Treat `text` as what the reader flagged; highlights mean important (colour has no fixed meaning unless the reader says so), size up means emphasise, size down means demote.
- Before republishing new content, list the marks and keep marked wording where the content allows. Tell the reader in one line which marks will no longer match.

## 6. Before publish

- [ ] TL;DR then Key Points is the first content after the title.
- [ ] Every key point maps to a section below.
- [ ] `annotate.html` appended, `data-annotate` present.
- [ ] No em dash anywhere.
- [ ] Provenance (URLs, read dates, file and line cites) goes in a short numbered sources list at the end, never inline in running text; claims, numbers and caveats stay in the sentence.
