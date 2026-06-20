# Journeys — the persistent user-journey map

One Markdown file per journey (`<slug>.md`) describing how a real user navigates a
part of the system, the inputs to use, and the outputs to expect. QA reads the
relevant journey **before** testing (so it doesn't re-discover navigation) and
QA + the engineer update it **after** every run, so the system's test knowledge
compounds. Copy `_template.md` to start a new one.

Schema and the read-before / update-after protocol: the **`journey-map`** skill.

Secrets never go here — reference an account by its `key` from
`.ae/resources.yaml`, never an email/password.

Local-only by default (git-excluded, like the rest of `.ae/`). To share the map
with your team, remove `/.ae/journeys/` from `.git/info/exclude` and commit it.
