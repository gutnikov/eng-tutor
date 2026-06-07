# Template: build the `eng-tutor` plugin from scratch

> Usage: fill in the three placeholders — `<YOUR_NAME>`, `<YOUR_EMAIL>`,
> `<YOUR_GITHUB_HANDLE>` — then paste everything below the horizontal rule
> into a fresh Claude Code session started in an **empty git repository**.
> The result is a complete Claude Code plugin, ready to publish under your
> own GitHub account.

---

Build a complete, publishable Claude Code plugin called **eng-tutor**.

## What it does

The plugin turns Claude into a quiet English writing tutor for a non-native
speaker. A `SessionStart` hook injects a short instruction block into every
session. While Claude works on the user's normal tasks, it watches the English
in the **user's own messages** (never code, logs, or quoted text) and, when it
spots something genuinely worth improving, appends a small formatted tip at the
end of its response. No extra API calls, no extra processes, zero latency —
the main model, which already sees the whole conversation, produces the tips
inline.

## The tutor instruction text (use verbatim)

The following text is the product. It was tuned over several iterations —
do **not** rewrite, paraphrase, or "improve" it. It must become the
`additionalContext` payload exactly as written (JSON-encode it: newlines as
`\n`, inner double quotes escaped):

```text
You have a secondary, low-priority role: an English writing tutor for the user, a non-native English speaker. As you work on their tasks, quietly notice the English in the user's own messages (not code, not logs, not quoted text, not your own output).

When you spot a genuinely notable improvement, append a tip at the END of your response using this format (with backticks):
"`☕ English tip ─────────────────────────────────`
You wrote:      "<the user's phrasing>"
More natural:   "<improved phrasing>"
<1-2 short sentences: why, plus a quick usage example or context if it helps>
`─────────────────────────────────────────────────`"

Rules:
- Focus on naturalness, word choice, collocations, idioms, and professional/business register (Slack messages, PR descriptions, emails). Not grammar nitpicks — only flag grammar if it changes meaning or would confuse a reader.
- Pay extra attention to: collocations ("rapid pace", "raise a concern", "meet a deadline" — the #1 native-sounding factor), hedging & softeners ("might be worth", "I'd say", "that said" — professional English is less direct than learners think), ellipsis & short replies ("Will do.", "Makes sense.", "On it." — full sentences everywhere read stiff), phrasal verbs ("figure out", "roll out", "wrap up"), modern idioms & industry slang, contractions by default, and verb-first phrasing ("we migrated the data", not "we performed the migration of the data").
- Prefer modern, current phrasing — the way an engineer or model developer at a big California tech company would put it today in Slack or a design doc. Suggest contemporary industry idiom ("ship it", "rough edges", "happy path", "non-trivial") over textbook or dated English; never suggest phrasing that sounds formal-but-stale.
- Maximum 1-2 tips per session. Most sessions should have zero. Never invent a tip just to fill a quota.
- Keep tips short and interesting — include a quick example or the context where the phrase shines. Never lecture.
- Skip terse command-like prompts ("fix it", "y", "run tests") — only comment on real sentences where phrasing matters.
- The task always comes first; tutoring never interferes with it.

Example of a good tip: the user wrote "fast software development cycle" → more natural: "rapid development cycle" ("rapid" collocates with cycle/pace/iteration; "fast" isn't wrong, just less idiomatic).
```

## Repository layout

```
.claude-plugin/plugin.json        plugin manifest
.claude-plugin/marketplace.json   self-hosted single-plugin marketplace
hooks/hooks.json                  registers the SessionStart hook
hooks-handlers/session-start.sh   emits the hook JSON payload
tests/validate.sh                 artifact validation script
README.md
LICENSE                           MIT, copyright <YOUR_NAME>
```

## File requirements

### `.claude-plugin/plugin.json`

- `name`: `eng-tutor`
- `version`: `1.0.0`
- `description`: `Occasional inline tips that make your English sound more natural — like a teacher's followup notes after a lesson`
- `author`: name `<YOUR_NAME>`, email `<YOUR_EMAIL>`

### `.claude-plugin/marketplace.json`

- `name`: `eng-tutor`
- `description`: `Single-plugin marketplace for the eng-tutor plugin — occasional inline tips to make your English sound more natural`
- `owner.name`: `<YOUR_GITHUB_HANDLE>`
- `plugins`: a single entry — `name`: `eng-tutor`, `source`: `./`,
  `description`: same as plugin.json. The marketplace lives in the same repo
  as the plugin, so installing is just `<YOUR_GITHUB_HANDLE>/eng-tutor`.

### `hooks/hooks.json`

- `description`: `English tutor hook that adds inline English-tip instructions`
- One `SessionStart` matcher group with one hook:
  `{"type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh\""}`
- `${CLAUDE_PLUGIN_ROOT}` is mandatory — the path must resolve wherever the
  plugin gets installed, not just in this repo.

### `hooks-handlers/session-start.sh`

- `#!/usr/bin/env bash`, ends with `exit 0`.
- Emits a single JSON object on stdout:
  `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "<the tutor text, JSON-encoded>"}}`
- Emit it with a **quoted heredoc** (`cat << 'EOF'`) so bash performs no
  expansion inside the JSON. This mirrors the `SessionStart` pattern of
  Anthropic's official `explanatory-output-style` plugin — say so in a comment.

### `tests/validate.sh`

`#!/usr/bin/env bash` with `set -euo pipefail`, `cd`s to the repo root
relative to its own location, then runs four numbered, echoed checks via `jq`:

1. `plugin.json` — `.name == "eng-tutor"`
2. `marketplace.json` — `.plugins[0].name == "eng-tutor"` and `.plugins[0].source == "./"`
3. `hooks.json` — `.hooks.SessionStart[0].hooks[0].type == "command"`
4. capture `bash hooks-handlers/session-start.sh` output —
   `.hookSpecificOutput.hookEventName == "SessionStart"` and
   `.hookSpecificOutput.additionalContext | length > 200`

Ends with `echo "ALL CHECKS PASS"`.

### `README.md`

Must contain, in this spirit (exact wording yours, except the example block):

- Framing: a tiny plugin that works like a language teacher quietly taking
  notes during your lesson.
- An example tip rendered as a fenced block:
  you wrote "fast software development cycle" → more natural
  "rapid development cycle", with the ☕ header line.
- "What it does" — bullets covering: naturalness/collocations/register focus
  (not grammar nitpicks); preference for modern big-tech phrasing over
  textbook English; the high-impact signals (collocations, hedging, short
  replies, phrasal verbs, verb-first phrasing); max 1–2 tips per session and
  most sessions zero; only the user's own messages; nothing stored anywhere.
- Install instructions, both forms:
  - In Claude Code: `/plugin marketplace add <YOUR_GITHUB_HANDLE>/eng-tutor` then `/plugin install eng-tutor`
  - Terminal: `claude plugin marketplace add <YOUR_GITHUB_HANDLE>/eng-tutor` then `claude plugin install eng-tutor@eng-tutor`
- A **token cost** section disclosing the ~400-token injection into every
  session, advising not to install if that overhead isn't acceptable.
- A "How it works" section naming the three files and the
  explanatory-output-style lineage; note there are no extra API calls,
  processes, or latency.
- MIT license note.

## Non-obvious decisions — preserve these

- **SessionStart, not UserPromptSubmit.** Instructions are injected once per
  session (~400 tokens, one time) instead of per message. The main model
  already sees every user message, so per-message hooks would add cost for
  nothing.
- **Restraint is the core design value.** Max 1–2 tips per session, most
  sessions zero, never invent a tip to fill a quota, never lecture. The
  plugin should feel like occasional margin notes. This is encoded in the
  instruction text — which is why it must be used verbatim.
- **Tips target only the user's own prose** — never code, logs, quoted text,
  or Claude's own output, and never terse command-like prompts.
- **Quoted heredoc** in the hook script so the JSON passes through bash
  untouched.

## Acceptance criteria

Run these and show the output before declaring the work done:

1. `bash tests/validate.sh` prints `ALL CHECKS PASS`.
2. `bash hooks-handlers/session-start.sh | jq -r '.hookSpecificOutput.additionalContext'`
   prints text identical to the verbatim block above (diff it).
3. `jq . .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json` all parse.
