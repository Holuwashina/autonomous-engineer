#!/usr/bin/env sh
# Autonomous Engineer — preflight.
#
# Run automatically by the Orchestrator at the start of a run (Step 0), and again
# with --ui right before the QA phase when the change has a UI surface.
#
# It checks the tools a run needs and AUTO-INSTALLS everything that needs no
# credentials (local AE install + safety hooks + base branch, and the browser
# MCPs). For the few things only the user can do — a connector that needs a token,
# or the Claude Code restart that newly added MCPs require — it prints one precise
# instruction instead of failing silently.
#
# Usage:
#   sh preflight.sh            # base checks (local setup + ticket connector hint)
#   sh preflight.sh --ui       # also require Playwright + Chrome DevTools MCPs
#
# Exit codes: 0 = OK to proceed · 2 = action needed (user) · 3 = restart needed.

set -u

TARGET="$PWD"
UI=0; [ "${1:-}" = "--ui" ] && UI=1
AE_SRC="$(cat "$TARGET/.ae/ae-source" 2>/dev/null || true)"

need_restart=0
actions=""
say(){ printf '%s\n' "$1"; }
add_action(){ actions="$actions
  - $1"; }

[ "$UI" = 1 ] && _lbl=" (UI)" || _lbl=""
say "== Autonomous Engineer preflight$_lbl =="

# 1) Local install / hooks / base branch — self-heal via setup.sh if AE source is known
missing_local=0
[ -f "$TARGET/.claude/commands/ae-start.md" ] || missing_local=1
if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
  [ -x "$TARGET/.git/hooks/pre-commit" ] || missing_local=1
  [ -x "$TARGET/.git/hooks/pre-push" ]   || missing_local=1
else
  add_action "Not a git repo — run 'git init' (the agent needs git to branch/commit)."
fi

if [ "$missing_local" = 1 ]; then
  if [ -n "$AE_SRC" ] && [ -f "$AE_SRC/setup.sh" ]; then
    say "• Local setup incomplete — running setup.sh"
    if sh "$AE_SRC/setup.sh" "$TARGET" >/dev/null 2>&1; then say "  local setup OK"; else
      add_action "Local setup failed — run manually: sh \"$AE_SRC/setup.sh\""
    fi
  else
    add_action "AE source not recorded — run: sh <autonomous-engineer>/setup.sh"
  fi
else
  say "• Local install + safety hooks: present"
fi

# 2) MCP servers (only if the claude CLI is reachable from this shell)
if command -v claude >/dev/null 2>&1; then
  mcp_list="$(claude mcp list 2>/dev/null || true)"
  have(){ printf '%s' "$mcp_list" | grep -qiE "$1"; }
  ensure_mcp(){ # label  match-regex  add-command...
    label="$1"; rx="$2"; shift 2
    if have "$rx"; then say "• MCP $label: present"; return; fi
    say "• MCP $label: missing — installing (no credentials needed)"
    if "$@" >/dev/null 2>&1; then
      say "  installed $label"; need_restart=1
    else
      add_action "Could not auto-install $label — run: $*"
    fi
  }
  if [ "$UI" = 1 ]; then
    ensure_mcp "playwright" "playwright" claude mcp add playwright --command npx --args "@playwright/mcp"
    ensure_mcp "chrome-devtools" "chrome.devtools|devtools" claude mcp add chrome-devtools --command npx --args "chrome-devtools-mcp"
  fi
  # Ticket connector is optional (you can paste the ticket inline), so only hint.
  if ! printf '%s' "$mcp_list" | grep -qiE "jira|clickup|github|linear|notion"; then
    say "• No ticket connector detected — that's fine; paste the ticket inline, or add one via /ae-setup."
  fi
else
  say "• claude CLI not on PATH here — skipping MCP checks."
  [ "$UI" = 1 ] && add_action "Install the Playwright + Chrome DevTools MCPs (see mcp-setup) so UI work can be verified live."
fi

# 3) Verdict
if [ -n "$actions" ]; then
  say ""
  say "PREFLIGHT: ACTION NEEDED${actions}"
  exit 2
elif [ "$need_restart" = 1 ]; then
  say ""
  say "PREFLIGHT: RESTART NEEDED — new MCP tools load only after restarting Claude Code. Restart, then re-run /ae-start."
  exit 3
else
  say ""
  say "PREFLIGHT: OK"
  exit 0
fi
