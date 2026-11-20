---
description: Negotiation and hard-conversation advice from a negotiation-advisor subagent, with ready-to-send lines and reply branches.
argument-hint: <situation, message you received, or question>
---

## Step 1: intake (you, before dispatch; the subagent cannot ask the user anything)
Build a situation brief from the user's text and the conversation. Fields:
1. Counterpart: who, relationship to the user, personality cues (talkative/warm, direct/fast, data-driven/quiet).
2. Their exact words: the last message or what they said, verbatim where possible.
3. Situation: what happened so far, channel (message, phone, in person), what was already tried.
4. User's goal: best outcome and walk-away point.
5. Leverage and limits: real alternatives, real deadlines, money, who else decides.
6. Their likely needs and fears; anything unusual known about them.
7. What the user wants back: ready-to-send message, call script, or analysis; language.

If a field that would change the advice is missing (usually 2, 4 or 5) and the conversation cannot fill it, ask the user once, at most 4 short questions in one message, then dispatch. Skip the questions when the brief is already sufficient or the user says to go ahead.

Do not paste confidential material (client names, contract text, personal data) into the brief; describe it generically.

## Step 2: dispatch
Dispatch the `negotiation-advisor` subagent with the Agent tool. Send the user's text verbatim, then the situation brief (mark unknown fields "unknown"), plus earlier answers in this conversation.

## Step 3: relay
Relay the agent's answer as it is (including its questions and label). Add no advice of your own unless the user asks. When the user answers the questions, dispatch again with the updated brief.

User's text:
$ARGUMENTS

If empty, ask the user in one line which situation or message they want advice on, then dispatch.
