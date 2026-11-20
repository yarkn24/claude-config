# SOURCE AND PROVENANCE

## THE TALK

| Field | Value |
|---|---|
| Title | Boris Cherny: Building Claude Code |
| Venue | Y Combinator, Startup School 2026 |
| Speakers | Boris Cherny (Claude Code creator, Anthropic), Diana Hu (host) |
| Published | 2026-07-27 |
| Duration | 35:51 |
| Video | `https://www.youtube.com/watch?v=qyPCVqFUyDo` |
| Official page | `https://www.ycombinator.com/library/UN-boris-cherny-building-claude-code` |

## TWO SOURCES, NEITHER COMPLETE, READ THIS BEFORE QUOTING

| Source | How obtained | Size | Strength | Weakness |
|---|---|---|---|---|
| OFFICIAL | YC page, embedded JSON field `transcript` | 5,472 words | Human-edited, speaker-labeled, clean wording | ABRIDGED, whole passages cut |
| CAPTIONS | `yt-dlp --write-auto-sub`, de-duplicated | 6,825 words | Full coverage, timestamped | Auto-generated, transcription artifacts |

CONFIRMED CUT FROM THE OFFICIAL TRANSCRIPT, present in captions only:

| Passage | Official | Captions |
|---|---|---|
| "Delete your hooks" | absent | present, 00:07:04 |
| "for Opus 5, this is something we really do recommend" | absent | present, 00:07:08 |
| The entire D4 verification story ("too hard", "tools to verify", "get stuck") | absent | present, 00:20:15 onward |
| "a new form of test time compute" | absent | present, 00:26:56 |
| The two-week Swift rewrite and "pixel by pixel" run | absent | present, 00:21:47 |

Label note: `[talk transcript]` marks a quote from the published transcript of a conference talk. It is not product documentation.

CONFIRMED CAPTION ARTIFACTS, corrected by the published transcript:

| Caption text | Official text |
|---|---|
| "way over we specific instructions" | "way overly specific instructions" |
| "forget all of the things that you learned" | "forget all the things that you learned" |
| "ablation essentially is a eval where you delete things" | "ablation essentially it's an eval, but you delete things" |
| "quad", "Clocko" | "Claude" (the official transcript still prints "quad" in places) |

## SOURCING RULE, BINDING

1. PASSAGE IN BOTH: quote the OFFICIAL wording. It is human-edited.
2. PASSAGE IN CAPTIONS ONLY: quote the caption and LABEL IT `[caption]`. It is auto-generated and may contain artifacts.
3. NEVER silently clean a caption and present the result as a quote.
4. NEVER cite the official transcript for a passage it does not contain. Its absence is an editorial cut, not a denial.

## VERIFIED QUOTES

Every line below was confirmed by literal string match against the named source.

### D1, DELETE FIRST

> [talk transcript] So yeah, we deleted 80% of the system prompt.

> [talk transcript] And we actually use this as a sort of ablation to figure out: is the prompt useful? And what's interesting is that the model is actually a little bit more intelligent without these prompts.

> [talk transcript] ablation essentially it's an eval, but you delete things to figure out the impact.

> [talk transcript] you delete the entire system prompt, and then you bring it back line by line to figure out what is the impact of each individual line.

### D1 COUNTERWEIGHT, DO NOT SKIP THIS ONE

> [talk transcript] But when you use Claude Code as a product, you do actually want some of these prompts because it helps you use the product and it it helps them the product behave and the model behave in the way that you would want when when you're using it as a person.

This is the empirical basis for the KEEP buckets. Smarter without prompts is not the same as better-behaved without prompts.

### D2, REBUILD

> [talk transcript] every six months delete your Claude.md. Delete your skills.

> [caption, 00:07:04] Delete your hooks. See what the model does and it might surprise you.

> [caption, 00:07:08] And actually for Opus 5, this is something we really do recommend is just try deleting all of these things because the model might really just not need all those instructions that you needed for past models.

> [talk transcript] So you do it you do it kind of piece by piece. So the first step is you delete. The next step is you use it.

> [talk transcript] And you don't wanna guess what's the instruction that the model needs because you might not predict it correctly.

> [caption, 00:08:14] And only when you see it repeatedly stumble on the same thing, that's when you add it back.

### D3, TASK FRAMING

> [talk transcript] they just give it like way overly specific instructions.

> [talk transcript] You must do like one, then two, then three, then four.

> [talk transcript] And for modern models, that's actually really not the way to do it. You wanna go a little bit higher level.

> [talk transcript] You wanna describe the task, you wanna describe the guardrails, you wanna describe like the exit criteria, and then just go with the model cook.

The closing phrase reads oddly in both sources. Quote it as printed; do not "fix" it to "let the model cook".

### D4, VERIFICATION, CAPTIONS ONLY

The official transcript cuts this passage entirely. It is the single highest-value directive, so the caption text is retained here with its artifacts intact.

> [caption, 00:20:29] And the verification I think is probably the single most important thing that people do not get right

> [caption, 00:22:40] but really all you need is give the model the task, give it a way to verify the output of its work so it doesn't get stuck, and it will just go.

> [caption, 00:23:38] You have to give it a task that's too hard. You have to give it the tools to verify the work like you would yourself, like you would if you were doing the task.

### D5, UNHOBBLING

> [talk transcript] you should give the model slightly harder tasks than what you think it can do.

> [talk transcript] how should future founders here think about unhobbling Claude and fixing this product overhang.

### D6, ORCHESTRATION

> [talk transcript] So my background is functional programming. And so the way that we design this is it's essentially an algebra for agents.

> [caption, 00:26:56] this is actually like a new form of test time compute.

### D7, EVALS

> [talk transcript] I think evals they outlive the harness a little bit, but not by that much. Like an eval might live for maybe one, two, three model generations.

> [talk transcript] Very often we just saturate the eval and then we have to throw it away and we have to come up with a new eval.

### D8, EMPIRICAL MINDSET

> [talk transcript] And it's really about being empirical. So forget all the things that you learned about past models. Forget everything that you've learned about computer science theory in class. Look at the model, try to do a task, see where it struggles

> [talk transcript] it's not a theoretical science, it's become an empirical science.


### HONEST LIMITS, QUOTE THIS WHEN SOMEONE OVERCLAIMS

> [talk transcript] So coding is solved for the kind of coding that I do. It's not solved for everyone.

> [talk transcript] there's still code bases that are like super deep systems code bases where quad still struggles. There's distributed systems where quad still struggles. There's really kind of in the weeds UI verification, like something's off by Pixel or something.

### WHAT SURVIVED THE CUT, THE BASIS OF THE RUBRIC

> [caption, 00:06:26] actually the code that's in the Claude code harness today, almost all of it is about safety and permissions and static analysis and there's a bunch of UI code and we've actually unshipped a lot of the other code already.

Safety, permissions, and static analysis survived an 80% cut. That is buckets A and C. Style guidance did not survive. That is bucket D.

## MECHANISM CLAIMS, VERIFY BEFORE RELYING

> [talk transcript] when you run Claude Code, you can just do like dash-system prompt and set whatever system prompt you want if you want to experiment with it.

> [talk transcript] this is actually this kind of undocumented feature. If you do claude code simple equals one, like this uh environment variable, and then you run Claude, it'll delete all the system prompts, including from the tools.

STATUS AS OF 2026-08-06, checked against `claude --help` on 2.1.221: `CLAUDE_CODE_SIMPLE=1` is no longer undocumented. It is set by the first-class `--bare` flag, which also skips hooks, LSP, plugin sync, auto-memory, and CLAUDE.md auto-discovery. Re-check `claude --help` before repeating either claim.

## COMMERCIAL-BIAS CAVEAT, BINDING

Advice from a vendor's talk to run thousands of agents for days has not been validated for this environment. Validate cost and benefit on a small scope before scaling.

| Lesson | Cost to adopt | Verdict |
|---|---|---|
| Delete unneeded instructions | Zero, it saves tokens | ADOPT |
| Give the model a way to verify itself | Small, one-off engineering | ADOPT, highest value |
| Stop over-specifying prompts | Zero | ADOPT |
| Run a frontier model unattended for weeks | Very high | DO NOT ADOPT as default |
| Fan out thousands of subagents | Very high | ADOPT ONLY when scoped and budgeted |

The Opus-plans / Sonnet-executes split stays.

## INDEPENDENT CROSS-CHECK

`https://code.claude.com/docs/en/best-practices` states the same core claims without the vendor-bias problem:

- "Give Claude a way to verify its work"
- "If Claude already does something correctly without the instruction, delete it or convert it to a hook."
- "Bloated CLAUDE.md files cause Claude to ignore your actual instructions."

The doctrine does not rest on the video alone.

## OFFICIAL-FIRST CHECK

`github.com/anthropics/skills` ships no skill covering model migration, system-prompt ablation, or context engineering. Hand-writing this skill is justified rather than duplicative.
