---
name: ticket-protocol
description: How Autonomous Engineer interacts with ticket systems (Jira, ClickUp, GitHub Issues) — fetch, comment, transition, attach evidence. Provider-specific conventions for the Orchestrator and Engineering Manager.
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

### Tool surface note

The Orchestrator runs in the **main session loop**, so it has the full tool surface natively — no frontmatter grants needed for ticket fetch at intake. The `engineering-manager` subagent, however, needs ticket-MCP tools for close-out (comment + transition).

**Critical: subagent `tools:` grants must use the `mcp__<server>__*` form — not mid-string wildcards.** Claude Code grants a subagent an MCP tool only when an entry matches `mcp__<server>__<tool>` (the `mcp__<server>__*` suffix wildcard is recognized). A mid-string pattern like `mcp__*clickup*` does **not** match and the subagent silently gets **none** of that server's tools — which looks like "MCP not propagating to subagents" even though the host shows it connected. Because a server can be CLI-installed (`mcp__clickup__*`) or claude.ai-hosted (`mcp__claude_ai_ClickUp__*`), list **both** forms. `engineering-manager.md` lists both for each provider.

If a ticket close-out fails for a provider not in the list, add its two entries to `engineering-manager.md`'s `tools:` — `mcp__<server>__*` and `mcp__claude_ai_<Provider>__*` — then restart Claude Code (subagent frontmatter loads at startup).

## Fetch fallback chain (auto-healing)

The Orchestrator never stops at the first miss. The chain is fixed and ordered. **The env-token / raw-API rung is intentionally absent** — this team uses connector-managed OAuth only; do not curl `https://api.<provider>.com` with a personal token even when one is available.

| Rung | What | When it runs |
|---|---|---|
| 1 | **claude.ai connector tools** (`mcp__claude_ai_<Provider>__*`) | First. Cheapest. Use `ToolSearch` to load the schema if it's deferred, then call the task-fetch tool. |
| 2 | **claude.ai connector re-auth** (`__authenticate` / `__complete_authentication`) | When rung 1 returns "MCP server X is not connected" *and* the connector's auth methods are still in the deferred-tools surface. |
| 3 | **CLI-installed MCP** (`mcp__<provider>__*`) | When the user has set up the provider via `claude mcp add` instead of (or in addition to) the claude.ai connector. |
| 4 | **Provider CLI** | `gh issue view <id>` for GitHub. ClickUp / Jira / Linear have no first-party CLI worth depending on — skip to rung 5. |
| 5 | **Inline-paste prompt** | Last resort. Ask the user to paste title + description + acceptance + status + relevant comments. |

If every rung fails the Orchestrator emits the "Intake blocked" message with the exact failure of each rung listed in the `Reason:` line. Silent stalls are forbidden.

### Reconnect protocol (rung 2)

The reconnect path differs by connector type. Identify which kind of MCP failed first, then follow the matching protocol.

#### Connector type detection

| Tool name pattern | Connector kind | Reauth path |
|---|---|---|
| `mcp__claude_ai_<Provider>__*` | **claude.ai-hosted** | User must run `/mcp` inside Claude Code (or visit claude.ai/settings/connectors). No programmatic OAuth from the Orchestrator. |
| `mcp__<provider>__*` (no `claude_ai_` prefix) | **CLI-installed** (`claude mcp add ...`) | If the MCP exposes `__authenticate` / `__complete_authentication` tools, the Orchestrator can drive the OAuth flow directly (see below). Otherwise the user has to re-run `claude mcp add` with a fresh token. |

#### Path A — claude.ai-hosted connector

These are gated behind `/mcp` (a Claude Code slash command, user-input only) — neither the Orchestrator nor any subagent can trigger them. The `__authenticate` tool returns a stub message pointing at `/mcp`; there's no OAuth URL to open. There's also no `claude mcp` CLI subcommand to force reauth (only `add`/`get`/`list`/`remove`/`reset-project-choices`/`serve` exist).

The Orchestrator's job here is to surface the fix clearly and auto-open the settings page as a backup, then stop:

1. **Detect the disconnect.** Either rung 1 returns "MCP server `claude.ai <Provider>` is not connected", or the session emits a `MCP server disconnected` system reminder for the provider's deferred tools, or only `__authenticate` / `__complete_authentication` are reachable (a "needs reauth" state — the connector is alive at the CLI level but the OAuth token has expired).
2. **Auto-open the connectors settings page** as a visual backup (in case `/mcp` itself fails or the user prefers the web flow):

   ```bash
   if command -v open >/dev/null 2>&1; then open https://claude.ai/settings/connectors        # macOS
   elif command -v xdg-open >/dev/null 2>&1; then xdg-open https://claude.ai/settings/connectors  # Linux
   elif command -v start >/dev/null 2>&1; then start https://claude.ai/settings/connectors   # Windows / WSL
   fi
   ```
3. **Surface the in-CLI fix as the recommended path** — `/mcp` is faster than the browser flow because it doesn't require leaving the conversation:

   ```
   Orchestrator — <Provider> needs reauth

   The claude.ai <Provider> connector is registered but its tool surface
   isn't reachable from this session. Fastest fix: type /mcp here, select
   "claude.ai <Provider>", and reauthorize — you'll stay in this run.

   (I also opened https://claude.ai/settings/connectors in your browser
   as a backup if /mcp doesn't work for you.)

   Reply when you've reauthorized and I'll retry the fetch.
   ```
4. **Wait.** When the user reports back, retry rung 1 from inside the same conversation. If the deferred-tools surface didn't re-sync (which it sometimes doesn't until the next session start), tell the user to relaunch Claude Code — but only after they've reauthorized via `/mcp` or the web.

#### Path B — CLI-installed MCP with auth methods

For MCPs added via `claude mcp add` that expose programmatic auth tools, the Orchestrator can drive the OAuth flow itself:

1. **Probe for auth methods.** Try `ToolSearch` for `mcp__<provider>__authenticate`. If absent, skip to rung 3 (different CLI-installed MCP) or rung 5 (inline-paste).
2. **Start auth.** Call `mcp__<provider>__authenticate`. It returns either a URL the user must visit or a token-paste prompt.
3. **Auto-open the URL in the browser.** Use Bash with platform detection:

   ```bash
   URL="<the URL the auth call returned>"
   if command -v open >/dev/null 2>&1; then open "$URL"
   elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL"
   elif command -v start >/dev/null 2>&1; then start "$URL"
   else echo "Open this URL manually: $URL"
   fi
   ```
4. **Surface status:**

   ```
   Orchestrator — Reconnecting <Provider>

   I opened the authorization page in your browser — sign in and approve.
   If the browser didn't open:
     <URL>

   I'll resume the fetch as soon as auth completes.
   ```
5. **Complete auth.** Call `mcp__<provider>__complete_authentication` with whatever payload the start step returned. Some connectors auto-complete; others need a code.
6. **Retry rung 1.** If it still fails, log the failure and drop to rung 3 / 5.

The reconnect is logged as a single `[INFO] [intake] [orchestrator] Reconnected <Provider> via <kind> reauth` line so the audit trail shows the healing without dumping the URL into the log.

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

For long-running multi-iteration runs, the Orchestrator may post a status comment after each major phase. Default behaviour is **no mid-run comments** — the close-out comment is sufficient. Mid-run comments only happen when:
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

Reviewer verdicts (lenses that ran):
- <lens>: <verdict>

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
