#!/usr/bin/env sh
# Autonomous Engineer — /selfcheck runner
#
# Objective, model-independent scoring for the golden tickets. Each golden
# acceptance spec in evals/expected/*.test.solved.ts is an oracle: a correct
# pipeline run leaves the matching fixture source satisfying that spec.
#
# Usage (run from the repo root):
#   sh evals/run-selfcheck.sh baseline   # install deps + confirm the starting suite is green
#   sh evals/run-selfcheck.sh score      # score the CURRENT fixture state against the golden specs
#   sh evals/run-selfcheck.sh reset      # restore the fixture to its starting state (git)
#
# Typical flow:
#   1. sh evals/run-selfcheck.sh baseline
#   2. In Claude Code, run /ticket against evals/fixtures/ts-cart for each golden ticket
#   3. sh evals/run-selfcheck.sh score

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="$ROOT/evals/fixtures/ts-cart"
EXP="$ROOT/evals/expected"

ensure_deps() {
    if [ ! -x "$FIX/node_modules/.bin/jest" ]; then
        echo "Installing fixture dependencies..."
        (cd "$FIX" && npm install --no-audit --no-fund >/dev/null 2>&1)
    fi
}

case "${1:-}" in
  baseline)
    ensure_deps
    echo "== Baseline (starting state: bugs latent, features absent) =="
    (cd "$FIX" && npx jest 2>&1 | grep -E "Tests:|Test Suites:")
    echo "Expected: all green. The rounding bug and the authz hole are latent (uncovered)."
    ;;

  score)
    ensure_deps
    echo "== Scoring current fixture state against the golden acceptance spec(s) =="

    # 1) The pipeline's own tests + type-check must pass.
    own_tests="FAIL"; typecheck="FAIL"
    if (cd "$FIX" && npx jest >/dev/null 2>&1); then own_tests="PASS"; fi
    if (cd "$FIX" && npx tsc --noEmit >/dev/null 2>&1); then typecheck="PASS"; fi

    # 2) Overlay every acceptance spec onto its matching source test, run once, restore.
    overlaid=""
    for spec in "$EXP"/*.test.solved.ts; do
      [ -e "$spec" ] || continue
      base="$(basename "$spec" .test.solved.ts)"     # e.g. cart, orders
      target="$FIX/src/$base.test.ts"
      cp "$target" "$target.bak" 2>/dev/null || true
      cp "$spec" "$target"
      overlaid="$overlaid $target"
    done
    acceptance="FAIL"
    if (cd "$FIX" && npx jest >/dev/null 2>&1); then acceptance="PASS"; fi
    for t in $overlaid; do
      [ -e "$t.bak" ] && mv "$t.bak" "$t"
    done

    # 3) The pipeline must have added its own test(s). Count it()/test() cases in
    #    the fixture's own test files (NOT comments); baseline has exactly 3.
    test_count="$(grep -rhoE "\b(it|test)\(" "$FIX"/src/*.test.ts 2>/dev/null | wc -l | tr -d ' ')"
    added_test="FAIL"
    if [ "${test_count:-0}" -gt 3 ]; then added_test="PASS"; fi

    echo "  pipeline tests pass : $own_tests"
    echo "  type-check passes   : $typecheck"
    echo "  golden acceptance   : $acceptance"
    echo "  added own test(s)   : $added_test"
    if [ "$own_tests" = PASS ] && [ "$typecheck" = PASS ] && [ "$acceptance" = PASS ] && [ "$added_test" = PASS ]; then
      echo "SELFCHECK: PASS"
    else
      echo "SELFCHECK: FAIL"
      exit 1
    fi
    ;;

  reset)
    echo "Restoring fixture to starting state via git:"
    (cd "$ROOT" && git checkout -- evals/fixtures/ts-cart/src 2>/dev/null) \
      && echo "  reset OK" || echo "  (git not available or files untracked — reset manually)"
    ;;

  *)
    echo "Usage: sh evals/run-selfcheck.sh [baseline|score|reset]" >&2
    exit 2
    ;;
esac
