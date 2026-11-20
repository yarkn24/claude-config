# D4: VERIFICATION IS THE WHOLE GAME

## DIRECTIVE

GIVE THE MODEL A WAY TO CHECK ITS OWN WORK. This matters more than any instruction you could write.

Source calls verification "the single most important thing that people do not get right" [caption, 00:20:29]. Official docs agree independently: "Give Claude a way to verify its work."

## WHY IT BEATS INSTRUCTION

| Approach | Cost | Catches | Scales with task length |
|---|---|---|---|
| Instruction in prose | Every session, forever | Nothing, it only asks | No |
| Verification loop | Once, to build | Actual failures | Yes |

An instruction expresses a hope. A verifier produces a fact. Long autonomous runs work only because the model can tell whether it is still on track.

## THE VERIFICATION LADDER

Climb as far as the task allows. Higher rungs subsume lower ones.

| Rung | Mechanism | Example |
|---|---|---|
| 0. NONE | Model asserts success | "I fixed it" |
| 1. SELF-REVIEW | Model re-reads its own output | Re-read the diff |
| 2. DETERMINISTIC CHECK | Script returns pass or fail | Linter, compiler, schema validator |
| 3. TEST SUITE | Behaviour asserted against expectation | Unit and integration tests |
| 4. ORACLE COMPARISON | Output compared to a known-good reference | Pixel diff against the original app |
| 5. INDEPENDENT AUDITOR | A second agent tries to refute the result | Adversarial review pass |

Rung 0 is where most harnesses actually sit while believing they are higher.

## THE EXIT-CODE RULE

A GATE THAT ONLY PRINTS IS NOT A GATE. If a check signals failure by writing JSON to stdout, any caller that skips reading stdout passes it silently.

| Signal | Enforceable |
|---|---|
| Non-zero exit code | Yes, the harness cannot ignore it |
| stdout JSON with a status field | Only if every caller parses it, every time |
| A sentence in a prompt telling the agent to check | No |

RULE: every script framed as a gate returns non-zero on failure. Then wire it to a hook or a test runner so skipping it is impossible.

## THE WIRING RULE

A validator nobody calls is not verification. It is a file.

Audit question: for each verifier, which command, hook, test, or schedule invokes it? If the answer is "an agent is told to run it in prose", the answer is nobody.

| State | Meaning |
|---|---|
| Called by a hook | Enforced |
| Called by a test runner or CI | Enforced |
| Called by a script the pipeline runs | Enforced |
| Mentioned in prose as "run this after X" | NOT enforced |
| Called by nothing | Dead code, retire it or wire it |

## BUILD THE VERIFIER BEFORE THE HARD TASK

The source's pattern for long autonomous runs: give a task slightly too hard, give a way to verify, let it run.

Inverted, that is the failure mode: a task too hard WITHOUT verification produces confident, wrong, expensive output.

RULE: no long autonomous run ships without at least rung 2.

## WHAT TO VERIFY IN A DOCUMENT PIPELINE

| Property | Rung | Mechanism |
|---|---|---|
| Output parses and compiles | 2 | Compiler exit code |
| Required sections present | 2 | Structural check script |
| No fabricated claim | 5 | Auditor pass against a source of truth |
| Numeric threshold met | 2 | Scorer with a non-zero exit |
| Formatting and style | 2 | Linter, not prose |

Style rules belong here, at rung 2, not in always-on prose. That is what makes them bucket C rather than bucket D.

## ANTI-PATTERNS

- Asserting "fixed" without showing the command output.
- A gate script whose only exit path is zero.
- A parity or regression test referenced in prose but wired to nothing.
- Test failures carried as folklore in handoff notes instead of a recorded baseline.
- Trusting a subagent's report that it wrote a file, without checking the file.
