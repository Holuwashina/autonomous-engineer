#!/usr/bin/env sh
# Autonomous Engineer installer — copies the canonical Autonomous Engineer layout into a
# project (default) or into Claude Code's user-level config (--global).
#
# Alternative install: this repo is also a Claude Code plugin. Run
#   /plugin install https://github.com/Holuwashina/autonomous-engineer.git
# from inside Claude Code for the plugin-native install path.
#
# Usage:
#   ./install.sh                      # install into $PWD (project mode)
#   ./install.sh /path/to/project     # install into that project
#   ./install.sh --global             # install into ~/.claude/ (global mode)
#   ./install.sh --force              # overwrite existing installed files
#   ./install.sh --help
#
# Project mode (default):
#   - agents, commands, skills → <project>/.claude/...
#   - CLAUDE.md, .ae/resources.yaml.example → <project>/
#   Use when Autonomous Engineer should only operate inside one project.
#
# Global mode (--global):
#   - agents, commands, skills → ~/.claude/...
#   - No CLAUDE.md (each project keeps its own)
#   - No .ae/resources.yaml.example (per-project config)
#   Use when Autonomous Engineer should be available across every Claude Code session.
#
# The installer refuses to clobber an existing install without --force.

set -eu

print_help() {
    cat <<'EOF'
Autonomous Engineer installer

Usage:
  install.sh [TARGET_DIR] [--global] [--force]

Arguments:
  TARGET_DIR   Project directory to install into. Ignored when --global is set.
               Defaults to $PWD.

Options:
  --global     Install into ~/.claude/ instead of a project directory.
  --force      Overwrite existing installed files in the target.
  -h, --help   Show this help.

Project mode (default):
  TARGET_DIR/.claude/agents/*.md
  TARGET_DIR/.claude/commands/*.md
  TARGET_DIR/.claude/skills/*/SKILL.md
  TARGET_DIR/CLAUDE.md
  TARGET_DIR/.ae/resources.yaml.example

Global mode:
  ~/.claude/agents/*.md
  ~/.claude/commands/*.md
  ~/.claude/skills/*/SKILL.md
  (No CLAUDE.md or resources.yaml.example — those stay per-project.)

Mixed mode (recommended for power users):
  1. install.sh --global              # Autonomous Engineer available everywhere
  2. install.sh /path/to/project      # per-project CLAUDE.md + resources.yaml
                                       (skip --global if already done globally)

What does NOT get installed in either mode:
  - .mcp.json (use the mcp-setup skill to add MCP servers)
  - .ae/resources.yaml (copy from the .example and edit; gitignored)
  - Credentials of any kind
EOF
}

FORCE=0
GLOBAL=0
TARGET=""

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            print_help
            exit 0
            ;;
        --force)
            FORCE=1
            ;;
        --global)
            GLOBAL=1
            ;;
        -*)
            echo "install.sh: unknown option: $arg" >&2
            print_help >&2
            exit 2
            ;;
        *)
            if [ -n "$TARGET" ]; then
                echo "install.sh: only one TARGET_DIR is allowed (got: $TARGET and $arg)" >&2
                exit 2
            fi
            TARGET="$arg"
            ;;
    esac
done

if [ "$GLOBAL" -eq 1 ]; then
    if [ -n "$TARGET" ]; then
        echo "install.sh: cannot combine --global with an explicit TARGET_DIR" >&2
        exit 2
    fi
    TARGET="$HOME/.claude"
    mkdir -p "$TARGET"
elif [ -z "$TARGET" ]; then
    TARGET="$PWD"
fi

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SOURCE_DIR/agents" ]; then
    echo "install.sh: source layout missing — expected $SOURCE_DIR/agents/" >&2
    echo "" >&2
    echo "Are you running install.sh from the autonomous-engineer repo root?" >&2
    echo "" >&2
    echo "If you cloned to ~/autonomous-engineer, run one of:" >&2
    echo "  sh ~/autonomous-engineer/install.sh --global" >&2
    echo "  cd ~/autonomous-engineer && sh ./install.sh --global" >&2
    echo "" >&2
    echo "Or use the remote bootstrap (no clone needed):" >&2
    echo "  curl -fsSL https://raw.githubusercontent.com/Holuwashina/autonomous-engineer/main/bootstrap.sh | sh" >&2
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "install.sh: target directory does not exist: $TARGET" >&2
    exit 1
fi

# Detect existing Autonomous Engineer install in the target.
EXISTING=0
if [ -d "$TARGET/agents" ] && [ "$GLOBAL" -eq 1 ]; then
    if ls "$TARGET/agents/"intake-analyst.md >/dev/null 2>&1; then
        EXISTING=1
    fi
elif [ -d "$TARGET/.claude/agents" ]; then
    if ls "$TARGET/.claude/agents/"intake-analyst.md >/dev/null 2>&1; then
        EXISTING=1
    fi
fi

if [ "$EXISTING" -eq 1 ] && [ "$FORCE" -ne 1 ]; then
    echo "install.sh: installed files already exist in $TARGET" >&2
    echo "Re-run with --force to overwrite." >&2
    exit 1
fi

if [ "$GLOBAL" -eq 1 ]; then
    AGENTS_DIR="$TARGET/agents"
    COMMANDS_DIR="$TARGET/commands"
    SKILLS_DIR="$TARGET/skills"
    echo "Autonomous Engineer → installing GLOBALLY into: $TARGET"
else
    AGENTS_DIR="$TARGET/.claude/agents"
    COMMANDS_DIR="$TARGET/.claude/commands"
    SKILLS_DIR="$TARGET/.claude/skills"
    echo "Autonomous Engineer → installing into PROJECT: $TARGET"
fi

mkdir -p "$AGENTS_DIR" "$COMMANDS_DIR" "$SKILLS_DIR"

# Agents
for f in "$SOURCE_DIR/agents/"*.md; do
    [ -e "$f" ] || continue
    cp "$f" "$AGENTS_DIR/$(basename "$f")"
done

# Commands
for f in "$SOURCE_DIR/commands/"*.md; do
    [ -e "$f" ] || continue
    cp "$f" "$COMMANDS_DIR/$(basename "$f")"
done

# Skills (each lives in its own directory)
for d in "$SOURCE_DIR/skills/"*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    mkdir -p "$SKILLS_DIR/$name"
    for f in "$d"*; do
        [ -e "$f" ] || continue
        cp "$f" "$SKILLS_DIR/$name/$(basename "$f")"
    done
done

if [ "$GLOBAL" -eq 0 ]; then
    mkdir -p "$TARGET/.ae"

    # CLAUDE.md — never overwrite the host project's CLAUDE.md silently.
    if [ -f "$TARGET/CLAUDE.md" ] && [ "$FORCE" -ne 1 ]; then
        cp "$SOURCE_DIR/CLAUDE.md" "$TARGET/CLAUDE.ae.md"
        echo "Existing CLAUDE.md preserved. Autonomous Engineer rules written to CLAUDE.ae.md — merge manually."
    else
        cp "$SOURCE_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
    fi

    # Resources example
    cp "$SOURCE_DIR/.ae/resources.yaml.example" "$TARGET/.ae/resources.yaml.example"
fi

if [ "$GLOBAL" -eq 1 ]; then
    cat <<EOF

Autonomous Engineer installed globally.

The 5 specialist agents, 11 commands, and 11 skills are now available in
every Claude Code session, regardless of working directory.

Next steps:
  1. (Per project) Add CLAUDE.md and resources.yaml to each project that
     should run Autonomous Engineer end-to-end:
        sh $SOURCE_DIR/install.sh /path/to/your-project
     This adds the CLAUDE.md rules and the .ae/resources.yaml.example
     template without re-installing the global agents.
  2. (Per project) cp .ae/resources.yaml.example .ae/resources.yaml
     and edit with real values (the live file is gitignored).
  3. Restart Claude Code so it picks up the new agents/commands/skills.
  4. Try it:  /ticket <YOUR-TICKET-ID> --base <BRANCH>
EOF
else
    cat <<EOF

Autonomous Engineer installed.

Next steps:
  1. Open this project in Claude Code.
  2. Run /setup to configure resources and MCP servers.
  3. cp .ae/resources.yaml.example .ae/resources.yaml
     Edit .ae/resources.yaml — fill in real values (the file is gitignored).
  4. Try it:  /ticket <YOUR-TICKET-ID> --base <BRANCH>

If your project already had a CLAUDE.md, see CLAUDE.ae.md for the Autonomous Engineer rules to merge in.
EOF
fi
