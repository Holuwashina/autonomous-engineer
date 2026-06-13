---
name: cceo-mcp-setup
description: How to add the MCP servers CCEO integrates with — Jira, ClickUp, GitHub, Git, Playwright, Mailtrap, Slack — via the Claude Code CLI. CCEO does not ship a .mcp.json; the user installs what they need under their own credentials.
---

# CCEO MCP Setup

CCEO does **not** ship a `.mcp.json`. MCP servers are installed by the user via the Claude Code CLI, so credentials enter under the user's own authority. This skill documents the commands.

Verify what's currently installed:

```
claude mcp list
```

After installing, restart Claude Code to pick up the changes.

---

## Ticket source (pick one)

CCEO needs a way to fetch tickets, comment on them, and (optionally) transition status.

### Jira

```
claude mcp add jira --transport http --url https://YOUR-DOMAIN.atlassian.net/mcp \
  --header "Authorization: Bearer ${JIRA_API_TOKEN}"
```

Set `JIRA_API_TOKEN` in your environment. The exact transport varies by provider — check Atlassian's MCP docs for the current canonical command. Some teams use a stdio-based MCP wrapper instead.

### ClickUp

```
claude mcp add clickup --command "npx" --args "@clickup/mcp-server" \
  --env "CLICKUP_API_TOKEN=${CLICKUP_API_TOKEN}"
```

### GitHub Issues (as the ticket source)

The GitHub MCP doubles as both ticket source and code host — see below.

---

## Code host

### GitHub

```
claude mcp add github --command "npx" --args "@modelcontextprotocol/server-github" \
  --env "GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}"
```

Token scopes: `repo` (read/write), `issues` (read/write), `pull_requests` (read/write).

### Git (local)

Usually unnecessary — `Bash` + `git` covers it. If you want git operations exposed as MCP tools:

```
claude mcp add git --command "uvx" --args "mcp-server-git"
```

---

## Browser automation

### Playwright

```
claude mcp add playwright --command "npx" --args "@modelcontextprotocol/server-playwright"
```

This brings up a Chromium-driven MCP that the QA Reproducer and QA Validator drive. No credentials required for the server itself; per-journey login credentials come from `.cceo/resources.yaml` resolution.

---

## Communications

### Mailtrap (preferred)

```
claude mcp add mailtrap --command "npx" --args "mailtrap-mcp" \
  --env "MAILTRAP_API_TOKEN=${MAILTRAP_API_TOKEN}"
```

The QA Communications Engineer reads from the Mailtrap inbox you configure in `.cceo/resources.yaml` under `communications`.

### Mailpit / MailHog (self-hosted)

There may not be a packaged MCP for these; the Comms Engineer falls back to plain HTTP via the configured `api_url`. No MCP install needed.

### Twilio (test sandbox, for SMS/OTP)

```
claude mcp add twilio --command "npx" --args "twilio-mcp" \
  --env "TWILIO_ACCOUNT_SID=${TWILIO_TEST_ACCOUNT_SID}" \
  --env "TWILIO_AUTH_TOKEN=${TWILIO_TEST_AUTH_TOKEN}"
```

---

## Notifications (optional)

### Slack

```
claude mcp add slack --command "npx" --args "@modelcontextprotocol/server-slack" \
  --env "SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}"
```

CCEO uses Slack only when the user explicitly wires it into a workflow (e.g. "notify #eng on every PR opened"). It's not required.

---

## Verification

After installing the providers you need:

1. `claude mcp list` — confirm each server is registered.
2. Restart Claude Code so the new tools surface in the runtime.
3. Spot-check by asking Claude to list tools — `mcp__<server>__*` tools should appear for each installed provider.

CCEO degrades gracefully when a provider is missing:
- No ticket MCP → Director asks the user to paste the ticket description.
- No GitHub MCP → Engineering Manager uses `gh` CLI via `Bash`, or asks the user to open the PR manually.
- No Playwright MCP → QA Reproducer / Validator surface a blocker; the Director either drops to manual validation steps or escalates.
- No Mailtrap MCP → QA Comms Engineer surfaces a blocker; journeys involving email become manual checkpoints.

## Anti-patterns

- Committing `.mcp.json` with real credentials to the project repo.
- Setting environment-variable values inline in `claude mcp add` instead of using `${VAR}` references.
- Installing every available MCP "just in case". Install what you use.
- Skipping the post-install restart.
