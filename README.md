# Claude Code Engineering Organization (CCEO)

CCEO turns Claude Code into a senior software engineering team — a coordinated set of specialist subagents, slash commands, and skills that take a ticket from intake to Pull Request.

```
/ticket MM-123 --base develop
```

The Principal Engineering Director reads the ticket, explains its understanding, classifies the work, assembles specialists, runs the appropriate workflow patterns, and reports back the way a real engineering team would.

## What's in this repo

- `.claude/agents/cceo-*.md` — 15 specialist subagents (Director, Technical Lead, QA, reviewers, etc.)
- `.claude/commands/*.md` — 9 slash commands (`/ticket`, `/bug`, `/feature`, `/review`, `/qa`, `/pr`, `/status`, `/resume`, `/setup`)
- `.claude/skills/cceo-*/SKILL.md` — 9 skills (workflow patterns, bug/feature pipelines, ticket/PR protocols, MCP setup, multi-tenant testing, progress reporting, resources)
- `CLAUDE.md` — the org's iron rules
- `.cceo/resources.yaml.example` — QA resource registry template (environments, tenants, accounts, communications — secrets inline; copy to `.cceo/resources.yaml` and fill in real values, file is gitignored)
- `install.sh` — copies CCEO into a target project

## Install

```sh
git clone <this-repo>.git cceo
cd <your-project>
sh /path/to/cceo/install.sh        # installs into $PWD
```

Or with an explicit target:

```sh
sh /path/to/cceo/install.sh /path/to/your-project
```

`install.sh --force` overwrites an existing CCEO install. If your project already has a `CLAUDE.md`, CCEO's rules are written to `CLAUDE.cceo.md` for manual merge.

## Configure

1. **Expose repositories.** Whatever directory you launched Claude Code from is already in scope. For additional repos, run `/add-dir frontend`, `/add-dir backend`, etc. The Solutions Architect surveys all of them automatically.
2. **Configure resources.** `cp .cceo/resources.yaml.example .cceo/resources.yaml`, then edit. Environments, tenants, accounts (with passwords), communications (with API tokens), external services. All values inline. The live file is gitignored.
3. **Add MCP servers.** Run `/setup` and follow the prompts, or read the `cceo-mcp-setup` skill. Typical providers: Jira, ClickUp, GitHub, Playwright, Mailtrap, Slack.
4. **Confirm.** `/setup` walks you through verification.

## Use

```
/ticket MM-123 --base develop
```

Other entrypoints:

| Command | What it does |
|---|---|
| `/ticket <id> [--base <branch>]` | End-to-end: classification → implementation → review → PR |
| `/bug <id> [--base <branch>]` | Force bug workflow |
| `/feature <id> [--base <branch>]` | Force feature workflow |
| `/review [--scope <area>]` | Run the reviewer panel (code / security / perf / architecture) on the current diff |
| `/qa [--journey <name>]` | Run QA validator + comms specialist |
| `/pr [--draft]` | Engineering Manager prepares + opens the PR |
| `/status` | Report current state of the active ticket run |
| `/resume [<id>]` | Resume an interrupted run |
| `/setup` | Configure resources and MCP servers |

## Philosophy

CCEO is not a framework. It is a configuration of Claude Code that uses its native primitives:

- **Subagents** carry specialist roles
- **Slash commands** are entrypoints
- **Skills** encode reusable team conventions and workflow patterns
- **MCP servers** provide ticket systems, browser automation, communication sinks
- **Current working directory + `/add-dir`** is how repositories enter scope

No custom orchestrator. No parallel AI runtime. No hidden state.

## License

MIT. See `LICENSE` if shipped, or treat this repo as your team's internal config.
