# 10. Chat summary

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
