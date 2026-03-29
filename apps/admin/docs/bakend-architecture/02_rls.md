# Backend Architecture — 02: Row Level Security (RLS)

**Project:** Multi-Tenant Commerce  
**Version:** 2.0  
**Status:** Finalized  

## Table of Contents

- [1. Overview](#1-overview)
- [2. The Two-Layer Security Model](#2-the-two-layer-security-model)
- [3. The Three Roles](#3-the-three-roles)
- [4. How RLS Reads the JWT Claims](#4-how-rls-reads-the-jwt-claims)
- [5. The Tenant Isolation Pattern](#5-the-tenant-isolation-pattern)
- [6. RLS Policy Matrix](#6-rls-policy-matrix)
- [7. Policy Design Notes](#7-policy-design-notes)
- [8. The "Own Row" Pattern](#8-the-own-row-pattern)
- [9. The Broadcast Notifications Pattern](#9-the-broadcast-notifications-pattern)
- [10. Special Tables — No Standard RLS](#10-special-tables--no-standard-rls)
- [11. RLS Must Be Enabled on Every Table](#11-rls-must-be-enabled-on-every-table)
- [12. Complete Policy Reference](#12-complete-policy-reference)
- [13. Changelog](#13-changelog)

## 1. Overview

Row Level Security (RLS) is Supabase's mechanism for enforcing data access
rules at the database level. Every query — regardless of where it originates
— is checked against RLS policies before Supabase returns any data. If no
policy permits the operation, the query returns nothing or an error.

RLS is the most critical security layer in this system. Even if the frontend
is bypassed entirely (e.g. a direct API call via Postman or curl), RLS
ensures:

1. A staff member can **never access data belonging to another tenant**
2. A staff member can **never access data above their role's permission level**

Both guarantees are enforced at the database level — not in application code.

## 2. The Two-Layer Security Model

Every policy in this system enforces **two independent conditions**:

```
Layer 1 — Tenant Isolation:  tenant_id = current user's tenant_id (from JWT)
Layer 2 — Role Permission:   role = 'admin' | 'manager' | 'staff' (from JWT)
```

Both must pass. A manager from Tenant A cannot access Tenant B's data even
if they somehow obtained a valid JWT — because the `tenant_id` claim in that
JWT will never match Tenant B's rows.

```sql
-- The pattern every policy follows
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid   -- Layer 1: tenant isolation
  AND auth.jwt() ->> 'role' IN ('admin', 'manager') -- Layer 2: role permission
)
```

## 3. The Three Roles

All role-based access is derived from the `role` claim in the JWT, stamped
at login by the Auth Hook.

| Role | Who they are |
|---|---|
| `admin` | Restaurant owner — full access to all data within their tenant |
| `manager` | Operational access — manages orders, customers, products, staff |
| `staff` | Limited access — primarily handles order operations |

## 4. How RLS Reads the JWT Claims

Two JWT claims are used in every policy. Both are stamped by the Auth Hook
at login time (see `Backend_Architecture_03_JWT_Auth_Hook`).

```sql
-- Read the staff member's role
auth.jwt() ->> 'role'

-- Read the staff member's tenant
(auth.jwt() ->> 'tenant_id')::uuid

-- Read the staff member's own user ID (built-in Supabase function)
auth.uid()
```

Full example — allow admins to read all rows within their tenant:

```sql
CREATE POLICY "tenant_admins_select_all"
ON table_name
FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
```

## 5. The Tenant Isolation Pattern

Tenant isolation is the first and most important check. It appears in
every single policy across all 13 tables (except `tenants` itself, which
has no staff-facing policies).

```sql
tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
```

This single expression is the complete isolation mechanism. Because
`tenant_id` is stamped into the JWT at login and cannot be altered by
the client, a staff member is permanently bound to their tenant for
the entire session.

**Why this is sufficient:** The JWT is signed by Supabase Auth using a
secret key. The client cannot modify the claims — including `tenant_id`.
Any attempt to forge a JWT with a different `tenant_id` will fail
signature validation before RLS is even evaluated.

## 6. RLS Policy Matrix

The following table defines permissions for each role across all tables.
All operations are additionally scoped to the staff member's own tenant.
Operations not listed are denied by default.

| Table | admin | manager | staff |
|---|---|---|---|
| `staff_profiles` | Full | SELECT all (own tenant), UPDATE own row | SELECT own row, UPDATE own row |
| `customers` | Full | Full | SELECT only |
| `addresses` | Full | Full | SELECT, INSERT, UPDATE |
| `categories` | Full | SELECT, INSERT, UPDATE (no DELETE) | SELECT only |
| `products` | Full | SELECT, INSERT, UPDATE (no DELETE) | SELECT only |
| `product_variants` | Full | SELECT, INSERT, UPDATE (no DELETE) | SELECT only |
| `coupons` | Full | Full | SELECT only |
| `orders` | Full | Full | SELECT, INSERT, UPDATE (no DELETE) |
| `order_items` | Full | Full | SELECT, INSERT (no UPDATE, no DELETE) |
| `payments` | Full | SELECT, UPDATE | SELECT only |
| `audit_logs` | SELECT, INSERT | INSERT only | INSERT only |
| `notifications` | Full | Own + tenant broadcasts | Own + tenant broadcasts |
| `tenants` | No staff access | No staff access | No staff access |

> **Note:** `tenants` table is accessible only via the service role key
> from the super-admin portal. No staff-facing RLS policies exist on it.

> **Note:** `audit_logs` has no DELETE policy for any role — immutability
> is enforced by a trigger that raises an exception on any DELETE attempt.

## 7. Policy Design Notes

### staff_profiles

Managers can see all staff profiles within their tenant because they are
responsible for managing staff operations. Staff can only see and edit their
own profile. Only admins can create new staff accounts or soft-delete
existing ones via `is_active = false`.

Cross-tenant access is impossible — every policy includes
`tenant_id = (auth.jwt() ->> 'tenant_id')::uuid`.

---

### categories, products, product_variants

Managers can create and modify catalog items but cannot delete them.
The `is_active = false` mechanism is sufficient for taking items out of
circulation without permanent deletion. This prevents accidental catalog
data loss.

---

### coupons

Managers have full access including DELETE — mistakes in coupon creation
should be correctable without requiring admin intervention. Deletion of
a coupon does not affect historical orders because coupon data is
snapshotted onto the order at placement time.

---

### orders, order_items

Staff can create and update orders as part of day-to-day operations.
Staff cannot delete orders — order deletion is admin-only to maintain
a complete order history.

`order_items` are immutable after creation — no UPDATE policy is defined
for any role. If a mistake is made, the order is cancelled and recreated.

---

### payments

Admins and managers can view and update payment records (e.g. recording
a refund). Staff can view payments but cannot modify them. Only admins
can delete payment records, which should be extremely rare.

---

### audit_logs

All staff roles can INSERT audit logs (every Server Action writes one).
Only admins can SELECT (read) audit logs. No role can UPDATE or DELETE
audit logs — the immutability trigger enforces this regardless of RLS.

---

### notifications

Each staff member can read their own targeted notifications and all
broadcast notifications for their tenant. The broadcast pattern is:
`staff_id = auth.uid() OR staff_id IS NULL` — both conditions are
additionally gated by `tenant_id`. A broadcast notification from Tenant A
is invisible to Tenant B's staff even though `staff_id IS NULL`.

## 8. The "Own Row" Pattern

For tables where users can only access their own record, policies use
`auth.uid()` alongside the tenant check:

```sql
-- Staff can only update their own profile
CREATE POLICY "staff_update_own_profile"
ON staff_profiles
FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.uid() = id
)
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.uid() = id
);
```

```sql
-- Managers can read all staff within their tenant
CREATE POLICY "managers_read_tenant_staff"
ON staff_profiles
FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'manager'
);
```

## 9. The Broadcast Notifications Pattern

Notifications use a combined pattern — personal notifications targeted
at a specific staff member, and broadcast notifications visible to all
staff of the same tenant.

```sql
-- Staff can read their own notifications AND tenant-scoped broadcasts
CREATE POLICY "tenant_staff_read_notifications"
ON notifications
FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND (
    staff_id = auth.uid()   -- personal notification
    OR staff_id IS NULL     -- broadcast to all tenant staff
  )
);
```

The `tenant_id` check is critical here. Without it, `staff_id IS NULL`
would return broadcast notifications from all tenants on the platform —
a serious data leak.

## 10. Special Tables — No Standard RLS

### `tenants`

The `tenants` table has RLS enabled but **no staff-facing policies**.
A staff member's JWT grants zero access to this table. All reads and
writes to `tenants` are performed via the service role key from the
super-admin portal only.

```sql
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
-- No policies defined for staff roles intentionally.
-- All access via service role key from super-admin application only.
```

### `audit_logs` — immutability override

`audit_logs` has RLS enabled with SELECT and INSERT policies, but UPDATE
and DELETE are blocked by a database trigger — not by absence of policy.
The trigger raises an exception on any UPDATE or DELETE attempt regardless
of who is calling.

## 11. RLS Must Be Enabled on Every Table

RLS must be explicitly enabled on each table. A table with RLS disabled
allows any authenticated user to access all its data — regardless of role
or tenant.

```sql
-- Apply to all 13 tables including tenants
ALTER TABLE tenants           ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants  ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons           ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications     ENABLE ROW LEVEL SECURITY;
```

**Also enable for `product_images`** (child table defined inside
`DB_Table_05_products`):

```sql
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
```

## 12. Complete Policy Reference

The full SQL for every policy is defined in the individual DB table
documents (`DB_Table_01` through `DB_Table_12`). This section provides
the canonical pattern template that all policies follow.

### Single-role policy template

```sql
CREATE POLICY "{tenant}_{role}_{operation}_{table}"
ON {table}
FOR {SELECT | INSERT | UPDATE | DELETE}
USING (                                                    -- for SELECT, UPDATE, DELETE
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = '{role}'
)
WITH CHECK (                                               -- for INSERT, UPDATE
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = '{role}'
);
```

### Multi-role policy template

```sql
CREATE POLICY "{tenant}_staff_{operation}_{table}"
ON {table}
FOR {SELECT | INSERT | UPDATE | DELETE}
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);
```

### Own-row policy template

```sql
CREATE POLICY "{tenant}_staff_{operation}_own_{table}"
ON {table}
FOR {UPDATE | SELECT}
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.uid() = id
)
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.uid() = id
);
```

## 13. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial RLS matrix finalized |
| 2.0 | 2026-03-23 | Full rewrite for multi-tenant platform architecture |
| 2.0 | 2026-03-23 | Two-layer security model documented — tenant isolation + role permission |
| 2.0 | 2026-03-23 | Every policy now includes `tenant_id = (auth.jwt() ->> 'tenant_id')::uuid` as first condition |
| 2.0 | 2026-03-23 | `tenants` table added — no staff-facing policies, service role only |
| 2.0 | 2026-03-23 | Broadcast notifications pattern documented — `tenant_id` gates `staff_id IS NULL` |
| 2.0 | 2026-03-23 | `audit_logs` immutability clarified — trigger blocks UPDATE/DELETE regardless of RLS |
| 2.0 | 2026-03-23 | Policy matrix updated — 13 tables, all roles tenant-scoped |
| 2.0 | 2026-03-23 | Complete policy template reference added |
| 2.0 | 2026-03-23 | `product_images` RLS enablement noted |
