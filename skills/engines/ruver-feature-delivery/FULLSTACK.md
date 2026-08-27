# Full-stack (frontend + backend) via Orca orchestration + worktrees

When the task spans **frontend and backend**, the orchestrator **does not**
implement everything in one repo. It uses **Orca orchestration** + **worktrees**
on **both** repositories, with the **same branch**.

Ticket/design context still comes from the **project MCP** (Linear/Figma/…).
Orca **coordinates workers and worktrees**. It does not replace Linear MCP.

## 1. Detect full-stack

Set `scope: fullstack` if **any** of these is true:

- Ticket/goal mentions API + UI, endpoint + screen, backend + frontend
- Labels/AC ask for a REST/GraphQL contract change **and** UI consumption
- Related tickets / paths in both repos
- User explicitly says "fe+be", "api and ui", "two repos"

Otherwise: `scope: frontend_only | backend_only | mono` (current single-repo path).

Repos in STATE:

```yaml
scope: fullstack
repos:
  frontend: empath-ui   # or Orca path/selector
  backend: empath-api-v2
branch: feature/dev-1212   # SAME on both
```

Empath defaults (adjust if the project is different):

| Role | Typical Orca project / repo |
|---|---|
| Frontend | `github:empathmsp/empath-ui` / empath-ui |
| Backend | `github:empathmsp/empath-api-v2` / empath-api-v2 |

Discover with `orca project list --json` if the defaults do not match.

## 2. One branch

Branch name (same string on **both** repos):

1. Linear `gitBranchName` if it exists
2. else `feature/<id-lowercase>` → `feature/dev-1212`

**Forbidden:** `feature/dev-1212-ui` vs `feature/dev-1212-api` unless the user asked.

## 3. Orca worktrees (both repos)

Load live guides (do not invent flags):

```bash
orca skills get orca-cli
orca skills get orchestration
orca status --json
```

Create a worktree **per repo** with the **same** `--name` (= branch):

```bash
# Backend
orca worktree create \
  --repo name:empath-api-v2 \
  --name feature/dev-1212 \
  --base-branch main \
  --linear-issue DEV-1212 \
  --json

# Frontend
orca worktree create \
  --repo name:empath-ui \
  --name feature/dev-1212 \
  --base-branch main \
  --linear-issue DEV-1212 \
  --json
```

Notes:

- Prefer selectors from `orca project list` / `orca worktree list` if `name:` fails
  (e.g. `--project github:empathmsp/empath-ui`).
- `--name` = working branch aligned on both.
- If a worktree with that name already exists, reuse it (`orca worktree list --json`).
- Store paths/handles in STATE: `worktrees.backend`, `worktrees.frontend`.

Fallback **only if Orca worktree is unavailable** (document in STATE):

```bash
git -C <backend-root> worktree add ../empath-api-v2-feature-dev-1212 -b feature/dev-1212 origin/main
git -C <frontend-root> worktree add ../empath-ui-feature-dev-1212 -b feature/dev-1212 origin/main
```

User preference: **Orca worktrees**, not a silent fallback.

## 4. Orchestration (coordinator)

The experimental orchestration feature must be on. Minimal flow:

```bash
orca orchestration run-create --json
# keep run_id

# Backend task (contract first, if the UI depends on the API)
orca orchestration task-create \
  --task-title "BE DEV-1212: ..." \
  --spec "<backend spec: endpoints, migrations, TDD, worktree path, branch feature/dev-1212>" \
  --run <run_id> --json

# Frontend task (deps = [backend_task_id] if the contract must exist)
orca orchestration task-create \
  --task-title "FE DEV-1212: ..." \
  --spec "<frontend spec: UI DS, consume API, TDD, worktree, SAME branch>" \
  --deps '["<backend_task_id>"]' \
  --run <run_id> --json
```

Supervised workers (example — confirm flags with `orca skills get orchestration`):

```bash
orca orchestration worker-start \
  --task <backend_task_id> \
  --worktree new-top-level \
  --repo name:empath-api-v2 \
  --name feature/dev-1212 \
  --base-branch main \
  --agent <claude|codex|...> \
  --run <run_id> --json

orca orchestration worker-start \
  --task <frontend_task_id> \
  --worktree new-top-level \
  --repo name:empath-ui \
  --name feature/dev-1212 \
  --base-branch main \
  --agent <...> \
  --run <run_id> --json
```

Or `--worktree` pointing at worktrees already created (preferred if they exist).

Coordinator:

- `orca orchestration check --wait` / inbox per the skill
- handles `worker_done`, `ask`, `escalation`
- **does not** edit product code in place of the workers — "gates" may edit
  **only** `.ruver-feature-delivery/*` and rebase conflict resolution; never `src/`

### Dep order

| Situation | DAG |
|---|---|
| UI needs a new endpoint/contract | **BE → FE** (`deps`) |
| BE only exposes a field already consumable / FE and BE independent | parallel (no deps) |
| FE only + temporary mock | avoid; prefer BE first if the contract is new |

If BE **has no ticket yet** or the contract is not Done: see [BLOCKERS.md](BLOCKERS.md) —
create a Linear **Draft**, comment the endpoint interface, `blockedBy`, wait until Done,
while advancing what you can on FE (shell/DS).

## 5. Spec each worker receives

Inject into `--spec` / worker prompt:

- worktree path + **identical** branch
- linear-context (AC) — copied file or summary; MCP in the worker if the environment has it
- backend: contracts, migrations, API TDD
- frontend: UI_DESIGN_SYSTEM + Figma + contract consumption
- **never merge**; draft PR at the end if open_pr
- thermo fix all in that worker's repo before shipping that repo

## 6. Dual ship + CI green

For **each** repo, after worker_done ok:

1. quality / thermo in that repo's worktree
2. commit + push on the **same** branch
3. draft PR (base main) linking Linear + the sibling PR
   - reviewers/assignee from each repo's `AGENTS.md`
4. **ci_watch** on **each** PR (`gh pr checks` until green) — [CI_DELIVERY.md](CI_DELIVERY.md)

**Delivered** only when **FE and BE** are green.

STATE:

```yaml
prs:
  backend: https://github.com/.../pull/N
  frontend: https://github.com/.../pull/M
ci:
  backend: green|pending|fail
  frontend: green|pending|fail
```

## 7. Integration in the Ruver graph

```
mcp_context → triage
  if scope=fullstack:
    → fullstack_setup (worktrees + run + tasks)
    → orchestration workers (BE/FE)
    → aggregate results → dual ship
  else:
    → current single-repo path
```

Triage writes `scope`. Node/orchestrator writes `worktrees` + `run_id`.

## 8. Anti-patterns

- Implementing BE+FE only in the frontend repo
- Different branch names across repos
- Worktree in only one repo
- "Handoff" without orchestration when the user asked to coordinate FE+BE
- Generic local subagent **instead of** `orca orchestration` for dual-repo
- Using `orca linear` to read the ticket (Linear MCP wins)

## 9. Checklist

- [ ] `scope: fullstack` detected and logged
- [ ] unique branch name
- [ ] Orca worktree FE + BE with the same name
- [ ] run + tasks + workers via orchestration
- [ ] BE→FE deps if the contract is new
- [ ] draft PRs on both (if open_pr)
- [ ] English summary with paths, branch, 2 PRs
