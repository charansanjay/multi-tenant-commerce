# Backend Architecture — 05: Database Triggers

**Project:** Multi-Tenant Commerce
**Version:** 2.0
**Status:** Finalized

## Table of Contents

- [1. Overview](#1-overview)
- [2. Trigger Type 1 — `updated_at` Timestamp](#2-trigger-type-1--updated_at-timestamp)
- [3. Trigger Type 2 — Audit Logging](#3-trigger-type-2--audit-logging)
- [4. Trigger Type 3 — New Order Notification](#4-trigger-type-3--new-order-notification)
- [5. Trigger Type 4 — Auto-Mark Notifications as Read on Order Completion](#5-trigger-type-4--auto-mark-notifications-as-read-on-order-completion)
- [6. Summary](#6-summary)
- [7. Changelog](#7-changelog)

## 1. Overview

Database triggers are rules attached to tables that fire automatically when
a specified event occurs — an INSERT, UPDATE, or DELETE. They execute at
the database level, meaning they run reliably every single time without any
application code needing to remember to call them.

This project uses four types of triggers, each solving a specific
cross-cutting concern that would otherwise need to be handled repeatedly
and inconsistently across every module.

## 2. Trigger Type 1 — `updated_at` Timestamp

### 2.1. Purpose

Every table that supports updates has an `updated_at` column. This column
must always reflect the exact time a row was last modified. A trigger
handles this automatically — no application code needs to set it.

### 2.2. Behaviour

```text
Any UPDATE operation on a watched table
      ↓
Trigger fires before the update is committed
      ↓
Sets updated_at = NOW() on the affected row
      ↓
Update is committed with the correct timestamp
```

### 2.3. Applies To

The trigger applies to tables that have an `updated_at` column and support
row updates. Two tables are intentionally excluded:

- `order_items` — immutable after creation. No `updated_at` column exists.
- `audit_logs` — append-only. No `updated_at` column exists.

| Table | Has `updated_at` | Trigger applied |
|---|---|---|
| `tenants` | ✅ | ✅ |
| `staff_profiles` | ✅ | ✅ |
| `customers` | ✅ | ✅ |
| `addresses` | ✅ | ✅ |
| `categories` | ✅ | ✅ |
| `products` | ✅ | ✅ |
| `product_variants` | ✅ | ✅ |
| `coupons` | ✅ | ✅ |
| `orders` | ✅ | ✅ |
| `payments` | ✅ | ✅ |
| `notifications` | ❌ | ❌ |
| `order_items` | ❌ (immutable) | ❌ |
| `audit_logs` | ❌ (append-only) | ❌ |

### 2.4. Implementation Pattern

A single reusable function shared across all applicable tables:

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

Attached to each applicable table:

```sql
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON {table_name}
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## 3. Trigger Type 2 — Audit Logging

### 3.1. Purpose

The `audit_logs` table records every significant write operation — who
did what, to which record, and when. Rather than scattering audit log
INSERT statements throughout every Server Action, a database trigger
writes the audit entry automatically whenever a watched table is modified.

### 3.2. Behaviour

```text
INSERT, UPDATE, or DELETE on a watched table
      ↓
Trigger fires after the operation is committed
      ↓
Writes a record to audit_logs containing:
  - tenant_id    (from the affected row's tenant_id column)
  - tenant_name  (from JWT claim — snapshotted at write time)
  - staff_id     (from auth.uid())
  - staff_name   (from JWT claim — snapshotted at write time)
  - staff_email  (from auth.jwt())
  - staff_role   (from JWT claim — snapshotted at write time)
  - action       ('INSERT' | 'UPDATE' | 'DELETE')
  - entity_type  (table name)
  - entity_id    (primary key of the affected row)
  - old_values   (JSON snapshot before the change — null for INSERT)
  - new_values   (JSON snapshot after the change — null for DELETE)
  - created_at   (current timestamp)
```

### 3.3. Tables With Audit Logging Enabled

| Table | Audit logged | Reason |
|---|---|---|
| `staff_profiles` | ✅ | Staff account changes are sensitive |
| `customers` | ✅ | Customer data changes need tracking |
| `addresses` | ✅ | Address changes affect order history |
| `categories` | ✅ | Catalog changes |
| `products` | ✅ | Catalog changes |
| `product_variants` | ✅ | Pricing changes especially |
| `coupons` | ✅ | Financial impact |
| `orders` | ✅ | Core business record |
| `order_items` | ✅ | Core business record (INSERT only — immutable) |
| `payments` | ✅ | Financial record |
| `audit_logs` | ❌ | Would cause infinite recursion |
| `notifications` | ❌ | Low operational value, high noise |
| `tenants` | ❌ | Managed by super-admin — not via staff RLS |

### 3.4. Implementation Pattern

The audit log function reads the tenant context and staff snapshot from
the JWT claims. This ensures every auto-generated audit log entry is
fully self-contained — no joins needed to understand who did what.

```sql
CREATE OR REPLACE FUNCTION write_audit_log()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id   uuid;
  v_tenant_name text;
  v_staff_name  text;
  v_staff_email text;
  v_staff_role  text;
BEGIN
  -- Read tenant and staff context from JWT claims
  -- These are stamped by the Auth Hook at login time
  v_tenant_id   := (auth.jwt() ->> 'tenant_id')::uuid;
  v_tenant_name := auth.jwt() ->> 'tenant_name';
  v_staff_name  := auth.jwt() ->> 'staff_name';
  v_staff_email := auth.jwt() ->> 'email';
  v_staff_role  := auth.jwt() ->> 'role';

  INSERT INTO audit_logs (
    tenant_id,
    tenant_name,
    staff_id,
    staff_name,
    staff_email,
    staff_role,
    action,
    entity_type,
    entity_id,
    old_values,
    new_values,
    created_at
  ) VALUES (
    v_tenant_id,
    v_tenant_name,
    auth.uid(),
    v_staff_name,
    v_staff_email,
    v_staff_role,
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE row_to_json(OLD)::jsonb END,
    CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE row_to_json(NEW)::jsonb END,
    NOW()
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Attached to each watched table:

```sql
CREATE TRIGGER audit_log_trigger
AFTER INSERT OR UPDATE OR DELETE ON {table_name}
FOR EACH ROW EXECUTE FUNCTION write_audit_log();
```

> **Note:** The function uses `SECURITY DEFINER` so it can INSERT into
> `audit_logs` even when called by a `staff` role that has only INSERT
> permission. The INSERT itself is covered by the `tenant_staff_insert_audit_logs`
> RLS policy.

> **Note:** `row_to_json(OLD)` and `row_to_json(NEW)` produce a full row
> snapshot. For large tables this may include more fields than needed.
> Server Actions that want a more targeted snapshot (changed fields only)
> should write their own audit log INSERT rather than relying on this trigger.
> The trigger is a safety net — Server Actions are the primary audit
> mechanism.

> **Note:** For `order_items` (which is INSERT-only/immutable), only the
> INSERT trigger fires. No UPDATE or DELETE will ever occur on this table,
> so the trigger attachment is:
>
> ```sql
> CREATE TRIGGER audit_log_trigger
> AFTER INSERT ON order_items
> FOR EACH ROW EXECUTE FUNCTION write_audit_log();
> ```

## 4. Trigger Type 3 — New Order Notification

### 4.1. Purpose

When a new order is created, all staff members of the **same tenant** must
receive a notification. This trigger automatically inserts a broadcast
notification row the moment a new order is inserted.

### 4.2. Behaviour

```text
New row inserted into orders table
      ↓
Trigger fires after the INSERT is committed
      ↓
Reads tenant_id from the new order row
      ↓
Inserts one broadcast notification row for this tenant
(staff_id = NULL — broadcast to all tenant staff)
      ↓
Supabase Realtime pushes to all connected staff of this tenant
```

### 4.3. Who Receives Notifications

All active staff members within the **same tenant** as the order.
The notification uses the broadcast pattern (`staff_id = NULL`) rather
than inserting one row per staff member. This is more efficient and
aligns with the multi-tenant broadcast design.

> **Note:** This is a change from the v1.0 design which inserted one row
> per staff member. The broadcast pattern (`staff_id = NULL, tenant_id =
> order.tenant_id`) achieves the same result with a single INSERT —
> all tenant staff receive it via the Realtime subscription filter.

### 4.4. Notification Content

| Field | Value |
|---|---|
| `tenant_id` | `NEW.tenant_id` — from the order row |
| `staff_id` | `NULL` — broadcast to all tenant staff |
| `type` | `'new_order'` |
| `severity` | `'info'` |
| `title` | `'New Order Received'` |
| `message` | `'Order ORD-2026-XXXXX has been placed'` |
| `entity_type` | `'order'` |
| `entity_id` | the new order's UUID |
| `entity_label` | the order number |

### 4.5. Implementation Pattern

```sql
CREATE OR REPLACE FUNCTION notify_staff_new_order()
RETURNS TRIGGER AS $$
BEGIN
  -- Broadcast to all staff of this tenant (staff_id = NULL)
  -- RLS on notifications ensures only this tenant's staff see it
  INSERT INTO notifications (
    tenant_id,
    staff_id,
    type,
    severity,
    title,
    message,
    entity_type,
    entity_id,
    entity_label
  ) VALUES (
    NEW.tenant_id,
    NULL,
    'new_order',
    'info',
    'New Order Received',
    'Order ' || NEW.order_number || ' has been placed',
    'order',
    NEW.id,
    NEW.order_number
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER new_order_notification_trigger
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION notify_staff_new_order();
```

## 5. Trigger Type 4 — Auto-Mark Notifications as Read on Order Completion

### 5.1. Purpose

When an order reaches a terminal status (`completed`, `cancelled`), all
notification rows for that order within the same tenant are automatically
marked as read. Staff logging in for a later shift only see notifications
for orders that still require attention.

### 5.2. The Problem It Solves

Without this trigger, a staff member logging in for an evening shift could
see dozens of unread notifications for orders already fully handled. The
inbox should only surface actionable information.

### 5.3. Behaviour

```text
Order status updated to a terminal status
      ↓
Trigger fires after the UPDATE is committed
      ↓
Updates notification rows WHERE:
  entity_type = 'order'
  AND entity_id = order id
  AND tenant_id = order.tenant_id  ← tenant-scoped
  AND read_at IS NULL
      ↓
Sets read_at = NOW() for all matching rows
```

### 5.4. Which Statuses Trigger the Auto-Mark

Terminal statuses only — the order is fully handled, no further action
needed:

| Status | Auto-marks notifications as read |
|---|---|
| `completed` | ✅ |
| `cancelled` | ✅ |
| `pending` | ❌ |
| `preparing` | ❌ |
| `ready` | ❌ |
| `out_for_delivery` | ❌ |

> **Note:** `out_for_delivery` is not a terminal status — the order still
> requires final confirmation. Only `completed` and `cancelled` are terminal.
> The original v1.0 document incorrectly included `'Delivered'` as a status
> — this does not exist in the `order_status` enum. Corrected here.

### 5.5. Implementation Pattern

```sql
CREATE OR REPLACE FUNCTION auto_mark_notifications_read_on_order_complete()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire when status changes to a terminal state
  IF NEW.status IN ('completed', 'cancelled')
    AND OLD.status NOT IN ('completed', 'cancelled')
  THEN
    UPDATE notifications
    SET read_at = NOW()
    WHERE entity_type = 'order'
      AND entity_id = NEW.id
      AND tenant_id = NEW.tenant_id   -- tenant-scoped
      AND read_at IS NULL;            -- unread only
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER auto_mark_notifications_read_trigger
AFTER UPDATE OF status ON orders
FOR EACH ROW EXECUTE FUNCTION auto_mark_notifications_read_on_order_complete();
```

### 5.6. Important Notes

- Fires only when `status` specifically changes — not on every order update.
- `OLD.status NOT IN (...)` prevents re-firing between terminal states.
- Uses `read_at = NOW()` instead of `is_read = true` — matches the
  `notifications` table design which uses a timestamp, not a boolean.
- Scoped to `tenant_id = NEW.tenant_id` — only marks notifications
  belonging to the same tenant as the order.
- Staff can still manually mark individual notifications as read at any
  time — this trigger handles automatic cleanup only.

## 6. Summary

| Trigger | Event | Tables | Does |
|---|---|---|---|
| `set_updated_at` | BEFORE UPDATE | 10 tables (all with `updated_at` column) | Sets `updated_at = NOW()` |
| `audit_log_trigger` | AFTER INSERT, UPDATE, DELETE | 10 tables (excluding `audit_logs`, `notifications`, `tenants`) | Writes tenant-scoped audit entry with staff snapshot |
| `new_order_notification_trigger` | AFTER INSERT | `orders` only | Inserts one broadcast notification scoped to the order's tenant |
| `auto_mark_notifications_read_trigger` | AFTER UPDATE OF status | `orders` only | Sets `read_at = NOW()` on all tenant notification rows when order reaches terminal status |

## 7. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial database triggers design finalized |
| 1.1 | 2026-03-20 | Added Trigger Type 4 — auto-mark notifications as read on order completion |
| 2.0 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 2.0 | 2026-03-23 | `updated_at` trigger table list corrected — `order_items` and `audit_logs` excluded (no `updated_at` column). `tenants` table added. |
| 2.0 | 2026-03-23 | `write_audit_log` function updated — now reads `tenant_id`, `tenant_name`, `staff_name`, `staff_role` from JWT claims and includes them in every audit log INSERT |
| 2.0 | 2026-03-23 | `notify_staff_new_order` updated — now inserts one broadcast notification (`staff_id = NULL`) scoped to `NEW.tenant_id` instead of one row per staff member |
| 2.0 | 2026-03-23 | `auto_mark_notifications_read` updated — status values corrected to lowercase enum values (`completed`, `cancelled`). `read_at = NOW()` replaces `is_read = true`. Tenant scope added. |
| 2.0 | 2026-03-23 | `order_items` audit trigger noted as INSERT-only due to immutability |
