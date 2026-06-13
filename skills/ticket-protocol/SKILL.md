---
name: ticket-protocol
description: How Autonomous Engineer interacts with ticket systems (Jira, ClickUp, GitHub Issues) — fetch, comment, transition, attach evidence. Provider-specific conventions for the Engineering Director and Engineering Manager.
---

# Ticket Protocol

Autonomous Engineer treats tickets as first-class. Every run touches the ticket at intake and at close-out. The exact commands depend on which ticket MCP is configured.

## Provider detection

Look at the runtime tool surface for any tool name matching these patterns. The exact prefix depends on whether the MCP is locally installed (`claude mcp add ...`) or hosted by claude.ai:

| Provider | Local-install prefix | claude.ai-hosted prefix |
|---|---|---|
| Jira | `mcp__jira__*` | `mcp__claude_ai_Jira__*` |
| ClickUp | `mcp__clickup__*` | `mcp__claude_ai_ClickUp__*` |
| GitHub Issues | `mcp__github__*` | `mcp__claude_ai_GitHub__*` |
| Linear | `mcp__linear__*` | `mcp__claude_ai_Linear__*` |
| Notion | `mcp__notion__*` | `mcp__claude_ai_Notion__*` |

If none are present, ask the user to paste the ticket description and treat it as a free-form ticket — comments and transitions become no-ops.

### Tool surface gotcha (subagents)

Subagent frontmatter `tools:` fields use wildcard patterns. A bare `mcp__*` is too broad — Claude Code's tool resolver does NOT expand it as a glob in subagent surfaces, so subagents declared with `mcp__*` silently miss claude.ai-hosted MCPs. The Director and Technical Lead agents enumerate explicit substring patterns (`mcp__*clickup*, mcp__*ClickUp*, mcp__*jira*, ...`) to cover both casing conventions.

If a user reports a ticket-fetch failure for a provider not in the explicit list, the fix is a one-line edit to the agent's `tools:` field — add `mcp__*<provider-substring>*` (case-sensitive both ways if needed).

## Fetch fallback chain (auto-healing)

The Director never stops at the first miss. The chain is fixed and ordered. **The env-token / raw-API rung is intentionally absent** — this team uses connector-managed OAuth only; do not curl `https://api.<provider>.com` with a personal token even when one is available.

| Rung | What | When it runs |
|---|---|---|
| 1 | **claude.ai connector tools** (`mcp__claude_ai_<Provider>__*`) | First. Cheapest. Use `ToolSearch` to load the schema if it's deferred, then call the task-fetch tool. |
| 2 | **claude.ai connector re-auth** (`__authenticate` / `__complete_authentication`) | When rung 1 returns "MCP server X is not connected" *and* the connector's auth methods are still in the deferred-tools surface. |
| 3 | **CLI-installed MCP** (`mcp__<provider>__*`) | When the user has set up the provider via `claude mcp add` instead of (or in addition to) the claude.ai connector. |
| 4 | **Provider CLI** | `gh issue view <id>` for GitHub. ClickUp / Jira / Linear have no first-party CLI worth depending on — skip to rung 5. |
| 5 | **Inline-paste prompt** | Last resort. Ask the user to paste title + description + acceptance + status + relevant comments. |

If every rung fails the Director emits the "Intake blocked" message with the exact failure of each rung listed in the `Reason:` line. Silent stalls are forbidden.

### Reconnect protocol (rung 2)

When a claude.ai connector is configured for the user but disconnected for this session, the Director invokes the same OAuth flow the user originally completed — not a "go reconnect at the URL" punt.

1. **Detect the disconnect.** Either rung 1 returns "MCP server `claude.ai <Provider>` is not connected", or the session emits a `MCP server disconnected` system reminder for the provider's deferred tools.
2. **Probe for auth methods.** Try `ToolSearch` for `mcp__claude_ai_<Provider>__authenticate`. If absent (the whole connector is gone, not just disconnected), skip to rung 3.
3. **Start auth.** Call `mcp__claude_ai_<Provider>__authenticate`. It returns either a URL the user must visit or a token-paste prompt.
4. **Surface the URL.** Render it as a clickable line — one short sentence, no decoration:

   ```
   Engineering Director — Reconnecting <Provider>

   The <Provider> connector dropped mid-session. Click to reauthorize:
     <URL>

   I'll resume the fetch as soon as the connector reports authorized.
   ```

5. **Complete auth.** Once the user authorizes, call `mcp__claude_ai_<Provider>__complete_authentication` with whatever payload the start step returned. Some connectors auto-complete; others need a code.
6. **Retry rung 1.** If it still fails, log the failure and drop to rung 3.

The reconnect is logged as a single `[INFO] [intake] [director] Reconnected <Provider> via claude.ai OAuth` line so the audit trail shows the healing without dumping the URL into the log.

### When the connector is entirely absent

Some sessions (headless / cron / CI) genuinely lack the claude.ai connector surface — auth methods aren't even in the deferred list. That's not a failure mode the Director can heal mid-run. Skip rungs 1–2, attempt rungs 3–4, and if those fail too, emit the intake-blocked message with rung 5's paste option as the recommended unblock.

## Ticket ID conventions

| Provider | Pattern | Example |
|---|---|---|
| Jira | `[A-Z]+-\d+` | `MM-123`, `ENG-4521` |
| ClickUp | `CU-[a-z0-9]+` or task id | `CU-abc123`, `86abc12d3` |
| GitHub Issues | `<owner>/<repo>#<num>` or just `#<num>` if in a known repo | `#456`, `acme/web#456` |

If the user provides an ambiguous ID, ask before guessing.

## Lifecycle

### Intake (at the start of every run)

1. Fetch the ticket: title, description, comments, labels, assignee, status, attachments, linked tickets.
2. Read the full description and every comment — context lives in comments.
3. Pull attached screenshots / logs and reference them as evidence.

### Mid-run (optional)

For long-running multi-iteration runs, the Director may post a status comment after each major phase. Default behaviour is **no mid-run comments** — the close-out comment is sufficient. Mid-run comments only happen when:
- The run is paused waiting on the user (e.g. "reproduction failed — please confirm steps").
- A reviewer raises a blocking finding the user might want visibility on.

### Close-out (after PR is opened)

The Engineering Manager posts a single comment with:

```
Engineering team update — <date>

Pull Request: <PR URL>

Summary: <one paragraph — what was built/fixed and why>

Validation:
- <acceptance criterion / repro> — <pass/fail> — <evidence link>
- ...

Reviewer panel:
- Code: <verdict>
- Security: <verdict>
- Performance: <verdict>
- Architecture: <verdict>

Follow-ups (not in this PR):
- <bullet, or "none">

Generated by Autonomous Engineer.
```

### Status transitions

- **Default: do not transition.** Many teams have nuanced workflows (peer review states, QA states, deployment gates) Autonomous Engineer can't infer.
- **Transition only when** the project's config explicitly maps "PR opened" → a target status. If unsure, comment a recommendation:

  > "Recommend transitioning this to **In Review**."

- Never close a ticket from Autonomous Engineer. The user decides when the work is done.

## Provider-specific notes

### Jira

- Use the Jira MCP tools for read/comment. Status transitions go through the workflow API and require the destination status to be reachable from the current state.
- Custom fields (Story Points, Sprint, Components) are read-only from Autonomous Engineer unless the user requests otherwise.
- Quote `Description` from ADF (Atlassian Document Format) when reading; render its plain text to the user, not the raw JSON.

### ClickUp

- Use ClickUp MCP tools for read/comment. Task statuses are list-defined; transition only when the project config provides a mapping.
- ClickUp custom fields are accessed by ID — capture the relevant ones at intake (priority, sprint, etc.).

### GitHub Issues

- Use the GitHub MCP. Comments use markdown.
- "Status" is approximated by labels (`status:in-progress`, `status:in-review`). Do not invent labels — only apply labels that already exist on the repo.
- Closing an issue is **never** automatic — even if a PR auto-closes on merge, that's the user's PR + repo config, not Autonomous Engineer's action.

## Anti-patterns

- Auto-transitioning a ticket without explicit config.
- Closing the ticket on behalf of the user.
- Editing the ticket description.
- Posting more than one close-out comment per run.
- Quoting whole stack traces from attachments — link the attachment and quote the relevant excerpt.
- Inventing labels or statuses that don't exist on the project.
