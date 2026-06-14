#!/usr/bin/env sh
# Autonomous Engineer — /ae-selfcheck runner
#
# Objective, model-independent scoring for the golden tickets. Each golden
# acceptance spec in evals/expected/ is an oracle: a correct pipeline run leaves
# the matching fixture source satisfying it.
#
# Usage (run from the repo root):
#   sh evals/run-selfcheck.sh baseline                 # install deps + confirm starting suite is green
#   sh evals/run-selfcheck.sh score [scope]            # score; scope = security|bug|feature|all (default all)
#   sh evals/run-selfcheck.sh reset                    # restore the fixture to its starting state (git)
#
# The scope MUST match the scope of the /ae-selfcheck (or /ae-start) run, so a scoped
# run is judged only on its own oracle and not on tickets it correctly left alone.

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

# Map a scope to the oracle pairs it should be scored against.
# Each pair is "<expected-spec-file>:<fixture-test-file>".
specs_for_scope() {
    case "$1" in
        security) echo "orders.test.solved.ts:orders.test.ts" ;;
        bug)      echo "cart.bug.test.solved.ts:cart.test.ts" ;;
        feature)  echo "cart.feature.test.solved.ts:cart.test.ts" ;;
        all)      echo "orders.test.solved.ts:orders.test.ts cart.test.solved.ts:cart.test.ts" ;;
        *)        echo "" ;;
    esac
}

case "${1:-}" in
  baseline)
    ensure_deps
    echo "== Baseline (starting state: bugs latent, features absent) =="
    (cd "$FIX" && npx jest 2>&1 | grep -E "Tests:|Test Suites:")
    echo "Expected: all green. The rounding bug and the authz hole are latent (uncovered)."
    ;;

  score)
    scope="${2:-all}"
    pairs="$(specs_for_scope "$scope")"
    if [ -z "$pairs" ]; then
      echo "Unknown scope '$scope'. Use: security | bug | feature | all" >&2
      exit 2
    fi
    ensure_deps
    echo "== Scoring (scope: $scope) =="

    # 1) The pipeline's own tests + type-check must pass.
    own_tests="FAIL"; typecheck="FAIL"
    if (cd "$FIX" && npx jest >/dev/null 2>&1); then own_tests="PASS"; fi
    if (cd "$FIX" && npx tsc --noEmit >/dev/null 2>&1); then typecheck="PASS"; fi

    # 2) Overlay this scope's acceptance oracle(s), run once, restore.
    overlaid=""
    for pair in $pairs; do
      spec="$EXP/${pair%%:*}"
      target="$FIX/src/${pair##*:}"
      [ -e "$spec" ] || { echo "missing oracle: $spec" >&2; continue; }
      cp "$target" "$target.bak" 2>/dev/null || true
      cp "$spec" "$target"
      overlaid="$overlaid $target"
    done
    acceptance="FAIL"
    if (cd "$FIX" && npx jest >/dev/null 2>&1); then acceptance="PASS"; fi
    for t in $overlaid; do [ -e "$t.bak" ] && mv "$t.bak" "$t"; done

    # 3) The pipeline must have added its own test(s); baseline has exactly 3.
    test_count="$(grep -rhoE "\b(it|test)\(" "$FIX"/src/*.test.ts 2>/dev/null | wc -l | tr -d ' ')"
    added_test="FAIL"
    if [ "${test_count:-0}" -gt 3 ]; then added_test="PASS"; fi

    echo "  pipeline tests pass : $own_tests"
    echo "  type-check passes   : $typecheck"
    echo "  golden acceptance   : $acceptance  (scope: $scope)"
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
    echo "Usage: sh evals/run-selfcheck.sh [baseline | score [scope] | reset]" >&2
    exit 2
    ;;
esac
