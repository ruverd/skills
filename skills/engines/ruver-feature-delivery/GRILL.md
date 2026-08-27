# Grill (Matt Pocock, last-resort ASK)

Source: bundled `grill-with-docs` + `grill-me` (`skills/lib/`).
This file is the adapted loop. Policy: [DECISION_POLICY.md](DECISION_POLICY.md).
Formats: [CONTEXT-FORMAT.md](../../lib/grill-with-docs/CONTEXT-FORMAT.md),
[ADR-FORMAT.md](../../lib/grill-with-docs/ADR-FORMAT.md).

ASK is last resort: very important **and** high uncertainty, after lookup.

## Goal

Walk the design tree until the frontier is empty. For each question: look it up, recommend, **apply**. Do not interview the user through the tree.

## Loop

1. Compute the frontier.
2. For each item, look it up (`how` / `why` / Linear / neighbor code / CLAUDE.md). Never ask a fact.
3. Write a recommendation.
4. **DECIDE**, log, recompute frontier. Chat one line in the S/D/P rollup.
5. ASK only if the last-resort test passes. One question. `waiting_user`. Next user message (or `/ruver-developer resume`) is the answer. Continue. Do not restart.
6. Frontier empty → **spec**. Never "close the grill?".

Most runs never hit step 5.

Load bundled `how` / `why` for the subsystem you will touch, not the
whole monorepo. One pass. Do not spawn a how-explorer swarm on a small
change. Do **not** run vanilla grill-with-docs interview-and-wait.

New module: run `architect`. Take the synthesized sketch (DECIDE). Checkpoint only as last-resort policy.

## ASK format (rare)

Speak in English:

```
Q: <only the tie lookup did not break>

A. ...
B. ...

Recommendation: A, because <fact>.
I am asking because: important + high uncertainty after <paths / Linear>.
```

## Docs (grill-with-docs)

Read, in order, whatever exists:

1. `CONTEXT.md` (only if already in the repo)
2. `CLAUDE.md` / `AGENTS.md`
3. nearest `src/**/CLAUDE.md`
4. `docs/en-US/` or `docs/adr/` if the area has them

Code vs ticket wording: the code + docs win unless Linear AC explicitly overrides. DECIDE. ASK only if both readings are still plausible **and** the fork is very important.

Do **not** create a new `CONTEXT.md` or ADR in the git repo unless that tree already exists. Domain terms go in STATE `## Decisions`. If `CONTEXT.md` / `docs/adr/` already exist, update them lazily (domain language only).

ADR when hard to reverse + surprising later + real trade-off. Write it on DECIDE. Do not ASK for permission to write an ADR.

## UI

DS of the repo. Figma if the ticket has it. No Figma → copy 2–5 recent same-type screens. Record those paths. Do not invent visual.

## Ungrillable

Feel, layout, "one page or three": prototype, then DECIDE the smaller option that matches existing screens. ASK only if the prototype still leaves a last-resort fork.

## Done

Frontier empty → spec. short English rollup of decisions.
Append rows to `decisions.tsv` (bundled `show-me-your-work` TSV format).
