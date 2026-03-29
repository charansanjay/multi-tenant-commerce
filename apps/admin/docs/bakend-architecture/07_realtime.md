# Backend Architecture — 07: Realtime Channel Design

**Project:** Multi-Tenant Commerce  
**Version:** 2.0  
**Status:** Finalized  

## Table of Contents

- [1. Overview](#1-overview)
- [2. Use Case — Notification Inbox](#2-use-case--notification-inbox)
- [3. Channel Design](#3-channel-design)
- [4. Tenant Isolation in Realtime](#4-tenant-isolation-in-realtime)
- [5. Subscription Lifecycle](#5-subscription-lifecycle)
- [6. Where the Subscription Lives](#6-where-the-subscription-lives)
- [7. State Management](#7-state-management)
- [8. Implementation Pattern](#8-implementation-pattern)
- [9. Scalability Note](#9-scalability-note)
- [10. Summary](#10-summary)
- [11. Changelog](#11-changelog)

## 1. Overview

Supabase Realtime maintains a persistent open connection between the
browser and Supabase. When a watched database row changes, Supabase pushes
the update to all subscribed browsers instantly — without polling.

This project uses Realtime for one specific purpose: the staff notification
inbox. When a new order arrives, a database trigger inserts a broadcast
notification row, and Realtime pushes it to every connected staff member
of the same tenant immediately.

## 2. Use Case — Notification Inbox

The notification inbox must update in real time when new orders are placed.
Staff should see the notification bell badge update and new notifications
appear without refreshing the page.

**Read/unread state is not handled via Realtime.** When a staff member
marks a notification as read, this is a standard Server Action update.
Only the arrival of new notifications is handled via the Realtime
subscription.

## 3. Channel Design

Each logged-in staff member opens **two Realtime listeners** on a single
channel — one for personal notifications and one for tenant broadcast
notifications.

This is a change from v1.0 which only had a personal notification listener.
In v1.0, the new order trigger inserted one row per staff member. In v2.0,
the trigger inserts a single broadcast row (`staff_id = NULL`) — so the
subscription must also listen for `staff_id IS NULL` rows belonging to the
current tenant.

| Listener | Filter | Receives |
|---|---|---|
| Personal | `staff_id=eq.{current_user_id}` | Notifications targeted at this staff member only |
| Broadcast | `staff_id=is.null` | Notifications broadcast to all tenant staff |

RLS on the `notifications` table ensures the broadcast listener only
receives rows belonging to the current tenant — even though the filter
is `staff_id IS NULL`, rows from other tenants are never returned.

### 3.1. Why a Single Channel with Two Listeners

Both listeners are attached to the same channel object. This keeps the
connection count to one per staff member regardless of notification type.
A single channel with two `on()` event handlers is more efficient than
two separate channel connections.

## 4. Tenant Isolation in Realtime

Realtime tenant isolation is enforced at two levels:

**Level 1 — RLS on `notifications` table:**
The RLS SELECT policy on `notifications` requires
`tenant_id = (auth.jwt() ->> 'tenant_id')::uuid`. Supabase Realtime
respects RLS — rows that would be blocked by RLS are never pushed to
the subscriber, regardless of the subscription filter.

**Level 2 — JWT authentication on the Realtime connection:**
The browser client uses the staff member's session JWT. The `tenant_id`
claim in that JWT is the scope boundary. A staff member from Tenant A
cannot receive Tenant B's notifications even if they construct a
subscription filter that would technically match Tenant B's rows.

The practical result: **the frontend does not need to filter by
`tenant_id` explicitly.** RLS handles it. The filters `staff_id=eq.{id}`
and `staff_id=is.null` are sufficient — Supabase will never push
out-of-tenant rows through.

## 5. Subscription Lifecycle

```text
Staff logs in → authenticated layout mounts
      ↓
NotificationProvider opens Realtime channel: notifications:{staff_id}
      ↓
Channel attaches two listeners:
  - INSERT WHERE staff_id = current_user_id  (personal)
  - INSERT WHERE staff_id IS NULL            (broadcast — RLS scopes to tenant)
      ↓
New order placed
      ↓
DB trigger inserts one broadcast notification (staff_id = NULL, tenant_id = order.tenant_id)
      ↓
Supabase pushes the row to all connected staff of this tenant
      ↓
Both personal and broadcast listeners check — broadcast listener matches
      ↓
Notification bell badge increments → inbox panel updates
      ↓
Staff logs out → channel unsubscribed and closed → connection cleaned up
```

## 6. Where the Subscription Lives

The subscription is initialised in `NotificationProvider.tsx` — a Client
Component at the root of the authenticated layout. This ensures:

- The subscription opens once per session, not per page navigation
- Navigation between modules does not create duplicate subscriptions
- The subscription is properly cleaned up on unmount (logout)

```text
app/
  (admin)/
    layout.tsx                ← Server Component — reads user, tenant_id from session
      NotificationProvider.tsx ← Client Component — holds both Realtime listeners
```

`NotificationProvider` receives both `staffId` and `tenantId` as props
from the server layout (already established in Frontend Architecture).

## 7. State Management

Incoming Realtime notifications are handled by the Zustand
`notifications.store.ts`. When a new notification arrives — whether
personal or broadcast:

1. The notification is appended to the in-memory notifications list
2. The unread count increments
3. The notification bell and inbox panel re-render automatically

No distinction between personal and broadcast in the store — both are
added to the same list and handled identically in the UI.

## 8. Implementation Pattern

```typescript
// NotificationProvider.tsx — Client Component
'use client'

import { useEffect } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'
import { useNotificationStore } from '@/stores/notifications.store'

interface NotificationProviderProps {
  staffId: string
  tenantId: string
  children: React.ReactNode
}

export function NotificationProvider({ staffId, tenantId, children }: NotificationProviderProps) {
  const addNotification = useNotificationStore(s => s.addNotification)

  useEffect(() => {
    const supabase = createBrowserClient()

    const channel = supabase
      .channel(`notifications:${staffId}`)

      // Listener 1: personal notifications targeted at this staff member
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `staff_id=eq.${staffId}`,
        },
        (payload) => {
          addNotification(payload.new)
        }
      )

      // Listener 2: broadcast notifications for all tenant staff
      // RLS ensures only this tenant's broadcasts are received —
      // no explicit tenant_id filter needed here
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: 'staff_id=is.null',
        },
        (payload) => {
          addNotification(payload.new)
        }
      )

      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [staffId, addNotification])

  return <>{children}</>
}
```

## 9. Scalability Note

Each logged-in staff member holds one open Realtime channel with two
event listeners. At the expected concurrent session count (≥ 50 per NFRs),
this is well within Supabase's standard plan limits.

The broadcast pattern (`staff_id = NULL`) is more scalable than the
previous per-staff INSERT approach. A new order now triggers one DB
INSERT instead of N INSERTs (one per active staff member). As tenant
staff counts grow, the notification trigger remains O(1) instead of O(N).

## 10. Summary

| Channel | Table | Event | Listeners | Lives in |
|---|---|---|---|---|
| `notifications:{staff_id}` | `notifications` | INSERT only | Personal (`staff_id=eq.{id}`) + Broadcast (`staff_id=is.null`) | `NotificationProvider.tsx` — top-level authenticated layout |

**Tenant isolation mechanism:** RLS on `notifications` table — no
explicit `tenant_id` filter needed in the subscription.

## 11. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial Realtime channel design finalized |
| 2.0 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 2.0 | 2026-03-23 | Channel now has two listeners — personal and broadcast — matching the new trigger design |
| 2.0 | 2026-03-23 | New Section 4 — Tenant Isolation in Realtime — explains RLS as the isolation mechanism |
| 2.0 | 2026-03-23 | `NotificationProvider` updated — now receives `tenantId` prop alongside `staffId` |
| 2.0 | 2026-03-23 | Subscription lifecycle updated — broadcast notification flow documented |
| 2.0 | 2026-03-23 | Scalability note updated — broadcast pattern is O(1) vs previous O(N) per-staff INSERT |
