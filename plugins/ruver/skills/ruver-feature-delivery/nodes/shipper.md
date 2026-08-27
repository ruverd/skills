# Node: shipper

**Verb:** package
**Capability:** git commit + push + draft PR; **never** merge
**Does not** mark final delivery alone — **ci_watch** closes done.

## Mission

After quality ok: commit → push → draft PR.
Then the orchestrator **always** runs **ci_watch** if `open_pr: true`.

## Sequence

1. Pre-checks: review pass, tester pass, quality fix-all + hard_gate_after pass —
   confirm exit codes in `.ruver-feature-delivery/gates.log` if it exists.
2. Branch == `linear_branch` if Linear.
3. Idempotency: `gh pr list --head <branch>` — PR already exists → update, do not recreate.
4. If skill `/ruver-validate-branch` exists in the environment: run it BEFORE push;
   failed → stop.
5. Commit (cite DEV-XXXX). **No Co-Authored-By, no "Generated with", no trailers.**
6. Push (`-u`, no force).
7. Draft PR (default) with Linear link (body via repo `pr-description` skill if it exists).
8. **Reviewers + assignee (required on create and update):**
   ```bash
   # create
   gh pr create --draft \
     --title "..." --body "..." \
     --reviewer izaiasneto4,samuelfaj,chrislong365,AirtonSth,PauloMendees \
     --assignee ruverd

   # PR already exists (idempotency)
   gh pr edit --add-reviewer izaiasneto4,samuelfaj,chrislong365,AirtonSth,PauloMendees \
     --add-assignee ruverd
   ```
   Fixed list (do not omit): `izaiasneto4`, `samuelfaj`, `chrislong365`, `AirtonSth`, `PauloMendees`.
   Assignee always: `ruverd`.
   If one reviewer fails (outside the org / already requested), record it in the summary and continue with the rest — **do not** block the ship.
9. STATE: PR URL; `ci.status: pending`.
10. **Hand off to ci_watch** (required with a PR).
11. Short Brazilian Portuguese summary: "PR open; waiting on CI green to deliver."

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
- Every PR (create or update): fixed reviewers above + assignee `ruverd`.
