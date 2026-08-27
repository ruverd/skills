# Skill map

This graph does **not** use Superpowers as the spine
(`brainstorming`, `writing-plans`, `subagent-driven-development`,
`systematic-debugging`).

Spine is Matt Pocock, adapted, plus **pstack**:

```
grill-with-docs → to-spec → to-tickets → implement(/tdd) → code-review
```

Bugs: `diagnose` (then one implement ticket). Ungrillable feel: `prototype`, then DECIDE.

## Matt Pocock (local skills)

These names exist on this machine. Load the skill, then follow the **adapted** node.

| Skill on disk | Node | Adaptation |
|---|---|---|
| `grill-with-docs` + `grill-me` | `grill` | Recommend + follow. ASK last resort. See [GRILL.md](GRILL.md). Vanilla "ask every branch and wait" is **off**. |
| `to-prd` | `spec` | Synthesize only. Write local `SPEC.md`. Do **not** publish a PRD to Linear. |
| `to-issues` | `tickets` | Vertical slices into local `TICKETS.md`. Do **not** create Linear issues here. [BLOCKERS.md](BLOCKERS.md) is the only Linear-create path. |
| `tdd` (pstack) + this graph's [TDD.md](TDD.md) | `implement` | Iron law wins. Do not skip RED because pstack tdd says the path is expensive. |
| `diagnose` | `diagnose` | Root cause. No product fix in this node. |
| `handoff` | `handoff` | Limit near / other runtime. |

`implement` does not reopen the plan. That is the point.

Do **not** start this graph with `using-superpowers`.

## pstack (used)

| Skill | Where |
|---|---|
| **unslop** | all chat, specs, PR text ([VOICE.md](VOICE.md)) |
| **how** | before changing a subsystem (`grill`, `diagnose`, `review`) |
| **why** | before changing an existing shape |
| **blast-radius** | `blast` node, before quality/ship |
| **architect** | non-trivial new module during grill; checkpoint only as last-resort ASK |
| **interrogate** | after spec, before implement, on `full_feature` |
| **show-me-your-work** | `decisions.tsv` under `$RUVER_ROOT/.ruver-feature-delivery/` |
| **figure-it-out** | diagnose, when no narrower playbook fits |
| **tdd** | complements [TDD.md](TDD.md). Iron law still wins. |
| **no-comments** | review |
| **typescript-best-practices** | review, any `.ts` / `.tsx` |
| **technical-writing** | spec, PR body |
| **principle-prove-it-works** | tester. Done is a falsifiable command + exit code. |
| **principle-sequence-verifiable-units** | tickets: one vertical slice, verify before the next |
| **principle-model-the-domain** | grill-with-docs |
| **principle-exhaust-the-design-space** | architect: ≥2 whole shapes; DECIDE when one is clearly better |
| **principle-guard-the-context-window** | one ticket per implement subagent |
| **principle-fix-root-causes** | diagnose before fix |
| **principle-type-system-discipline** | review on TypeBox / Prisma / TS diffs |

## Empath extras (keep)

| Skill | Where |
|---|---|
| **thermo-nuclear-code-quality-review** | `quality` node, `fix all`, before shipper |
| **UI_DESIGN_SYSTEM** | grill / spec / implement / review when UI |

## pstack (not the spine)

| Skill | Why not |
|---|---|
| principle-never-block-on-the-human | Mechanical work may proceed. Real last-resort doubt still ASKs. |
| arena / swarm | Optional inside architect. Do not fan out coders on one checkout. |
| bro / poteto-mode | Tone. Unslop already owns voice. |
| recall / reflect / teach / automate-me | Outside delivery. |
| ruver-code-review | Outer PR review graph. Slice review is `nodes/reviewer.md`. |

## Superpowers (not the spine)

Keep the TDD **iron law** from `test-driven-development` inside [TDD.md](TDD.md).
Do not run brainstorming, writing-plans, systematic-debugging, or SDD as the graph.
