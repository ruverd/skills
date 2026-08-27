---
description: QA a GitHub PR (Playwright + browser). Hands potential bugs to ruver_triage.
argument-hint: "<PR url or owner/repo#N>"
---

# /ruver-qa

Follow **`~/.agents/skills/ruver-qa/SKILL.md`** in full.

**Args:** `$ARGUMENTS`

PR link is required. If the user passed a number, resolve it in the
current repo. If nothing was passed, ask.

Do not mark FAIL on a suspected product bug until `ruver_triage`
confirms, unless the failure is unambiguous.
