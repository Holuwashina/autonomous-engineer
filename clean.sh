#!/usr/bin/env sh
# Autonomous Engineer — housekeeping.
#
# Prunes the data a run leaves behind so the project doesn't grow unbounded:
#   - run logs + QA evidence + specialist payloads under .ae/runs/
#   - stale local fix/* and feat/* branches already merged into the base branch
#
# DRY-RUN by default — it only reports. Pass --yes to actually delete. (The
# Orchestrator treats deletion as destructive and confirms with you before --yes.)
#
# Usage (from the project root):
#   sh clean.sh                          # summary of what could be cleaned (dry-run)
#   sh clean.sh runs [--days N|--all]    # run dirs older than N days (default 30), or all
#   sh clean.sh branches                 # local fix/*, feat/* merged into base
#   sh clean.sh all  [--days N|--all]    # both
#   add --yes to any of the above to actually delete

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RUNS="$ROOT/.ae/runs"
BASE="${AE_BASE:-}"
[ -z "$BASE" ] && BASE="$(git -C "$ROOT" config --get ae.base 2>/dev/null)"
[ -z "$BASE" ] && BASE="dev"

SCOPE="summary"; DAYS=30; ALL=0; YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    runs|branches|all|summary) SCOPE="$1" ;;
    --yes) YES=1 ;;
    --all) ALL=1 ;;
    --days) shift; DAYS="${1:-30}" ;;
    *) ;;
  esac
  shift
done

run_dirs() {
  [ -d "$RUNS" ] || return 0
  if [ "$ALL" = 1 ]; then
    find "$RUNS" -mindepth 1 -maxdepth 1 -type d
  else
    find "$RUNS" -mindepth 1 -maxdepth 1 -type d -mtime +"$DAYS"
  fi
}

merged_branches() {
  git -C "$ROOT" rev-parse --verify -q "$BASE" >/dev/null 2>&1 || return 0
  git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads/fix refs/heads/feat 2>/dev/null | while read -r b; do
    [ -n "$b" ] || continue
    if git -C "$ROOT" merge-base --is-ancestor "$b" "$BASE" 2>/dev/null; then echo "$b"; fi
  done
}

clean_runs() {
  dirs="$(run_dirs)"
  if [ -z "$dirs" ]; then
    echo "• runs: nothing to prune ($([ "$ALL" = 1 ] && echo 'all' || echo ">${DAYS}d"))"
    return
  fi
  n="$(printf '%s\n' "$dirs" | wc -l | tr -d ' ')"
  echo "• runs: $n run dir(s) eligible ($([ "$ALL" = 1 ] && echo 'ALL' || echo ">${DAYS}d"))"
  if [ "$YES" = 1 ]; then
    printf '%s\n' "$dirs" | xargs rm -rf
    echo "  removed $n run dir(s)"
  else
    printf '%s\n' "$dirs" | sed 's#^#    #'
    echo "  (dry-run — add --yes to delete)"
  fi
}

clean_branches() {
  b="$(merged_branches)"
  if [ -z "$b" ]; then
    echo "• branches: no merged fix/* or feat/* into '$BASE'"
    return
  fi
  n="$(printf '%s\n' "$b" | wc -l | tr -d ' ')"
  echo "• branches: $n merged branch(es) into '$BASE' eligible"
  if [ "$YES" = 1 ]; then
    printf '%s\n' "$b" | xargs -n1 git -C "$ROOT" branch -d
    echo "  deleted $n branch(es)"
  else
    printf '%s\n' "$b" | sed 's#^#    #'
    echo "  (dry-run — add --yes to delete)"
  fi
}

echo "== Autonomous Engineer clean ==  (root: $ROOT, base: $BASE)"
case "$SCOPE" in
  runs)     clean_runs ;;
  branches) clean_branches ;;
  all)      clean_runs; clean_branches ;;
  *)
    YES=0
    if [ -d "$RUNS" ]; then echo "• .ae/runs total: $(du -sh "$RUNS" 2>/dev/null | awk '{print $1}')"; else echo "• .ae/runs: none"; fi
    clean_runs
    clean_branches
    echo ""
    echo "Delete:  sh clean.sh runs --yes  |  sh clean.sh branches --yes  |  sh clean.sh all --yes"
    echo "Window:  sh clean.sh runs --days 14 --yes      Everything:  sh clean.sh runs --all --yes"
    ;;
esac
