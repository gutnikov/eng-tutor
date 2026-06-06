# eng-tutor-followup plugin — Design

**Date:** 2026-06-06
**Status:** Approved

## Purpose

A Claude Code plugin that acts like a language teacher quietly taking notes during a
lesson: while the user works on their normal tasks, Claude occasionally surfaces a
small tip about how to make the user's English phrasing more natural (e.g., "fast
software development cycle" → "rapid development cycle").

Modeled on the `explanatory-output-style` official plugin: a `SessionStart` hook
injects behavioral instructions via `additionalContext`; the main model — which
already sees every user message — produces the tips inline. No extra API calls, no
extra processes, zero latency.

## Requirements

- Tips appear **inline** during normal sessions, formatted as a distinctive box.
- Scope: **naturalness, word choice, collocations, idioms, professional/business
  register** (Slack messages, PR descriptions, emails). Grammar only when it changes
  meaning or confuses the reader. Tips should be interesting, with a short example
  or context — never boring or lecture-like.
- Frequency: **notable only, max 1–2 tips per session; most sessions zero.** No quota.
- Analyze only the **user's own messages** — never code, logs, quoted text, or
  Claude's output.
- No persistence: tips are shown in the session only.
- Distribution: **public GitHub repo** that is its own single-plugin marketplace, so
  anyone can install via `/plugin marketplace add <owner>/eng-tutor-followup`.

## Architecture

Identical pattern to `explanatory-output-style@1.0.0`:

```
eng-tutor-followup/
├── .claude-plugin/
│   ├── plugin.json          # name, version, description, author
│   └── marketplace.json     # single-plugin marketplace, source "./"
├── hooks/
│   └── hooks.json           # registers SessionStart → session-start.sh
├── hooks-handlers/
│   └── session-start.sh     # static `cat` of hookSpecificOutput JSON
├── docs/superpowers/specs/  # this design doc
├── README.md                # what/why, install steps, example tip, token-cost note
└── LICENSE                  # MIT
```

### Components

**`hooks/hooks.json`** — registers a `SessionStart` hook running
`bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh"`. SessionStart fires on
startup, resume, clear, and compact, so the instructions survive long sessions.

**`hooks-handlers/session-start.sh`** — a static heredoc `cat` of:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<tutor instructions>"
  }
}
```

Exit 0 always. No logic, no dependencies beyond bash, nothing to fail.

### The injected instructions (the actual product)

> You have a secondary, low-priority role: an English writing tutor for the user, a
> non-native English speaker. As you work, quietly notice the English in the user's
> own messages (not code, not logs, not quoted text).
>
> When you spot a genuinely notable improvement, append a tip at the END of your
> response (with backticks):
>
> `★ English tip ─────────────────────────────────`
> You wrote:      "fast software development cycle"
> More natural:   "rapid development cycle"
> "Rapid" collocates with cycle/pace/iteration — "fast" isn't wrong, just less
> idiomatic. E.g., "we kept a rapid release cadence."
> `─────────────────────────────────────────────────`
>
> Rules:
> - Focus on naturalness, word choice, collocations, idioms, and professional
>   register (Slack/PRs/emails). Not grammar nitpicks — only flag grammar if it
>   changes meaning or would confuse a reader.
> - Max 1–2 tips per session. Most sessions should have zero. Never invent a tip
>   to fill a quota.
> - Keep it short and interesting — include a quick example or the context where
>   the phrase shines. Never lecture.
> - Skip terse command-like prompts ("fix it", "y", "run tests") — only comment on
>   real sentences where phrasing matters.
> - The task always comes first; tutoring never interferes with it.

(Exact JSON-escaped wording finalized during implementation; content as above.)

## Alternatives considered

- **Prompt logging + Stop-hook analysis via `claude -p --model haiku`** — rejected:
  far more complexity (state files, subprocess calls, per-call cost, end-of-turn
  latency) and lower-quality tips since the analyzer lacks conversation context.
- **On-demand `/eng-followup` skill** — rejected for v1: not automatic. Could be
  added later as an explicit "end of lesson" summary.

## Error handling

The hook is a static `cat` with `exit 0` — there are no failure modes beyond a
malformed JSON heredoc, which is covered by testing. If the hook somehow fails,
Claude Code degrades gracefully: the session simply starts without tutor context.

## Testing

1. **JSON validity:** `bash hooks-handlers/session-start.sh | jq .` succeeds and
   contains `hookEventName: "SessionStart"` and a non-empty `additionalContext`.
2. **Manual end-to-end:** install from the local marketplace, start a fresh session,
   send a prompt containing a known unnatural phrasing → a `★ English tip` box
   appears at the end of the response. Send terse prompts → no tip.

## Distribution

1. Public GitHub repo `eng-tutor-followup` under the user's account.
2. `marketplace.json` lists the plugin with `"source": "./"`.
3. Install: `/plugin marketplace add <owner>/eng-tutor-followup` then
   `/plugin install eng-tutor-followup`.
4. README includes a token-cost warning (mirrors the explanatory plugin's warning)
   since the instructions are injected into every session.
