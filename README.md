# eng-tutor

A tiny Claude Code plugin that works like a language teacher quietly taking
notes during your lesson: while you work on your normal tasks, Claude
occasionally drops a small tip on how to make your English phrasing sound
more natural.

```
★ English tip ─────────────────────────────────
You wrote:      "fast software development cycle"
More natural:   "rapid development cycle"
"Rapid" collocates with cycle/pace/iteration — "fast" isn't wrong,
just less idiomatic. E.g., "we kept a rapid release cadence."
─────────────────────────────────────────────────
```

## What it does

A `SessionStart` hook injects a short instruction into every session telling
Claude to quietly watch the English in **your own messages** and, when it
notices something genuinely worth improving, append a small tip at the end of
its response.

- Focuses on **naturalness, word choice, collocations, idioms, and
  professional register** (Slack messages, PR descriptions, emails) — not
  grammar nitpicks.
- **Max 1–2 tips per session; most sessions have zero.** It never invents a
  tip just to fill a quota.
- Only looks at your messages — never code, logs, or quoted text.
- Nothing is stored anywhere; tips just appear in the conversation.

## Install

In Claude Code:

```
/plugin marketplace add gutnikov/eng-tutor
/plugin install eng-tutor
```

Or from the terminal:

```bash
claude plugin marketplace add gutnikov/eng-tutor
claude plugin install eng-tutor@eng-tutor
```

Then start a new session.

## Token cost

The instructions (~250 tokens) are injected into **every** session. Don't
install if you're not fine with that small overhead.

## How it works

Three files, same pattern as Anthropic's `explanatory-output-style` plugin:

- `hooks/hooks.json` registers a `SessionStart` hook
- `hooks-handlers/session-start.sh` emits `additionalContext` JSON with the
  tutor instructions
- the main model — which already sees your whole conversation — produces the
  tips inline; no extra API calls, no extra processes, zero latency

## License

MIT
