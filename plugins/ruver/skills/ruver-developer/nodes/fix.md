# Node: fix

**Verb:** patch  
**Capability:** spawn fd **coder** (or equivalent) on the existing branch

## Mission

`QA_RESULT` FAIL + triage `PR_BUG` only. Contract:
`~/.agents/skills/ruver-triage/references/DEVELOPER.md`.

Same PR. No new PR. Root cause first (`diagnose` if the bug is not already pinned). TDD if behavioral. Push.

## Output

commit sha, files, tests, same `pr_url`.
