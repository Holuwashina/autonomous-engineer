---
name: cceo-multi-tenant
description: Multi-tenant detection, isolation testing, and cross-tenant + cross-role validation patterns for CCEO QA specialists. Used by the QA Validator when the application supports multiple tenants.
---

# Multi-Tenant Validation

Multi-tenant applications fail in ways single-tenant apps don't: data leaks, role bleed, branding swaps, auth boundary holes. CCEO validation in multi-tenant codebases must explicitly cover these.

## Detect multi-tenancy

The Solutions Architect identifies multi-tenancy by:
- A `tenants` table or equivalent in the schema
- `tenant_id` / `org_id` / `workspace_id` columns on user-owned tables
- Routing by subdomain or path prefix (`acme.example.com`, `example.com/acme`)
- A tenant selector in the UI
- `.cceo/resources.yaml` includes a `tenants` section

If multi-tenancy is detected, the QA Validator runs the multi-tenant scenarios below in addition to the normal validation plan.

## Required scenarios

### 1. Within-tenant happy path
The primary acceptance journey, run inside the primary tenant with the primary role. This is the baseline.

### 2. Tenant isolation — data
For any feature that reads or writes user data, confirm:
- A user in tenant A cannot see data from tenant B.
- A user in tenant A cannot reference / modify a record from tenant B by guessing IDs.

Practical test: sign in as `admin_acme`, note an entity's ID, sign out, sign in as `admin_beta`, attempt to fetch / modify that ID. Expected: 404 or 403, not 200.

### 3. Tenant isolation — communications
Outbound emails / notifications scoped correctly:
- Action in tenant A produces a message to a user in tenant A.
- No message lands in a tenant-B inbox / address.

The QA Comms Engineer runs this in coordination with the Validator.

### 4. Branding / theming
If the app themes per tenant, confirm:
- Logo, colours, copy match the tenant.
- No tenant-B branding leaks into tenant-A pages.

### 5. Subdomain / routing
- Direct access to `acme.example.com/<resource>` works.
- Direct access to `beta.example.com/<resource-from-acme>` does not work (404 or redirect).

### 6. Auth boundary
- Session for tenant A does not authenticate against tenant B's subdomain.
- Cookies are scoped (`Domain`, `Path`, `SameSite`) per tenant policy.

### 7. Cross-role within tenant
For each role the feature exposes (admin, manager, user, guest):
- Permitted roles see/do the expected things.
- Forbidden roles get the expected denial (UI-hidden + server-enforced).

UI-hidden alone is **not** sufficient. The server must enforce.

## Required accounts

The QA Environment Manager pre-selects:
- Primary tenant: primary role + at least one above + one below.
- Secondary tenant: a primary-role account for cross-tenant isolation tests.

If `.cceo/resources.yaml` lacks the required accounts, surface a blocker — do not improvise.

## Reporting

The Validator's report includes a dedicated multi-tenant section:

```
### Multi-tenant validation
- Within-tenant happy path: <pass | fail> — <evidence>
- Tenant isolation (data): <pass | fail> — <evidence>
- Tenant isolation (comms): <pass | fail | n/a> — <evidence>
- Branding / theming: <pass | fail | n/a> — <evidence>
- Subdomain / routing: <pass | fail> — <evidence>
- Auth boundary: <pass | fail> — <evidence>
- Cross-role: <pass | fail> — <evidence per role>
```

## Anti-patterns

- Asserting tenant isolation by only checking that the UI hides data. Always probe the server.
- Skipping cross-tenant tests because "the codebase has a middleware that handles it" — verify the middleware actually fires on the new endpoint.
- Sharing fixtures across tenants. Use distinct tenant-A and tenant-B fixtures.
- Trusting URL path scoping alone without checking subdomain isolation.
- Marking the run pass when one of the seven scenarios is `n/a` without explaining why it's `n/a`.
