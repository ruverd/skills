# QA execution

Walk [PLAN.md](PLAN.md) (`.ruver-qa/PLAN.md`). That file is the
surface. Do not skip steps. Do not add ad-hoc screens unless a step
is impossible without them (record the extra step in PLAN.md first).

## Per step

1. Run the e2e spec if the step names one (`qa_tool` from PRODUCT.md:
   Playwright `--video=on`, Cypress record, or the repo's command).
2. Exercise the route or endpoint the way a user (or API client) would.
   UI: browser. Backend with a resolved frontend sibling: mapped FE
   route if a caller exists. Backend with no UI: HTTP the changed
   endpoints. Do not invent a screen.
3. Check `pass_if` and the listed variants.
4. Record: command + exit, failing names, artifact paths,
   a short excerpt — not the full log.
5. **Evidence is mandatory.** UI: video if the tool can record, else
   screenshots + steps. API-only: recorded HTTP (status + body excerpt).
   Notes without that evidence are not enough for PASS.

One screenshot is not enough for a screen step.
A unit/CI-only walk is not enough when a FE route exists.

Do not invent credentials; use the repo's documented test auth.

## Findings (along the way)

If a step **looks like** a product error (wrong UI, wrong payload,
AC miss, unexpected 4xx/5xx from app code):

1. Append `## F<n>` to `.ruver-qa/FINDINGS.md`
   ([templates/FINDINGS.md](../templates/FINDINGS.md)).
2. Chat one English line: finding id + step + actual.
3. **Continue** the remaining plan. Later steps are more evidence.

Stop the plan only when QA cannot run: no PR, no env, no auth,
app will not start → `BLOCKED`. That is not a finding.

Clearly infra (dev server down, expired login, missing fixture)
with no product smell → `BLOCKED`, no triage.

A red e2e test is **not** a verdict. It is evidence for a
finding or for `BLOCKED`.

## After the last step

| Result | Next |
|---|---|
| No findings, ACs hold | **verdict** `PASS` |
| Any `## F<n>` | **request_triage** (one envelope, all findings) |
| Unambiguous FAIL (VERDICTS.md) | **verdict** `FAIL` |
| Cannot run | **verdict** `BLOCKED` |
