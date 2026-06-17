#!/usr/bin/env sh
# Autonomous Engineer — update an installed project to the latest release.
#
# Pulls the newest AE source, then re-syncs THIS project: copies changed
# agents/commands/skills, PRUNES anything removed upstream (via the manifest),
# refreshes the safety hooks + git-excludes, and re-stamps the version.
#
#   sh /path/to/autonomous-engineer/update.sh            # update the current dir
#   sh /path/to/autonomous-engineer/update.sh /my/proj   # update that project
#
# To update EVERY project at once, loop over them, e.g.:
#   for p in ~/code/*; do [ -f "$p/.ae/ae-source" ] && sh "$(cat "$p/.ae/ae-source")/update.sh" "$p"; done

set -eu

TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || true)"
[ -n "$TARGET" ] || { echo "update.sh: target directory does not exist." >&2; exit 1; }

AE_SRC="$(cat "$TARGET/.ae/ae-source" 2>/dev/null || true)"
if [ -z "$AE_SRC" ] || [ ! -f "$AE_SRC/setup.sh" ]; then
  echo "update.sh: can't find AE source (.ae/ae-source missing or invalid)." >&2
  echo "Run setup.sh once first:  sh <autonomous-engineer>/setup.sh \"$TARGET\"" >&2
  exit 1
fi

OLD_VER="$(cat "$TARGET/.ae/ae-version" 2>/dev/null || echo 'unknown')"

# 1) Pull the newest source (this is where the 'install part' updates too).
if git -C "$AE_SRC" rev-parse --git-dir >/dev/null 2>&1; then
  echo "• Pulling latest AE source: $AE_SRC"
  git -C "$AE_SRC" pull --ff-only || echo "  (pull skipped/failed — re-syncing from local source as-is)"
else
  echo "• AE source isn't a git clone — re-syncing from local files as-is."
fi

# 2) Re-sync this project. setup.sh copies new files, prunes removed ones,
#    refreshes hooks + excludes, and re-stamps the version — all idempotent.
echo "• Re-syncing project: $TARGET"
sh "$AE_SRC/setup.sh" "$TARGET"

NEW_VER="$(cat "$TARGET/.ae/ae-version" 2>/dev/null || echo 'unknown')"
echo ""
if [ "$OLD_VER" = "$NEW_VER" ]; then
  echo "✅ Already current: $NEW_VER (files re-synced)."
else
  echo "✅ Updated: $OLD_VER → $NEW_VER"
fi
echo "   Restart Claude Code so it reloads the agents/commands/skills."
