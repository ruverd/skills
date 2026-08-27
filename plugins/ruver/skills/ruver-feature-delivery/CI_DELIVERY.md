# CI/CD green = delivered

**Graph done:** PR(s) open **and** **all** CI/CD checks green. Until then the
task is **not** delivered (`status` ≠ `done`).

Source of truth: **`gh pr checks`** (not only `gh run list`).
Support skills (Claude-only): `loop-on-ci`, `fix-ci`. On Grok, follow
`nodes/ci_watch.md` + STATE `ci_fix_loops`.

## Sequence after quality

```
quality ok
 → commit + push
 → create/update draft PR
      reviewers: izaiasneto4,samuelfaj,chrislong365,AirtonSth,PauloMendees
      assignee: ruverd
 → ci_watch (required if open_pr)
      pending → poll `gh pr checks` (short calls, ~5 min apart)
      fail → diagnose + fix (coder subagent) + push → re-check
      green → status=done
```

PR packaging (shipper): always request review from the logins above and assign `ruverd`
(`gh pr create --reviewer … --assignee ruverd` or `gh pr edit --add-reviewer … --add-assignee ruverd`).

With **`--no-pr`**: local delivery = tester + quality ok; PR CI does not apply.
If the user still says "deliver it", prefer opening a PR and waiting for green CI.

Fullstack: **each** PR (FE and BE) must be green. Delivered only when **both** are green.

## Commands

```bash
gh pr view --json number,url,headRefName,statusCheckRollup
gh pr checks --json name,bucket,state,workflow,link
# poll: repeat the call above until green/fail (~5 min apart).
# NEVER depend on `gh pr checks --watch` finishing in one tool call:
# Bash cap = 10 min; empath-ui CI = 20-30 min. A dead watch is not a CI fail.

# GHA logs if the link is Actions
gh run view <run-id> --log-failed
```

Green = no **required** check in `fail` / `pending` / failed `cancelled`. Prefer:

- every `state` success (or a neutral skip if the repo treats skip as ok)
- `bucket` / required: if `gh` exposes required, require those; otherwise
  **every** check attached to the PR

## Fix loop

1. Extract the **first** actionable failure.
2. Coder / fix-ci subagent: smallest diff.
3. Commit + push (no force).
4. Re-run full `gh pr checks`.
5. Repeat until green or the cap:

```yaml
ci_fix_loops: 5   # default; use 3 on repos with CI >15 min (empath-ui)
```

If loops blow / infinite flake / failure on main that is unrelated:

- merge latest `main` when that is the case
- or `status: escalated` + a Brazilian Portuguese summary (PR URL, red checks, logs)

**Forbidden:** declare done with CI red/pending.
**Forbidden:** `--no-verify` to "pass".

## STATE

```yaml
ci:
  status: pending | watching | fixing | green | escalated
  pr_url: ...
  last_checks: summary
  fix_loops_used: 0
```

Graph `status: done` **only** if `ci.status: green` (when there was a PR).

If this run sits **inside** the `ruver-developer` graph, `done` here
**does not** finish delivery: the developer orchestrator continues to
`mergeable` → `request_qa`. QA (comment + video on the PR) belongs to
`ruver-qa`, not this graph. `/ruver-fd` alone **does not** call QA.

## User summary

Call it **delivered** only when you have:

- PR URL
- CI green (check list or "all green")
- branch + SHA

Speak that summary in Brazilian Portuguese. Fullstack: FE green + BE green.
