# Setup

Bring Autonomous Engineer up in a new project in under 10 minutes.

This is the canonical walkthrough. The `/ae-setup` slash command runs an interactive version of these same steps from inside Claude Code — use whichever you prefer.

## TL;DR — the fast path

In your **terminal**, from the project AE should work on:

```bash
sh /path/to/autonomous-engineer/setup.sh
```

This installs commands/agents/skills project-locally (no `~/.claude` writes),
installs the safety git hooks, and creates the `dev` base branch. Then **open
Claude Code in that folder** and run `/ae-setup` to finish (resources + MCP).

**The one rule:** slash commands (`/ae-setup`, `/ae-start`, `/ae-selfcheck`) run *inside
Claude Code*; `sh …` and `git …` run in the *terminal*. Typing a `/command` at a
shell prompt just gives `no such file or directory`. The detailed steps below are
for when you want to do it by hand or troubleshoot.

---

## Contents

1. [Prerequisites](#1-prerequisites)
2. [Choose install mode](#2-choose-install-mode)
3. [Install](#3-install)
4. [Expose your repositories](#4-expose-your-repositories)
5. [Configure `.ae/resources.yaml`](#5-configure-autonomous-engineerresourcesyaml)
6. [Add MCP servers](#6-add-mcp-servers)
7. [Smoke test](#7-smoke-test)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

| Tool | Why | Check |
|---|---|---|
| [Claude Code CLI](https://claude.com/claude-code) | The runtime Autonomous Engineer operates on | `claude --version` |
| `git` | Branching, commits, PR scaffolding | `git --version` |
| `gh` CLI (optional but recommended) | PR opening when GitHub MCP isn't used | `gh --version` |
| `ruby` or Python with PyYAML | YAML parsing in validation helpers (system Ruby works on macOS) | `ruby -ryaml -e 'puts YAML::VERSION'` |

Optional MCP-related dependencies are installed per provider in step 5 — you don't need them upfront.

---

## 2. Choose install mode

| Mode | When | What lands where |
|---|---|---|
| **Plugin** (recommended) | You want Claude Code's plugin system to manage the install + updates. | `~/.claude/plugins/autonomous-engineer/` — Claude Code auto-exposes everything. |
| **Shell — global** (`--global`) | You want Autonomous Engineer available in every Claude Code session without using the plugin system. | `~/.claude/agents/`, `~/.claude/commands/`, `~/.claude/skills/`. No CLAUDE.md or resources.yaml (those stay per-project). |
| **Shell — project** (default) | You want Autonomous Engineer only inside this one codebase. | `<project>/.claude/...` + `<project>/CLAUDE.md` + `<project>/.ae/resources.yaml.example` |

The plugin path is the cleanest: one install, one update command, no shell needed. The shell paths exist for users who want offline setup, CI/CD integration, or per-project scoping without plugin involvement.

---

## 3. Install

### Plugin mode (recommended)

From inside Claude Code:

```bash
/plugin install https://github.com/Holuwashina/autonomous-engineer.git
```

Claude Code clones the repo into `~/.claude/plugins/autonomous-engineer/` and exposes the agents/commands/skills automatically. Update later with:

```bash
/plugin update autonomous-engineer
```

After install, jump to [§4 Expose your repositories](#4-expose-your-repositories) — but first copy the per-project resources template:

```bash
cd ~/path/to/your-project
mkdir -p .ae
cp ~/.claude/plugins/autonomous-engineer/.ae/resources.yaml.example .ae/resources.yaml.example
cp .ae/resources.yaml.example .ae/resources.yaml
$EDITOR .ae/resources.yaml
```

Optional — drop the Autonomous Engineer `CLAUDE.md` rules into your project so non-`/ae-start` work follows the same iron rules:

```bash
cp ~/.claude/plugins/autonomous-engineer/CLAUDE.md ./CLAUDE.md
# or, if you already have a CLAUDE.md, merge manually
```

### Shell install — clone first

For both shell modes below, clone Autonomous Engineer somewhere stable:

```bash
git clone https://github.com/Holuwashina/autonomous-engineer.git ~/autonomous-engineer
```

### Project mode (default shell install)

```bash
cd ~/path/to/your-project
sh ~/autonomous-engineer/install.sh
```

Installs into:
- `<project>/.claude/agents/*.md`
- `<project>/.claude/commands/*.md`
- `<project>/.claude/skills/*/`
- `<project>/CLAUDE.md` (or `CLAUDE.ae.md` if one already exists)
- `<project>/.ae/resources.yaml.example`

Verify:

```bash
ls .claude/agents/*.md | wc -l                # → 5
ls .claude/commands/*.md | wc -l              # → (commands 8 / skills 11)
ls .claude/skills/*/SKILL.md | wc -l          # → (commands 8 / skills 11)
```

### Global mode

```bash
sh ~/autonomous-engineer/install.sh --global
```

Installs into:
- `~/.claude/agents/*.md`
- `~/.claude/commands/*.md`
- `~/.claude/skills/*/`

Does **not** touch `CLAUDE.md` or `.ae/` (those live per-project).

Verify:

```bash
ls ~/.claude/agents/*.md | wc -l              # → 5 (or more, if you have other agents)
ls ~/.claude/commands/*.md | wc -l            # → (commands 8 / skills 11) (or more, if you have other commands)
ls ~/.claude/skills/*/SKILL.md | wc -l        # → (commands 8 / skills 11) (or more, if you have other skills)
```

**After a global install, restart Claude Code** so it re-scans `~/.claude/`.

### Both (mixed install — recommended)

```bash
# Once — makes Autonomous Engineer available everywhere
sh ~/autonomous-engineer/install.sh --global

# Per project — adds CLAUDE.md + resources.yaml.example
cd ~/project-a && sh ~/autonomous-engineer/install.sh
cd ~/project-b && sh ~/autonomous-engineer/install.sh
```

### Flags

| Flag | Effect |
|---|---|
| `--global` | Install into `~/.claude/` instead of a project. |
| `--force` | Overwrite an existing Autonomous Engineer install in the target. |
| `--help` | Print usage. |

---

## 4. Expose your repositories

Claude Code's current working directory is **already in scope** — whatever directory you launched `claude` from is the implicit root.

For additional repos (sibling frontend, backend, shared libs, infra), use `/add-dir`:

```
/add-dir ../frontend
/add-dir ../backend
/add-dir ../shared-types
```

The Intake Analyst (`intake-analyst`) surveys all of them automatically. No Autonomous Engineer-side registration is required.

> **Tip:** monorepos with multiple packages under one root only need the root directory — Claude Code already sees the whole tree.

---

## 5. Configure `.ae/resources.yaml`

Copy the example, then edit:

```bash
cp .ae/resources.yaml.example .ae/resources.yaml
$EDITOR .ae/resources.yaml
```

The file is **gitignored** — secrets stay local.

### Sections

| Section | Required | Notes |
|---|---|---|
| `environments` | Yes | At least one (`local` is fine for solo dev). Production read-only must have `write: false`. |
| `tenants` | If multi-tenant | Drop the section entirely for single-tenant apps. |
| `accounts` | Yes | At minimum the roles your app supports. Inline emails + passwords. |
| `browsers` | Recommended | Defaults to Playwright Chromium. Add `playwright_mobile` if you do mobile journeys. |
| `communications` | If features use email/SMS | Mailtrap (preferred), Maildrop (public dev), Mailpit/Mailhog (self-hosted). |
| `external_services` | As needed | Stripe sandbox, OAuth test clients, S3, Maps API, etc. |

### Account schema

```yaml
accounts:
  - key: admin_tenant_a       # stable identifier other entries reference
    tenant: tenant_a          # FK into the tenants list (omit if single-tenant)
    role: admin               # used by the QA Environment Engineer to pick by role
    email: admin@acme.test    # inline
    password: hunter2         # inline; the file is gitignored
    notes: Optional.
```

### Validation

Dry-parse to catch typos:

```bash
ruby -ryaml -e 'pp YAML.load_file(".ae/resources.yaml")' | head
```

---

## 6. Add MCP servers

Autonomous Engineer does not ship a `.mcp.json`. You install each provider under your own credentials so they live in your MCP config, not the repo.

### Ticket source (pick one)

**Jira:**
```bash
claude mcp add jira --transport http \
  --url https://YOUR-DOMAIN.atlassian.net/mcp \
  --header "Authorization: Bearer $JIRA_API_TOKEN"
```

**ClickUp:**
```bash
claude mcp add clickup --command npx --args "@clickup/mcp-server" \
  --env "CLICKUP_API_TOKEN=$CLICKUP_API_TOKEN"
```

**GitHub Issues** (doubles as the code host below):
```bash
claude mcp add github --command npx --args "@modelcontextprotocol/server-github" \
  --env "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN"
```

GitHub token scopes: `repo`, `issues`, `pull_requests`.

### Code host

Same `gh` MCP from above. Or use the `gh` CLI through Bash if you prefer.

### Browser automation

```bash
claude mcp add playwright --command npx --args "@playwright/mcp"
```

### Communications (only if your features use email/SMS)

**Mailtrap:**
```bash
claude mcp add mailtrap --command npx --args mailtrap-mcp \
  --env "MAILTRAP_API_TOKEN=$MAILTRAP_API_TOKEN"
```

**Maildrop** (public, no auth — the example resources.yaml is pre-configured for this):
No MCP needed. The QA Communications Engineer hits `https://api.maildrop.cc/graphql` directly via Bash.

### Optional

**Slack** (for run notifications):
```bash
claude mcp add slack --command npx --args "@modelcontextprotocol/server-slack" \
  --env "SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN"
```

### Verify

```bash
claude mcp list
```

Restart Claude Code so the new tools surface.

---

## 7. Smoke test

The cheapest end-to-end confidence check:

```
/ae-start FAKE-1 --base dev
```

The Orchestrator will:

1. Attempt to fetch ticket `FAKE-1` via the configured ticket MCP.
2. The fetch will fail (intended — there is no FAKE-1).
3. The Orchestrator surfaces the failure as a blocker and stops.

That confirms the wiring without mutating state. If you don't see the ready message, something upstream is broken — see Troubleshooting.

Then try a real ticket:

```
/ae-start <YOUR-REAL-TICKET-ID> --base develop
```

The Orchestrator will reply with the ready message (understanding, classification, risk tier, specialists, workflow, plan, risks, confidence). **No code changes happen until you confirm or redirect.**

---

## 8. Troubleshooting

### `/ae-start` does nothing

- Restart Claude Code so it re-scans `.claude/commands/`.
- Confirm files: `ls .claude/commands/ae-start.md` returns a real file.
- Confirm the agents loaded: in Claude Code, ask "list my agents" — you should see the 5 Autonomous Engineer specialists (`intake-analyst`, `software-engineer`, `qa-engineer`, `reviewer`, `engineering-manager`). The Orchestrator is the main session loop (the `orchestration` skill), not a listed agent.

### "Cannot fetch ticket — MCP missing"

- `claude mcp list` should show your ticket source.
- If absent, re-run the `claude mcp add ...` command from §5.
- Restart Claude Code after adding an MCP.

### "`.ae/resources.yaml` not found"

- Did you `cp .ae/resources.yaml.example .ae/resources.yaml`?
- The file is gitignored, so a fresh clone won't have it.

### "Account not selectable — no admin role found"

- Confirm your accounts include `role:` fields. The QA Engineer picks by role.
- Confirm the role names you use in the file match the ones in the journey (admin / manager / user / customer / guest).

### Run keeps looping

- The loop cap is per tier (2 for T1, 3 for T2). After that it escalates.
- If escalation isn't happening, check that `skills/orchestration/SKILL.md` is unmodified (specifically the Loop-Until-Done section).

### Playwright says "no browser available"

- The Playwright MCP doesn't include browsers by default. Run `npx playwright install` in the project where you installed the MCP.

### Maildrop messages not arriving

- Maildrop has a **10-message cap per mailbox** and **24-hour idle eviction**. Old mailboxes can be wiped at any time.
- Use a unique mailbox name to avoid collisions.
- For anything sensitive or persistent, switch to Mailtrap.

### CLAUDE.md got overwritten

- The installer writes Autonomous Engineer's CLAUDE.md to `CLAUDE.ae.md` when one already exists in the target — unless you passed `--force`. Merge the two manually.

---

## What's next

Once `/ae-start FAKE-1 --base dev` produces a ready message, you're configured. The `/ae-setup` skill from inside Claude Code can re-walk this any time, and the `mcp-setup` skill is the canonical reference for adding new providers later.

For deeper reading, see:

- [`README.md`](README.md) — architecture diagram + overview
- [`CLAUDE.md`](CLAUDE.md) — iron rules the org operates under
- [`.claude/skills/orchestration/SKILL.md`](.claude/skills/orchestration/SKILL.md) — the main-loop protocol + risk tiers
- [`.claude/skills/workflow-patterns/SKILL.md`](.claude/skills/workflow-patterns/SKILL.md) — the six patterns the Orchestrator composes
- [`.claude/skills/bug-workflow/SKILL.md`](.claude/skills/bug-workflow/SKILL.md) — full bug pipeline
- [`.claude/skills/feature-workflow/SKILL.md`](.claude/skills/feature-workflow/SKILL.md) — full feature pipeline
