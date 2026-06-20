# Journey: <name, e.g. "Apply a discount code at checkout">
Covers: <features / endpoints / ticket IDs this journey exercises>
Surface: ui | api | both
Persona: <account key from .ae/resources.yaml, e.g. accounts.standard_user | guest>
Entry: <UI path off base_url, or METHOD /endpoint>

## Preconditions / test data
- <what must exist first, and how to make it: declared fixture | create via the app's own flow (preferred) | seed script>

## Steps (the way a real user does it)
1. <action> — <stable landmark: role/label/data-test, or METHOD URL> — input: <value/shape>
2. ...

## Expected outcome (assertions)
- <observable result on the surface, or response status + shape>
- Edge / negative cases: <input → expected result>

## Last verified
<YYYY-MM-DD> on <env> by run <run-id>. <note on anything that changed.>
