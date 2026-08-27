# `/ruver-validate-branch`

Pre-PR (or existing-PR) **local** validation. Take a branch from
“I think it’s done” to typecheck/lint/tests green, then ask before
push.

Skill: [`plugins/ruver/skills/ruver-validate-branch`](../../plugins/ruver/skills/ruver-validate-branch).

## When

- `/ruver-validate-branch`
- `/ruver-validate-branch https://github.com/org/repo/pull/99`
- “ready to push?” / “validate this branch”

## Pipeline

```
SETUP → ANALYZE (parallel auditors) → DECIDE
  → ambiguities (pt-BR, one at a time)
  → FIX → simplify → tests → VERIFY
  → ask before push / PR
```

Pre-PR mode stays local until the author confirms push. PR mode
pushes then loops [`/ruver-code-review`](ruver-code-review.md) until
APPROVE (cap 5).

Auditors are read-only. The graph engineer applies fixes.

## Never

- Push or open a PR without an explicit yes in pt-BR.
- `git push --force`.
- Amend the author’s commits.
- Finish with a red build.

## Related

[`/ruver-code-review`](ruver-code-review.md) ·
[`/ruver-create-pr-frontend`](ruver-create-pr.md)
