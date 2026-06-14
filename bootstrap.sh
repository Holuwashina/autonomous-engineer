#!/usr/bin/env sh
# Autonomous Engineer — one-command remote bootstrap.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Holuwashina/autonomous-engineer/main/bootstrap.sh | sh
#
# What it does:
#   1. Clones (or updates) https://github.com/Holuwashina/autonomous-engineer
#      into ~/.autonomous-engineer
#   2. Runs install.sh --global to install into ~/.claude/
#   3. Tells you what to do next.
#
# Safe to re-run: it pulls the latest main and re-installs.

set -eu

REPO_URL="https://github.com/Holuwashina/autonomous-engineer.git"
INSTALL_DIR="${AUTONOMOUS_ENGINEER_HOME:-$HOME/.autonomous-engineer}"

printf '\033[1;36m== Autonomous Engineer bootstrap ==\033[0m\n'
echo

# Prereq: git
if ! command -v git >/dev/null 2>&1; then
    echo "bootstrap: git is required but not found in PATH" >&2
    exit 1
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    echo "→ Updating existing checkout at $INSTALL_DIR"
    git -C "$INSTALL_DIR" fetch --quiet origin main
    git -C "$INSTALL_DIR" reset --quiet --hard origin/main
else
    echo "→ Cloning $REPO_URL into $INSTALL_DIR"
    git clone --quiet --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

echo
echo "→ Running global install"
sh "$INSTALL_DIR/install.sh" --global --force

cat <<EOF

\033[1;32mBootstrap complete.\033[0m

Source checkout:  $INSTALL_DIR
Installed into:   $HOME/.claude/{agents,commands,skills}/

Next steps:

  1. RESTART Claude Code so it picks up the new agents/commands/skills.

  2. In any project where you'll run /ae-ticket, drop in the per-project
     resources template:

       cd <your-project>
       mkdir -p .ae
       cp $INSTALL_DIR/.ae/resources.yaml.example .ae/resources.yaml.example
       cp .ae/resources.yaml.example .ae/resources.yaml
       \$EDITOR .ae/resources.yaml

  3. Wire MCP servers. At minimum:

       claude mcp add playwright --command npx --args "@playwright/mcp"

     For ticket source + others, see:
     $INSTALL_DIR/skills/mcp-setup/SKILL.md

  4. Restart Claude Code AGAIN after MCP installs, then:

       /ae-ticket <TICKET-ID> --base <BRANCH>

Update later with:

  sh $INSTALL_DIR/install.sh --global --force
  # or just re-run this bootstrap

EOF
