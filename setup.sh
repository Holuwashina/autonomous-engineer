#!/usr/bin/env sh
# Autonomous Engineer — one-shot project setup (the terminal half).
#
# Run this ONCE, in your terminal, from inside the project you want AE to work on
# (or pass the project path):
#
#   sh /path/to/autonomous-engineer/setup.sh            # sets up the current directory
#   sh /path/to/autonomous-engineer/setup.sh /my/project
#
# It installs AE's commands/agents/skills into <project>/.claude and the safety
# git hooks, makes sure a base branch exists, and — importantly — adds the AE
# files to the project's LOCAL git exclude (.git/info/exclude) so they are never
# shown as changes, never committed, and never pushed to that repo. AE rides
# along locally; the project's history stays clean. Nothing is written to
# ~/.claude either (no global install).
#
# Idempotent: safe to re-run (it refreshes the installed files).

set -eu

AE_SRC="$(cd "$(dirname "$0")" && pwd)"
BASE="${AE_BASE:-dev}"

# Parse args: a target dir (optional) + flags. --auto-approve installs a Claude Code
# permission allow-list so routine AE tools stop prompting.
AUTO_APPROVE=0
TARGET=""
for a in "$@"; do
  case "$a" in
    --auto-approve|--yolo) AUTO_APPROVE=1 ;;
    -*) ;;
    *) [ -z "$TARGET" ] && TARGET="$a" ;;
  esac
done
[ -n "$TARGET" ] || TARGET="$PWD"

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

# Record where AE lives so the in-session preflight can self-heal + auto-install.
mkdir -p "$TARGET/.ae"
printf '%s\n' "$AE_SRC" > "$TARGET/.ae/ae-source"

# Optional: stop Claude Code's per-tool permission prompts for the tools AE uses.
if [ "$AUTO_APPROVE" = 1 ]; then
  dest="$TARGET/.claude/settings.local.json"
  if [ -f "$dest" ]; then
    echo "• Auto-approve: $dest already exists — leaving it (merge the allow-list from $AE_SRC/templates/settings.local.json if you want)"
  else
    cp "$AE_SRC/templates/settings.local.json" "$dest"
    echo "• Auto-approve: installed permission allow-list — Claude Code won't prompt for AE's routine tools"
  fi
fi

if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  # 2) Keep AE out of the project's git — local-only, never committed/pushed -----
  EXCLUDE="$(git -C "$TARGET" rev-parse --git-path info/exclude)"
  mkdir -p "$(dirname "$EXCLUDE")"
  add_exclude() { grep -qxF "$1" "$EXCLUDE" 2>/dev/null || echo "$1" >> "$EXCLUDE"; }
  add_exclude "# Autonomous Engineer — local-only, do not commit (added by setup.sh)"
  for f in "$AE_SRC"/commands/*.md; do add_exclude "/.claude/commands/$(basename "$f")"; done
  for f in "$AE_SRC"/agents/*.md;   do add_exclude "/.claude/agents/$(basename "$f")"; done
  for d in "$AE_SRC"/skills/*/;     do add_exclude "/.claude/skills/$(basename "$d")/"; done
  add_exclude "/CLAUDE.ae.md"
  add_exclude "/.ae/"
  add_exclude "/.claude/settings.local.json"
  # CLAUDE.md: exclude ONLY the AE-installed one (untracked + byte-identical to ours).
  # A CLAUDE.md the project already owns/tracks is never touched.
  if [ -f "$TARGET/CLAUDE.md" ] \
     && ! git -C "$TARGET" ls-files --error-unmatch CLAUDE.md >/dev/null 2>&1 \
     && cmp -s "$TARGET/CLAUDE.md" "$AE_SRC/CLAUDE.md"; then
    add_exclude "/CLAUDE.md"
  fi
  echo "• Excluded AE files from this repo's git (local-only via .git/info/exclude)"

  # 3) Safety hooks -----------------------------------------------------------
  echo "• Installing safety git hooks"
  ( cd "$TARGET" && sh "$AE_SRC/hooks/install-safety-hooks.sh" >/dev/null ) \
    && echo "    pre-commit + pre-push installed"

  # 4) Base branch ------------------------------------------------------------
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
  echo "• Not a git repo — skipping git-exclude, hooks, and base branch (run 'git init' first)"
fi

# 5) Handoff -------------------------------------------------------------------
cat <<EOF

────────────────────────────────────────────────────────────────────────
✅ Terminal setup complete. AE is installed LOCALLY — its files are excluded
   from this repo's git, so nothing AE will ever be committed or pushed here.

NEXT: open Claude Code in this folder, then run   /ae-setup
      to finish configuration (QA resources + MCP servers).

How commands work — this trips everyone once:
  • Slash commands  (/ae-setup, /ae-start, /ae-selfcheck)  run INSIDE Claude Code.
  • Shell commands  (sh …, git …)                          run here in the terminal.
  Typing /ae-setup in this terminal will just say "no such file or directory".

Tip: make per-project setup a one-liner —
     alias ae-here='sh $AE_SRC/setup.sh'   then just run  ae-here  in any project.

Tired of Claude Code's permission prompts? Re-run with --auto-approve to install
an allow-list for AE's tools (no more "allow this?" spam):
     sh $AE_SRC/setup.sh --auto-approve
(or launch once with:  claude --dangerously-skip-permissions)

Then start work:   (inside Claude Code)   /ae-start      (it asks what to work on)
────────────────────────────────────────────────────────────────────────
EOF
