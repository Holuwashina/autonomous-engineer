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

**Restart Claude Code.** New MCP tools do not surface in a running session — the runtime only scans the MCP registry at startup. Skip the restart and the QA Engineer will report "no Playwright MCP available" even though you just installed it.

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

If you already have `gh` authenticated (`gh auth status` says yes), **skip installing the GitHub MCP entirely**. The Engineering Manager and `/ae-pr` command both fall back to `gh` via Bash. Less to install, fewer tokens to manage, same outcome.

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

## Browser tools — QA Engineer requires BOTH

The QA Engineer uses exactly two browser MCPs, no more. Playwright drives; Chrome DevTools inspects. Both are required, not "pick one." See the `qa-engineer` agent for the per-phase usage rules.

### Playwright MCP (canonical: Microsoft's `@playwright/mcp`)

The *driving* tool. Walks user journeys, asserts acceptance criteria, generates reusable regression scripts.

```
claude mcp add playwright --command npx --args "@playwright/mcp"
```

> ⚠️ The pattern `@modelcontextprotocol/server-playwright` does NOT exist as a published package. Use `@playwright/mcp` (Microsoft's official). If you see the wrong name elsewhere, it's stale.

After install, you may need to run `npx playwright install` once to fetch the browser binaries. No credentials required for the server itself.

### Chrome DevTools MCP (canonical: Google's `chrome-devtools-mcp`)

The *perception* tool. Drives real Chrome and exposes DevTools-level inspection — console with sourcemap-resolved stack traces, network requests with bodies, live DOM/CSS, performance state. Use it when "the bug reproduces but you can't see why" or when validation needs to confirm the symptom is gone at the runtime layer, not just visually.

```
claude mcp add chrome-devtools --command npx --args "chrome-devtools-mcp"
```

> ⚠️ Package names in this space shift faster than docs do. Confirm the current canonical package with `claude mcp marketplace search chrome` before running this command. The well-known one as of writing is Google's `chrome-devtools-mcp`.

The `--autoConnect` flag lets it attach to your already-logged-in Chrome session, which is useful for bugs that only show up against your authenticated account state (Playwright's clean profile won't reach those). Add it as a server argument when you need that behaviour:

```
claude mcp add chrome-devtools --command npx --args "chrome-devtools-mcp" --args "--autoConnect"
```

### Why both, not one

- Playwright tells you **what** happened from the user's perspective. "I clicked the button, the page navigated, the modal didn't open."
- Chrome DevTools tells you **why** it happened from the browser's perspective. "The button's click handler threw `Cannot read property 'foo' of undefined` at `src/x.ts:42`; the fetch returned 500 with `{...}`."

Most bug reproductions need both, and so do validations of fixes where the visible behaviour might look right but the runtime is still broken (silent console errors, retried network calls, etc.). Installing only Playwright is a degraded setup; the QA Engineer will surface a blocker on bugs whose root cause can't be seen at the user surface.

---

## Communications

### Mailtrap

```
claude mcp add mailtrap --command npx --args mailtrap-mcp \
  --env "MAILTRAP_API_TOKEN=${MAILTRAP_API_TOKEN}"
```

The QA Engineer reads from the Mailtrap inbox configured in `.ae/resources.yaml`.

### Maildrop (no MCP)

If your `resources.yaml` uses maildrop.cc, no MCP install is needed — the QA Engineer hits `https://api.maildrop.cc/graphql` directly via Bash. Maildrop has no auth, a 10-message cap per mailbox, and 24-hour idle eviction. QA fixtures only.

### Mailpit / MailHog (self-hosted)

No packaged MCP; the QA Engineer falls back to plain HTTP via the configured `api_url`. No install needed.

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

1. **Playwright MCP + Chrome DevTools MCP** — bug repro + acceptance validation need both. Without Playwright the QA Engineer can't drive a journey at all; without DevTools it can't explain runtime failures. Either missing → live confirmation blocks.
2. **A ticket source** — Jira MCP, GitHub MCP, or claude.ai-hosted ClickUp. Without one, the Orchestrator asks the user to paste ticket descriptions.

GitHub MCP, Mailtrap MCP, Slack MCP, Git MCP — all skippable for most projects. The Engineering Manager falls back to `gh` CLI; Mailtrap and Maildrop both work without MCPs (HTTP + Bash); Slack is opt-in.

---

## Verification

After installing what you need:

1. `claude mcp list` — confirm each server is registered.
2. **Restart Claude Code** so new tools surface in the runtime.
3. Spot-check by asking Claude to list tools — `mcp__<server>__*` tools should appear for each installed provider.

Autonomous Engineer degrades gracefully when a provider is missing:

| Missing MCP | Orchestrator behaviour |
|---|---|
| Ticket source | Orchestrator asks the user to paste the ticket description. |
| GitHub | Engineering Manager uses `gh` CLI via Bash. |
| Playwright | QA Engineer surfaces a blocker (in either `reproduce` or `validate` mode); Orchestrator drops to the method-appropriate evidence or escalates. |
| Mailtrap | QA Engineer surfaces a blocker on comms checks; email journeys become manual checkpoints (unless you configured maildrop, which needs no MCP). |

## Anti-patterns

- Committing `.mcp.json` with real credentials to the project repo.
- Setting environment-variable values inline in `claude mcp add` instead of using `${VAR}` references.
- Installing every available MCP "just in case". Install what you use.
- Skipping the post-install restart.
- Trusting a package name from this doc without `claude mcp marketplace search` if the install fails — names shift.
