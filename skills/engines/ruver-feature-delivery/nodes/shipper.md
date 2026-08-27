# Node: shipper

**Verb:** package
**Capability:** git commit + push + draft PR; **never** merge
**Does not** mark final delivery alone — **ci_watch** closes done.

## Mission

After quality ok: commit → push → draft PR.
Then the orchestrator runs **ci_watch** if a PR/MR exists.

## Sequence

1. Pre-checks: review pass, tester pass, quality fix-all + hard_gate_after pass —
   confirm exit codes in `.ruver-feature-delivery/gates.log` if it exists.
2. Branch == tracker branch if set.
3. Forge from [PRODUCT.md](../PRODUCT.md). `github` → `gh`. `gitlab` → `glab`. `git` → push only, no PR (`done_local` unless the user insisted).
4. Idempotency: list PRs/MRs on this head. Exists → update, do not recreate.
5. Commit (cite ticket id if any). **No Co-Authored-By, no "Generated with", no trailers.**
6. Push (`-u`, no force).
7. Draft PR/MR with the ticket link (body via repo `pr-description` skill if it exists).
8. **Reviewers + assignee** per PRODUCT.md.
   ```bash
   ME=$(gh api user --jq .login)   # or glab equivalent
   gh pr create --draft --title "..." --body "..." \
     --assignee "${ASSIGNEE:-$ME}"
   ```
   One failed reviewer request must not block the rest. Never pass
   `git user.name` to `--assignee`.
9. STATE: PR/MR URL; `ci.status: pending`.
10. **Hand off to ci_watch** when a PR/MR exists.
11. Short English summary: "PR open; waiting on CI green to deliver."

## Done

| Situation | graph `status` |
|---|---|
| PR + CI green | **`done`** (delivered) |
| PR + CI pending/red | `shipping` / `ci_watching` — **not** delivered |
| `--no-pr` + quality ok | `done_local` or done with note "no PR CI" |

## Hard rules

- Never merge / force-push.
- Never "delivered" with failing checks.
- Fullstack: ship per repo + ci_watch on **each** PR.
- Every PR (create or update): reviewers/assignee per PRODUCT.md.
