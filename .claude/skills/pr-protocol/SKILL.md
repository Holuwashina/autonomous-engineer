---
name: pr-protocol
description: Autonomous Engineer Pull Request conventions — title format, body template, test plan checklist, draft vs ready, ticket linking. Used by the Engineering Manager when opening a PR.
---

# PR Protocol

PRs are written to be useful to the human reviewer on GitHub — not as a marketing summary of what was done.

## Title format — Conventional Commits

```
<type>(<scope>): <imperative summary> (<ticket-id>)
```

- **type** (maps from the classification): `fix` (bug) · `feat` (feature/enhancement) · `refactor` · `perf` · `docs` · `test` · `build` · `chore`. Trust-boundary/security fixes still use `fix`.
- **scope** (optional): the affected area in parens, e.g. `(auth)`, `(cart)`, `(billing)`. Omit if it spans many.
- **summary**: imperative mood, lowercase start, **≤72 chars total**, no trailing period, no emoji.
- **ticket-id**: append in parens (or omit for a standalone `/ae-pr`). It's also linked in the body.

Examples:
- `fix(auth): stop logout redirect loop on Safari (MM-123)`
- `feat(reports): add CSV export to the dashboard (ENG-4521)`
- `fix(billing): verify webhook signature before processing (#456)`

This matches the Conventional Commits standard so titles are greppable, changelog-friendly, and consistent across the team.

## Body template

```markdown
## Summary
<one to three sentences — what changed and why. No emojis. No "this PR".>

## Linked ticket
- [<TICKET-ID>](<url>) — <classification: bug/feature/enhancement/refactor>

## What changed
<bulleted list of meaningful changes, grouped by repo if multi-repo>

## Validation
<one paragraph — environment + journey covered, plus any communication checks>

### Acceptance criteria
- [x] <criterion> — <evidence ref>
- [x] <criterion> — <evidence ref>
- [ ] <criterion that was not covered, with reason>

For bugs, replace this section with **Reproduction & fix**:
- Original symptom: <one line>
- Root cause: <one line, with `file:line`>
- Fix: <one line>
- Regression test: `<path>`

## Reviewer verdicts (lenses that ran)
- **<lens>** (`code` | `security` | `perf` | `arch`): <approve | approve_with_findings | request_changes> — <one line>
- ... (only the lenses the tier required)

(Findings addressed in iteration N are noted with "resolved in iter N".)

## How to test (for the reviewer / QA)
A human-runnable plan — anyone should be able to follow it without reading the diff:
- **Preconditions / test data:** <accounts, seed data, feature flags, the env + URL>
- **Steps:**
  1. <concrete action — "log in as manager_acme, open /cart">
  2. <action>
- **Expected result:** <what they should see — the fix's observable behaviour>
- **Edge / negative cases:** <e.g. non-manager is denied; empty cart>
- **Screens (UI only):** verified at mobile / tablet / desktop — re-check at each
- **Automated:** `<exact test command>` → all green

## Risks and rollback
- Risks: <bulleted or "none beyond standard release risk">
- Rollback: <one line — revert this PR + any companion artefact (migration, feature flag, etc.)>

## Follow-ups (not in this PR)
- <bullet, or "none">

---
*Opened by Autonomous Engineer. The full run trace lives in the Claude Code session.*
```

## Draft vs ready

- Default: **ready**.
- `--draft` is used when the user wants to leave the PR open for further iteration before requesting review.
- When the reviewer panel produced any `request_changes` verdict that wasn't resolved, the PR is opened as **draft** even if the user didn't say so — and the Engineering Manager notes the unresolved findings prominently in the body.

## Branch and base

- Branch name follows the implementer's convention: `fix/<ticket>-<slug>` or `feat/<ticket>-<slug>`.
- Base is whatever the user passed via `--base`, defaulting to `main`.
- Never PR into `production`, `release/*`, or other protected branches unless the user explicitly asked.

## Pushing

- First push: `git push -u origin <branch>` (sets upstream).
- Subsequent pushes: plain `git push`.
- **No force pushes** unless the user has explicitly authorised one in this run. If history needs to be rewritten, ask first.

## Auto-merge

- **Never.** Even if the project has auto-merge enabled, Autonomous Engineer does not enable it on the PR. The user decides when to merge.

## Anti-patterns

- Marketing-language summaries ("This PR delivers...", "🚀 Big improvements!").
- Hiding reviewer findings to make the PR look cleaner. Resolved findings are noted; unresolved ones are surfaced.
- Test plan checkboxes pre-checked. The reviewer checks them.
- Linking the ticket but not also commenting on the ticket with the PR link (bidirectional linking is mandatory — that lives in `ticket-protocol`).
- Bundling multiple unrelated changes into one PR.
- "And while I was here, I also..." — fold those into the follow-ups section, don't bundle.
