# Decision policy

Talk to the user **as a last resort**. Almost every call is **DECIDE**.

ASK only when **both** are true:

1. **Very important.** Hard to reverse, or it changes product / security / money / tenant / public API in a way the ticket does not already settle.
2. **High uncertainty.** After reading the repo, Linear, and (if needed) a prototype, you still cannot defend a recommendation.

Importance alone is not enough. Uncertainty on a small call is not enough. Pick the smaller local option, log it, continue.

## Three modes

| Mode | When | Action |
|---|---|---|
| **DECIDE** | Default. You have a recommendation you can defend, or the call is not that important | Choose, log, continue. Do not wait. |
| **ASK** | Last resort: very important **and** high uncertainty | One question in Brazilian Portuguese. Show the recommendation. Wait. Then continue. |
| **ESCALATE** | Loops exhausted, missing critical MCP, cannot run the graph | Freeze. Summarize in Brazilian Portuguese. Wait. |

Before ASK, spend the lookup: `how` / `why` / Linear / neighbor files / a throwaway prototype. If that produces a rec you would ship, **DECIDE**.

Test: would you stop a senior engineer at 11pm for this. If no, DECIDE.

## How to DECIDE when you are not 100% sure

Prefer, in order: stated Linear AC, existing pattern in the same feature, YAGNI (smaller change), CLAUDE.md / AGENTS.md / TypeBox / module isolation.

Log residual risk. Do not convert leftover doubt into a question.

## ASK (last resort only)

All of these must hold:

- Very important (auth / tenant / PII / money / destructive migration, or a product fork Linear does not settle).
- High uncertainty (two+ options with similar force; looking it up did not break the tie).
- Last resort (you already tried repo + Linear + prototype if the question is ungrillable).

If any bullet fails: **DECIDE**.

Forbidden ASK:

- "Which seam?"
- "Full feature or bug?" when the ticket title already says.
- "Close the spec / grill?"
- Rubber-stamping a recommendation you already believe.
- Path choice when ROUTING.md already classifies it.
- Anything you asked because the topic felt important.

TDD looking impossible without a redesign: ASK the redesign. Do not skip TDD.

## How to ASK

Brazilian Portuguese. **One question.** Then `waiting_user`. After the answer, DECIDE the rest. Do not restart.

Shape (speak this in Brazilian Portuguese):

```
Q: <only the tie lookup did not break>
A. ...
B. ...
Recommendation: A, because <fact>.
I am asking because: important + high uncertainty after <paths / Linear>.
```

## Grill vs implement

Grill decides internally. Implement does not reopen the plan. `NEEDS_CONTEXT` from a coder: parent DECIDE from spec + repo. ASK only if that too is last-resort.

## Facts

Never ask for a fact you can grep. Missing Linear on a **fresh Empath start**: you may run as a local goal, but prefer the ticket id if the user gave one. Do not invent ACs.

## Anti-invention

- Do not invent a lib, state pattern, folder, or abstraction if a neighbor already solves it.
- Do not "improve the architecture" outside the goal.
- Do not skip TDD because "it is simple".
- Do not invent product AC. If it is missing, ASK or escalate with an explicit testable hypothesis.
- UI: do not invent visual. [UI_DESIGN_SYSTEM.md](UI_DESIGN_SYSTEM.md).
- Missing contract: [BLOCKERS.md](BLOCKERS.md). Do not fake the endpoint.

## Log

STATE → `## Decisions`:

```markdown
- **ISO-TIME | DECIDE|ASK**
  - **Choice:** ...
  - **Who:** agent | user
  - **Confidence:** high | medium | low
  - **Evidence:** path or Linear id
  - **Residual risk:** ...
```

Also append `decisions.tsv` when grilling. Chat a short rollup of auto-decisions. Do not hide DECIDE.

## Escalate

1. STATE `status: escalated`. No new dispatch.
2. Brazilian Portuguese summary: PR / ticket / red checks.
3. Optional Linear comment with the same summary.
4. End the turn. Resume at the named node.

Slice loop exhaustion (`review_fix_loops` / `test_fix_loops`): mark the ticket `blocked` and escalate. Never skip to the next ticket or to shipper.
