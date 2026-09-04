# QA execution

Walk [PLAN.md](PLAN.md) (`.ruver-qa/PLAN.md`). That file is the
surface. Do not skip steps. Do not add ad-hoc screens unless a step
is impossible without them (record the extra step in PLAN.md first).

UI execute is **agent-browser** only. Do not run the app's Playwright
or Cypress suite (`e2e_cmd` is CI). Load
[before-and-after](../../before-and-after/SKILL.md) for session,
stills, and attach. Load `agent-browser skills get core` before
clicking.

## Per step

1. If `kind` is `endpoint` and there is no UI: HTTP the changed
   path. Record status + body excerpt.
2. If `kind` is a screen / widget / visual / state: agent-browser.
   Restore the shared session, then follow that step's `how`
   (happy or user-break).
3. Check `pass_if`. Do not skip `intent: user-break` because a
   happy step passed.
4. Record: command + exit, failing names, artifact paths, a short
   excerpt — not the full log.
5. **Evidence is mandatory.** UI: `agent-browser record` of the
   whole plan walk (`.webm`), including user-break steps, plus
   stills of the AC paths. API-only: recorded HTTP of happy and
   user-break. Notes without that evidence are not enough for PASS.

One screenshot is not enough for a screen step.
A unit/CI-only walk is not enough when a FE route exists.

Do not invent credentials; use the repo's documented test auth.

`command -v agent-browser` fails on a UI PR → `BLOCKED`. Do not
reach for Playwright, Cypress, or a host browser MCP.

## Auth (gated screens)

If any plan step is behind login:

1. `eval "$(../before-and-after/scripts/ensure-session.sh)"` and
   restore the shared session (`--restore`). If gated chrome is
   already visible, skip the helper.
2. Else find the repo helper (`package.json` `qa:otp` / `qa:login`,
   `docs/ai/qa-login.md`, `AGENTS.md`). Run it on `$SESSION`. Login
   is a precondition, not the recording. Keep `--restore` on.
3. Confirm gated chrome is visible (not Sign in, not Check your
   email). Snapshot that page to a start text file
   (`agent-browser --session "$SESSION" snapshot` and/or `get url`).
4. Then record on that session, no URL, no `--state` / `--restore`:

```bash
agent-browser --session "$SESSION" record start "$VIDEO"
```

   `record start` does not accept --state. `--session` on this
   command is load-bearing. Omitting it records a different context
   than the walk. Never pass a URL (the CLI would navigate the
   recorder away).
5. Walk PLAN.md (happy + user-break) with `--session "$SESSION"`.
   Then `agent-browser --session "$SESSION" record stop`. Snapshot
   stop (same `--session`). Run
   `../scripts/walk-video-gate.sh --start … --stop …`. Login-wall /
   Check-your-email samples → re-record or BLOCKED, never PASS.
6. **BLOCKED** only after the auth helper is missing or fails, or
   the walk-video gate fails and a re-record is impossible.

Never record before login. Never run `qa:login` in a different `--session`
than `record start`. They must share the same --session.

## Findings (along the way)

If a step **looks like** a product error (wrong UI, wrong payload,
AC miss, user-break accepted silently, unexpected 4xx/5xx from
app code):

1. Append `## F<n>` to `.ruver-qa/FINDINGS.md`
   ([templates/FINDINGS.md](../templates/FINDINGS.md)).
2. Chat one English line: finding id + step + actual.
3. **Continue** the remaining plan. Later steps are more evidence.

Stop the plan only when QA cannot run: no PR, no env, no auth,
app will not start, no agent-browser on UI → `BLOCKED`. That is
not a finding.

Clearly infra (dev server down, expired login, missing fixture)
with no product smell → `BLOCKED`, no triage.

A broken walk is **not** a verdict. It is evidence for a finding
or for `BLOCKED`.

## After the last step

GitHub UI PR whose body has no `ruver-before-and-after` block:
capture base vs HEAD stills and publish
([before-and-after](../../before-and-after/SKILL.md)). Then verdict.

| Result | Next |
|---|---|
| No findings, ACs hold, user-break steps walked | **verdict** `PASS` |
| Any `## F<n>` | **request_triage** (one envelope, all findings) |
| Unambiguous FAIL (VERDICTS.md) | **verdict** `FAIL` |
| Cannot run | **verdict** `BLOCKED` |
