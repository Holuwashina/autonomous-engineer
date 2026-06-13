---
name: mcp-setup
description: How to add the MCP servers Autonomous Engineer integrates with — Jira, ClickUp, GitHub, Git, Playwright, Mailtrap, Slack — via the Claude Code CLI. Autonomous Engineer does not ship a .mcp.json; the user installs what they need under their own credentials. Includes verified canonical package names and the gh-CLI-instead-of-GitHub-MCP shortcut.
---

# Autonomous Engineer MCP Setup

Autonomous Engineer does **not** ship a `.mcp.json`. MCP servers are installed by the user via the Claude Code CLI, so credentials enter under the user's own authority. This skill documents the canonical commands.

## Important — package names move

Third-party MCP package names change. Before running any command below, sanity-check with:

```
claude mcp marketplace search <provider>
```

The commands here are the canonical packages **as of the most recent skill update**. If a `claude mcp add` fails with `package not found`, the package was renamed — search the marketplace, then file an issue against this skill so we update it.

## After every install

**Restart Claude Code.** New MCP tools do not surface in a running session — the runtime only scans the MCP registry at startup. Skip the restart and the QA Investigation Engineer will report "no Playwright MCP available" even though you just installed it.

```
claude mcp list      # confirm registration
# then restart Claude Code
```

---

## Ticket source (pick one)

Autonomous Engineer needs a way to fetch tickets, comment on them, and (optionally) transition status.

### Jira

```
claude mcp add jira --transport http --url https://YOUR-DOMAIN.atlassian.net/mcp \
  --header "Authorization: Bearer ${JIRA_API_TOKEN}"
```

Set `JIRA_API_TOKEN` in your environment. Some teams use a stdio-based MCP wrapper instead — check Atlassian's current MCP docs.

### ClickUp

ClickUp's MCP situation is unsettled at time of writing — Anthropic's claude.ai surfaces a `clickup` MCP that uses OAuth, but there is no widely-published npm package yet. Two paths:

1. **Use the claude.ai-hosted ClickUp connector** (if available in your tenant) — no `claude mcp add` needed.
2. **Drop ClickUp and use GitHub Issues / Jira instead** — both have stable MCPs.

If you find a third-party ClickUp MCP package, verify it before using.

### GitHub Issues (as the ticket source)

The GitHub MCP doubles as both ticket source and code host — see below.

---

## Code host

### Option A — gh CLI (recommended, no MCP)

If you already have `gh` authenticated (`gh auth status` says yes), **skip installing the GitHub MCP entirely**. The Engineering Manager and `/pr` command both fall back to `gh` via Bash. Less to install, fewer tokens to manage, same outcome.

### Option B — GitHub MCP

If you do want the MCP (richer tool surface for issue/PR queries):

```
claude mcp add github --command npx --args "@modelcontextprotocol/server-github" \
  --env "GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}"
```

Token scopes: `repo`, `issues`, `pull_requests`.

### Git (local)

Usually unnecessary — `Bash` + `git` covers it. If you want git operations exposed as MCP tools:

```
claude mcp add git --command uvx --args mcp-server-git
```

---

## Browser automation

### Playwright (canonical: Microsoft's `@playwright/mcp`)

```
claude mcp add playwright --command npx --args "@playwright/mcp"
```

> ⚠️ The pattern `@modelcontextprotocol/server-playwright` does NOT exist as a published package. Use `@playwright/mcp` (Microsoft's official). If you see the wrong name elsewhere, it's stale.

This brings up a Chromium-driven MCP that the QA Investigation Engineer and QA Engineer drive. No credentials required for the server itself. After install, you may also need to run `npx playwright install` once to fetch the browser binaries.

---

## Communications

### Mailtrap

```
claude mcp add mailtrap --command npx --args mailtrap-mcp \
  --env "MAILTRAP_API_TOKEN=${MAILTRAP_API_TOKEN}"
```

The QA Communications Engineer reads from the Mailtrap inbox configured in `.ae/resources.yaml`.

### Maildrop (no MCP)

If your `resources.yaml` uses maildrop.cc, no MCP install is needed — the QA Communications Engineer hits `https://api.maildrop.cc/graphql` directly via Bash. Maildrop has no auth, a 10-message cap per mailbox, and 24-hour idle eviction. QA fixtures only.

### Mailpit / MailHog (self-hosted)

No packaged MCP; the Comms Engineer falls back to plain HTTP via the configured `api_url`. No install needed.

### Twilio (test sandbox, for SMS/OTP)

Verify the current canonical Twilio MCP via `claude mcp marketplace search twilio`. A pattern like:

```
claude mcp add twilio --command npx --args twilio-mcp \
  --env "TWILIO_ACCOUNT_SID=${TWILIO_TEST_ACCOUNT_SID}" \
  --env "TWILIO_AUTH_TOKEN=${TWILIO_TEST_AUTH_TOKEN}"
```

— but package names in this space shift; confirm before running.

---

## Notifications (optional)

### Slack

```
claude mcp add slack --command npx --args "@modelcontextprotocol/server-slack" \
  --env "SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}"
```

Autonomous Engineer uses Slack only when the user explicitly wires it into a workflow. Not required.

---

## The minimum viable wiring

For most runs the **minimum** is:

1. **Playwright MCP** — bug repro + acceptance validation need it. Without it the QA Investigation Engineer blocks every bug run.
2. **A ticket source** — Jira MCP, GitHub MCP, or claude.ai-hosted ClickUp. Without one, the Director asks the user to paste ticket descriptions.

GitHub MCP, Mailtrap MCP, Slack MCP, Git MCP — all skippable for most projects. The Engineering Manager falls back to `gh` CLI; Mailtrap and Maildrop both work without MCPs (HTTP + Bash); Slack is opt-in.

---

## Verification

After installing what you need:

1. `claude mcp list` — confirm each server is registered.
2. **Restart Claude Code** so new tools surface in the runtime.
3. Spot-check by asking Claude to list tools — `mcp__<server>__*` tools should appear for each installed provider.

Autonomous Engineer degrades gracefully when a provider is missing:

| Missing MCP | Director behaviour |
|---|---|
| Ticket source | Director asks the user to paste the ticket description. |
| GitHub | Engineering Manager uses `gh` CLI via Bash. |
| Playwright | QA Investigation Engineer / Validator surface a blocker; Director drops to manual validation steps or escalates. |
| Mailtrap | QA Communications Engineer surfaces a blocker; email journeys become manual checkpoints (unless you configured maildrop, which needs no MCP). |

## Anti-patterns

- Committing `.mcp.json` with real credentials to the project repo.
- Setting environment-variable values inline in `claude mcp add` instead of using `${VAR}` references.
- Installing every available MCP "just in case". Install what you use.
- Skipping the post-install restart.
- Trusting a package name from this doc without `claude mcp marketplace search` if the install fails — names shift.
