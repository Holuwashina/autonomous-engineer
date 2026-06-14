#!/usr/bin/env sh
# Install Autonomous Engineer safety hooks into a git repository.
#
# Run from inside the repo the agent will operate on (the project where /ae-start
# runs and where commits/pushes happen) — NOT necessarily this repo:
#
#   sh /path/to/autonomous-engineer/hooks/install-safety-hooks.sh
#
# It copies pre-commit and pre-push into the repo's .git/hooks/. Existing hooks
# are backed up to <hook>.pre-ae unless --force is given.

set -eu

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

SRC="$(cd "$(dirname "$0")" && pwd)"
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || {
  echo "install-safety-hooks: not inside a git repository." >&2
  exit 1
}

mkdir -p "$GITDIR/hooks"
for h in pre-commit pre-push; do
  dest="$GITDIR/hooks/$h"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    if ! grep -q "Autonomous Engineer safety hook" "$dest" 2>/dev/null; then
      cp "$dest" "$dest.pre-ae"
      echo "backed up existing $h -> $h.pre-ae"
    fi
  fi
  cp "$SRC/$h" "$dest"
  chmod +x "$dest"
  echo "installed $dest"
done

echo ""
echo "Protected branches: ${AE_PROTECTED_BRANCHES:-$(git config --get ae.protectedBranches 2>/dev/null || echo 'main master dev develop production release')}"
echo "Customise with:  git config ae.protectedBranches \"main release/prod\""
echo "Remote branch-protection rules are still the real backstop — these are the local gate."
