# LIMITS PLAYBOOK — hourly + weekly quota optimization

Subscriptions have two meters: the rolling short window (Claude: 5 hours;
Codex: hourly-ish) and the weekly cap (both). Weekly is the one that ends
your month early. No tool manages these for you — this protocol does.

## Rule 1 — Route by taste, spend by tier

The weekly cap drains per-model: Opus-class burns allowance several times
faster than Sonnet-class, and mechanical work on a premium model is pure
waste. Standing routing:

| Work | Route to | Why |
|---|---|---|
| Direction, architecture, design taste, hard debugging | Opus, short sessions | only place premium burn pays |
| Implementation on locked direction | Sonnet / Codex default | the workhorse tier |
| Research, summarization, bulk reads, second opinions | Gemini CLI (free tier) | someone else's quota |
| Thinking, briefs, reviewing outputs, writing feedback lists | you, offline | free and it's the actual job |

Multi-subscription arbitrage is the same idea across apps: Claude for
taste + hard problems, Codex quota for implementation volume, Gemini free
for everything mechanical. Same SOLO rule — smart-first on judgment,
cheap/free on mechanics — applied to quotas instead of API prices.

## Rule 2 — Sessions are blocks, not dribbles

The 5-hour window opens at your FIRST message and closes 5h later
regardless of use. Twenty scattered mini-chats across a day open windows
constantly and waste each one.

- Batch agent work into 1–2 deliberate blocks per day. Open a window ON
  PURPOSE, drain it with prepared tasks, stop.
- Prepare OUTSIDE the window: briefs, screenshots, feedback lists, task
  queues — all written before the first message.
- Check `/usage` (Claude Code) at block start and end. Know your pace.

## Rule 3 — Kill the re-read multiplier

Every message re-reads the whole conversation, so long sessions cost more
per turn as they age. This is the #1 silent weekly-cap killer.

- Batch feedback: one numbered list per review round, never per-item pings.
- Park and restart: phase done → park_state → fresh session → resume_state.
  A fresh session reading a 40-line note is far cheaper than turn 60 of a
  bloated one. In Claude Code, /compact at natural milestones; /clear
  between unrelated tasks.
- Never let an agent "explore" in a long-lived session. Exploration =
  new session, park the conclusion, kill it.

## Rule 4 — Weekly budget with a Wednesday check

Treat the week like a burn-down:

- Mon: plan the week's agent-heavy work. Decide what deserves Opus (usually
  1–2 direction sessions) — everything else defaults down-tier.
- Wed: check usage. Past half? Downgrade defaults one tier and push
  mechanical work to Gemini/Codex for the rest of the week.
- Guard a reserve (~15%) for a late-week emergency. Hitting the weekly cap
  on Thursday because Monday was spent on polish is the failure mode.

## Rule 5 — The noticeable-difference test still governs

Before any premium-model turn: "will I notice the result being worse if I
skip this?" Polish rounds, re-explanations, and "make it a bit better"
fail the test. Unspent quota rolls into real work later in the week;
spent quota never comes back.

## The one metric

Accepted results per week per quota spent. If it drops, the fix is a
better brief or a cheaper route — never "more turns".
