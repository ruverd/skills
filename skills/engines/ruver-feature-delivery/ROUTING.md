# Routing

Do this after `mcp_context`. Evidence first, not "everything is a feature".

## Classification

Write into STATE:

```yaml
work_kind: feature | bug | regression | chore | spike
path: full_feature | debug_fix | light_change
scope: frontend_only | backend_only | fullstack
route_confidence: alta | media | baixa
route_reason: "..."
```

| Looks like | path |
|---|---|
| New behavior, UX, or a rule that needs grilling | `full_feature` |
| Bug, regression, red test, "X is broken" | `debug_fix` |
| Chore, rename, 1–2 obvious files, no product fork | `light_change` |

If the ticket is both a bug and a redesign: DECIDE `debug_fix` when the AC is "restore X"; DECIDE `full_feature` when Linear asks for new behavior. Do not ASK the path.

`debug_fix` never skips root cause. If diagnose finds a missing feature, re-route to `full_feature` (grill).

`light_change` still TDD if behavior changes. If you cannot write a failing test, upgrade the path yourself (DECIDE). Do not ASK to upgrade.

## Scope

| scope | When |
|---|---|
| `frontend_only` | this git root is UI only |
| `backend_only` | this git root is API only |
| `mono` | UI and API in **this** git root |
| `fullstack` | ticket needs both sides **and** a sibling resolved ([PRODUCT.md](PRODUCT.md)) |

Signals: new endpoint + screen; "backend and frontend"; AC on both repos.

On fullstack, `path` applies **per worker**.

## Paths

### `full_feature`

```
triage → grill → spec → tickets → implement* (TDD) → review → tester
       → blast → quality (thermo) → shipper → ci_watch
```

Use when: new feature, multi-file design still open, high blast radius (auth, billing, contract).

### `debug_fix`

```
triage → diagnose → one ticket (RED repro) → implement → review → tester
       → blast → quality → shipper → ci_watch
```

Skip grill and multi-ticket split. Do **not** skip root cause, TDD, review, thermo.

Iron law: no product fix before root cause.

### `light_change`

```
triage → one ticket → implement → review → tester → quality → shipper
```

Skip grill and blast. Still a subagent for product code. Docs-only outside `src/` may be edited on the main thread.

### `spike`

Read-only diagnose. `done_report`. No PR. If it is a bug, re-route `debug_fix`. If it is a feature, re-route `full_feature`.

## Stages

| Stage | full_feature | debug_fix | light_change |
|---|---|---|---|
| triage | yes | yes | yes |
| grill | yes | no | no |
| diagnose | no | **required** | no |
| spec + tickets | yes | one ticket | one ticket |
| TDD | yes | yes (repro test) | if behavior |
| review | yes | yes | yes |
| tester | yes | yes | yes |
| blast-radius | yes | yes | no |
| thermo fix all | yes if ship | yes if ship | yes if ship |

## Anti-patterns

- full_feature on a null-check
- Quick fix of a bug with no diagnose
- Skipping TDD because "I reproduced it by hand"
- Skipping thermo when a PR will open
- Staying on debug_fix after you found a missing feature
