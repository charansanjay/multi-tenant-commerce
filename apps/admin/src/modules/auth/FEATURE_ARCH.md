# FEATURE_ARCH.md — Module 1: Auth + Layout Shell

**Project:** Multi-Tenant Commerce — Admin Portal  
**Module:** 01 — Auth + Layout Shell  
**Status:** Step 1 of 10 — Feature Architecture  
**Date:** 2026-03-29  
**Scope:** Login page, proxy route protection, admin layout shell (Sidebar + Topbar + PageContainer), role-based navigation

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Screens and Features](#2-screens-and-features)
3. [File Structure](#3-file-structure)
4. [Component Architecture](#4-component-architecture)
5. [Auth Flow](#5-auth-flow)
6. [Proxy (Route Protection)](#6-proxy-route-protection)
7. [Admin Layout Shell](#7-admin-layout-shell)
8. [Sidebar](#8-sidebar)
9. [Topbar](#9-topbar)
10. [State Management](#10-state-management)
11. [i18n](#11-i18n)
12. [Supabase Layer](#12-supabase-layer)
13. [Role-Based Access Control](#13-role-based-access-control)
14. [CDS Components Required](#14-cds-components-required)
15. [GitHub Issues](#15-github-issues)
16. [Open Questions](#16-open-questions)

## 1. Module Overview

Module 1 is the foundation every other module sits inside. It delivers two things:

**Authentication** — a login page that exchanges credentials for a Supabase session carrying `role`, `tenant_id`, `tenant_name`, and `staff_name` in the JWT, stamped by the custom Auth Hook.

**Layout Shell** — the persistent chrome (Sidebar + Topbar + PageContainer) that wraps every subsequent module screen. This module contains no data-fetching business logic beyond reading the authenticated session — it is purely structural.

Nothing else can be built until this module is complete.

### Deliverables

| Deliverable | Route / File |
|---|---|
| Login page | `/login` |
| Proxy (route guard) | `proxy.ts` |
| Root admin layout | `app/(admin)/layout.tsx` |
| Sidebar component | `components/layout/Sidebar.tsx` |
| Topbar component | `components/layout/Topbar.tsx` |
| PageContainer component | `components/layout/PageContainer.tsx` |
| UI store (sidebar state) | `stores/ui.store.ts` |
| Locale switcher action | `modules/auth/actions/setLocale.ts` |
| Sign-out action | `modules/auth/actions/signOut.ts` |
| `useCurrentUser` hook | `hooks/useCurrentUser.ts` |
| Placeholder dashboard page | `app/(admin)/dashboard/page.tsx` |

## 2. Screens and Features

This module produces two visible screens.

### Approved Mockups

| Screen | File | Status |
|---|---|---|
| Login page | `apps/admin/docs/mockups/01_login.html` | ✅ Approved Step 4 |
| Admin layout shell | `apps/admin/docs/mockups/02_admin_shell.html` | ✅ Approved Step 4 |

All implementation in Step 7 must match these mockups exactly.

### Screen 1 — `/login`

The only public-facing screen. Renders without the admin layout shell.

Features:

- Email + password form
- Zod validation (email format required, password non-empty)
- Supabase `signInWithPassword()` on submit
- Button loading state during sign-in
- Error state for failed credentials (generic message — Auth Hook blocks leaking reason)
- Error state for `?error=account_error` query param (account not provisioned)
- On success: redirect to `/dashboard`
- All strings i18n — no hardcoded copy

### Screen 2 — Admin Layout Shell (visible on every `(admin)` route)

Not a standalone page — it is `app/(admin)/layout.tsx`. During this module a placeholder `/dashboard` page is created so the shell can be fully tested and signed off before Module 4 (Dashboard) builds the real content.

Features:

- **Sidebar** — full navigation menu, collapsible, role-filtered
- **Topbar** — logo, language selector, notification bell (static badge for now), user avatar + name, sign-out
- **PageContainer** — constrains content width, provides consistent padding
- Active route highlighted in sidebar
- Sidebar collapsed state: icon-only, 64px wide, tooltips on hover/focus
- Sidebar collapsed preference persists in Zustand `useUIStore` for the session

## 3. File Structure

Files created or modified by this module:

```text
src/
├── app/
│   ├── (auth)/
│   │   └── login/
│   │       └── page.tsx                  ← Login page (Client Component)
│   ├── (admin)/
│   │   ├── layout.tsx                    ← Admin layout shell (Server Component)
│   │   └── dashboard/
│   │       └── page.tsx                  ← Placeholder only — replaced in Module 4
│   └── layout.tsx                        ← Root layout (Providers, IntlProvider)
│
├── components/
│   └── layout/
│       ├── Sidebar.tsx                   ← Server/Client split — see §8
│       ├── Topbar.tsx                    ← Client Component
│       └── PageContainer.tsx             ← Server Component (no interactivity)
│
├── modules/
│   └── auth/
│       ├── components/
│       │   └── LoginForm.tsx             ← Client Component
│       └── actions/
│           ├── signOut.ts                ← Server Action
│           └── setLocale.ts              ← Server Action
│
├── hooks/
│   └── useCurrentUser.ts                 ← Reads JWT claims from Supabase session
│
├── stores/
│   └── ui.store.ts                       ← Sidebar collapsed state (Zustand)
│
├── lib/
│   ├── supabase/
│   │   ├── server.ts                     ← Already exists from scaffold
│   │   ├── client.ts                     ← Already exists from scaffold
│   │   └── proxy.ts                      ← Already exists from scaffold
│   └── constants.ts                      ← ROLE_ROUTE_MAP added here
│
├── i18n/
│   ├── en.json                           ← auth namespace added
│   ├── cs.json
│   └── de.json
│
└── proxy.ts                              ← Root proxy (route guard)
```

## 4. Component Architecture

### Server vs Client split

| Component | Type | Reason |
|---|---|---|
| `app/(auth)/login/page.tsx` | Server | Thin wrapper only — redirects if already authed |
| `modules/auth/components/LoginForm.tsx` | **Client** | React Hook Form, `useState`, `supabase.auth.signInWithPassword()` |
| `app/(admin)/layout.tsx` | Server | Reads session from cookies via server client; passes user data to shell |
| `components/layout/PageContainer.tsx` | Server | Pure structure, no interactivity |
| `components/layout/Sidebar.tsx` | **Client** | `usePathname()`, `useUIStore()`, collapse toggle |
| `components/layout/Topbar.tsx` | **Client** | `onSignOut`, `onLocaleChange`, `DropdownMenu`, user state |
| `hooks/useCurrentUser.ts` | Client hook | Reads session from browser Supabase client |
| `stores/ui.store.ts` | Client (Zustand) | Sidebar collapsed state |

### Data flow for the layout shell

```text
app/(admin)/layout.tsx  (Server Component)
  │
  ├── createServerClient()
  ├── supabase.auth.getUser()
  │     → { full_name, avatar_url, role }  from app_metadata + staff_profiles
  │
  ├── <Sidebar role={role} />          ← role drives nav item visibility
  ├── <Topbar user={user} />           ← user drives avatar + name
  └── <PageContainer>{children}</PageContainer>
```

The server layout reads the session once and passes minimal props down. Sidebar and Topbar are Client Components that handle their own interactivity.

## 5. Auth Flow

### Sign-in sequence

```text
User submits email + password
  ↓
LoginForm calls supabase.auth.signInWithPassword()
  ↓
Supabase Auth validates credentials
  ↓
Auth Hook fires (PostgreSQL function)
  ├── Looks up staff_profiles by auth.uid()
  ├── Checks staff is_active
  ├── Looks up tenants by tenant_id
  ├── Checks tenant is_active
  └── Stamps { role, tenant_id, tenant_name, staff_name } into JWT app_metadata
  ↓
If Auth Hook throws → Supabase returns generic auth error
  → LoginForm shows: "Your account has been deactivated or does not exist."
  ↓
If success → session cookie set by @supabase/ssr
  ↓
LoginForm calls router.push('/dashboard')
  ↓
proxy.ts runs on /dashboard request
  ├── Session found → allow
  └── role + tenant_id verified → render (admin)/layout.tsx
```

### Sign-out sequence

```text
User clicks "Sign out" in Topbar user menu
  ↓
Topbar calls signOut Server Action
  ↓
Server Action: supabase.auth.signOut()  (server client)
  ↓
Session cookie cleared
  ↓
redirect('/login')
```

### Error states on `/login`

| Condition | Error shown |
|---|---|
| Invalid credentials | "Invalid email or password." |
| Auth Hook blocked (any reason) | "Your account has been deactivated or does not exist. Please contact your administrator." |
| `?error=account_error` in URL (proxy redirect) | "Your account is not properly configured. Please contact your administrator." |
| Network / unexpected error | "Something went wrong. Please try again." |

All error strings live in `i18n/{locale}.json` under the `auth` namespace.

## 6. Proxy (Route Protection)

File: `proxy.ts` at the repo root.

### Responsibilities

1. Refresh the Supabase session on every request (rotates access token if needed).
2. Redirect unauthenticated users to `/login`.
3. Redirect already-authenticated users away from `/login` to `/dashboard`.
4. Check `tenant_id` claim — missing means account not provisioned → redirect `/login?error=account_error`.
5. Enforce role-based route restrictions via `ROLE_ROUTE_MAP`.

### ROLE_ROUTE_MAP

Defined in `lib/constants.ts`:

```ts
export const ROLE_ROUTE_MAP: Record<string, Array<'admin' | 'manager' | 'staff'>> = {
  '/settings':   ['admin'],
  '/audit-logs': ['admin'],
  '/sales':      ['admin'],
}
// All routes not listed are accessible to all authenticated roles.
```

Routes not listed: `/dashboard`, `/customers`, `/catalog/categories`, `/catalog/products`, `/orders`, `/addresses` — accessible to admin, manager, and staff.

### Proxy matcher

```ts
export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
```

### Important note on naming

In Next.js 16 the file is `proxy.ts` and the exported function is `proxy` (not `middleware`). This is already established in the scaffold — do not create a `middleware.ts`.

## 7. Admin Layout Shell

File: `app/(admin)/layout.tsx`

### Implementation pattern

```tsx
// Server Component — reads session, passes to Sidebar + Topbar
import { createServerClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { Sidebar } from '@/components/layout/Sidebar'
import { Topbar } from '@/components/layout/Topbar'
import { PageContainer } from '@/components/layout/PageContainer'

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const role = user.app_metadata?.role as 'admin' | 'manager' | 'staff'
  const fullName = user.app_metadata?.staff_name as string
  const tenantName = user.app_metadata?.tenant_name as string

  // avatar_url requires a separate query to staff_profiles
  const { data: profile } = await supabase
    .from('staff_profiles')
    .select('avatar_url')
    .eq('id', user.id)
    .single()

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar role={role} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Topbar
          user={{ full_name: fullName, avatar_url: profile?.avatar_url, role }}
        />
        <main className="flex-1 overflow-y-auto">
          <PageContainer>{children}</PageContainer>
        </main>
      </div>
    </div>
  )
}
```

### Layout geometry

```text
┌──────────────────────────────────────────────────────────────────┐
│  Topbar  (h-14, fixed top, full width, z-10)                     │
├──────────────┬───────────────────────────────────────────────────┤
│              │                                                   │
│  Sidebar     │  main (overflow-y-auto)                           │
│  (fixed,     │    PageContainer (max-w-screen-2xl, px-6, py-8)   │
│   left,      │      PageHeader                                   │
│   h-full)    │      Module content                               │
│              │                                                   │
└──────────────┴───────────────────────────────────────────────────┘
```

## 8. Sidebar

File: `components/layout/Sidebar.tsx`

### Props

```tsx
interface SidebarProps {
  role: 'admin' | 'manager' | 'staff'
}
// collapsed state comes from useUIStore — not a prop
```

### Nav item configuration

```tsx
interface NavItem {
  label:     string           // i18n key, e.g. 'nav.dashboard'
  href:      string
  icon:      LucideIcon
  roles:     UserRole[]
  children?: NavItem[]
}

const NAV_ITEMS: NavItem[] = [
  { label: 'nav.dashboard',  href: '/dashboard',           icon: LayoutDashboard, roles: ['admin', 'manager', 'staff'] },
  { label: 'nav.orders',     href: '/orders',               icon: ShoppingBag,     roles: ['admin', 'manager', 'staff'] },
  { label: 'nav.customers',  href: '/customers',            icon: Users,           roles: ['admin', 'manager', 'staff'] },
  {
    label: 'nav.catalog', href: '/catalog', icon: UtensilsCrossed, roles: ['admin', 'manager', 'staff'],
    children: [
      { label: 'nav.categories', href: '/catalog/categories', icon: Tag,     roles: ['admin', 'manager', 'staff'] },
      { label: 'nav.products',   href: '/catalog/products',   icon: Package, roles: ['admin', 'manager', 'staff'] },
    ],
  },
  { label: 'nav.addresses',  href: '/addresses',            icon: MapPin,          roles: ['admin', 'manager'] },
  { label: 'nav.sales',      href: '/sales',                icon: BarChart3,       roles: ['admin'] },
  { label: 'nav.settings',   href: '/settings',             icon: Settings,        roles: ['admin'] },
  { label: 'nav.auditLogs',  href: '/audit-logs',           icon: ScrollText,      roles: ['admin'] },
]
```

**Role visibility summary:**

| Nav item | admin | manager | staff |
|---|---|---|---|
| Dashboard | ✅ | ✅ | ✅ |
| Orders | ✅ | ✅ | ✅ |
| Customers | ✅ | ✅ | ✅ |
| Catalog → Categories | ✅ | ✅ | ✅ |
| Catalog → Products | ✅ | ✅ | ✅ |
| Addresses | ✅ | ✅ | ❌ |
| Sales | ✅ | ❌ | ❌ |
| Settings | ✅ | ❌ | ❌ |
| Audit Logs | ✅ | ❌ | ❌ |

Items are filtered at render time. Items a role cannot access are **not rendered** — not hidden.

### Collapsed behaviour

- Expanded (default): icon + label, 240px wide
- Collapsed: icon only, 64px wide
- Collapsed items show a Tooltip on hover/focus with the item label
- Collapse toggle button at bottom of sidebar (or top — decide in mockup step)
- Nested Catalog group: in expanded mode shows a chevron; in collapsed mode the parent icon shows a Tooltip listing children (or collapses children into separate icons — decide in mockup step)

### Active state

- `usePathname()` detects current route
- Exact match for top-level items
- Parent (Catalog) is highlighted if any child route is active
- Active: `--sidebar-active-bg` background, left border in `--sidebar-accent` (amber), text and icon in `--sidebar-active-text` (amber-300)
- Inactive: text and icon in `--sidebar-muted-text` (#9191A0)

### Accessibility

- `<nav aria-label="Main navigation">`
- Active link: `aria-current="page"`
- Toggle button: `aria-label` updates between "Collapse sidebar" / "Expand sidebar"
- Nested groups: `aria-expanded` on parent item button
- Collapsed tooltips appear on keyboard focus (not just hover)

## 9. Topbar

File: `components/layout/Topbar.tsx`

### Props

```tsx
interface TopbarProps {
  user: {
    full_name:   string
    avatar_url?: string
    role:        'admin' | 'manager' | 'staff'
  }
}
// locale and signOut handled internally via Server Actions
```

### Layout (left → right)

```text
[Logo / App name]  ──────────────────  [Language]  [Notifications 🔔]  [Avatar + Name ▾]
```

### Elements

**Logo / App name:**

- Text: "Admin Portal" (or tenant name if available — decision: use `tenant_name` from JWT)
- Links to `/dashboard`
- Left-aligned, aligned with sidebar width when expanded

**Language selector:**

- `Select` component showing current locale: EN / CS / DE
- On change: calls `setLocale` Server Action → updates locale cookie → page reloads with new locale via `router.refresh()`
- Supported locales: `en`, `cs`, `de`

**Notification bell** _(stub in this module — full implementation in Module 11)_

- `IconButton` with `Bell` icon
- No live count in this module — static, no badge
- Clicking does nothing in this module (wired up in Module 11)
- Comment in code: `// TODO: wire to notifications store in Module 11`

**User menu:**

- `Avatar` component (initials fallback if no `avatar_url`)
- Displays `full_name` next to avatar on larger screens
- `DropdownMenu` with two items:
  - "My profile" → links to `/settings` (for now — will point to dedicated profile page if built)
  - "Sign out" → calls `signOut` Server Action

### Sign-out Server Action

```ts
// modules/auth/actions/signOut.ts
'use server'
import { createServerClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export async function signOut() {
  const supabase = createServerClient()
  await supabase.auth.signOut()
  redirect('/login')
}
```

### Locale Server Action

```ts
// modules/auth/actions/setLocale.ts
'use server'
import { cookies } from 'next/headers'

export async function setLocale(locale: 'en' | 'cs' | 'de') {
  cookies().set('locale', locale, { path: '/', maxAge: 60 * 60 * 24 * 365 })
}
```

## 10. State Management

### Zustand — UI store

```ts
// stores/ui.store.ts
import { create } from 'zustand'

interface UIStore {
  sidebarCollapsed: boolean
  toggleSidebar:    () => void
  setSidebarCollapsed: (collapsed: boolean) => void
}

export const useUIStore = create<UIStore>((set) => ({
  sidebarCollapsed: false,
  toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
  setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed }),
}))
```

Sidebar calls `useUIStore()` for both reading state and the toggle handler. Preference is session-scoped (in-memory Zustand — not persisted to localStorage).

### `useCurrentUser` hook

```ts
// hooks/useCurrentUser.ts
'use client'
import { useEffect, useState } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'

export function useCurrentUser() {
  const [user, setUser] = useState<{ role: string; tenant_id: string; staff_name: string } | null>(null)

  useEffect(() => {
    const supabase = createBrowserClient()
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) {
        setUser({
          role:        data.user.app_metadata?.role,
          tenant_id:   data.user.app_metadata?.tenant_id,
          staff_name:  data.user.app_metadata?.staff_name,
        })
      }
    })
  }, [])

  return user
}
```

Used by any Client Component that needs to read the current user's role or identity without a prop drill.

## 11. i18n

All strings for this module live under the `auth` and `nav` namespaces in the locale files.

### Keys to add — `auth` namespace

```json
{
  "auth": {
    "loginTitle": "Sign in to your account",
    "loginSubtitle": "Enter your credentials to continue",
    "email": "Email",
    "password": "Password",
    "signIn": "Sign in",
    "signingIn": "Signing in...",
    "errorInvalidCredentials": "Invalid email or password.",
    "errorAccountDeactivated": "Your account has been deactivated or does not exist. Please contact your administrator.",
    "errorAccountNotConfigured": "Your account is not properly configured. Please contact your administrator.",
    "errorUnexpected": "Something went wrong. Please try again.",
    "signOut": "Sign out",
    "myProfile": "My profile"
  }
}
```

### Keys to add — `nav` namespace

```json
{
  "nav": {
    "dashboard":   "Dashboard",
    "orders":      "Orders",
    "customers":   "Customers",
    "catalog":     "Catalog",
    "categories":  "Categories",
    "products":    "Products",
    "addresses":   "Addresses",
    "sales":       "Sales",
    "settings":    "Settings",
    "auditLogs":   "Audit Logs"
  }
}
```

### Language selector labels

```json
{
  "locale": {
    "en": "EN",
    "cs": "CS",
    "de": "DE"
  }
}
```

All three locale files (`en.json`, `cs.json`, `de.json`) must have matching keys — only values differ.

## 12. Supabase Layer

### Clients used in this module

| Context | Client | Why |
|---|---|---|
| `proxy.ts` | Proxy client (`lib/supabase/proxy.ts`) | Session refresh, route guard |
| `app/(admin)/layout.tsx` | Server client | `getUser()`, fetch `avatar_url` from `staff_profiles` |
| `LoginForm.tsx` | Browser client | `signInWithPassword()` |
| `signOut.ts` Server Action | Server client | `signOut()` |

### Queries

**In `app/(admin)/layout.tsx`:**

```ts
supabase.auth.getUser()
// → user.app_metadata: { role, tenant_id, tenant_name, staff_name }

supabase.from('staff_profiles').select('avatar_url').eq('id', user.id).single()
// → avatar_url for Topbar Avatar component
// RLS: staff can SELECT own row — this always works for any role
```

No other Supabase queries in this module. All other data (orders, customers, etc.) is the responsibility of subsequent modules.

### RLS impact

The `avatar_url` fetch from `staff_profiles` is safe for all three roles — the RLS policy allows every role to `SELECT` their own row. No admin client needed.

## 13. Role-Based Access Control

### Three enforcement layers for this module

| Layer | Implementation | Where |
|---|---|---|
| Route-level | `proxy.ts` + `ROLE_ROUTE_MAP` | `/settings`, `/audit-logs`, `/sales` → admin only |
| Navigation visibility | `Sidebar` filters `NAV_ITEMS` by `role` prop | Non-admin roles never see Sales, Settings, Audit Logs links |
| Data layer | Supabase RLS (automatic) | All queries scoped to tenant; role enforced per table |

### Navigation visibility by role

Staff and managers are redirected to `/dashboard` by the proxy if they attempt to access a restricted URL directly — the sidebar not showing the link is UX polish, not the security enforcement (RLS is).

## 14. CDS Components Required

The following CDS components must be built (or confirmed as already built) before Step 7 (implementation).

### Must exist before Step 7

| Component | CDS Reference | Used in |
|---|---|---|
| `Button` | CDS-03 | LoginForm submit button |
| `Input` | CDS-03 | LoginForm email + password fields |
| `FormField` | CDS-06 | LoginForm field wrapper (label + error) |
| `Spinner` | CDS-03 | Button loading state |
| `Avatar` | CDS-03 | Topbar user avatar |
| `Select` | CDS-06 | Language selector |
| `DropdownMenu` | CDS-05 | Topbar user menu |
| `Tooltip` | CDS-05 | Collapsed sidebar item labels |
| `Sidebar` | CDS-08 | Layout shell |
| `Topbar` | CDS-08 | Layout shell |
| `PageContainer` | CDS-08 | Layout shell |
| `PageHeader` | CDS-08 | Used on placeholder dashboard page |
| `Toast / Sonner` | CDS-04 | Error feedback on login failure (optional — inline error may suffice) |

> **Note for Step 2 (CDS pre-check):** Confirm which of these are already built from the scaffold phase. Build only what is missing. `Sidebar`, `Topbar`, and `PageContainer` are the most likely to be partially or fully absent since they are layout-specific — check first.

### Components that can wait

| Component | Needed from |
|---|---|
| `IconButton` | Topbar notification bell — can use `Button` variant for now |
| `Badge` (notification count) | Module 11 (Notifications) |
| `DataTable` | Module 2 (Catalog — Categories) |
| `Drawer` | Module 2+ |
| `ConfirmDialog` | Module 2+ |

## 15. GitHub Issues

Three issues for this module. Create in GitHub with label `module:auth` and milestone `Auth + Layout Shell`.

```text
Title: [Auth] Login page — UI and form
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement the login page at /login.
- Email + password form using FormField, Input, Button components
- Zod schema: email (valid format, required), password (required, non-empty)
- supabase.auth.signInWithPassword() on submit
- Button loading state during sign-in
- Error states: invalid credentials, account deactivated, account not configured, unexpected
- Redirect to /dashboard on success
- All strings in i18n locale files under 'auth' namespace
Ref: modules/auth/FEATURE_ARCH.md §5
```

```text
Title: [Auth] Proxy — route protection and role guards
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement proxy.ts for route protection.
- Unauthenticated requests → redirect /login
- Authenticated users on /login → redirect /dashboard
- Missing tenant_id claim → redirect /login?error=account_error
- ROLE_ROUTE_MAP enforced: /settings, /audit-logs, /sales → admin only
- Session refresh on every request (@supabase/ssr)
Ref: modules/auth/FEATURE_ARCH.md §6
```

```text
Title: [Auth] Admin layout shell — Sidebar + Topbar + PageContainer
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement app/(admin)/layout.tsx with full layout shell.
- Server Component reads session: role, staff_name, avatar_url
- Sidebar with full nav menu, role-filtered, collapsible (useUIStore)
- Sidebar collapsed state: icon-only 64px, Tooltips on hover/focus
- Topbar: logo, language selector (EN/CS/DE), notification bell stub, user avatar + name, sign-out DropdownMenu
- PageContainer wrapping all children
- Active route detected via Next.js `usePathname()`. Active item uses `--sidebar-active-bg` for background, `--sidebar-accent` for the left border, and `--sidebar-active-text` for the icon and label. Inactive items use `--sidebar-muted-text`.
- setLocale Server Action (locale cookie)
- signOut Server Action
- Placeholder /dashboard page for testing the shell
Ref: modules/auth/FEATURE_ARCH.md §7–§10
```

## 16. Open Questions

These need a decision before or during the mockup step (Step 3). Record decisions in the mockup notes.

| # | Question | Default assumption |
|---|---|---|
| 1 | Where is the sidebar collapse toggle? Top of sidebar (below logo) or bottom? | Bottom — keeps nav items uninterrupted |
| 2 | In collapsed mode, how does the Catalog group behave? Show a single "Catalog" icon with a Tooltip listing children, or expand inline? | Single icon with Tooltip listing children |
| 3 | Should `tenant_name` from JWT appear in the Topbar logo area? | Yes — display as subtitle below "Admin Portal" |
| 4 | Should the language selector show flag icons or text codes only? | Text codes only (EN / CS / DE) — simpler, no flag assets needed |
| 5 | On mobile viewports (< 768px), does the sidebar become a drawer overlay or simply hide? | Out of scope for Module 1 — desktop-first; mobile nav is a later consideration |
| 6 | Login page: should there be a "Forgot password?" link? PRD does not specify. | Omit for Module 1. Password reset is a Settings/staff management concern. |

---

_This document is the source of truth for Module 1 implementation. All decisions made during Steps 3–7 that change this architecture should be noted as amendments below._

## Amendments

_(none yet)_
