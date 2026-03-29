# Frontend Architecture Global — Admin Portal

**Project:** # Multi-Tenant Commerce
**Version:** 2.0
**Scope:** Global — applies to all modules
**Status:** Finalized
**Date:** 2026-03-23

## Table of Contents

- [1. Folder Structure](#1-folder-structure)
- [2. Server vs Client Components](#2-server-vs-client-components)
  - [2.1. Pattern: Server shell → Client island](#21-pattern-server-shell--client-island)
- [3. Routing & URL Patterns](#3-routing--url-patterns)
  - [3.1. Route Groups](#31-route-groups)
  - [3.2. URL Structure](#32-url-structure)
  - [3.3. Nested Layouts](#33-nested-layouts)
  - [3.4. Dynamic Routes](#34-dynamic-routes)
- [4. Authentication Flow](#4-authentication-flow)
  - [4.1. Proxy (formerly Middleware)](#41-proxy-formerly-middleware)
  - [4.2. Role-to-Route Map](#42-role-to-route-map)
  - [4.3. Auth Flow Diagram](#43-auth-flow-diagram)
  - [4.4. Sign-In Page](#44-sign-in-page)
- [5. Global State Shape](#5-global-state-shape)
  - [5.1. TanStack Query — Server State](#51-tanstack-query--server-state)
    - [Query Key Conventions](#query-key-conventions)
    - [QueryClient Setup](#queryclient-setup)
  - [5.2. Zustand — Client State](#52-zustand--client-state)
- [6. Shared Layout](#6-shared-layout)
  - [6.1. AdminLayout (`app/(admin)/layout.tsx`)](#61-adminlayout-appadminlayouttsx)
  - [6.2. Sidebar](#62-sidebar)
  - [6.3. Topbar](#63-topbar)
  - [6.4. PageContainer](#64-pagecontainer)
  - [6.5. PageHeader](#65-pageheader)
- [7. Error, Loading & Empty States](#7-error-loading--empty-states)
  - [7.1. Error Boundaries](#71-error-boundaries)
  - [7.2. Loading States](#72-loading-states)
  - [7.3. Empty States](#73-empty-states)
  - [7.4. Toast Notifications](#74-toast-notifications)
- [8. Supabase Client Initialisation](#8-supabase-client-initialisation)
  - [8.1. Server Client](#81-server-client-libsupabaseserverts)
  - [8.2. Browser Client](#82-browser-client-libsupabaseclientts)
  - [8.3. Proxy Client](#83-proxy-client-libsupabaseproxyts)
  - [8.4. Quick Reference](#84-quick-reference)
- [9. i18n Architecture](#9-i18n-architecture)
- [10. Data Fetching Conventions](#10-data-fetching-conventions)
- [11. Form & Mutation Conventions](#11-form--mutation-conventions)
- [12. Audit Logging Convention](#12-audit-logging-convention)
- [13. Environment Variables](#13-environment-variables)
- [14. Changelog](#14-changelog)

## 1. Folder Structure

```text
src/
├── app/                          ← Next.js App Router (pages, layouts, routes)
│   ├── (auth)/
│   │   └── login/
│   │       └── page.tsx
│   ├── (admin)/                  ← Protected route group (requires auth)
│   │   ├── layout.tsx            ← Root admin layout (sidebar + topbar)
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   ├── customers/
│   │   │   ├── page.tsx
│   │   │   └── [id]/
│   │   │       └── page.tsx
│   │   ├── catalog/
│   │   │   ├── categories/
│   │   │   │   └── page.tsx
│   │   │   └── products/
│   │   │       ├── page.tsx
│   │   │       └── [id]/
│   │   │           └── page.tsx
│   │   ├── orders/
│   │   │   ├── page.tsx
│   │   │   └── [id]/
│   │   │       └── page.tsx
│   │   ├── addresses/
│   │   │   └── page.tsx
│   │   ├── sales/
│   │   │   └── page.tsx
│   │   ├── settings/
│   │   │   └── page.tsx
│   │   └── audit-logs/
│   │       └── page.tsx
│   ├── error.tsx                 ← Root error boundary
│   ├── not-found.tsx
│   └── layout.tsx                ← Root HTML layout (QueryProvider, i18n)
│
├── components/                   ← Shared, module-agnostic UI components
│   ├── ui/                       ← Design system components (fully custom, owned)
│   ├── layout/
│   │   ├── Sidebar.tsx
│   │   ├── Topbar.tsx
│   │   └── PageContainer.tsx
│   └── shared/
│       ├── DataTable.tsx         ← Generic TanStack Table wrapper
│       ├── ConfirmDialog.tsx
│       ├── StatusBadge.tsx
│       ├── EmptyState.tsx
│       └── PageHeader.tsx
│
├── modules/                      ← Feature modules (self-contained)
│   ├── dashboard/
│   ├── customers/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── actions/
│   │   ├── queries/
│   │   └── types.ts
│   ├── catalog/
│   │   ├── categories/
│   │   └── products/
│   ├── orders/
│   ├── addresses/
│   ├── sales/
│   ├── settings/
│   ├── audit-logs/
│   └── notifications/
│
├── lib/
│   ├── supabase/
│   │   ├── server.ts             ← Supabase server client (Server Components, Actions)
│   │   ├── client.ts             ← Supabase browser client (Client Components)
│   │   └── proxy.ts              ← Supabase session refresh helper for proxy
│   ├── utils.ts                  ← Shared utilities (cn(), formatCurrency(), etc.)
│   └── constants.ts              ← App-wide constants (roles, statuses, etc.)
│
├── hooks/
│   ├── useCurrentUser.ts         ← Reads session, role, and tenant_id from JWT
│   ├── useCurrentTenant.ts       ← Reads tenant context (id, name, settings)
│   └── useRoleGuard.ts           ← Client-side role check for conditional rendering
│
├── stores/
│   ├── ui.store.ts               ← Sidebar state, active module
│   ├── notifications.store.ts    ← Unread count, panel open/closed
│   ├── table.store.ts            ← Selected rows, column visibility
│   └── modals.store.ts           ← Open modal + entity ID
│
├── types/
│   ├── database.types.ts         ← Generated via `supabase gen types typescript`
│   └── index.ts                  ← Re-exports + shared app types
│
└── i18n/
    ├── en.json
    ├── cs.json
    └── de.json
```

### Key Rules

- `app/` contains only routing files (`page.tsx`, `layout.tsx`, `error.tsx`,
  `loading.tsx`). No business logic lives here.
- `modules/{name}/` is the home for all module-specific logic — components,
  hooks, Server Actions, query functions, and types.
- Cross-module dependencies are **forbidden**. Shared logic lives in `lib/`
  or `components/`.
- `components/` is for genuinely shared, module-agnostic components only.
- **Tenant isolation is never handled in the frontend.** RLS policies on the
  database enforce it. The frontend simply makes queries — Supabase returns
  only the current tenant's data automatically.

## 2. Server vs Client Components

Next.js 16 App Router defaults every component to a **Server Component**.
Use `"use client"` only when necessary.

| Scenario | Component type |
|---|---|
| Initial data fetch from Supabase | Server Component |
| Static layout rendering (sidebar, topbar shell) | Server Component |
| Interactive UI (modals, dropdowns, forms) | Client Component |
| TanStack Query hooks | Client Component |
| Zustand stores | Client Component |
| Supabase Realtime subscriptions | Client Component |

### 2.1. Pattern: Server shell → Client island

```tsx
// app/(admin)/orders/page.tsx — Server Component
import { createServerClient } from '@/lib/supabase/server'
import { OrdersTable } from '@/modules/orders/components/OrdersTable'

export default async function OrdersPage() {
  const supabase = createServerClient()
  // RLS automatically scopes this to the current tenant — no tenant_id filter needed
  const { data: initialOrders } = await supabase
    .from('orders')
    .select('...')
    .order('created_at', { ascending: false })
    .limit(50)

  return <OrdersTable initialData={initialOrders} />
}
```

```tsx
// modules/orders/components/OrdersTable.tsx — Client Component
'use client'
import { useQuery } from '@tanstack/react-query'

export function OrdersTable({ initialData }) {
  const { data } = useQuery({
    queryKey: ['orders'],
    queryFn: fetchOrders,
    initialData,   // ← Hydrates from server-fetched data, no client waterfall
  })
  // ...
}
```

The server fetches initial data, serialises it as props, and the client
component uses it as `initialData` in TanStack Query. No loading spinner
on initial paint.

> **Note on tenant scoping in queries:** You will notice that no explicit
> `tenant_id` filter appears in any Supabase query. This is intentional.
> RLS policies on every table enforce tenant isolation at the database level.
> A staff member's JWT contains their `tenant_id` claim — Supabase reads it
> and applies the policy automatically. The frontend never needs to filter by
> tenant — it simply cannot see data belonging to another tenant.

## 3. Routing & URL Patterns

### 3.1. Route Groups

| Group | Path prefix | Purpose |
|---|---|---|
| `(auth)` | `/login` | Unauthenticated pages |
| `(admin)` | All other routes | Protected — requires valid session |

---

### 3.2. URL Structure

```text
/login

/dashboard

/customers
/customers/[id]

/catalog/categories
/catalog/products
/catalog/products/[id]

/orders
/orders/[id]

/addresses

/sales

/settings

/audit-logs
```

---

### 3.3. Nested Layouts

```text
app/layout.tsx                  ← HTML shell, QueryClientProvider, IntlProvider, Sonner
└── app/(admin)/layout.tsx      ← AdminLayout (Sidebar + Topbar + PageContainer)
    └── app/(admin)/*/page.tsx  ← Module pages
```

---

### 3.4. Dynamic Routes

`[id]` segments are used for detail views (`/orders/[id]`,
`/customers/[id]`, `/catalog/products/[id]`). These pages fetch the
specific entity server-side and render the detail view.

## 4. Authentication Flow

Supabase Auth handles all session management. `@supabase/ssr` provides
cookie-based sessions compatible with Next.js App Router.

### 4.1. Proxy (formerly Middleware)

`proxy.ts` runs on every request before the route handler. It:

1. Refreshes the Supabase session (rotates access token if expired).
2. Reads the session from the refreshed cookie.
3. Redirects unauthenticated users to `/login`.
4. Redirects already-authenticated users away from `/login` to `/dashboard`.
5. Enforces role-based route access.
6. Reads `tenant_id` from the JWT — if missing (staff account not properly
   provisioned), redirects to `/login` with an error.

> **Next.js 16:** `middleware.ts` renamed to `proxy.ts`, exported function
> renamed from `middleware` to `proxy`. Logic identical. Node.js runtime only.

```ts
// proxy.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createProxyClient } from '@/lib/supabase/proxy'

export async function proxy(request: NextRequest) {
  const { supabase, response } = createProxyClient(request)

  const { data: { session } } = await supabase.auth.getSession()

  const { pathname } = request.nextUrl

  // Redirect unauthenticated users to login
  if (!session && !pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // Redirect authenticated users away from login
  if (session && pathname.startsWith('/login')) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  if (session) {
    const role = session.user.app_metadata?.role as 'admin' | 'manager' | 'staff'
    const tenantId = session.user.app_metadata?.tenant_id as string | undefined

    // Block access if tenant_id is missing — account not properly provisioned
    if (!tenantId) {
      return NextResponse.redirect(new URL('/login?error=account_error', request.url))
    }

    // Role-based route guard
    const restricted = ROLE_ROUTE_MAP[pathname]
    if (restricted && !restricted.includes(role)) {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  return response
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

---

### 4.2. Role-to-Route Map

```ts
// lib/constants.ts
export const ROLE_ROUTE_MAP: Record<string, Array<'admin' | 'manager' | 'staff'>> = {
  '/settings':    ['admin'],
  '/audit-logs':  ['admin'],
  '/sales':       ['admin'],
}
// Routes not listed are accessible to all authenticated roles.
```

---

### 4.3. Auth Flow Diagram

```txt
Browser Request
      │
      ▼
proxy.ts
  ├── No session?              → redirect /login
  ├── On /login + has session? → redirect /dashboard
  ├── Missing tenant_id?       → redirect /login?error=account_error
  └── Restricted route + wrong role? → redirect /dashboard
      │
      ▼
(admin)/layout.tsx  ← renders shell, reads session (role + tenant_id) for Topbar/Sidebar
      │
      ▼
page.tsx  ← Server Component, fetches data via server client (RLS auto-scopes to tenant)
      │
      ▼
Client Components  ← TanStack Query hydrated from server initialData
```

---

### 4.4. Sign-In Page

The `/login` page uses a Client Component with React Hook Form + Zod.
On submit it calls `supabase.auth.signInWithPassword()` directly from
the browser. On success, the Auth Hook stamps `role` and `tenant_id` into
the JWT, and the proxy handles the redirect.

## 5. Global State Shape

State is split between **TanStack Query** (server state) and **Zustand**
(client UI state). They do not overlap.

### 5.1. TanStack Query — Server State

All data from or to Supabase is owned by TanStack Query.

#### Query Key Conventions

Query keys are structured arrays, from general to specific. Tenant scoping
is **not included in query keys** — RLS handles it at the database level.
TanStack Query cache is per-session (in-memory), so there is no risk of
cross-tenant cache pollution.

```ts
['orders']                               // all orders (scoped to tenant by RLS)
['orders', { status: 'pending' }]        // filtered orders
['orders', orderId]                      // single order
['customers']
['customers', customerId]
['products']
['products', productId]
['categories']
['notifications']
['dashboard']
```

#### QueryClient Setup

```tsx
// app/layout.tsx
'use client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30 * 1000,       // 30 seconds
        gcTime: 5 * 60 * 1000,      // 5 minutes
        retry: 1,
        refetchOnWindowFocus: true,
      },
    },
  }))

  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )
}
```

---

### 5.2. Zustand — Client State

| Store file | State managed |
|---|---|
| `ui.store.ts` | `sidebarExpanded: boolean`, `activeModule: string` |
| `notifications.store.ts` | `unreadCount: number`, `panelOpen: boolean` |
| `table.store.ts` | `selectedRows: string[]`, `columnVisibility: Record<string, boolean>` |
| `modals.store.ts` | `openModal: string \| null`, `entityId: string \| null` |

#### Store Pattern

```ts
// stores/ui.store.ts
import { create } from 'zustand'

interface UIState {
  sidebarExpanded: boolean
  toggleSidebar: () => void
}

export const useUIStore = create<UIState>((set) => ({
  sidebarExpanded: true,
  toggleSidebar: () => set((s) => ({ sidebarExpanded: !s.sidebarExpanded })),
}))
```

## 6. Shared Layout

### 6.1. AdminLayout (`app/(admin)/layout.tsx`)

The admin layout reads both `role` and `tenant_id` from the session. The
`tenant_id` is passed to the Topbar for display and to the
`NotificationProvider` for the Realtime subscription filter.

```tsx
// app/(admin)/layout.tsx — Server Component
import { Sidebar } from '@/components/layout/Sidebar'
import { Topbar } from '@/components/layout/Topbar'
import { NotificationProvider } from '@/modules/notifications/NotificationProvider'
import { createServerClient } from '@/lib/supabase/server'

export default async function AdminLayout({ children }) {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  const role = user?.app_metadata?.role
  const tenantId = user?.app_metadata?.tenant_id

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar role={role} />
      <div className="flex flex-col flex-1 overflow-hidden">
        <Topbar user={user} />
        <main className="flex-1 overflow-y-auto bg-background">
          <NotificationProvider staffId={user?.id} tenantId={tenantId}>
            <PageContainer>
              {children}
            </PageContainer>
          </NotificationProvider>
        </main>
      </div>
    </div>
  )
}
```

---

### 6.2. Sidebar

- Fixed position, does not scroll with content.
- Default state: expanded (icon + label). Collapsed: icon only.
- Toggle stored in `useUIStore`.
- Role-aware: menu items not accessible to the current role are hidden.
- Active route highlighted via `usePathname()`.

---

### 6.3. Topbar

- Application logo / tenant branding (left) — reads from `tenants.settings`.
- Language selector (centre-right).
- Notification bell with unread count badge.
- User avatar + name + sign-out button (right).

---

### 6.4. PageContainer

```tsx
export function PageContainer({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto max-w-screen-2xl px-6 py-8">
      {children}
    </div>
  )
}
```

---

### 6.5. PageHeader

```tsx
interface PageHeaderProps {
  title: string
  description?: string
  actions?: React.ReactNode
}
```

## 7. Error, Loading & Empty States

### 7.1. Error Boundaries

```text
app/(admin)/layout.tsx          ← Shell always visible even if a page errors
app/(admin)/orders/error.tsx    ← Orders-specific error boundary
app/(admin)/customers/error.tsx
app/error.tsx                   ← Root fallback
```

```tsx
// app/(admin)/orders/error.tsx
'use client'
export default function OrdersError({ error, reset }) {
  return (
    <div className="flex flex-col items-center gap-4 p-8">
      <p className="text-destructive">Something went wrong loading orders.</p>
      <Button onClick={reset}>Try again</Button>
    </div>
  )
}
```

---

### 7.2. Loading States

```text
app/(admin)/orders/loading.tsx  ← Renders skeleton table while Server Component suspends
```

```tsx
import { TableSkeleton } from '@/components/shared/TableSkeleton'

export default function OrdersLoading() {
  return <TableSkeleton rows={10} columns={7} />
}
```

---

### 7.3. Empty States

```tsx
interface EmptyStateProps {
  icon: LucideIcon
  title: string
  description: string
  action?: React.ReactNode
}
```

---

### 7.4. Toast Notifications

```ts
// lib/utils.ts
import { toast } from 'sonner'

export const notify = {
  success: (msg: string) => toast.success(msg),
  error:   (msg: string) => toast.error(msg),
  info:    (msg: string) => toast.info(msg),
}
```

`<Toaster />` mounted once in `app/layout.tsx`.

## 8. Supabase Client Initialisation

Three distinct client contexts. Using the wrong one is a common bug and
a security risk.

### 8.1. Server Client (`lib/supabase/server.ts`)

Used in Server Components, Server Actions, Route Handlers.

```ts
import { createServerClient as createSSRServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database.types'

export function createServerClient() {
  const cookieStore = cookies()

  return createSSRServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name) { return cookieStore.get(name)?.value },
        set(name, value, options) { cookieStore.set({ name, value, ...options }) },
        remove(name, options) { cookieStore.set({ name, value: '', ...options }) },
      },
    }
  )
}
```

---

### 8.2. Browser Client (`lib/supabase/client.ts`)

Used in Client Components, TanStack Query functions, Realtime subscriptions.

```ts
import { createBrowserClient } from '@supabase/ssr'
import type { Database } from '@/types/database.types'

export function createBrowserClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  )
}
```

The browser client is a singleton — create it once per module query file.

---

### 8.3. Proxy Client (`lib/supabase/proxy.ts`)

Used only in `proxy.ts` for session refresh.

```ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export function createProxyClient(request: NextRequest) {
  let response = NextResponse.next({ request: { headers: request.headers } })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name) { return request.cookies.get(name)?.value },
        set(name, value, options) {
          request.cookies.set({ name, value, ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value, ...options })
        },
        remove(name, options) {
          request.cookies.set({ name, value: '', ...options })
          response = NextResponse.next({ request: { headers: request.headers } })
          response.cookies.set({ name, value: '', ...options })
        },
      },
    }
  )

  return { supabase, response }
}
```

---

### 8.4. Quick Reference

| Client | File | Used in |
|---|---|---|
| Server | `lib/supabase/server.ts` | Server Components, Server Actions |
| Browser | `lib/supabase/client.ts` | Client Components, query functions |
| Proxy | `lib/supabase/proxy.ts` | `proxy.ts` only |

## 9. i18n Architecture

### 9.1. Library: next-intl

All user-facing strings live in locale files. No hardcoded strings in
components. Language preference is stored per-staff-profile and defaults
to the tenant's configured language from `tenants.settings->>'language'`.

### 9.2. Locale Files

```text
src/i18n/
├── en.json
├── cs.json
└── de.json
```

Keys are namespaced by module:

```json
{
  "common": {
    "save": "Save",
    "cancel": "Cancel",
    "delete": "Delete",
    "edit": "Edit",
    "loading": "Loading...",
    "noResults": "No results found"
  },
  "orders": {
    "title": "Orders",
    "status": {
      "pending": "Pending",
      "preparing": "Preparing",
      "ready": "Ready",
      "outForDelivery": "Out for Delivery",
      "completed": "Completed",
      "cancelled": "Cancelled"
    }
  },
  "customers": { },
  "catalog": { }
}
```

---

### 9.3. Usage in Components

```tsx
import { useTranslations } from 'next-intl'

export function OrderStatusBadge({ status }) {
  const t = useTranslations('orders.status')
  return <Badge>{t(status)}</Badge>
}
```

---

### 9.4. Language Switching

Language preference is stored per-staff session. The topbar language
selector calls a Server Action that updates the cookie and triggers a
page reload to apply the new locale.

## 10. Data Fetching Conventions

### 10.1. Server-side (initial load)

Server Components fetch initial data directly via the server Supabase
client. Data is passed as `initialData` to Client Components to hydrate
TanStack Query without a client-side waterfall. RLS automatically scopes
all queries to the current tenant — no explicit `tenant_id` filter needed.

---

### 10.2. Client-side (TanStack Query)

Query functions live in `modules/{name}/queries/` and use the browser
Supabase client.

```ts
// modules/orders/queries/fetchOrders.ts
import { createBrowserClient } from '@/lib/supabase/client'

const supabase = createBrowserClient()

export async function fetchOrders({ status, page, search }: OrderFilters) {
  // No tenant_id filter — RLS handles tenant scoping automatically
  const { data, error, count } = await supabase
    .from('orders')
    .select('*, customer:customers(first_name, last_name), items:order_items(*)', { count: 'exact' })
    .eq(status ? 'status' : '', status ?? '')
    .ilike(search ? 'order_number' : '', search ? `%${search}%` : '')
    .order('created_at', { ascending: false })
    .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)

  if (error) throw error
  return { data, count }
}
```

```ts
// modules/orders/hooks/useOrders.ts
import { useQuery } from '@tanstack/react-query'
import { fetchOrders } from '../queries/fetchOrders'

export function useOrders(filters: OrderFilters) {
  return useQuery({
    queryKey: ['orders', filters],
    queryFn: () => fetchOrders(filters),
  })
}
```

---

### 10.3. Pagination

All tables use server-side pagination. Page size default: `50`. Max: `100`.
Page state lives in component-local state unless deep-linking is needed.

## 11. Form & Mutation Conventions

### 11.1. Pattern

Every create/edit form follows this pattern:

1. **Zod schema** defines shape and validation rules.
2. **React Hook Form** manages field state and triggers validation on submit.
3. **Server Action** receives validated data, re-validates server-side,
   writes to Supabase, writes audit log.
4. **TanStack Query mutation** wraps the Server Action, handles optimistic
   updates and cache invalidation.

```ts
// modules/orders/actions/updateOrderStatus.ts
'use server'
import { createServerClient } from '@/lib/supabase/server'
import { z } from 'zod'
import { revalidatePath } from 'next/cache'

const schema = z.object({
  orderId: z.string().uuid(),
  status: z.enum(['pending', 'preparing', 'ready', 'out_for_delivery', 'completed', 'cancelled']),
})

export async function updateOrderStatus(input: unknown) {
  const parsed = schema.safeParse(input)
  if (!parsed.success) throw new Error('Invalid input')

  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  const tenantId = user?.app_metadata?.tenant_id as string

  const { error } = await supabase
    .from('orders')
    .update({ status: parsed.data.status })
    .eq('id', parsed.data.orderId)
    // RLS enforces tenant scoping — the update only affects the current tenant's order

  if (error) throw error

  // Audit log — must include tenant_id and tenant_name
  await supabase.from('audit_logs').insert({
    tenant_id:   tenantId,
    tenant_name: user?.app_metadata?.tenant_name,
    staff_id:    user!.id,
    staff_name:  user?.app_metadata?.staff_name,
    staff_email: user?.email,
    staff_role:  user?.app_metadata?.role,
    action:      'status_changed',
    entity_type: 'order',
    entity_id:   parsed.data.orderId,
    new_values:  { status: parsed.data.status },
  })

  revalidatePath('/orders')
}
```

## 12. Audit Logging Convention

Every Server Action that writes to the database **must** write an audit
log entry. This is a non-negotiable architectural rule (NFR-O-01).

### 12.1. Audit Entry Shape

```ts
{
  // Tenant context (no FK on audit_logs — plain values)
  tenant_id:    string    // from user.app_metadata.tenant_id
  tenant_name:  string    // from user.app_metadata.tenant_name

  // Actor
  staff_id:     string    // from supabase.auth.getUser()
  staff_name:   string    // from user.app_metadata.staff_name
  staff_email:  string    // from user.email
  staff_role:   string    // from user.app_metadata.role

  // Action
  action:       string    // enum value: 'created', 'updated', 'deleted', etc.
  entity_type:  string    // e.g. 'order', 'product', 'customer'
  entity_id:    string    // affected row ID
  entity_label: string    // human-readable e.g. 'ORD-2026-00001'

  // Change snapshot (only changed fields — not full row dumps)
  old_values?:  Json
  new_values?:  Json
}
```

---

### 12.2. Action Name Conventions

```text
created        — a new record was created
updated        — an existing record was modified
deleted        — a record was deleted or soft-deleted
enabled        — is_active set to true
disabled       — is_active set to false
status_changed — a status field changed
login          — staff member logged in
logout         — staff member logged out
exported       — data was exported (GDPR compliance)
```

## 13. Environment Variables

```bash
# .env.local

# Supabase — safe to expose to client (RLS enforces access)
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>

# Supabase — server-only, NEVER expose to client
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

**Rule:** Any file that imports `SUPABASE_SERVICE_ROLE_KEY` must have
`import 'server-only'` at the top to prevent accidental client bundling.

## 14. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-19 | Initial frontend architecture finalized |
| 1.1 | 2026-03-23 | Upgraded to Next.js 16. Renamed `middleware.ts` → `proxy.ts`, `middleware()` → `proxy()`. Updated all references. |
| 2.0 | 2026-03-23 | Project renamed from Pizza Admin Portal to Multi-Tenant Food Ordering Platform Admin Portal |
| 2.0 | 2026-03-23 | Added `useCurrentTenant.ts` hook to `hooks/` folder |
| 2.0 | 2026-03-23 | `useCurrentUser.ts` updated — also reads `tenant_id` from JWT |
| 2.0 | 2026-03-23 | Proxy updated — validates `tenant_id` presence in JWT, redirects if missing |
| 2.0 | 2026-03-23 | Auth flow diagram updated — `tenant_id` validation step added |
| 2.0 | 2026-03-23 | AdminLayout updated — reads `tenant_id` and passes to `NotificationProvider` |
| 2.0 | 2026-03-23 | Query key conventions documented — tenant not in keys, RLS handles scoping |
| 2.0 | 2026-03-23 | Explicit note added to data fetching — no `tenant_id` filter in queries, RLS is the mechanism |
| 2.0 | 2026-03-23 | Audit log shape updated — `tenant_id`, `tenant_name`, full staff snapshot required |
| 2.0 | 2026-03-23 | Server Action example updated — reads `tenant_id` from JWT, passes to audit log |
| 2.0 | 2026-03-23 | Topbar updated — reads tenant branding from `tenants.settings` |
| 2.0 | 2026-03-23 | i18n default language updated — reads from `tenants.settings->>'language'` |
| 2.0 | 2026-03-23 | `components/ui/` comment updated — fully custom, no shadcn/ui dependency |
