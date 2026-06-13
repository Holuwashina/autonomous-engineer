#!/usr/bin/env sh
# CCEO installer — copies the canonical Claude Code Engineering Organization
# layout (.claude/, CLAUDE.md, .cceo/resources.yaml.example) into a target
# project directory.
#
# Usage:
#   ./install.sh                  # install into $PWD
#   ./install.sh /path/to/project # install into that project
#   ./install.sh --force          # overwrite existing CCEO files
#   ./install.sh --help
#
# The installer refuses to clobber an existing .claude/agents/cceo-* layout
# without --force, so an in-progress CCEO install in the target is preserved.

set -eu

print_help() {
    cat <<'EOF'
CCEO — Claude Code Engineering Organization installer

Usage:
  install.sh [TARGET_DIR] [--force]

Arguments:
  TARGET_DIR   Project directory to install CCEO into. Defaults to $PWD.

Options:
  --force      Overwrite existing CCEO files in the target.
  -h, --help   Show this help.

What gets installed:
  TARGET_DIR/CLAUDE.md
  TARGET_DIR/.claude/agents/cceo-*.md
  TARGET_DIR/.claude/commands/*.md
  TARGET_DIR/.claude/skills/cceo-*/SKILL.md
  TARGET_DIR/.cceo/resources.yaml.example

What does NOT get installed:
  - .mcp.json (use the cceo-mcp-setup skill to add MCP servers)
  - .cceo/resources.yaml (copy from the .example and edit; gitignored)
  - Credentials of any kind
EOF
}

FORCE=0
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

if [ -z "$TARGET" ]; then
    TARGET="$PWD"
fi

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "$SOURCE_DIR/.claude/agents" ]; then
    echo "install.sh: source layout missing — expected $SOURCE_DIR/.claude/agents/" >&2
    echo "Are you running install.sh from the CCEO repo root?" >&2
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "install.sh: target directory does not exist: $TARGET" >&2
    exit 1
fi

# Detect existing CCEO install in the target.
EXISTING=0
if [ -d "$TARGET/.claude/agents" ]; then
    if ls "$TARGET/.claude/agents/"cceo-*.md >/dev/null 2>&1; then
        EXISTING=1
    fi
fi

if [ "$EXISTING" -eq 1 ] && [ "$FORCE" -ne 1 ]; then
    echo "install.sh: CCEO files already exist in $TARGET/.claude/agents/" >&2
    echo "Re-run with --force to overwrite." >&2
    exit 1
fi

echo "CCEO → installing into: $TARGET"

mkdir -p "$TARGET/.claude/agents" \
         "$TARGET/.claude/commands" \
         "$TARGET/.claude/skills" \
         "$TARGET/.cceo"

# Agents
for f in "$SOURCE_DIR/.claude/agents/"cceo-*.md; do
    [ -e "$f" ] || continue
    cp "$f" "$TARGET/.claude/agents/$(basename "$f")"
done

# Commands
for f in "$SOURCE_DIR/.claude/commands/"*.md; do
    [ -e "$f" ] || continue
    cp "$f" "$TARGET/.claude/commands/$(basename "$f")"
done

# Skills (each lives in its own directory)
for d in "$SOURCE_DIR/.claude/skills/"cceo-*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    mkdir -p "$TARGET/.claude/skills/$name"
    for f in "$d"*; do
        [ -e "$f" ] || continue
        cp "$f" "$TARGET/.claude/skills/$name/$(basename "$f")"
    done
done

# CLAUDE.md — never overwrite the host project's CLAUDE.md silently.
if [ -f "$TARGET/CLAUDE.md" ] && [ "$FORCE" -ne 1 ]; then
    cp "$SOURCE_DIR/CLAUDE.md" "$TARGET/CLAUDE.cceo.md"
    echo "Existing CLAUDE.md preserved. CCEO rules written to CLAUDE.cceo.md — merge manually."
else
    cp "$SOURCE_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# Resources example
cp "$SOURCE_DIR/.cceo/resources.yaml.example" "$TARGET/.cceo/resources.yaml.example"

cat <<EOF

CCEO installed.

Next steps:
  1. Open this project in Claude Code.
  2. Run /setup to configure resources and MCP servers.
  3. cp .cceo/resources.yaml.example .cceo/resources.yaml
     Edit .cceo/resources.yaml — fill in real values (the file is gitignored).
  4. Try it:  /ticket <YOUR-TICKET-ID> --base <BRANCH>

If your project already had a CLAUDE.md, see CLAUDE.cceo.md for the CCEO rules to merge in.
EOF
