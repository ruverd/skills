# Node: fix

**Verb:** patch  
**Capability:** spawn fd **coder** (or equivalent) on the existing branch

## Mission

`QA_RESULT` FAIL + triage `PR_BUG` only. Contract:
`../../ruver-triage/references/DEVELOPER.md`.

Same PR. No new PR. Root cause first (`diagnose` if the bug is not already pinned). TDD if behavioral. Push.

Read `qa_verdict_log` before you start. On lap 2 or later the earlier fix did
not hold, so treat the previous attempt as evidence, not as a starting point.

## Output

commit sha, files, tests, same `pr_url`.
