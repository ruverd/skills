# `/ruver-create-pr-frontend` · `/ruver-create-pr-backend`

Draft a PR **description**. Do **not** open the PR. The author runs
`gh pr create`.

| Command | Repo |
|---|---|
| `/ruver-create-pr-frontend` | frontend (React app layout) |
| `/ruver-create-pr-backend` | backend (API layout) |

Skills:
[`ruver-create-pr-frontend`](../../plugins/ruver/skills/ruver-create-pr-frontend),
[`ruver-create-pr-backend`](../../plugins/ruver/skills/ruver-create-pr-backend).

These two are **product extras** (wired for empath-ui / empath-api-v2
detection). The core graphs do not depend on them.

## When

- “create a PR description” / “draft PR body”
- Optional arg: dependent PR URL

## Pipeline

```
SETUP → ANALYZE (parallel: spec, diff, coverage, risk, impact)
  → unresolved ACs (pt-BR, one at a time)
  → WRITE → RENDER one fenced markdown block
```

Final body is English. Prompts to the author are pt-BR.

## Never

- Auto `gh pr create`.
- Auto `/ruver-code-review`.
- Invent ACs, UI flows, or test steps that are not in the diff.
- Run the frontend command in a backend repo (and vice versa).

## Related

[`/ruver-validate-branch`](ruver-validate-branch.md) ·
[`/ruver-code-review`](ruver-code-review.md)
