---
name: resources-config
description: How to read and interpret .ae/resources.yaml — the single config file holding environments, tenants, accounts, browsers, communications, and external services (with their secrets inline). Used by the QA Engineer (which selects its own environment) and any agent that needs to know what resources are available.
---

# Autonomous Engineer Resources

`.ae/resources.yaml` is the **single** source of truth for QA resources. It holds both structural data (what environments exist, which tenants, account roles) and the secrets (passwords, API tokens) for those entries.

## File location

- **Live file:** `.ae/resources.yaml` — gitignored. Holds real values.
- **Template:** `.ae/resources.yaml.example` — committed. Holds the schema and `REPLACE_ME` placeholders.

If the live file is missing, do **not** improvise. Surface the missing file to the user and point them at `/ae-setup`.

## Why single-file

The user deliberately chose one file over a structure/secrets split. Don't reintroduce `${ENV_VAR}` placeholders, `_env:` fields, or a separate `.env.local`. If a future need genuinely requires env-var indirection (e.g. CI secret store integration), surface it explicitly before adding it.

## Schema

YAML with up to six top-level lists:

| Key | Purpose | Required? |
|---|---|---|
| `environments` | Where tests run | Yes |
| `tenants` | Multi-tenant identities | Only if multi-tenant |
| `accounts` | User identities per role | Yes |
| `browsers` | Browser automation config | Recommended |
| `communications` | Email / SMS / push providers | Required if features use them |
| `external_services` | Third-party APIs (Stripe, OAuth, S3, etc.) | As needed |

### Entry shape

Every entry has a stable `key` referenced elsewhere. Keys are snake_case strings, unique within their section. Fields vary by section; see the example file for the canonical shapes.

### Secret fields

Secrets live directly on the entry as ordinary string fields:

```yaml
accounts:
  - key: admin_acme
    tenant: acme
    role: admin
    email: admin@acme.test
    password: actual-password-here     # inline; live file only
```

In `.ae/resources.yaml.example` these fields hold `REPLACE_ME`. In the live `.ae/resources.yaml` they hold real values.

The known secret fields by section:
- `accounts` — `password`
- `communications` — `api_token`, `account_sid`, `auth_token`
- `external_services` — `api_key`, `client_id`, `client_secret`, `access_key_id`, `secret_access_key`

Treat any field whose name contains `password`, `token`, `secret`, `key`, or `sid` as sensitive. Never print its value in agent output.

## Reading the file

Pseudocode for the QA Engineer (Phase 0 environment selection):

```python
data = yaml.safe_load(open(".ae/resources.yaml").read())

def select_account(role, tenant=None):
    for entry in data["accounts"]:
        if entry["role"] == role and (tenant is None or entry.get("tenant") == tenant):
            return entry
    return None

account = select_account(role="admin", tenant="acme")
# account["email"] and account["password"] are direct strings
```

No env-var resolution, no `${...}` expansion, no `fields_from_env` walk. The YAML *is* the source.

## Selection rules

### Environment

| Purpose | Preferred | Acceptable fallback |
|---|---|---|
| `reproduce` (customer-reported bug) | `staging` | `development`, `local` |
| `reproduce` (internal-found) | `local` | `development` |
| `validate` (fresh implementation) | `local` | `development` |
| `validate` (release candidate) | `staging` | n/a |
| Production read-only | Never used for validation. Reproduction only, with explicit Orchestrator approval. | n/a |

### Tenant

- Single tenant: omit the section. Selection is `n/a`.
- Multi-tenant default: first entry in `tenants` is "primary".
- For cross-tenant isolation tests: primary + at least one secondary.

### Account

- Pick the account whose `role` matches the journey's required role.
- For cross-role tests: primary role + one above + one below in the privilege ladder.
- A `guest` account is unauthenticated; use it for public-page checks.

### Browser

- Default to `playwright_chromium`.
- Use `playwright_mobile` when the ticket mentions mobile UX, viewport behaviour, or responsive issues.

### Communications

- Prefer `mailtrap` (the canonical email sink). Fall back to `mailpit` / `mailhog` for self-hosted dev.
- For SMS/OTP, use `twilio_test`.
- Pick by `kind` (`email`, `sms`, `push`) matching the journey.

## Reporting

The QA Engineer emits a selection payload (see `qa-engineer` output format) that other agents consume directly. The payload includes `unresolved_fields` — entries where a sensitive field still holds `REPLACE_ME` or is empty. Downstream agents check this and stop if anything is unresolved.

Never print the value of a sensitive field. Only "resolved" or "unresolved".

## Anti-patterns

- Reintroducing `${VAR}` placeholders or `_env:` fields. The user explicitly chose against them.
- Splitting secrets into a separate `.env.local`. Same reason.
- Printing the value of a `password` / `token` / `secret` / `key` field anywhere in agent output.
- Substituting a different tenant when the requested one is missing — that's a blocker, not a recovery.
- Writing to `.ae/resources.yaml`. the agents are read-only on this file; the user maintains it.
- Treating `REPLACE_ME` as a valid value. Surface it as unresolved.
