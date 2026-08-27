# Failure classes (LSTM)

| Class | Action |
|---|---|
| Review still valid | **fix** |
| Review stale / wrong / YAGNI | **skip** + reason |
| Merge conflict | rebase, always |
| Test / CI red after patch | fix or escalate; never `--no-verify` |
| Unclear product / security | ASK last resort or escalate |
| Unrelated bug | note; do not pad this PR |
