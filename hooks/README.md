# Safety hooks

These git hooks turn three previously prompt-only iron rules into **deterministic
gates**. Prompt instructions are followed most of the time; a hook is followed
every time. They run in the repo the agent operates on.

## What they enforce

| Hook | Blocks |
|---|---|
| `pre-commit` | Direct commits to a protected branch; committing `.ae/resources.yaml` (secrets) |
| `pre-push` | Pushing directly to a protected branch; non-fast-forward (force) pushes that rewrite shared history |

Default protected branches: `main master dev develop production release`.
Override per-repo:

```bash
git config ae.protectedBranches "main release/prod"
# or, per shell:
export AE_PROTECTED_BRANCHES="main release/prod"
```

## Install (run inside the repo the agent works on)

```bash
sh /path/to/autonomous-engineer/hooks/install-safety-hooks.sh
```

It copies the hooks into that repo's `.git/hooks/`, backing up any existing hook
to `<hook>.pre-ae`. `/setup` offers to run this for you.

## Verified behaviour

Exercised in a throwaway repo (`hooks/` tests):

- commit on `main` → **blocked**; commit on `feat/…` → allowed
- push `feat/…` → allowed; push to `main` → **blocked**
- staging `.ae/resources.yaml` → **blocked**
- force-push that rewrites pushed history → **blocked**
- `git push --no-verify` → allowed (the deliberate human escape hatch)

## Limits — read this

- A hook is a **local** gate. `--no-verify` bypasses it; so does deleting it.
  That's intentional (humans need an escape hatch), but it means the hook is
  defense-in-depth, not a wall.
- The real backstop for "never merge / never push to main" is **remote branch
  protection** on GitHub/GitLab. Configure that too. The hook catches the
  accidental local mistake before it reaches the remote; branch protection
  catches everything else.
