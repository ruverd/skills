# Code-review graph

```
start (PR url / number / branch)
  → resolve           # SKILL §1–§2
  → wait_ci           # required CI pending — 5m loop, no PR comment
  → review            # SKILL §4–§11
  → defer             # CI red / unknown / draft / conflict — issue comment
```

## Edges

| From | Condition | To |
|---|---|---|
| start | always | **resolve** |
| resolve | CLOSED or MERGED | **stop** |
| resolve | draft or conflict | **defer** |
| resolve | `ci_overall` pending | **wait_ci** |
| resolve | `ci_overall` failure or unknown | **defer** |
| resolve | `ci_overall` success | **review** |
| wait_ci | still pending | **stop** (loop wakes in 5m) |
| wait_ci | success | **review** |
| wait_ci | failure or unknown | **defer** |
| wait_ci | CLOSED or MERGED | delete loop, **stop** |
| review | posted | delete loop, **stop** |
| defer | posted | delete loop, **stop** |

`--force` skips the CI rows (pending / failure / unknown) and goes to **review**.
`--dry-run` never creates a loop and never posts.

## Nodes

`nodes/wait_ci.md` · wait mechanics in [LOOP.md](LOOP.md)

Review and defer stay in [SKILL.md](SKILL.md) §4–§11 and §9.
