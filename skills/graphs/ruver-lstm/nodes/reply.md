# Node: reply

**Verb:** ack

Commands: [GITHUB.md](../references/GITHUB.md).

Every GitHub reply body (inline thread, skip reason, body-only COMMENT)
runs bundled **`unslop`** before POST. Load skill `unslop`. English on
the PR. Never post a reply that skipped it. Chat with the user stays English and is separate. Unslop both.

After analyze — **including skip**:

1. 👍 on the reviewer's **inline** comment.
2. 👍 on that review's **body** (`databaseId`).
3. Never put 👍 in reply text.
4. Reply on the inline thread (fix note or skip reason).
5. Body-only review (no inline): top-level COMMENT review **after**
   that review. Nested reply on `pullrequestreview-*` 404s.
6. Resolve the conversation **when a fix landed**. Skip threads
   stay open unless the skip reply is enough.
7. Re-request review from that reviewer when a fix landed.

Processed = 👍 + reply on **this** review id. Append it to
`processed_review_ids`. A later re-review needs its own pair.

Do not repeat 👍/reply on an id already processed.
