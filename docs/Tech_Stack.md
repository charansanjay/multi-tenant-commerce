# Platform — Tech Stack

**Project:** Multi-Tenant Commerce
**Version:** 1.3  
**Backend:** Supabase (PostgreSQL)  
**Status:** Finalized  
**Date:** 2026-03-23

## Table of Contents

- [1. Overview](#1-overview)
- [2. Frontend Framework](#2-frontend-framework)
- [3. UI and Styling](#3-ui-and-styling)
- [4. State Management](#4-state-management)
- [5. Tables and Data Grids](#5-tables-and-data-grids)
- [6. Forms and Validation](#6-forms-and-validation)
- [7. Feature Libraries](#7-feature-libraries)
- [8. Internationalisation](#8-internationalisation)
- [9. Backend — Supabase](#9-backend--supabase)
- [10. Tooling and Developer Experience](#10-tooling-and-developer-experience)
- [11. Testing](#11-testing)
- [12. Deployment](#12-deployment)
- [13. What to Avoid](#13-what-to-avoid)
- [14. Full Dependency Reference](#14-full-dependency-reference)
- [15. Changelog](#15-changelog)

## 1. Overview

This document defines the complete technology stack for the Pizza Admin System frontend. All decisions are tailored to the system requirements: a Supabase-backed admin portal with role-based access control, real-time notifications, large-dataset table operations, multi-module management (orders, customers, catalog, analytics), PDF invoice generation, and support for English, Czech, and German.

The stack is deliberately lean. Every library included has a specific job tied to a documented requirement. No library is included speculatively.

## 2. Frontend Framework

### Next.js 16 (App Router)

```sh
next: ^16.0.0
react: ^19.0.0
react-dom: ^19.0.0
typescript: ^5.0.0
```

**Why Next.js 16 with App Router:**

Server Components handle initial Supabase data fetching without client-side waterfalls. Route-based code splitting keeps the initial bundle small. Server Actions simplify form submissions and mutations (order status updates, product edits) without requiring separate API routes.

Turbopack is now the stable default bundler for both `next dev` and `next build` — no flags required. The React Compiler is stable in Next.js 16 and enabled by default, automatically memoizing components and eliminating unnecessary re-renders with zero manual code changes. Dev server startup is ~400% faster than Next.js 15.

**Breaking change from Next.js 15:** `middleware.ts` is renamed to `proxy.ts` and the exported function renamed from `middleware` to `proxy`. The logic stays the same — only the filename and export name change. The edge runtime is not supported in `proxy.ts`; it runs on Node.js only.

**Why React 19:**

Concurrent features are directly useful here. The real-time notification inbox and optimistic order status updates benefit from React's concurrent rendering model. Transitions keep the UI responsive while data loads.

**Why TypeScript 5:**

Non-negotiable for a codebase of this scale. TypeScript types are generated directly from the Supabase schema using `supabase gen types typescript`, meaning the DB column definitions and frontend types stay in sync automatically. Any mismatch between what the DB returns and what the frontend expects is caught at compile time.

**Project structure convention:**

```sh
src/
  app/                  ← Next.js App Router pages and layouts
  components/           ← Shared UI components
  modules/              ← Feature modules (orders, customers, catalog, etc.)
  lib/                  ← Supabase client, utility functions
  hooks/                ← Custom React hooks
  stores/               ← Zustand stores
  types/                ← Generated Supabase types + shared interfaces
  i18n/                 ← Locale files (en, cs, de)
```

## 3. UI and Styling

### Tailwind CSS 4

```sh
tailwindcss: ^4.0.0
```

Tailwind CSS 4 is a significant upgrade — it drops the config file requirement for basic usage, improves performance, and supports modern CSS features natively. Used for all layout, spacing, colour, and responsive styling.

### Custom Component System

All UI components are built fully custom and owned directly in the codebase under `src/components/ui/`. There is no shadcn/ui dependency. This decision is made deliberately for maximum portability — the component library has no external lineage and can travel to future projects without carrying a dependency chain.

The component system is defined in full in the CDS documents (CDS-01 through CDS-10), covering design tokens, primitives, feedback components, overlays, forms, data display, navigation, domain components, and the accessibility contract.

**Component categories and what they cover:**

| Category | Components |
|---|---|
| Primitives | Button, IconButton, Badge, Input, Textarea, Checkbox, RadioGroup, Switch, Label, Spinner, Skeleton, Divider, Avatar |
| Feedback | Toast, Alert, StatusBadge, ProgressBar |
| Overlays | Modal, ConfirmDialog, Drawer, Tooltip, Popover, DropdownMenu |
| Forms | FormField, Select, Combobox, DatePicker |
| Data Display | DataTable, Pagination, EmptyState, Card, StatCard |
| Navigation & Layout | Sidebar, Topbar, PageContainer, PageHeader, Tabs, Breadcrumb |
| Domain | OrderStatusBadge, PaymentStatusBadge, ProductStatusBadge, RoleBadge |

### Radix UI — conditional fallback only

```sh
@radix-ui/react-*: latest
```

Radix UI is **not used by default**. It is a named fallback for Tier 3 accessibility-heavy components only — Modal, Select, Combobox, DatePicker, DropdownMenu — if building WCAG AA compliance from scratch proves too costly during implementation. Radix is a headless accessibility primitives library (focus trapping, keyboard navigation, ARIA roles) with no visual opinions. If reached for, the custom visual layer is still built on top — Radix only provides the behaviour plumbing. See CDS-01 Section 4 for the full hybrid fallback rationale.

### Lucide React

```sh
lucide-react: ^0.400.0
```

Icon library used throughout the sidebar navigation, table actions, status badges, and notification indicators. Tree-shakeable — only icons actually imported are bundled.

## 4. State Management

Two libraries handle different categories of state. They do not overlap.

### TanStack Query v5 — server state

```sh
@tanstack/react-query: ^5.0.0
```

TanStack Query manages all data that comes from Supabase: fetching, caching, background refetching, and mutations. It is the most important library in the stack after Next.js itself.

**Why it is essential for this project:**

- Orders, customers, and products tables require real-time cache invalidation when another staff member makes a change
- Optimistic mutations allow order status updates to feel instant while the Supabase update runs in the background
- Automatic background refetching keeps the dashboard widgets (today's orders, revenue) current without manual polling logic
- Query deduplication prevents multiple components from firing the same Supabase request simultaneously

**Usage pattern:**

```typescript
// Fetching orders with filters
const { data, isLoading } = useQuery({
  queryKey: ['orders', { status, page, search }],
  queryFn: () => fetchOrders({ status, page, search }),
});

// Optimistic order status update
const mutation = useMutation({
  mutationFn: updateOrderStatus,
  onMutate: async ({ orderId, status }) => {
    await queryClient.cancelQueries({ queryKey: ['orders'] });
    const previous = queryClient.getQueryData(['orders']);
    queryClient.setQueryData(['orders'], (old) => optimisticUpdate(old, orderId, status));
    return { previous };
  },
  onError: (err, vars, context) => {
    queryClient.setQueryData(['orders'], context.previous);
  },
  onSettled: () => queryClient.invalidateQueries({ queryKey: ['orders'] }),
});
```

### Zustand — client state

```sh
zustand: ^4.0.0
```

Zustand handles lightweight client-only state that does not need to be persisted or fetched from a server.

**What Zustand manages:**

| Store | State |
|---|---|
| `ui` | Sidebar expanded/collapsed, active module |
| `notifications` | Unread count, notification panel open/closed |
| `table` | Selected rows (for bulk actions), column visibility |
| `modals` | Which modal is open, with what entity ID |

Zustand is preferred over React Context for this because it avoids unnecessary re-renders — only components subscribed to the specific slice of state they need will re-render when it changes.

## 5. Tables and Data Grids

### TanStack Table v8

```sh
@tanstack/react-table: ^8.0.0
```

TanStack Table is a headless table library — it provides all sorting, filtering, pagination, and selection logic while the custom `DataTable` component handles the actual rendering. This is the correct choice given the PRD's requirement for filtering, sorting, pagination, and export across every module.

**Server-side operations:** All sorting, filtering, and pagination run server-side against Supabase. TanStack Table's controlled state model (`manualSorting`, `manualFiltering`, `manualPagination`) passes the current state to the query function, which builds the appropriate Supabase query.

**Column definitions** are defined per module and include: sortable headers, filter inputs, status badge rendering, and action menus (edit, view, delete).

### TanStack Virtual

```sh
@tanstack/react-virtual: ^3.0.0
```

Used for virtualised rendering in the audit logs table and any table likely to display thousands of rows without pagination. Only the visible rows are rendered in the DOM — scroll performance remains smooth regardless of dataset size.

## 6. Forms and Validation

### React Hook Form

```sh
react-hook-form: ^7.0.0
```

React Hook Form minimises re-renders during form input — critical for complex forms like the order creation form, which includes customer selection, line items with quantity controls, address snapshot logic, coupon validation, and financial totals that update as items are added.

### Zod

```sh
zod: ^3.0.0
```

Zod schemas are the single source of truth for data shape and validation rules. Each schema:

- Mirrors the database table constraints (required fields, max lengths, enums)
- Provides TypeScript types via `z.infer<typeof schema>`
- Is used by React Hook Form via `@hookform/resolvers/zod`
- Is reused in Server Actions for server-side validation before the Supabase call

```sh
@hookform/resolvers: ^3.0.0
```

**Example — order creation schema:**

```typescript
const orderSchema = z.object({
  customer_name: z.string().min(1).max(200),
  payment_method: z.enum(['card', 'cash_on_delivery']),
  source: z.enum(['website', 'phone', 'walk_in', 'admin_created']),
  items: z.array(z.object({
    variant_id: z.string().uuid(),
    quantity: z.number().int().positive(),
  })).min(1),
  coupon_code: z.string().optional(),
  notes: z.string().optional(),
});
```

The same schema is used client-side (React Hook Form) and server-side (Server Action), eliminating any risk of bypassed validation.

## 7. Feature Libraries

### Charts — Recharts

```sh
recharts: ^2.0.0
```

Used in the Sales / Analytics module for: revenue by day, revenue by product, revenue by category, and orders per day. Recharts is React-native, composable, and sufficient for the chart types defined in the PRD. All data is pre-aggregated server-side before being passed to chart components.

### PDF Invoice Generation — @react-pdf/renderer

```sh
@react-pdf/renderer: ^3.0.0
```

Invoices are defined as React components and rendered to PDF. This approach allows the invoice template to be built and styled in JSX, with full TypeScript support. PDF generation runs in a Supabase Edge Function (server-side) to avoid shipping the renderer to the client bundle.

The PDF output per the PRD includes: order number, customer details, line items with prices, coupon discount, VAT breakdown, grand total, and payment status.

### CSV and Excel Export — SheetJS + PapaParse

```sh
xlsx: ^0.18.0
papaparse: ^5.0.0
```

SheetJS (`xlsx`) handles Excel export for all tables (orders, customers, products, addresses). PapaParse handles CSV export and also CSV import if needed. Both operations run client-side on the current filtered/sorted dataset. Every export generates an `exported` audit log entry per the GDPR requirement defined in DB_Table_11.

### Drag and Drop — @dnd-kit

```sh
@dnd-kit/core: ^6.0.0
@dnd-kit/sortable: ^7.0.0
```

Used in two places: reordering product images (the `product_images.sort_order` column) and reordering categories (the `categories.sort_order` column). `@dnd-kit` is accessible, touch-friendly, and has no jQuery dependency.

### Date Handling — date-fns

```sh
date-fns: ^3.0.0
```

Used for: formatting order timestamps, computing coupon validity windows (`valid_from` / `valid_until`), generating the analytics time filter ranges (daily, weekly, monthly, yearly), and displaying relative times in the notification inbox ("3 minutes ago").

Tree-shakeable — only the functions actually imported are included in the bundle.

### Image Upload — react-dropzone

```sh
react-dropzone: ^14.0.0
```

Handles file selection and drag-and-drop for uploading images to Supabase Storage. Used for: product images (up to 4 per product), staff profile avatars, customer profile avatars, and category images. Validates file type and size client-side before the Supabase Storage upload.

### Toast Notifications — Sonner

```sh
sonner: ^1.0.0
```

Used for all action confirmations and error messages in the admin UI: "Order status updated", "Product saved", "Coupon created", "Customer deleted". Sonner is framework-agnostic and supports queueing multiple toasts.

### Real-time Notifications — Supabase Realtime

Real-time delivery is handled by the `@supabase/supabase-js` client (no additional library needed). The frontend subscribes to `INSERT` events on the `notifications` table filtered by `staff_id = current_user_id OR staff_id IS NULL`. This powers the live notification inbox in the admin portal header.

## 8. Internationalisation

### next-intl

```sh
next-intl: ^3.0.0
```

Supports the three languages required by the PRD: English (`en`), Czech (`cs`), and German (`de`). `next-intl` integrates natively with Next.js App Router and supports Server Components — locale strings can be used in both server-rendered pages and client components without any hydration issues.

**Locale configuration:**

- Default language is configurable via the Settings module (`settings` table)
- Staff language preference is stored per staff profile
- The language selector in the top navigation bar switches locale immediately
- All date, number, and currency formatting is locale-aware

**Locale file structure:**

```sh
src/i18n/
  en.json
  cs.json
  de.json
```

## 9. Backend — Supabase

The backend is Supabase, as defined in the PRD. This section documents how the frontend integrates with each Supabase service.

### Client setup

```sh
@supabase/supabase-js: ^2.0.0
@supabase/ssr: ^0.0.10
```

`@supabase/ssr` is the current correct package for Supabase Auth integration with Next.js App Router. It replaces the deprecated `@supabase/auth-helpers-nextjs`. Two client instances are created:

- **Server client** — used in Server Components and Server Actions. Has access to the user's session via cookies.
- **Browser client** — used in Client Components. Used for Realtime subscriptions and client-side queries.

### Type generation

Supabase types are generated from the live database schema and committed to the repository:

```bash
supabase gen types typescript --project-id <project-id> > src/types/supabase.ts
```

These generated types are used directly in Zod schemas and API functions.

### Supabase services in use

| Service | Usage |
|---|---|
| **Database** | All 12 tables + triggers + RLS policies |
| **Auth** | Staff authentication. JWT custom claims carry `role` (admin, manager, staff) for RLS. |
| **Storage** | Product images, staff avatars, customer avatars, category images |
| **Realtime** | Live notification inbox subscriptions |
| **Edge Functions** | PDF invoice generation, atomic coupon `usage_count` increment, order number generation |

### Row Level Security

All RLS policies read the `role` claim from the Supabase JWT:

```sql
auth.jwt() ->> 'role'  -- returns 'admin', 'manager', or 'staff'
```

The custom claim is set during sign-in via a Supabase Auth hook that reads the user's role from `staff_profiles`. This is the pattern already defined in the database schema documents.

## 10. Tooling and Developer Experience

### ESLint

```sh
eslint: ^9.0.0
@typescript-eslint/eslint-plugin: ^7.0.0
@typescript-eslint/parser: ^7.0.0
eslint-config-next: ^16.0.0
```

Extends the Next.js recommended config. TypeScript rules enforce strict null checks and explicit return types on functions that interact with Supabase.

### Prettier

```sh
prettier: ^3.0.0
prettier-plugin-tailwindcss: ^0.6.0
```

`prettier-plugin-tailwindcss` automatically sorts Tailwind class names in a consistent order. Prettier runs on save in the editor and as a pre-commit check.

### Husky + lint-staged

```sh
husky: ^9.0.0
lint-staged: ^15.0.0
```

Pre-commit hook runs ESLint and Prettier on staged files only. This keeps commits clean without slowing down the full lint run.

```json
// package.json lint-staged config
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,css}": ["prettier --write"]
  }
}
```

### Supabase CLI

```sh
supabase: latest (dev dependency)
```

Used locally for: running a local Supabase instance during development, applying migrations, generating TypeScript types, and deploying Edge Functions.

## 11. Testing

### Vitest — unit and integration tests

```sh
vitest: ^1.0.0
@testing-library/react: ^14.0.0
@testing-library/user-event: ^14.0.0
jsdom: ^24.0.0
```

Vitest is the correct choice for a Next.js + Vite-adjacent stack. It is significantly faster than Jest and has native TypeScript support without additional configuration.

**What is unit-tested:**

- Zod validation schemas (all edge cases: missing contact info, invalid coupon dates, negative prices)
- Price calculation utilities (`actual_price`, `grand_total`, VAT calculation, coupon discount logic)
- Order number generation function
- Date formatting and locale utilities
- Zustand store actions

### Playwright — end-to-end tests

```sh
@playwright/test: ^1.40.0
```

Playwright runs E2E tests against a local Supabase instance seeded with test data.

**Critical flows covered:**

| Flow | Why |
|---|---|
| Staff login with role enforcement | RBAC is the security foundation of the system |
| Create an order with line items, coupon, and address | Most complex form in the system |
| Update order status through full workflow | Core operational task |
| Create a product with variants and images | Multi-step form with Supabase Storage |
| Export orders table to CSV and Excel | GDPR audit log dependency |
| Receive a real-time notification | Supabase Realtime integration |

## 12. Deployment

### Vercel

The natural deployment target for Next.js. Environment variables map directly to Supabase project credentials.

**Required environment variables:**

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=   # Server-only, never exposed to client
```

**Deployment strategy:**

| Branch | Environment | Notes |
|---|---|---|
| `main` | Production | Auto-deploy on merge |
| `develop` | Staging | Preview deployments |
| Feature branches | Preview | Per-PR preview URLs |

Supabase Edge Functions are deployed separately via the Supabase CLI as part of the CI pipeline.

## 13. What to Avoid

These are deliberate exclusions — tools that might seem applicable but are wrong for this project.

### No Prisma or Drizzle

An ORM adds a layer between the application and Supabase that creates friction with RLS policies, the Supabase client's query capabilities, and the generated TypeScript types. Call Supabase directly.

### No Redux or Redux Toolkit

The combination of TanStack Query (server state) and Zustand (client state) covers every state management need in this system. Redux adds boilerplate without benefit.

### No Next.js API routes as a proxy

Server Components and Server Actions call Supabase directly. API routes are only justified for webhook endpoints (e.g. a Stripe webhook updating payment status). Do not create API routes that simply proxy Supabase calls — this adds latency and duplicates error handling.

### No separate auth library

Supabase Auth handles everything: sessions, JWT, password reset, and MFA if needed. Do not add NextAuth or Clerk on top of it.

### No class-based components

This project uses only functional components with hooks throughout.

## 14. Full Dependency Reference

### Production dependencies

| Package | Version | Purpose |
|---|---|---|
| `next` | ^16.0.0 | Framework |
| `react` | ^19.0.0 | UI library |
| `react-dom` | ^19.0.0 | DOM rendering |
| `@supabase/supabase-js` | ^2.0.0 | Supabase client |
| `@supabase/ssr` | ^0.0.10 | Supabase Auth for App Router |
| `@tanstack/react-query` | ^5.0.0 | Server state management |
| `@tanstack/react-table` | ^8.0.0 | Headless table logic |
| `@tanstack/react-virtual` | ^3.0.0 | Virtualised list rendering |
| `zustand` | ^4.0.0 | Client state management |
| `react-hook-form` | ^7.0.0 | Form state and submission |
| `@hookform/resolvers` | ^3.0.0 | Zod adapter for React Hook Form |
| `zod` | ^3.0.0 | Schema validation |
| `tailwindcss` | ^4.0.0 | Utility-first CSS |
| `lucide-react` | ^0.400.0 | Icons |
| `recharts` | ^2.0.0 | Analytics charts |
| `@react-pdf/renderer` | ^3.0.0 | PDF invoice generation |
| `xlsx` | ^0.18.0 | Excel export |
| `papaparse` | ^5.0.0 | CSV export |
| `@dnd-kit/core` | ^6.0.0 | Drag and drop core |
| `@dnd-kit/sortable` | ^7.0.0 | Sortable list utilities |
| `date-fns` | ^3.0.0 | Date formatting and calculation |
| `react-dropzone` | ^14.0.0 | File upload UI |
| `sonner` | ^1.0.0 | Toast notifications |
| `next-intl` | ^3.0.0 | Internationalisation |

### Development dependencies

| Package | Version | Purpose |
|---|---|---|
| `typescript` | ^5.0.0 | Type safety |
| `eslint` | ^9.0.0 | Linting |
| `@typescript-eslint/eslint-plugin` | ^7.0.0 | TypeScript lint rules |
| `@typescript-eslint/parser` | ^7.0.0 | TypeScript parser for ESLint |
| `eslint-config-next` | ^16.0.0 | Next.js lint config |
| `prettier` | ^3.0.0 | Code formatting |
| `prettier-plugin-tailwindcss` | ^0.6.0 | Tailwind class sorting |
| `husky` | ^9.0.0 | Git hooks |
| `lint-staged` | ^15.0.0 | Pre-commit linting |
| `vitest` | ^1.0.0 | Unit testing |
| `@testing-library/react` | ^14.0.0 | React component testing |
| `@testing-library/user-event` | ^14.0.0 | User interaction simulation |
| `jsdom` | ^24.0.0 | DOM environment for Vitest |
| `@playwright/test` | ^1.40.0 | End-to-end testing |
| `supabase` | latest | Supabase CLI |

## 15. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-18 | Initial tech stack finalized |
| 1.1 | 2026-03-23 | Replaced shadcn/ui with fully custom component system per CDS-01. Radix UI repositioned as conditional fallback for Tier 3 accessibility-heavy components only. |
| 1.2 | 2026-03-23 | Upgraded from Next.js 15 to Next.js 16.2. Updated `next`, `eslint-config-next` to ^16.0.0. Noted Turbopack stable default, React Compiler stable, and `proxy.ts` rename from `middleware.ts`. |
| 1.3 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 1.3 | 2026-03-23 | Monorepo architecture adopted — Turborepo with `apps/admin`, `apps/web`, `apps/super-admin`, `packages/ui`, `packages/types`, `packages/utils` |
| 1.3 | 2026-03-23 | `variant_size` enum (`small`, `medium`, `large`) replaced with `option_name varchar(50)` — platform-generic variants |
| 1.3 | 2026-03-23 | Global `settings` table removed — per-tenant configuration lives in `tenants.settings` jsonb |
