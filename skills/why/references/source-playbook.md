# Source playbooks

The why skill spawns one investigator per available evidence category, each reading a single source-specific playbook beside this index. The playbooks are concrete examples for common MCPs; adapt them for a different MCP in the same category.

| Category | Playbook | Example MCP it documents |
|---|---|---|
| Source control history | [`source-code-archaeology.md`](source-code-archaeology.md) | git, `gh` |
| Issue / ticket tracker | [`source-linear.md`](source-linear.md) | Linear (adapt for Jira, GitHub Issues, Plane, Shortcut) |
| Long-form documents | [`source-notion.md`](source-notion.md) | Notion (adapt for Confluence, Google Docs, Coda) |
| Real-time team chat | [`source-slack.md`](source-slack.md) | Slack (adapt for Discord, Microsoft Teams, Mattermost) |
| Infrastructure observability | [`source-datadog.md`](source-datadog.md) | Datadog (adapt for New Relic, Honeycomb, Grafana, Splunk) |
| Error / exception tracking | [`source-sentry.md`](source-sentry.md) | Sentry (adapt for Rollbar, Bugsnag, Airbrake) |
| Product analytics warehouse | [`source-databricks.md`](source-databricks.md) | Databricks SQL (adapt for Snowflake, BigQuery, ClickHouse, dbt) |

Cross-cutting:

- [`source-incident-postmortem.md`](source-incident-postmortem.md). Add this if the target code looks defensive (null checks, retry, timeout, rate limit, feature flag, egress guard, OOM handler).
