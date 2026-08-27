# Review report

Exactly one status, then the blocks.

Statuses: `PASS` · `PR FAILURE` · `TEST FAILURE` · `INFRASTRUCTURE FAILURE`
· `ENVIRONMENT FAILURE` · `BRANCH FAILURE` · `UNRELATED FAILURE`
· `HUMAN INTERVENTION REQUIRED`

```text
Review: <status>
PR: <url>
SHA: <sha>
CI: green | red | pending | unknown
Mergeable: MERGEABLE | CONFLICTING | DIRTY | BLOCKED | UNKNOWN
ruver-code-review: APPROVED | CHANGES_REQUESTED | DEFERRED | SKIPPED

### Summary
<what was reviewed + result>

### Findings
<important code / test / CI / branch issues>

### Root Cause
<actual reason per failure>

### Evidence
<PR, check, test, commit, file, Linear>

### Action
<fixed / retry / Linear / human>
```

Do not report only symptoms.

Chat example (PT-BR):

> O CI falhou no E2E porque o serviço X não está no ambiente. O código
> do PR não participa desse fluxo e o mesmo teste falha na base.
> Classificação: INFRASTRUCTURE FAILURE.
