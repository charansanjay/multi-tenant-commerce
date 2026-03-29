# Backend Architecture — 03: Custom JWT Claims (Auth Hook)

**Project:** Multi-Tenant Commerce  
**Version:** 2.0  
**Status:** Finalized  

## Table of Contents

- [1. Overview](#1-overview)
- [2. The Problem](#2-the-problem)
- [3. Why This Cannot Be Solved in the Frontend](#3-why-this-cannot-be-solved-in-the-frontend)
- [4. The Solution — PostgreSQL Auth Hook](#4-the-solution--postgresql-auth-hook)
- [5. Auth Hook Logic](#5-auth-hook-logic)
- [6. Login Blocking Behaviour](#6-login-blocking-behaviour)
- [7. What Gets Stamped into the JWT](#7-what-gets-stamped-into-the-jwt)
- [8. How RLS Reads the Claims](#8-how-rls-reads-the-claims)
- [9. Token Refresh Behaviour](#9-token-refresh-behaviour)
- [10. Full SQL Implementation](#10-full-sql-implementation)
- [11. Security Considerations](#11-security-considerations)
- [12. Changelog](#12-changelog)

## 1. Overview

Supabase Auth manages staff sessions and JWT tokens, but by default the
issued JWT contains only standard fields — user ID, email, and expiry. It
has no knowledge of the `staff_profiles` or `tenants` tables.

Every RLS policy in this system depends on two claims in the JWT:

- `auth.jwt() ->> 'role'` — the staff member's role (`admin`, `manager`, `staff`)
- `(auth.jwt() ->> 'tenant_id')::uuid` — the tenant the staff member belongs to

If either claim is missing, the entire authorization layer is non-functional.
No RLS policy can evaluate correctly. No data can be returned.

This document defines the Auth Hook that stamps both claims — along with
convenience claims for audit logging — into the JWT at the moment of sign-in
and on every token refresh.

## 2. The Problem

When a staff member logs in, the issued JWT contains only:

```text
Staff logs in with email + password
      ↓
Supabase Auth validates credentials
      ↓
JWT issued: { "sub": "user-uuid", "email": "...", "exp": ... }
      ↓
RLS policy checks: (auth.jwt() ->> 'tenant_id')::uuid = tenant_id
      ↓
Returns null — no tenant_id claim exists
      ↓
Every RLS policy on every table fails — staff can see nothing
```

Without the Auth Hook, the system is completely non-functional. Every
authenticated user looks identical because there is no role or tenant
information to differentiate them.

## 3. Why This Cannot Be Solved in the Frontend

The natural alternative — fetch `role` and `tenant_id` after login and
store them in the frontend — is fundamentally insecure.

Even if the frontend blocks access based on locally stored values, Supabase
has already issued a valid JWT. That JWT can be extracted and used to call
the Supabase API directly, bypassing the frontend entirely. Without the
correct claims in the JWT, RLS policies fail unpredictably rather than
enforcing access control correctly.

More critically: issuing a JWT to a suspended staff member or a suspended
tenant is itself a security flaw — even if every subsequent query is blocked
by RLS. The backend hook prevents the token from being issued in the first
place.

**Authorization must be enforced before the token is issued, not after.**

## 4. The Solution — PostgreSQL Auth Hook

A PostgreSQL function is registered as a Supabase Auth Hook. Supabase calls
this function automatically every time a session token is issued or
refreshed. The function looks up the staff member's record and their
tenant's record, and injects the required claims into the JWT.

## 5. Auth Hook Logic

```text
Staff submits login credentials
      ↓
Supabase Auth validates credentials
      ↓
Auth Hook fires automatically
      ↓
Hook queries staff_profiles WHERE id = auth.uid()
      ↓
Row found?
  NO  → throw error → block login → no session issued

Row found — check is_active:
  is_active = false → throw error → block login → no session issued

Row found, active — query tenants WHERE id = staff_profiles.tenant_id:
  Tenant not found → throw error → block login (data integrity problem)
  Tenant is_active = false → throw error → block login → account suspended

All checks pass:
  → stamp { role, tenant_id, tenant_name, staff_name } into JWT
  → allow login → session issued
```

## 6. Login Blocking Behaviour

The hook blocks login on **three conditions**. Each produces the same
generic error message to the frontend — no internal details are leaked.

| Condition | Meaning | Action |
|---|---|---|
| No `staff_profiles` row | Account deleted or never properly created | Block — no JWT issued |
| `staff_profiles.is_active = false` | Account deactivated by admin | Block — no JWT issued |
| `tenants.is_active = false` | Tenant suspended by platform operator | Block — no JWT issued |

**Frontend behaviour on block:**

When the Auth Hook throws, Supabase Auth returns a login error. The
frontend displays:

> *"Your account has been deactivated or does not exist. Please contact
> your administrator."*

The same message is shown for all three blocking conditions intentionally —
leaking which specific check failed could be a security concern.

## 7. What Gets Stamped into the JWT

On successful login, the hook injects four custom claims into
`app_metadata`:

```json
{
  "sub": "staff-user-uuid",
  "email": "jan@pizzapalace.cz",
  "app_metadata": {
    "role":        "manager",
    "tenant_id":   "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "tenant_name": "Pizza Palace Praha",
    "staff_name":  "Jan Novák"
  },
  "exp": 1234567890
}
```

### Why four claims

| Claim | Used by | Why in JWT |
|---|---|---|
| `role` | Every RLS policy | Required — RLS cannot function without it |
| `tenant_id` | Every RLS policy | Required — tenant isolation cannot function without it |
| `tenant_name` | Server Actions → audit logs | Convenience — avoids a DB lookup per audit log write |
| `staff_name` | Server Actions → audit logs | Convenience — avoids a DB lookup per audit log write |

`tenant_name` and `staff_name` are convenience claims. They are not used
by RLS — they exist so Server Actions can write complete audit log entries
(which require staff and tenant snapshots) without making an extra database
query on every mutation.

## 8. How RLS Reads the Claims

```sql
-- Read the staff member's role
auth.jwt() ->> 'role'

-- Read the staff member's tenant (cast to uuid for FK comparison)
(auth.jwt() ->> 'tenant_id')::uuid

-- Read the staff member's own user ID (built-in Supabase function)
auth.uid()
```

The shorthand `auth.jwt() ->> 'role'` works because Supabase flattens
`app_metadata` claims to the top level of the JWT for convenience.
The full path is `auth.jwt() -> 'app_metadata' ->> 'role'` — both
expressions return the same value.

## 9. Token Refresh Behaviour

The Auth Hook fires on **every** token issuance and refresh — not just
on initial login. This means:

- If an admin changes a staff member's `role`, the new role is reflected
  in their JWT on the next token refresh — without requiring a logout.
- If a tenant is suspended (`is_active = false`), the next token refresh
  for any of that tenant's staff will be blocked — effectively ending all
  active sessions within one refresh cycle.
- If `tenant_name` or `staff_name` changes, the new values are reflected
  on the next refresh.

The default Supabase session refresh interval is every hour. This means
a suspended tenant's staff may continue using the system for up to one
hour after suspension — this is an acceptable trade-off. For immediate
termination, the admin client can invalidate all sessions for a tenant
directly via the Supabase Auth admin API.

## 10. Full SQL Implementation

```sql
CREATE OR REPLACE FUNCTION custom_jwt_claims()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff        staff_profiles%ROWTYPE;
  v_tenant       tenants%ROWTYPE;
  v_claims       jsonb;
BEGIN
  -- Look up the staff member
  SELECT * INTO v_staff
  FROM staff_profiles
  WHERE id = auth.uid();

  -- Block: no staff profile found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Account does not exist or has been removed';
  END IF;

  -- Block: staff account deactivated
  IF v_staff.is_active = false THEN
    RAISE EXCEPTION 'Account has been deactivated';
  END IF;

  -- Look up the tenant
  SELECT * INTO v_tenant
  FROM tenants
  WHERE id = v_staff.tenant_id;

  -- Block: tenant not found (data integrity problem)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tenant account not found';
  END IF;

  -- Block: tenant suspended
  IF v_tenant.is_active = false THEN
    RAISE EXCEPTION 'Account access has been suspended';
  END IF;

  -- Build the custom claims
  v_claims := jsonb_build_object(
    'role',        v_staff.role::text,
    'tenant_id',   v_staff.tenant_id::text,
    'tenant_name', v_tenant.name,
    'staff_name',  v_staff.first_name || ' ' || v_staff.last_name
  );

  RETURN v_claims;
END;
$$;
```

> **Note:** This function is registered in the Supabase dashboard under
> **Authentication → Hooks → Custom Access Token Hook**. Supabase calls it
> automatically — no application code triggers it directly.

> **Note:** The function uses `SECURITY DEFINER` to run with the privileges
> of the function owner (typically `postgres`), allowing it to read both
> `staff_profiles` and `tenants` regardless of RLS policies on those tables.
> This is safe because the function only reads — it never writes.

> **Note:** All four blocking conditions produce different internal exception
> messages. Supabase Auth normalises these into a single generic login error
> before returning to the client. The frontend never sees the internal reason.

## 11. Security Considerations

- **Read-only:** The hook must only read from `staff_profiles` and `tenants`.
  It must never perform any writes. The function body enforces this by design.
- **No internal detail leakage:** All three blocking conditions produce
  different internal messages but the same generic client-facing error.
- **SECURITY DEFINER is intentional:** The hook needs to read `staff_profiles`
  and `tenants` even when the user has not yet been granted a session. RLS
  would block this read — `SECURITY DEFINER` bypasses RLS for this specific
  function only.
- **Service Role Key not involved:** The hook runs as a trusted PostgreSQL
  function called by Supabase Auth internals — not via the API. The service
  role key is not used here.
- **Tenant suspension latency:** A suspended tenant's staff may retain a
  valid session for up to one hour (the refresh interval). For immediate
  revocation, use the Supabase Auth admin API to invalidate sessions directly.
- **Claims are server-side only:** The `app_metadata` claims are set by the
  server and cannot be modified by the client. Any attempt to forge a JWT
  with different claims will fail Supabase's signature verification.

## 12. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial Auth Hook design finalized — stamps `role` into JWT |
| 2.0 | 2026-03-23 | Hook now stamps four claims: `role`, `tenant_id`, `tenant_name`, `staff_name` |
| 2.0 | 2026-03-23 | Login blocking expanded — now also blocks on `staff_profiles.is_active = false` and `tenants.is_active = false` |
| 2.0 | 2026-03-23 | Full SQL implementation added |
| 2.0 | 2026-03-23 | Token refresh behaviour section expanded — tenant suspension latency documented |
| 2.0 | 2026-03-23 | Section 8 added — how RLS reads each claim |
| 2.0 | 2026-03-23 | Security considerations updated — SECURITY DEFINER rationale documented |
