---
name: pr-protocol
description: Autonomous Engineer Pull Request conventions — title format, body template, test plan checklist, draft vs ready, ticket linking. Used by the Engineering Manager when opening a PR.
---

# PR Protocol

PRs are written to be useful to the human reviewer on GitHub — not as a marketing summary of what was done.

## Title format

```
[<ticket-id>] <verb> <subject>
```

- Verb: `Fix`, `Add`, `Update`, `Refactor`, `Remove`, `Investigate`. Match the classification.
- Subject: ≤70 chars total. Crisp. No emoji.

Examples:
- `[MM-123] Fix logout redirect loop on Safari`
- `[ENG-4521] Add CSV export to reports dashboard`
- `[#456] Update billing webhook signature verification`

If the run has no ticket (e.g. standalone `/pr`):
```
<verb> <subject>
```

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

## Reviewer panel
- **Code review**: <approve | approve_with_findings | request_changes> — <one line>
- **Security review**: <verdict> — <one line>
- **Performance review**: <verdict> — <one line>
- **Architecture review**: <verdict> — <one line>

(Findings addressed in iteration N are noted with "resolved in iter N".)

## Test plan (for the reviewer)
- [ ] <step the reviewer should run to verify locally>
- [ ] <step>
- [ ] <step>

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
