# Prompt: build an `eng-tutor` plugin

> Paste this into a fresh Claude Code session in an empty git repository.

---

Build a tiny Claude Code plugin called **eng-tutor** that gives Claude a
secondary, low-priority role: a quiet English writing tutor for a non-native
speaker.

While Claude works on the user's normal tasks, it watches the English in the
**user's own messages** — never code, logs, quoted text, or Claude's own
output — and when it spots something genuinely worth improving, appends a
small tip at the end of its response:

```
☕ English tip ─────────────────────────────────
You wrote:      "fast software development cycle"
More natural:   "rapid development cycle"
"Rapid" collocates with cycle/pace/iteration — "fast" isn't wrong,
just less idiomatic. E.g., "we kept a rapid release cadence."
─────────────────────────────────────────────────
```

Tips focus on what actually makes writing sound native, in a professional
register (Slack messages, PR descriptions, emails): collocations, hedging &
softeners, ellipsis & short replies, phrasal verbs, contractions, verb-first
phrasing, and modern big-tech idiom — the way an engineer at a big California
tech company would phrase it today, never textbook-stale English. Grammar is
flagged only when it changes meaning. Restraint is the core design value:
max 1–2 tips per session, most sessions zero, never invent a tip to fill a
quota, never lecture, skip terse command-like prompts, and the task always
comes first.

Implement it the way Anthropic's official `explanatory-output-style` plugin
works: a `SessionStart` hook whose handler emits the tutor instructions as
`additionalContext`. The main model already sees the whole conversation, so
tips appear inline — no extra API calls, no extra processes, zero latency.

Write the tutor instruction text yourself from the description above. Make
the repo installable via `/plugin marketplace add <github-handle>/eng-tutor`,
and include a README that shows the example tip and discloses the per-session
token cost of the injected instructions.
