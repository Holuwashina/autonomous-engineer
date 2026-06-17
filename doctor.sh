#!/usr/bin/env sh
# Autonomous Engineer — project doctor.
# Read-only readiness check: tells you what your project has / is missing for AE
# to work at full rigor. Run from the project root:  sh doctor.sh
# Never prints secret values; never changes anything.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASE="${AE_BASE:-}"
[ -z "$BASE" ] && BASE="$(git -C "$ROOT" config --get ae.base 2>/dev/null)"
[ -z "$BASE" ] && BASE="dev"

ok=0; warn=0; bad=0
good(){ ok=$((ok+1));   printf '  [ok]   %s\n' "$1"; }
soft(){ warn=$((warn+1)); printf '  [warn] %s\n' "$1"; }
miss(){ bad=$((bad+1));  printf '  [MISS] %s\n' "$1"; }

is_git(){ git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; }
pkg_has(){ [ -f "$ROOT/package.json" ] && grep -qE "\"$1\"[[:space:]]*:" "$ROOT/package.json"; }
file_any(){ for f in "$@"; do [ -e "$ROOT/$f" ] && return 0; done; return 1; }
dep_has(){ [ -f "$ROOT/package.json" ] && grep -q "$1" "$ROOT/package.json"; }

echo "== Autonomous Engineer — project doctor =="
echo "repo: $ROOT   base: $BASE"
echo ""

echo "Essential"
if is_git; then good "git repository"
  if git -C "$ROOT" rev-parse --verify -q "$BASE" >/dev/null 2>&1; then good "base branch '$BASE' exists"
  else miss "base branch '$BASE' missing — run: git branch $BASE"; fi
  if [ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ]; then good "working tree clean"
  else soft "working tree has uncommitted changes"; fi
else miss "not a git repo — run: git init"; fi

if [ -f "$ROOT/package.json" ]; then
  if pkg_has test; then good "test script (AE is test-first)"; else miss "no \"test\" script in package.json"; fi
  if pkg_has dev || pkg_has start; then good "dev/start script (QA can run the app)"; else soft "no dev/start script — QA can't auto-detect how to run the app"; fi
  if pkg_has build; then good "build script"; else soft "no build script"; fi
  if pkg_has typecheck || file_any tsconfig.json; then good "type-check (tsc/tsconfig)"; else soft "no typecheck / tsconfig"; fi
  if pkg_has lint || file_any .eslintrc .eslintrc.js .eslintrc.json .eslintrc.cjs eslint.config.js .prettierrc .prettierrc.json; then good "lint/format config"; else soft "no eslint/prettier config"; fi
elif file_any pyproject.toml setup.cfg Makefile; then
  good "non-JS project (pyproject/Makefile)"
  if grep -qiE 'ruff|black|flake8|mypy' "$ROOT/pyproject.toml" 2>/dev/null; then good "lint/type tooling (ruff/black/mypy)"; else soft "no ruff/black/mypy in pyproject"; fi
  if file_any pytest.ini tox.ini || grep -qi pytest "$ROOT/pyproject.toml" 2>/dev/null; then good "pytest configured"; else soft "confirm a test command exists"; fi
else
  soft "no package.json/pyproject/Makefile — confirm test + run commands manually"
fi

if [ -f "$ROOT/.ae/resources.yaml" ]; then good ".ae/resources.yaml present"
  rm="$(grep -c 'REPLACE_ME' "$ROOT/.ae/resources.yaml" 2>/dev/null)"; [ -n "$rm" ] || rm=0
  if [ "$rm" -eq 0 ] 2>/dev/null; then good "  no unresolved REPLACE_ME fields"; else soft "  $rm unresolved REPLACE_ME field(s) to fill"; fi
else miss ".ae/resources.yaml missing — cp .ae/resources.yaml.example .ae/resources.yaml (then fill base_url + accounts)"; fi

echo ""
echo "AE install + safety"
if file_any .claude/commands/ae-start.md; then good "AE installed (.claude/)"; else miss "AE not installed here — run setup.sh in this project"; fi
if [ -x "$ROOT/.git/hooks/pre-commit" ] && grep -q "Autonomous Engineer" "$ROOT/.git/hooks/pre-commit" 2>/dev/null; then good "safety hooks installed"; else soft "safety hooks not installed — sh <ae>/hooks/install-safety-hooks.sh"; fi

echo ""
echo "Frontend / a11y"
if dep_has '@axe-core/playwright' || dep_has 'eslint-plugin-jsx-a11y'; then good "a11y tooling present (axe / jsx-a11y)"; else soft "no a11y tooling — npm i -D @axe-core/playwright eslint-plugin-jsx-a11y (QA falls back / flags)"; fi

echo ""
echo "MCP servers"
if command -v claude >/dev/null 2>&1; then
  mcp="$(claude mcp list 2>/dev/null || true)"
  for s in playwright chrome-devtools; do
    if printf '%s' "$mcp" | grep -qi "$s"; then good "MCP: $s"; else soft "MCP: $s missing (UI repro/validate, a11y, memory)"; fi
  done
  if printf '%s' "$mcp" | grep -qiE 'jira|clickup|github|linear|notion'; then good "MCP: a ticket source"; else soft "no ticket connector (inline-paste still works)"; fi
else
  soft "claude CLI not on PATH here — can't check MCP servers"
fi

echo ""
echo "Optional (higher assurance)"
if file_any .semgrep.yml semgrep.yml .gitleaks.toml || command -v semgrep >/dev/null 2>&1 || command -v gitleaks >/dev/null 2>&1; then good "security scanner available (semgrep/gitleaks)"; else soft "no SAST/secret scanner (npm audit / pip-audit still usable)"; fi
if file_any CLAUDE.md; then good "project CLAUDE.md (house conventions)"; else soft "no CLAUDE.md (optional — captures house conventions)"; fi

echo ""
echo "Summary: $ok ok · $warn warnings · $bad missing(essential)"
echo "NOTE: enable remote branch protection on '$BASE'/main on GitHub — the real backstop, not checkable locally."
[ "$bad" -eq 0 ] || echo "Address the [MISS] items before relying on AE for production work."
exit 0
