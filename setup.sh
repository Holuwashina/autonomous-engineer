#!/usr/bin/env sh
# Autonomous Engineer — one-shot project setup (the terminal half).
#
# Run this ONCE, in your terminal, from inside the project you want AE to work on
# (or pass the project path):
#
#   sh /path/to/autonomous-engineer/setup.sh            # sets up the current directory
#   sh /path/to/autonomous-engineer/setup.sh /my/project
#
# It installs AE's commands/agents/skills into <project>/.claude, installs the
# safety git hooks, and makes sure a base branch exists — all project-local, never
# touching ~/.claude. Then it tells you the one thing people get wrong:
# slash commands run INSIDE Claude Code, not in this terminal.
#
# Idempotent: safe to re-run (it refreshes the installed files).

set -eu

AE_SRC="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$PWD}"
BASE="${AE_BASE:-dev}"

TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"
[ -n "$TARGET" ] || { echo "setup.sh: target directory does not exist." >&2; exit 1; }

echo "Autonomous Engineer — setting up: $TARGET"
echo ""

# 1) Commands / agents / skills (project-local, no ~/.claude writes) -----------
if [ -f "$TARGET/.claude/commands/ae-start.md" ]; then
  echo "• AE already installed here — refreshing agents/commands/skills"
  mkdir -p "$TARGET/.claude/agents" "$TARGET/.claude/commands" "$TARGET/.claude/skills"
  cp -f "$AE_SRC"/agents/*.md       "$TARGET/.claude/agents/"
  cp -f "$AE_SRC"/commands/*.md     "$TARGET/.claude/commands/"
  cp -Rf "$AE_SRC"/skills/*         "$TARGET/.claude/skills/"
else
  echo "• Installing AE (project-local)"
  sh "$AE_SRC/install.sh" "$TARGET" >/dev/null
fi
echo "    agents:   $(ls "$TARGET/.claude/agents" | wc -l | tr -d ' ')"
echo "    commands: $(ls "$TARGET/.claude/commands" | wc -l | tr -d ' ')"
echo "    skills:   $(ls -d "$TARGET"/.claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ')"

# 2) Safety hooks --------------------------------------------------------------
if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  echo "• Installing safety git hooks"
  ( cd "$TARGET" && sh "$AE_SRC/hooks/install-safety-hooks.sh" >/dev/null ) \
    && echo "    pre-commit + pre-push installed"

  # 3) Base branch ------------------------------------------------------------
  if git -C "$TARGET" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    if git -C "$TARGET" rev-parse --verify -q "$BASE" >/dev/null 2>&1; then
      echo "• Base branch '$BASE' already exists"
    else
      git -C "$TARGET" branch "$BASE" && echo "• Created base branch '$BASE' (off current HEAD)"
    fi
  else
    echo "• (No commits yet — create your first commit, then 'git branch $BASE')"
  fi
else
  echo "• Not a git repo — skipping hooks and base branch (run 'git init' first)"
fi

# 4) Handoff -------------------------------------------------------------------
cat <<EOF

────────────────────────────────────────────────────────────────────────
✅ Terminal setup complete.

NEXT: open Claude Code in this folder, then run   /ae-setup
      to finish configuration (QA resources + MCP servers).

How commands work — this trips everyone once:
  • Slash commands  (/ae-setup, /ae-start, /ae-selfcheck)  run INSIDE Claude Code.
  • Shell commands  (sh …, git …)                  run here in the terminal.
  Typing /ae-setup in this terminal will just say "no such file or directory".

Then drop a ticket:   (inside Claude Code)   /ae-start <id> --base $BASE
────────────────────────────────────────────────────────────────────────
EOF
