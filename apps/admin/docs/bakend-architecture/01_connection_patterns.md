# Backend Architecture — 01: Connection Patterns

**Project:** Multi-Tenant Commerce
**Version:** 1.1  
**Status:** Finalized

## Table of Contents

- [1. Overview](#1-overview)
- [2. The Three Supabase Clients](#2-the-three-supabase-clients)
  - [2.1. Server Client](#21-server-client)
  - [2.2. Browser Client](#22-browser-client)
  - [2.3. Admin Client](#23-admin-client)
- [3. Environment Variables](#3-environment-variables)
- [4. Call Flow Summary](#4-call-flow-summary)
- [5. What to Avoid](#5-what-to-avoid)
- [6. Changelog](#6-changelog)

## 1. Overview

This document defines how the Next.js application communicates with Supabase. Because Next.js App Router runs code in two distinct environments — the server and the browser — two separate Supabase client configurations are required. A third configuration exists exclusively for privileged server-side operations that must bypass Row Level Security.

## 2. The Three Supabase Clients

### 2.1. Server Client

| Attribute | Value |
|---|---|
| **Used in** | Server Components, Server Actions |
| **Key used** | Anon key + user session read from cookies |
| **Respects RLS** | Yes |
| **Package** | `@supabase/ssr` |

The server client is the most commonly used client in the application. It reads the authenticated user's session from cookies (handled by `@supabase/ssr`) and attaches it to every Supabase request. Because the session carries the JWT with the staff `role` and `tenant_id` claims, all RLS policies evaluate correctly — both role-based access and tenant isolation are enforced automatically.

This client is used for:

- Fetching data in Server Components (orders, customers, products, etc.)
- All Server Action mutations (create, update, delete operations)
- Any server-side operation that should respect the logged-in user's permissions

**Rule:** This is the default client. Use it unless there is an explicit reason to use one of the other two clients.

---

### 2.2. Browser Client

| Attribute | Value |
|---|---|
| **Used in** | Client Components, Realtime subscriptions |
| **Key used** | Anon key only |
| **Respects RLS** | Yes |
| **Package** | `@supabase/ssr` |

The browser client runs exclusively in the user's browser. It uses the anon key, which is safe to expose publicly because RLS policies are active and enforce all access rules. The session is automatically managed via cookies shared with the server client.

This client is used for:

- Supabase Realtime channel subscriptions (notification inbox)
- Any Client Component that needs to interact with Supabase directly

**Rule:** Never use the browser client for data fetching that can be done in a Server Component. Prefer Server Components for initial data loads to avoid client-side waterfalls.

---

### 2.3. Admin Client

| Attribute | Value |
|---|---|
| **Used in** | Supabase Edge Functions only |
| **Key used** | Service Role Key |
| **Respects RLS** | No — bypasses all RLS policies |
| **Package** | `@supabase/supabase-js` |

The admin client uses the Service Role Key, which grants full unrestricted access to the database. It bypasses all RLS policies entirely. Because of this, it must never be used outside of Edge Functions and must never be exposed to the browser or included in the client bundle.

This client is used for:

- `generate-order-number` Edge Function
- `increment-coupon-usage` Edge Function
- `generate-invoice-pdf` Edge Function
- The Auth Hook that stamps the JWT `role` and `tenant_id` claims

**Rule:** The Service Role Key (`SUPABASE_SERVICE_ROLE_KEY`) is a server-only environment variable. It must never appear in any file prefixed with `NEXT_PUBLIC_` and must never be referenced in a Client Component.

## 3. Environment Variables

```bash
# Safe to expose to the browser
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Server only — never expose to the client
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## 4. Call Flow Summary

```text
Client Component
      ↓
Server Action (server client)
      ↓
Supabase Database (RLS enforced)
```

```text
Client Component (Realtime)
      ↓
Browser client → Supabase Realtime channel
```

```text
Server Action
      ↓
Edge Function (admin client)
      ↓
Supabase Database (RLS bypassed — controlled by Edge Function's own auth checks)
```

## 5. What to Avoid

- **Never** call an Edge Function directly from a Client Component. Always route through a Server Action.
- **Never** use the admin client in Server Components or Server Actions. Use it only inside Edge Functions.
- **Never** create Next.js API routes that proxy Supabase calls. Server Components and Server Actions call Supabase directly.

## 6. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial connection patterns finalized |
| 1.1 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 1.1 | 2026-03-23 | Server client description updated — JWT now carries both `role` and `tenant_id` claims |
| 1.1 | 2026-03-23 | Admin client bullet updated — Auth Hook stamps `role` and `tenant_id` |
