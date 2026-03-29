# CLAUDE.md — Multi-Tenant Commerce Admin Portal

This file is read automatically by Claude Code at the start of every session.
It contains everything needed to work on this codebase without prior context.
Read it fully before writing any code.

## Project Overview

A multi-tenant food ordering platform admin portal. Currently building
Tenant #1 (Pizza Palace) as the reference implementation. All subsequent
tenants use the same portal — their product catalogs, categories, and
branding are configured through tenant settings, not through new development.

**Monorepo:** Turborepo + pnpm workspaces  
**App:** `apps/admin` — Next.js 16, React 19, TypeScript 5 strict  
**Backend:** Supabase (Postgres + Auth + Storage + Realtime)  
**Styling:** Tailwind CSS 4 + fully custom CDS component system (no shadcn/ui)  
**State:** TanStack Query (server state) + Zustand (client state)  
**Forms:** React Hook Form + Zod  
**i18n:** next-intl (en, cs, de)  
**Testing:** Vitest (unit + integration) + Playwright (E2E)  
**OS:** Windows — Supabase CLI installed globally via Scoop, not via pnpm dlx

## Monorepo Structure

```text
platform/
├── CLAUDE.md                          ← This file
├── docs/                              ← Platform-wide documents
│   ├── roadmap.md
│   ├── tech-stack.md
│   ├── non-functional-requirements.md
│   ├── erm.md
│   └── workflows/
│       ├── 01_module_development_plan.md
│       ├── 02_feature_implementation_workflow.md
│       └── 03_daily_dev_deployment_flow.md
├── packages/
│   ├── ui/                            ← Shared CDS components
│   ├── types/                         ← Shared TypeScript types
│   └── utils/                         ← Shared utilities (cn, formatCurrency, etc.)
├── supabase/
│   ├── migrations/                    ← 15 SQL migration files — do not edit existing files
│   ├── functions/                     ← Edge Functions
│   └── config.toml                    ← Local Supabase config + JWT hook registration
└── apps/
    ├── web/                           ← Stubbed, built later (customer ordering site)
    ├── super-admin/                   ← Stubbed, built later (platform operator portal)
    └── admin/                         ← Active development
        ├── docs/                      ← Admin-specific documents
        │   ├── prd.md
        │   ├── frontend-architecture.md
        │   ├── testing-strategy.md
        │   ├── db-migrations.md
        │   ├── BUGS.md                ← Check before fixing any bug
        │   ├── TESTING_NOTES.md       ← Check before writing any test
        │   ├── backend-architecture/
        │   │   ├── 01_connection_patterns.md
        │   │   ├── 02_rls.md
        │   │   ├── 03_jwt_auth_hook.md
        │   │   ├── 04_edge_functions.md
        │   │   ├── 05_database_triggers.md
        │   │   ├── 06_storage_buckets.md
        │   │   └── 07_realtime.md
        │   └── cds/
        │       ├── 01_overview.md
        │       ├── 02_design_tokens.md
        │       ├── 03_primitives.md
        │       ├── 04_feedback_components.md
        │       ├── 05_overlay_components.md
        │       ├── 06_form_components.md
        │       ├── 07_data_display.md
        │       ├── 08_navigation_and_layout.md
        │       ├── 09_domain_components.md
        │       └── 10_accessibility_contract.md
        └── src/
            └── modules/
                └── [module]/
                    └── FEATURE_ARCH.md  ← Read before implementing anything here
```

## apps/admin Source Structure

```text
apps/admin/src/
├── app/
│   ├── (auth)/
│   │   └── login/page.tsx          ← Unauthenticated
│   ├── (admin)/                    ← All protected routes live here
│   │   ├── layout.tsx              ← Admin shell (Sidebar + Topbar + PageContainer)
│   │   ├── dashboard/page.tsx
│   │   ├── customers/page.tsx
│   │   ├── customers/[id]/page.tsx
│   │   ├── catalog/categories/page.tsx
│   │   ├── catalog/products/page.tsx
│   │   ├── catalog/products/[id]/page.tsx
│   │   ├── orders/page.tsx
│   │   ├── orders/[id]/page.tsx
│   │   ├── addresses/page.tsx
│   │   ├── sales/page.tsx
│   │   ├── settings/page.tsx
│   │   └── audit-logs/page.tsx
│   ├── error.tsx
│   ├── not-found.tsx
│   └── layout.tsx                  ← Root HTML shell (QueryProvider, IntlProvider)
├── components/
│   ├── ui/                         ← Pure CDS components — no business logic
│   └── shared/                     ← Domain-aware components (OrderStatusBadge, etc.)
├── modules/                        ← Feature modules — one folder per module
│   └── [module]/
│       ├── FEATURE_ARCH.md         ← Read this before implementing anything here
│       ├── components/             ← Module UI components
│       ├── hooks/                  ← TanStack Query hooks
│       ├── api.ts                  ← Supabase query functions
│       └── schemas.ts              ← Zod schemas
├── lib/
│   ├── supabase/
│   │   ├── server.ts               ← Server client (Server Components, Server Actions)
│   │   ├── client.ts               ← Browser client (Client Components, Realtime)
│   │   └── proxy.ts                ← Session refresh helper (Node.js only, not edge)
│   ├── utils.ts                    ← cn(), formatCurrency(), shared helpers
│   └── constants.ts                ← Roles, statuses, app-wide constants
├── hooks/                          ← Global custom hooks
├── stores/                         ← Zustand stores
├── types/
│   └── database.types.ts           ← Auto-generated — never hand-edit this file
└── i18n/
    ├── en.json                     ← English (primary)
    ├── cs.json                     ← Czech
    └── de.json                     ← German
```

## Critical Patterns — Always Follow These

### 1. Server Shell → Client Island

Every page is a Server Component that fetches initial data and passes it
to a Client Component via `initialData`. Never fetch data client-side
when a Server Component can do it.

```tsx
// app/(admin)/orders/page.tsx — Server Component (no 'use client')
import { createServerClient } from '@/lib/supabase/server'
import { OrdersTable } from '@/modules/orders/components/OrdersTable'

export default async function OrdersPage() {
  const supabase = createServerClient()
  const { data: initialOrders } = await supabase
    .from('orders')
    .select('id, status, created_at, customers(first_name, last_name)')
    .order('created_at', { ascending: false })
    .limit(50)

  return <OrdersTable initialData={initialOrders ?? []} />
}
```

```tsx
// modules/orders/components/OrdersTable.tsx — Client Component
'use client'
import { useQuery } from '@tanstack/react-query'
import { ordersKeys } from '../hooks/useOrders'
import { getOrders } from '../api'

export function OrdersTable({ initialData }: { initialData: Order[] }) {
  const { data } = useQuery({
    queryKey: ordersKeys.list(),
    queryFn: getOrders,
    initialData, // ← No loading spinner on initial paint
  })
  // ...
}
```

### 2. No Manual Tenant Filtering — Ever

Never add `.eq('tenant_id', ...)` to any Supabase query. RLS policies
on every table enforce tenant isolation automatically using the `tenant_id`
claim in the user's JWT. Adding manual filters is redundant and signals
a misunderstanding of the architecture.

```ts
// ✅ Correct — RLS handles tenant scoping automatically
const { data } = await supabase.from('orders').select('*')

// ❌ Wrong — never do this
const { data } = await supabase.from('orders').select('*').eq('tenant_id', tenantId)
```

### 3. Database Types Are Auto-Generated — Never Hand-Edit

All database types live in `src/types/database.types.ts`. This file is
generated by `pnpm db:types` from the live local Supabase schema. Any
manual edits will be overwritten on the next type generation. If a type
is wrong, fix the migration SQL and regenerate.

### 4. All User-Facing Strings in Locale Files

Never hardcode strings that appear in the UI. Use `useTranslations()`
from next-intl. All keys live in `src/i18n/en.json` (and `cs.json`,
`de.json`).

```tsx
// ✅ Correct
const t = useTranslations('orders')
return <h1>{t('title')}</h1>

// ❌ Wrong
return <h1>Orders</h1>
```

### 5. Three States on Every Data-Fetching Component

Every component that fetches data must handle all three states explicitly.
No state can be silently ignored.

```tsx
if (isLoading)     return <SkeletonTable rows={5} />
if (isError)       return <Alert variant="error" message={t('error.load_failed')} />
if (!data?.length) return <EmptyState ... />
return <DataTable data={data} columns={columns} />
```

### 6. Query Functions in api.ts, Hooks in hooks/, Never Inline

All Supabase query functions go in `modules/[module]/api.ts`.
All TanStack Query hooks go in `modules/[module]/hooks/`.
Components import from hooks — never call Supabase directly inside
a component.

### 7. Mutations Invalidate Query Keys on Success

After any create, update, or delete mutation, invalidate the relevant
query key so the list re-fetches and reflects the change.

```ts
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: ordersKeys.list() })
}
```

### 8. RBAC Is Conditional Rendering — RLS Is the Real Security

Role-based UI restrictions (hiding buttons from Staff that only Admins
should see) are done by reading the role from the Zustand auth store and
conditionally rendering. This is UX only — RLS enforces the actual
security at the database level. Both layers must always exist.

## Before Fixing Any Bug

Read `apps/admin/docs/BUGS.md` first. Check the Pattern Index for any
existing solution to the same class of problem before investigating.

When reporting or investigating a bug, always provide:

- File path and approximate line number
- Exact error message copied verbatim
- What has already been ruled out

## Before Writing Any Test

Read `apps/admin/docs/TESTING_NOTES.md` first. Check for existing
workarounds relevant to the component or pattern being tested.

## Component System

All UI components are fully custom and owned in `src/components/ui/`.
There is no shadcn/ui dependency. The complete component spec is in
`apps/admin/docs/cds/` (CDS-01 through CDS-10).

Before building any new UI component, check the CDS docs to see if it
is already specified. If specified but not yet built, build it to spec.
If not in the CDS at all, discuss before inventing.

```text
components/ui/      ← Pure UI — no imports from modules/, stores/, or lib/supabase/
components/shared/  ← Domain-aware — knows about order statuses, roles, etc.
```

## Before Implementing Any Module

1. Read `FEATURE_ARCH.md` in the module folder — it is the full spec
2. Check which CDS components are required — build missing ones first
3. Confirm Supabase migrations are applied (`pnpm db:status`)
4. Confirm TypeScript types are current (`pnpm db:types` if schema changed recently)

## Supabase Client — Which One Where

| Context                         | Client                  | Import from                             |
| ------------------------------- | ----------------------- | --------------------------------------- |
| Server Component, Server Action | `createServerClient()`  | `@/lib/supabase/server`                 |
| Client Component, Realtime      | `createBrowserClient()` | `@/lib/supabase/client`                 |
| Privileged op (bypass RLS)      | Admin client            | `@/lib/supabase/server` (admin variant) |

Never use the browser client in a Server Component.
Never use the server client in a Client Component.

## Key Commands

All `db:*` commands call the Supabase CLI installed globally via Scoop
on Windows. Use the `pnpm db:*` script names — do not use `pnpm dlx supabase`.

```bash
# Development
pnpm dev              # Start all apps in development mode (admin on localhost:3000)
pnpm type-check       # TypeScript check across all workspaces — must pass before commit
pnpm lint             # ESLint across all workspaces
pnpm test             # Run Vitest unit + integration tests
pnpm test --watch     # Run tests in watch mode during development

# Supabase local
pnpm db:start         # Start local Supabase Docker containers
pnpm db:stop          # Stop local Supabase Docker containers
pnpm db:status        # Show running containers and local URLs
pnpm db:reset         # Wipe local DB and rerun all migrations from scratch
pnpm db:types         # Regenerate TypeScript types from local schema
pnpm db:migrate NAME  # Create a new timestamped migration file
pnpm db:push          # Push pending migrations to remote Supabase project
```

Local Supabase Studio: `http://localhost:54323`

## Reference Documents

```text
# Platform-wide (platform/docs/)
platform/docs/roadmap.md
platform/docs/tech-stack.md
platform/docs/non-functional-requirements.md
platform/docs/erm.md
platform/docs/workflows/01_module_development_plan.md
platform/docs/workflows/02_feature_implementation_workflow.md
platform/docs/workflows/03_daily_dev_deployment_flow.md

# Admin-specific (apps/admin/docs/)
apps/admin/docs/prd.md
apps/admin/docs/frontend-architecture.md
apps/admin/docs/backend-architecture/01_connection_patterns.md
apps/admin/docs/backend-architecture/02_rls.md
apps/admin/docs/backend-architecture/03_jwt_auth_hook.md
apps/admin/docs/backend-architecture/04_edge_functions.md
apps/admin/docs/backend-architecture/05_database_triggers.md
apps/admin/docs/backend-architecture/06_storage_buckets.md
apps/admin/docs/backend-architecture/07_realtime.md
apps/admin/docs/cds/01_overview.md
apps/admin/docs/cds/02_design_tokens.md
apps/admin/docs/cds/03_primitives.md
apps/admin/docs/cds/04_feedback_components.md
apps/admin/docs/cds/05_overlay_components.md
apps/admin/docs/cds/06_form_components.md
apps/admin/docs/cds/07_data_display.md
apps/admin/docs/cds/08_navigation_and_layout.md
apps/admin/docs/cds/09_domain_components.md
apps/admin/docs/cds/10_accessibility_contract.md
apps/admin/docs/testing-strategy.md
apps/admin/docs/db-migrations.md
apps/admin/docs/BUGS.md
apps/admin/docs/TESTING_NOTES.md
```

## Current Development State

### ✅ Completed Modules

— None yet

### 🔄 In Progress

— Auth + Layout Shell

### ⏳ Not Started

```text
— Catalog: Categories
— Catalog: Products
— Customers
— Orders
— Addresses
— Dashboard
— Sales / Analytics
— Staff Management
— Settings
— Audit Logs
— Notifications
```

---

*Update this section after each module is completed.*  
*Move the module from In Progress → Completed with the completion date.*