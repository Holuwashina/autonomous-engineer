# Changelog

All notable changes to Autonomous Engineer are documented here.

## [2.0.0] — 2026-06-14

Major redesign for correctness, speed, and token efficiency. See `ARCHITECTURE.md` for the rationale.

### Changed — architecture
- **Orchestrator is now the main session loop, not a subagent.** `/ae-start`, `/bug`, `/feature`, and `/ae-resume` load the new `orchestration` skill and drive the run from the main loop. This fixes the v1 flaw where the Engineering Director (a subagent) was expected to spawn subagents — something the runtime does not reliably allow.
- **Roster consolidated from 13 agents to 5.**
  - `intake-analyst` replaces `technical-lead` + `solutions-architect` (classify + risk tier + repo map in one pass).
  - `software-engineer` absorbs `product-engineer` via a new `plan` mode (modes: `plan` / `bug` / `feature`).
  - `qa-engineer` absorbs `qa-environment-engineer` + `qa-communications-engineer` (selects its own env, comms inline; modes: `reproduce` / `validate`).
  - `reviewer` replaces the four reviewer agents with one lens-parameterized agent (`code` | `security` | `perf` | `arch`), spawned as independent parallel instances.
  - `engineering-manager` retained.

### Added
- **Risk-tier routing (T0 / T1 / T2).** Depth scales with risk: trivial work runs ~3 agent calls, high-risk work runs the full pipeline. Tier is declared in the ready message and is user-overridable.
- **Method-flexible evidence gates.** Reproduction/validation method fits the bug class (browser / API / data / build / timing). The gate is "reproduced/validated with evidence", not "via Playwright" — removing the v1 dead-end for non-UI bugs.
- **Token-discipline rules** in the orchestration skill: context slicing, compact structured returns, cached intake/repo map across loop iterations, lazy skill loading, and a per-run call-count budget in the ready message.
- **Eval harness + `/ae-selfcheck`** (`evals/`): a Node+TS fixture with a planted bug, a feature gap, and a security hole; three golden tickets — T1 bug (AE-BUG-1), T1 feature (AE-FEAT-1), and a **T2 broken-access-control** case (AE-SEC-1) that forces the mandatory security lens; golden acceptance specs as scoring oracles; and `run-selfcheck.sh` (baseline/score/reset). Makes pipeline correctness measurable and gives a regression gate for prompt changes. Verified end to end: real red→green on all three tickets, and the scorer discriminates solved vs unsolved.
- **One-shot `setup.sh`** (terminal side): installs commands/agents/skills project-locally (no `~/.claude` writes), installs the safety hooks, and creates the base branch — idempotent. **Adds all AE files to the project's local git exclude (`.git/info/exclude`)** so AE never appears in `git status`, is never committed, and never pushed to the target repo (a project's own tracked `CLAUDE.md` is left untouched). Lets any engineer run AE on any project with zero footprint on its history. Plus a hardened `/ae-setup` that states the slash-vs-shell rule explicitly. Removes the first-run friction (global-vs-project, missing `dev` branch, typing slash commands at a shell prompt).
- **Safety git hooks** (`hooks/`): `pre-commit` blocks direct commits to protected branches and commits of the secrets file; `pre-push` blocks direct pushes to protected branches and non-fast-forward (force) pushes. Installed via `hooks/install-safety-hooks.sh` or `/ae-setup` Phase 4. Turns the protected-branch / shared-history iron rules from prompt-only into deterministic gates (with `--no-verify` as the human escape hatch). Verified against a throwaway repo.
- `CHANGELOG.md` and a `version` bump to 2.0.0 in `plugin.json`.

### Added — speed
- **Per-agent models** (frontmatter `model:`): `intake-analyst` + `engineering-manager` → `haiku`, `qa-engineer` + `reviewer` → `sonnet`, `software-engineer` → session model. Cuts latency/cost on the cheap roles; tune per your plan.
- **Speed levers** in the orchestration skill: strict tier sizing (T1 skips reproduce), T1 review defaults to the code lens (one risk lens only if the diff touches it), targeted re-validation on loop iterations, responsive screenshots at key states only, reviewers always parallel.
- **`/ae-start --fast`** — minimal pipeline (no reproduce, single code review, loop cap 1) for low-risk changes; ignored for T2.

### Fixed
- **Command names namespaced + de-duplicated.** All slash commands now carry an `ae-` prefix so they no longer collide with Claude Code built-ins (`/bug`, `/review`, `/status`, `/resume`). Folded the thin wrappers: `/bug` and `/feature` became `/ae-start --as bug|feature`, and `/log` became `/ae-status --log`. Net: 11 commands → 8 (`ae-start`, `ae-review`, `ae-qa`, `ae-pr`, `ae-status`, `ae-resume`, `ae-setup`, `ae-selfcheck`).
- Default base branch unified to `dev` across all entrypoints (was `main` in the Director, `dev` elsewhere).
- Removed the duplicated "When you may pause mid-run" block (the old Director file carried it twice).
- `install.sh` and `/ae-setup` install-detection markers updated from the removed `engineering-director.md` to v2 files.

### Removed
- `engineering-director.md` (→ `skills/orchestration`), `technical-lead.md`, `solutions-architect.md`, `product-engineer.md`, `qa-environment-engineer.md`, `qa-communications-engineer.md`, `code-reviewer.md`, `security-engineer.md`, `performance-engineer.md`, `software-architect.md`.

## [1.0.0]
- Initial release: 13-agent roster, 10 commands, 10 skills, ticket-to-PR pipeline.
