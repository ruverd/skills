---
name: ruver-code-review
description: >
  Adaptive PR review via gh. One PR: main thread. Two or more PRs: one fresh
  subagent per PR (full skill each), orchestrator only resolves list and
  aggregates chat summary. Pending required CI waits 5m (no PR comment) then
  reviews on green; defers on CI red, draft, or conflict. Deep then light on
  SHA history. One artifact per PR: REQUEST_CHANGES / APPROVE / DEFER.
  Use when /ruver-code-review with URL(s), number(s), or current branch.
---

# Ruver Code Review

Sequential phases per PR. Depth adapts to review history.
**Multi-PR:** one subagent per PR (see §0).
**CI fork:** [GRAPH.md](GRAPH.md) · [LOOP.md](LOOP.md). Pending required CI
waits 5m and does **not** post. Red CI still DEFERS.

## Invariants — never break

1. **Subagents only when reviewing 2+ PRs in one invocation.** Single-PR stays on
   the main thread. Multi-PR: orchestrator must **not** review diffs itself —
   spawn one fresh subagent per PR, each running this skill for **that PR only**.
2. **Exactly one artifact per PR** — one review (inline comments in the same
   call) or one issue comment. Never both. Never two of either **on the same PR**.
3. **Never APPROVE** while any required check is failed, pending or unknown.
4. **Never invent a finding.** A finding with no concrete trigger is dropped in
   silence — not downgraded, not mentioned.
5. **Nits never block, and most stay silent.** A nit reaches the PR only inside the
   collapsed Nits block (§9), only with a concrete `path:line`, max 5 per run, and
   never changes the verdict. Always silent regardless: praise, generic refactor
   advice, speculative perf, pre-existing debt, anything the diff did not touch.
   "Could be cleaner" is silent except the one code-judo nit in Phase 8, which must
   name a layer, branch, or helper to delete.
6. **Voice.** GitHub text and chat follow **Voice** (just above §9). Teammate
   English on the PR. English in chat. Never caveman. Never a form.
7. **Fixed output template** (§9). Section order never changes; empty sections vanish.
8. **Phases run in order.** Do not start a phase before the previous one is done.
9. **Other reviewers' state is ignored.** An open CHANGES_REQUESTED from someone
   else is never a gate, never a DEFER reason, and never enters the body. Teams
   reply and push instead of dismissing, so that state is noise. Findings come from
   the code at the head SHA, not from review history. Never fetch their threads:
   a problem that still exists is found again by the axes; one that was fixed leaves
   nothing to deduplicate.
10. **My own open findings never expire silently.** A prior finding of mine is
    dropped only after it is re-verified against the head SHA (§4.1).

## Caps

| Budget | Deep | Light |
|---|---|---|
| Full files read | 15 (highest churn first) | 4 (only to confirm a suspicion) + carry-forward re-reads (§4.1, ≤10, outside the cap) |
| Codegraph / caller queries | 8 | 3 |
| Findings published | 10 (blockers first) | 10 |
| Nits published | 5, collapsed block, never inline | 5 |
| Neighbour test files | only when new logic has no test in the diff | same |

Large PR (`additions + deletions > 2500` or `changedFiles > 25`): keep the caps,
review hotspots first (auth, permissions, data writes, migrations, public API,
money, PII), and declare uncovered files in the Coverage block.

---

## 0. Multi-PR fan-out (orchestrator only)

Run this section **once** at the start of the invocation, before any §1–§11 work
that reads a diff.

### 0.1 Parse arguments → PR list

Accept one or more of: PR URL, `owner/repo#N`, bare number (current repo), or empty
(current branch → one PR). Flags (`--deep`, `--light`, `--dry-run`, `--force`) apply
to every PR in the batch.

Normalize into an ordered list of `{REPO, PR}` pairs. Deduplicate by `repo#number`.
If empty after resolve, stop (same as single unresolvable PR).

### 0.2 Branch

| Count | Action |
|---|---|
| **1** | Stay on the **main thread**. Run §1–§11 for that PR. No subagent. |
| **2+** | **Orchestrator mode** — do **not** fetch diffs, run axes, or post reviews on the main thread. Follow §0.3–§0.5. |

### 0.3 Spawn — one fresh subagent per PR

For each PR in the list, spawn a **separate** subagent (parallel when the host allows):

- **Fresh context** — no shared review state between children.
- **Prompt must include:** this skill path / name (`ruver-code-review`), the single
  target (`REPO` + `PR` or full URL), the same flags as the parent, and an explicit
  constraint: **review this one PR only; do not fan out again; do not spawn further
  multi-PR subagents**.
- Each child runs the full skill as a **single-PR** invocation (§1 → §11), including
  gates, publish, and its own chat-style return summary.

Do not batch multiple PRs into one subagent. Do not review "a bit of each" on the
main thread while children run.

### 0.4 Wait and aggregate

Wait for all children (or until the host reports permanent failure). Collect from
each: `repo#pr`, pass, verdict (`APPROVED` / `CHANGES_REQUESTED` / `DEFERRED` /
`SKIPPED` / error), head sha7, findings counts, posted yes/no.

Main-thread chat output is an **aggregate table only** — one row per PR — plus any
spawn failures. Do not re-run the review on the main thread. Do not merge findings
across PRs into one GitHub artifact.

```
# Multi-PR review — N PRs

| PR | Pass | Verdict | Findings | Posted |
|---|---|---|---|---|
| owner/repo#12 | deep | CHANGES_REQUESTED | 1b · 2m | yes |
| owner/repo#15 | light | APPROVED | 0 | yes |
| owner/repo#18 | — | ERROR | — | no — spawn failed |
```

### 0.5 Child failure

| Situation | Action |
|---|---|
| one child fails / times out | mark that row ERROR; still wait for siblings; do not abort the batch |
| all children fail | report all errors; post nothing extra from the orchestrator |
| user cancels mid-batch | stop spawning new children; report completed rows |

Nested multi-PR inside a child is **forbidden**. If a child receives 2+ PRs by
mistake, it must refuse and return ERROR for that spawn.

---

## 1. Resolve

Argument: **one** PR URL, **one** PR number, or empty (PR of the current branch).
If the invocation already listed 2+ PRs, the orchestrator (§0) handled fan-out —
this section only ever sees a single target (main thread or one child).

```bash
gh auth status                       # stop and print output if unauthenticated
gh repo view --json nameWithOwner --jq .nameWithOwner   # → REPO when arg is a number
ME=$(gh api user --jq .login)
```

Flags: `--deep` force deep, `--light` force light, `--dry-run` run everything and
print to chat but post nothing, `--force` review despite non-green CI. `--deep` and
`--light` override §2 only; nothing but `--force` relaxes a §3 gate, and it relaxes
the CI rows alone.

Stop if the repo or PR cannot be resolved. Never guess a repo.

## 2. State → pass decision

```bash
gh pr view "$PR" --repo "$REPO" --json number,title,body,state,isDraft,mergeStateStatus,headRefOid,baseRefName,headRefName,statusCheckRollup,additions,deletions,changedFiles

gh api "repos/$REPO/pulls/$PR/reviews" --paginate \
  --jq "[.[] | select(.user.login==\"$ME\") | {kind:\"review\", state, commit_id, at:.submitted_at, body}]"

gh api "repos/$REPO/issues/$PR/comments" --paginate \
  --jq "[.[] | select(.user.login==\"$ME\" and (.body|test(\"ruver-review:\"))) | {kind:\"comment\", state:\"DEFERRED\", at:.created_at, body}]"
```

Take the artifact with the latest timestamp. Parse its marker:

```
<!-- ruver-review: v=1 pass=deep|light|none sha=<sha> blockers=<n> majors=<n> reason=<slug>
     open=<path>:<line>:<slug>|<path>:<line>:<slug> -->
```

`pass=none` means the run stopped at a §3 gate and **read no code**. Any decision
below that leads to APPROVE must check for a `pass=deep|light` marker first.

`open=` lists every **blocker and major** published by that run, max 10, `-` when
none. Nits never enter the ledger — they are said once and never carried. It is the
carry-forward ledger (§4.1): a light pass must re-verify each entry, because the
incremental diff alone cannot prove a prior finding was addressed. Slugs are short
kebab-case labels of the finding title.

A review without a marker (older tooling, manual review) still counts: use its
`commit_id` as `sha` and its `state` as the verdict.

| Last artifact | Decision |
|---|---|
| none | **deep** |
| `sha == headRefOid`, state APPROVED or CHANGES_REQUESTED | **skip** — post nothing, report in chat |
| `sha == headRefOid`, DEFERRED `pass=deep\|light`, `reason=ci*`, CI now green, `blockers=0 majors=0` | **promote** — §8.1, no diff re-read |
| `sha == headRefOid`, DEFERRED `pass=none` `reason=ci_pending`, CI still pending | **wait_ci** — [LOOP.md](LOOP.md). No new comment. |
| `sha == headRefOid`, DEFERRED `pass=none` (gate), the gated condition is gone | **deep** — nothing was reviewed yet |
| `sha == headRefOid`, DEFERRED, the gated condition still holds (not `ci_pending`) | **skip** — report the same reason in chat, post nothing |
| `sha == headRefOid`, DEFERRED with `reason=uncertainty` | **skip** — needs a human answer or a new commit |
| `sha != headRefOid`, prior marker `pass=none` | **deep** on the full diff — no prior pass to be incremental against |
| `sha != headRefOid`, prior marker `pass=deep\|light` | **light** on `sha..headRefOid` |

A second DEFER for a reason already posted on the same SHA is a duplicate artifact:
skip and report in chat instead. `ci_pending` is never posted; that path is wait_ci.

Skip output is chat-only: state the reason and the SHA. Do not touch the PR.

## 3. Gates — before reading any diff

Nothing below this line reads a diff or a file. Draft, conflict, and CI-red
gates still post one issue comment. Pending required CI does **not** post.
It waits ([LOOP.md](LOOP.md)).

Compute `ci_overall` from the `statusCheckRollup` already fetched in §2:
`failure` if any required check failed, else `pending` if any required check is
pending/queued/in_progress, else `success`. Empty rollup → `unknown`.
What counts as required is in [LOOP.md](LOOP.md) (CI workflow + GitHub-required;
ignore review bots).

| Condition | Action |
|---|---|
| `state` is CLOSED or MERGED | print state, post nothing, stop |
| `isDraft` | DEFER, `reason=draft` |
| `mergeStateStatus` in `DIRTY`, `CONFLICTING` | DEFER, `reason=conflict` |
| `ci_overall` = failure | DEFER, `reason=ci_red`, list ≤8 failing checks with log links |
| `ci_overall` = pending | **wait_ci** — [LOOP.md](LOOP.md). No PR comment. Chat only. Stop. |
| `ci_overall` = unknown | DEFER, `reason=ci_unknown` |

Every gate DEFER carries `pass=none` in its marker — **no code was reviewed**. That
value is what stops §8.1 from later promoting unreviewed code to APPROVE.
`wait_ci` posts nothing, so there is no marker until a later review or DEFER.

`--force` skips the three CI rows only (state, draft and conflict gates never
yield). Use it to review while CI is still running. It also skips `wait_ci`.

## 4. Fetch — pass dependent

```bash
gh pr checks "$PR" --repo "$REPO"        # only for the failing/pending check names
```

**Deep** — full PR diff plus whole changed files:

```bash
gh pr diff "$PR" --repo "$REPO"
```

Then `Read` each changed file in full, highest churn first, up to the cap.

**Light** — incremental diff only:

```bash
gh api "repos/$REPO/compare/$OLD_SHA...$HEAD_SHA" \
  --jq '.files[] | {filename, status, additions, deletions, patch}'
```

`404` or missing SHA (force-push, rebase) → fall back to the full `gh pr diff`,
note `stale_base` in the chat summary, and treat the pass as light anyway.

### 4.1 Carry-forward — light pass only

Every entry in the prior marker's `open=` list must be resolved before this run can
publish. Reads here are **outside** the light file cap, bounded by the 10-entry list.

| Entry | Action |
|---|---|
| its file appears in the incremental diff | re-verify against the new code |
| its file is untouched | `Read` that file at the head SHA and re-verify |
| still reproduces | re-publish it, same severity, suffixed `carried from <sha7>` |
| no longer reproduces | drop it in silence |
| its file was deleted, or the code it pointed at is gone | drop it in silence |

An author reply, a comment, or a pushed commit is **not** evidence that a carried
finding was fixed. Only the code at the head SHA is. A run that cannot re-verify an
entry (file unreadable, cap exhausted) treats it as unresolved and keeps it.

## 5. Phases

Run in order. Do not begin a phase before the previous one is complete.

### Phase 1 — Context

- Repo conventions: `CLAUDE.md` at the repo root (deep only; light reuses what the
  diff needs). Read `AGENTS.md` only if `CLAUDE.md` is absent.
- PR title and body: stated intent and acceptance criteria.
- Linear ticket: extract `[A-Z][A-Z0-9]+-\d+` from `headRefName` or title. If found, one call
  `mcp__linear-server__get_issue`. If the MCP is unavailable or no ID exists, note
  it and continue on the PR body alone.

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
mcp__codegraph__codegraph_explore  →  "<ChangedSymbol> <OtherSymbol> callers"
```

Codegraph unavailable → `Grep` the symbol name, same cap. Then check:

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

## 6. Severity

| Tier | Meaning | Effect |
|---|---|---|
| **blocker** | proven defect, security flaw, broken contract, data loss; request body written into role, tenant, price, or flag/permission | REQUEST_CHANGES |
| **major** | closed list only: new logic without a test; swallowed error or silent catch or masking fallback; missing error or loading state on a new data flow; `any` or cast that erases a real check; documented repo rule broken; contract change leaving callers unhandled; a new special-case branch bolted onto an unrelated flow (concrete path and trigger); user input concatenated into SQL, HTML, shell, or href; broad catch, or `?.` skipping a required operation | REQUEST_CHANGES |
| **nit** | everything else, including the reviewer preferences below | collapsed Nits block, max 5, never blocks |

Introduced or worsened by this PR, and anchored to a changed path. Pre-existing
problems the PR merely touches are nits.

### Reviewer preferences — always nits

Personal standards, not repo rules. They are worth saying once and never worth
blocking a merge over. A preference stated in the repo's `CLAUDE.md` stops being a
preference and becomes a **major** under §6 instead.

- `it(...)` descriptions start with `should`
- names spelled out, not abbreviated — `knowledgeCheck`, never `kc`
- a file this PR pushed from under 1000 lines to 1000 or more
- at most one code-judo nit: name the layer, branch, or helper to delete
- new validation covered only by a happy-path test
- a comment this PR added or changed that contradicts the code, or only restates it
- a new nested ternary, or new nesting an early return would flatten
- a new optional-field bag that admits illegal combinations (no `as`/`!` in the diff)

A preference with no `path:line` in the diff is dropped, like any other nit.

## 7. Coverage — required before APPROVE

One row per changed file with what was verified. Silence is not evidence. A file
left unverified because of a cap is declared and forces **DEFER**, never APPROVE.

## 8. Verdict

Reaching this section means §3 passed, so CI is green — unless `--force` was used.

Carried findings that still reproduce (§4.1) count exactly like new ones. APPROVE
requires zero surviving findings, new **and** carried.

| Findings | Verdict |
|---|---|
| ≥1 blocker (new or carried) | **REQUEST_CHANGES** |
| ≥1 major (new or carried), 0 blocker | **REQUEST_CHANGES** |
| clean, full coverage, CI green | **APPROVE** |
| clean, full coverage, CI not green (`--force` run) | **DEFER** `reason=ci_red\|ci_pending\|ci_unknown`, marker keeps `pass=deep\|light` |
| clean, coverage incomplete | **DEFER** `reason=coverage` |
| blocker-level uncertainty | **DEFER** `reason=uncertainty` |
| empty diff, CI green | **APPROVE**, body says no code changes |

### 8.1 Promote

All must hold: SHA unchanged, prior artifact was a DEFER with `reason=ci*`, its
marker says **`pass=deep` or `pass=light`**, `blockers=0 majors=0`, `open=-`. Then
post APPROVE whose body links the earlier comment. First line: "I already
reviewed this SHA while CI was still running. Checks are green now, so this is
the approve." Marker keeps the prior `pass=` and adds `reason=promote`.

`pass=none` never promotes — that marker proves no code was read. Run a deep pass.

## Voice

Applies to the GitHub artifact and to chat with the user. Does not apply to the
marker HTML, the tables, or the bash.

Write like a teammate who just read the code. Short sentences. Plain words. Name
the file, the condition, and the fix. Use "I" when you are judging ("I would not
merge this until retries reset").

Do not write like a form, a linter, or a status page.

Keep:

- One idea per sentence, or one short sentence plus one that explains it.
- Active voice. "This calls `send` with null", not "null is passed to send".
- When it happens, and what to change. The reader should know what to type.
- English in chat. English on the PR. Always unslop.

Drop:

- Chatbot filler ("happy to review", "great work", "I hope this helps").
- Hedging ("it appears that", "this could potentially", "you may want to consider").
- Em dashes. Use a period or a comma.
- Synonym cycling. Pick "bug" or "break", not both in one paragraph.
- Restating template labels as the comment. `Trigger:` and `Fix:` are for your
  notes in §5 phase 10. On the PR, write sentences.

Do not invent warmth. No praise. No questions that hand the work back
("could you look into this?"). A real open question belongs under Open, and
only when a yes would be a blocker.

Same finding, two voices:

Bad: "This change introduces a potential regression in the retry flow under
certain conditions. It is important to note that `attempts` may not be reset.
Consider resetting it."

Good: "If the user retries after a failure, `attempts` still has the old number
and the cap never fires. Reset it before the new run. I would not merge this
until that path is fixed."

A DEFER is also a sentence: "CI is still red on lint and typecheck, so I did
not read the diff."

A wait_ci chat line: "Required CI is still pending, so I did not read the
diff. Checking again in 5 minutes."

## 9. Publish — one artifact, fixed template

### Review (APPROVE / REQUEST_CHANGES)

One atomic call. Findings with `in_diff: true` become inline comments; every other
finding goes in the body.

```bash
PAYLOAD=$(mktemp /tmp/ruver-review-XXXX.json)   # session scratchpad if one is set
# {"commit_id","event":"APPROVE|REQUEST_CHANGES","body":"...","comments":[{"path","line","side":"RIGHT","body"}]}
gh api "repos/$REPO/pulls/$PR/reviews" -X POST --input "$PAYLOAD"
```

`422` means an invalid position and kills the whole review atomically. Retry
**once** with `comments: []` and all findings in the body, then record
`inline_failed` in the chat summary. No further retries.

### Body template — identical for all verdicts, only the header changes

Section order is fixed. The words inside are Voice, not labels pasted as the comment.

```markdown
## ✅ Approved: <repo>#<pr>

Adds the company seat picker. I did not find a merge blocker.

| | |
|---|---|
| Pass | deep, 1st review |
| CI | green |
| Coverage | 12 of 12 changed files |
| Findings | 1 blocker · 2 majors |

### 🛑 Blockers
1. `src/x.ts:42`. **Retry keeps the old count.** If the user retries after a failure, `attempts` still has the old number and the cap never fires. Reset it before the new run.

### ⚠️ Majors
1. `src/y.ts:10`. Empty list has no test. Add one that asserts the empty state.
2. `src/a.ts:42`. Seat cap is not checked again before the write. Validate there. _(still open from 9b2f1ac)_

### ❓ Open
- I cannot tell if api-v2 returns 409 on a duplicate submit. If it does not, this path double-writes.

<details><summary>Nits (skip these if you want)</summary>

- `src/y.test.ts:14`. The test name should start with `should`.
</details>

<details><summary>Coverage</summary>

| File | Checked |
|---|---|
| `src/x.ts` | logic, contract, tests |
</details>

<details><summary>Skipped axes</summary>

- Perf. No render, query or effect change in the diff.
</details>

<!-- ruver-review: v=1 pass=deep sha=abc1234 blockers=1 majors=2 reason=-
     open=src/x.ts:42:unreset-retry-count|src/y.ts:10:missing-empty-list-test|src/a.ts:42:seat-cap-not-rechecked -->
```

The marker is written on **every** artifact, including gate DEFERs (`pass=none`,
`open=-`). Without it the next run loses the ledger and re-reviews from scratch.

Headers: `## ✅ Approved: <repo>#<pr>`, `## ❌ Changes requested: <repo>#<pr>`,
`## ⏸️ Deferred: <repo>#<pr>`. Sections with no content are omitted. Inline
findings still appear in the body list so the summary stands alone.

### Inline comment — one shape only

Two to four sentences. First line is the severity and the break. Then when it
happens and what to change. No `Trigger:` / `Fix:` labels on the PR.

```markdown
🛑 **Blocker.** `send` gets null.

On first render `user.email` is still undefined, and this calls `send` anyway. Guard before the call.
```

`⚠️ **Major.**` for majors. No praise. No questions. No list of other ways to
fix it.

### DEFER — issue comment, never a review

```bash
BODY=$(mktemp /tmp/ruver-defer-XXXX.md)
gh api "repos/$REPO/issues/$PR/comments" -F body=@"$BODY"
```

Same template. The line under the header is a sentence, not a status code:
"CI is still red on lint and typecheck, so I did not read the diff."
Under `### ❓ Open`, name the reason: failing checks with log links (max 8),
the draft or conflict, the files you could not cover, or the open question.
Never call `gh pr review` on a DEFER.

### Post-verify

```bash
gh api "repos/$REPO/pulls/$PR/reviews" --jq '.[-1] | {user: .user.login, state, commit_id}'
```

DEFER: print the comment URL instead. `--dry-run`: print the payload, post nothing,
and label the chat summary `DRY-RUN`.

## 10. Chat summary

Lead with two to four sentences in English. Unslop. Say the
verdict and the one thing that drove it. Then the table. Do not paste the
GitHub body into chat.

```
# Review: <repo>#<pr>, <pass> pass

| | |
|---|---|
| Head | <sha7> |
| Prior | none | deep@<sha7> APPROVED | ... |
| CI | success \| failure \| pending \| unknown |
| Axes | 1,2,4,5,7,8,10 (skipped 3 no ticket, 6 no auth surface, 9 no render change) |
| Read | 12 files, 5 codegraph queries |
| Findings | N blockers · N majors · N nits · N dropped by self-verify |
| Carried | N re-verified — N still reproduce, N resolved |
| Coverage | 12/12 |
| Posted | APPROVED \| CHANGES_REQUESTED \| DEFERRED — reason \| WAITING — loop <id> \| SKIPPED — reason \| DRY-RUN |
```

## 11. Failure modes

| Situation | Action |
|---|---|
| `gh` unauthenticated | stop, print `gh auth status` |
| repo or PR unresolvable | stop, never guess |
| review call fails after the one 422 retry | print the error, post nothing else, report in chat |
| codegraph unavailable | `Grep` fallback, note it in the chat summary |
| Linear MCP unavailable | continue on the PR body, note it |
| compare endpoint 404 (force-push) | full diff, `stale_base`, stay light |
| cannot prove a suspected bug | drop it in silence, or `uncertainties` if outside the repo |
| user asks for a second opinion on the **same** PR | refuse; that is a separate run, not nested subagents |
| multi-PR invocation | **required** fan-out (§0) — one subagent per PR; never sequential multi-review on main |
| child receives 2+ PRs | refuse, return ERROR; only the orchestrator fans out |
| required CI pending | **wait_ci** ([LOOP.md](LOOP.md)), never a PR comment |
