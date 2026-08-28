# 5. Phases

Run in order. Do not begin a phase before the previous one is complete.

### Phase 1 — Context

- Repo conventions: `CLAUDE.md` at the repo root (deep only; light reuses what the
  diff needs). Read `AGENTS.md` only if `CLAUDE.md` is absent.
- PR title and body: stated intent and acceptance criteria.
- Tracker ticket: extract `[A-Z][A-Z0-9]+-\d+` from `headRefName` or title. If found,
  one `tracker_fetch_issue` call (HOST.md, Optional MCP). If the capability is
  absent or no ID exists, note it and continue on the PR body alone.

### Phase 2 — Plan

Pick axes from the table below by diff shape. In chat, one short line before
you review: which axes you are running, which you skipped and why.

Axes 4, 8 and 10 are **never** skippable. "Diff is large" is not a valid reason to
skip an axis — it reduces files read, which the Coverage block must declare.

| Axis | Runs when | Deep | Light |
|---|---|---|---|
| 3. Requirements | ticket or AC exists | ✅ | only if new diff touches AC surface |
| 5. Contract & data | diff touches service, hook, type, endpoint, migration, schema | ✅ | ✅ |
| 6. Security & permissions | diff touches auth, RBAC, token, storage, user input, URL, upload, impersonation, SQL, `$queryRaw` | ✅ | ✅ |
| 7. Tests | diff adds logic | ✅ | ✅ |
| 9. Perf | diff touches list, render path, query, effect, loop | ✅ | only if new diff is exactly that |

### Phase 3 — Requirements

Map each acceptance criterion to code in the diff. Report an AC that the diff
claims to satisfy but does not, and behaviour added beyond the ticket that changes
existing flows. Wording mismatches are nits — silent.

### Phase 4 — Correctness & regression (never skipped)

For each changed exported symbol, find who else uses it:

```
code_graph_explore  →  "<ChangedSymbol> <OtherSymbol> callers"
```

`code_graph_explore` is HOST.md, Optional MCP. Absent → `Grep` the symbol name,
same cap. Then check:

- signature, prop, return-shape or enum change that its callers do not handle
- null / undefined reaching a call that assumes a value
- state that is not reset between runs (retry, pagination, wizard step, filters)
- stale closure or missing dependency in `useEffect`, `useCallback`, `useMemo`
- React Query: wrong or missing key member, mutation without invalidation,
  missing `enabled` guard on a dependent query
- async ordering: unawaited promise, race between two writes, unmounted-component
  update
- early return that skips required cleanup or a required write
- off-by-one and empty-collection paths in new logic
- broad `catch` (`Error`, `unknown`, or untyped) that can hide an unexpected failure
- `?.` skipping an operation that must run

### Phase 5 — Contract & data

Request and response shape versus the type, error branch handled, pagination and
default values, nullable field treated as required, migration reversibility and
backfill, id or tenant scoping on every query that touches shared tables.

Spreading the request body into a write is mass assignment. **Blocker** if that
can set role, tenant, price, or a flag/permission. Otherwise drop.

New or changed types only: an optional-field bag that admits illegal combinations
(e.g. `{ done?: boolean; doneAt?: Date }`) is a **nit**. **Major** only if the
same diff already uses `as` or `!` to paper over it. Skip when the diff does not
create or change a type.

### Phase 6 — Security & permissions

Permission checked on the actual action rather than only in the UI, token or secret
in logs or query strings, user input concatenated into SQL (`$queryRaw`,
string-built query), HTML, shell, or href, redirect target validated, object
ownership verified before read or write, PII in analytics or Sentry payloads.
String-built SQL/HTML/shell/href with user input is a **major**. A proven exploit
with a concrete trigger stays a **blocker**.

### Phase 7 — Tests

New meaningful logic with no test is a **major**. Also: test asserts a mock instead
of behaviour, error path untested, `it` description missing the `should` prefix
(project rule), test disabled or skipped in the diff. New validation covered only
by a happy-path test is a **nit**.

### Phase 8 — Standards (never skipped)

Only rules written in the repo's `CLAUDE.md` / `AGENTS.md`. Quote the
rule you are applying. A repo rule broken is a **major**; a style
preference not written down is a nit.

Structure checks also run here. They are not repo rules. No extra reads.

- **1k-line crossing (nit).** A changed file that is ≥1000 lines at HEAD and was
  <1000 before this PR. `before ≈ head_lines - additions + deletions` from the
  Read line count and that file's diff stats. Skip files you did not Read. Skip
  lockfiles and generated snapshots. Files already over 1k stay silent.
- **Bolted special-case.** A new `if`, flag, or nullable inserted into a flow
  that does not own the feature. **Major** only with a concrete path, the extra
  branch, and what happens. No path or no trigger → drop.
- **Code judo (nit, max 1).** A visible way to delete a layer, branch, or helper
  without changing behaviour. Name what to delete. No concrete deletion → drop.
  Does not block. At most one per run.
- **Nested ternary / deep nesting (nit).** A new nested ternary, or new nesting
  that an early return would flatten. Skip pre-existing nesting the PR only
  touches.
- **Lying or slop comments (nit).** A comment this PR added or changed that
  contradicts the code, or only restates it. Do not ask for new comments.

### Phase 9 — Perf

Only concrete and reachable: unbounded query or list render, work in a render body,
N+1 request in a loop, a new effect that refetches on every render. Anything
requiring a benchmark to prove is a nit.

### Phase 10 — Self-verify (never skipped)

No new reading in this phase. Every surviving finding must carry all four fields:

```json
{
  "severity": "blocker | major",
  "path": "src/x.ts",
  "line": 42,
  "in_diff": true,
  "title": "Retry count keeps old value.",
  "trigger": "concrete condition — input, state, call order",
  "impact": "what the user or system observes",
  "fix": "one imperative sentence",
  "refutation": "strongest argument that this is not a bug, and why it fails"
}
```

Cut rules, biased toward refutation:

- no concrete `trigger` → **drop in silence**
- `refutation` holds → **drop in silence**
- depends on behaviour outside this repo (api-v2 contract, flag, production data)
  → move to `uncertainties`
- an uncertainty causes DEFER **only** if, were it true, it would be a blocker.
  Uncertainty about a major or a nit disappears.
