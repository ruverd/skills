# `/ruver-feature-delivery`

Alias: `/ruver-fd`.

Delivery **engine** inside [`/ruver-developer`](ruver-developer.md).
Grill → spec → tickets → TDD implement → review → CI. The main thread
still does not write product code.

Skill: [`../../skills/engines/ruver-feature-delivery`](../../skills/engines/ruver-feature-delivery).

## When

- `/ruver-fd ABC-123`
- `/ruver-fd null crash in MembersTable`
- `/ruver-fd resume`
- `/ruver-fd … --no-pr`
- Implicitly, from developer `deliver`

Prefer `/ruver-developer` when you also want MERGEABLE + QA after CI.
`/ruver-fd` alone stops at CI green (it does **not** call QA).

## Spine

```
grill-with-docs → spec → tickets → implement (TDD) → review → tester
  → blast → quality → shipper → CI
```

| Path | When |
|---|---|
| `full_feature` | new behavior |
| `debug_fix` | bug — diagnose first, one TDD ticket |
| `light_change` | chore — one ticket, one coder |
| `scope: fullstack` | FE and BE, same branch |

Grill, spec, and tickets stay on the **main thread**. Implement /
tester / quality / shipper are workers (`ruver-fd-coder`, …).

## What “delivered” means here

Draft PR **and** required CI green. Until then `status ≠ done`.
Reviewers and assignee: [PRODUCT.md](../../skills/engines/ruver-feature-delivery/PRODUCT.md).

## Never

- Merge.
- Product edits on the main thread.
- Skip TDD on a behavior change.
- Skip quality `fix all` before the PR.
- Invent Linear AC when MCP is down — stop.

## Related

[`/ruver-developer`](ruver-developer.md) · [`/ruver-goal`](ruver-goal.md) ·
workers in the [README catalog](../../README.md#agents)
