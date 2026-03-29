# Module Development Plan

**Project:** Multi-Tenant Commerce — Admin Portal  
**Document:** `docs/workflows/01_module_development_plan.md`  
**Version:** 1.0  
**Date:** 2026-03-27  
**Status:** Active

## Table of Contents

- [1. Current State](#1-current-state)
- [2. Module Order and Rationale](#2-module-order-and-rationale)
- [3. Module Development Cycle](#3-module-development-cycle)
- [4. CDS Component Strategy](#4-cds-component-strategy)
- [5. HTML Mockup Workflow](#5-html-mockup-workflow)
- [6. CLAUDE.md — Content and Structure](#6-claudemd--content-and-structure)
- [7. GitHub Project Setup](#7-github-project-setup)
- [8. GitHub Issue Templates by Module](#8-github-issue-templates-by-module)
- [9. Living Document — How to Keep This Updated](#9-living-document--how-to-keep-this-updated)
- [10. Changelog](#10-changelog)

## 1. Current State

| Phase | Status |
|---|---|
| Project scope and PRD | ✅ Complete |
| Entity Relationship Map | ✅ Complete |
| Database schema and tables | ✅ Complete |
| Tech stack decisions | ✅ Complete |
| Non-Functional Requirements | ✅ Complete |
| Frontend Architecture (global) | ✅ Complete |
| Backend Architecture (global) | ✅ Complete |
| Component Design System (CDS-01 to CDS-10) | ✅ Complete |
| Testing Strategy | ✅ Complete |
| Project Scaffold | ✅ Complete |
| Database Migrations | ✅ Complete and verified |
| **Module Development** | 🔄 Starting now |

## 2. Module Order and Rationale

Modules are ordered by dependency. A module that other modules rely on must be
built first. Building out of this order means either working against incomplete
data or having to retrofit dependencies later.

| # | Module | Depends On | Rationale |
|---|---|---|---|
| 1 | Auth + Layout Shell | — | Every other module lives inside this shell. Login, middleware, sidebar, topbar, and the page layout must exist before any feature screen can be rendered. |
| 2 | Catalog — Categories | Auth Shell | The simplest data entity with no foreign key dependencies. Establishes all base patterns: DataTable, forms, empty states, RLS queries, TanStack Query setup. Module 1 is always the hardest — this is the right one to take that hit on. |
| 3 | Catalog — Products | Categories | Products have a required `category_id` foreign key. Categories must exist first. Products also introduce image upload (Supabase Storage), variants (nested data), and status management — more complex than Categories, building on the patterns established there. |
| 4 | Customers | Auth Shell | No dependency on Catalog. Can be built in parallel conceptually, but follows Products because the patterns from Catalog carry over. Introduces profile pictures (Storage) and the address sub-entity. |
| 5 | Orders | Catalog + Customers | Orders reference both `customer_id` and `product_variant_id`. Both must exist. Orders are the most complex module: status workflow, payment status, order items, invoice PDF generation, and real-time updates. |
| 6 | Addresses | Customers | Addresses are a read/manage view over address data created through Customers. Customers must be built first. This is a relatively thin module — most heavy lifting was done in Customers. |
| 7 | Dashboard | Orders + Catalog | The dashboard aggregates live data — today's orders, revenue, low stock, top sellers. Meaningful only when real Orders and Catalog data exist. |
| 8 | Sales / Analytics | Orders | Analytics are derived from order data. Orders must be complete before analytics queries are meaningful to build and test. |
| 9 | Staff Management | Auth Shell | Manage staff accounts and roles. Kept late because it requires understanding of how roles are used across all other modules before the management UI makes full sense. |
| 10 | Settings | Auth Shell | Tenant configuration — branding, language, payment methods, security. No hard dependencies on other modules. Kept late because settings inform but don't block any other module. |
| 11 | Audit Logs | All modules | Audit log entries are created passively by database triggers throughout all modules. The read/filter UI is built last when all entry types exist and can be tested. |
| 12 | Notifications | Orders + Auth Shell | Notification triggers come primarily from Orders (new order, low stock, failed payment). Built last when the trigger sources are stable. |

## 3. Module Development Cycle

This is the exact sequence followed for every module, every time. No steps
are skipped. No steps are reordered.

```text
Step 1 → Feature Architecture (Claude Web)
Step 2 → CDS Component Pre-Check
Step 3 → HTML Mockup — screen by screen (Claude Web)
Step 4 → Full Module Mockup (Claude Web)
Step 5 → Mockup Approval
Step 6 → Supabase Layer Review
Step 7 → Implementation (Claude Code)
Step 8 → Testing
Step 9 → Review and Refactor
Step 10 → Close GitHub Issues + Update This Document
```

---

### Step 1 — Feature Architecture (Claude Web)

**Where:** Claude Web app (this interface)  
**Output:** `apps/admin/src/modules/[module]/FEATURE_ARCH.md`

Produce a Feature Architecture document for the module. This document is the
single source of truth that Claude Code works from during implementation. It
must be thorough — vague architecture leads to drift.

The Feature Architecture document covers:

- Module overview and scope
- All screens in this module (list, detail, forms, sub-pages)
- Component tree per screen — which components, what props, Server vs Client
- Data requirements per component — what data, where it comes from
- TanStack Query keys and query functions
- Supabase queries (select, insert, update, delete)
- Zod schemas for all forms
- URL routes and dynamic segments
- Empty states, loading states, error states
- RBAC — which roles can see/do what in this module
- Edge cases and business rules

**Once written, commit this file to the repo before any implementation starts.**

---

### Step 2 — CDS Component Pre-Check

**Where:** Claude Web app  
**Output:** A short checklist of required vs available components

Before touching any code, review the component tree from the Feature
Architecture document and check it against what exists in
`apps/admin/src/components/ui/` and `apps/admin/src/components/shared/`.

For each component required by this module:

- ✅ Already built — proceed
- 🔨 Missing — build it before starting implementation

Build missing components first, in isolation, before implementing the module.
This prevents being blocked mid-implementation.

**Rule:** Never discover a missing component after implementation has started.
The pre-check exists to prevent exactly this.

---

### Step 3 — HTML Mockup — Screen by Screen (Claude Web)

**Where:** Claude Web app  
**Output:** Reviewed and approved HTML files per screen

For each screen identified in the Feature Architecture document, produce an
HTML mockup. Screens are reviewed and approved individually before moving to
the next.

Each mockup shows:

- Exact layout, component placement, and spacing
- Real-looking data (not lorem ipsum — use realistic pizza shop data)
- All interactive states visible: empty state, loaded state, loading skeleton
- Form fields, validation states, and error messages
- Action buttons, filters, sort controls
- Mobile responsiveness if applicable

The screens are reviewed one by one. Feedback is incorporated. Only when a
screen is explicitly approved does the next screen's mockup get produced.

See [Section 5](#5-html-mockup-workflow) for the full mockup workflow.

---

### Step 4 — Full Module Mockup (Claude Web)

**Where:** Claude Web app  
**Output:** One consolidated HTML file showing the full module flow

Once all individual screens are approved, produce a single mockup that shows
the module as a whole — navigation between screens, how list → detail →
form → back flows together. This is the final visual sanity check before
any real code is written.

---

### Step 5 — Mockup Approval

Explicit go/no-go before implementation starts.

If approved: proceed to Step 6.  
If changes needed: revise the relevant screen mockup and re-review.

**No implementation starts without explicit approval.**

---

### Step 6 — Supabase Layer Review

**Where:** Claude Web app  
**Duration:** Short — this is a review, not a design session

Review the Supabase layer requirements for this module against what is already
in place from the global backend architecture and existing migrations:

- Are all required tables and columns present?
- Are RLS policies correct for this module's access patterns?
- Are any new Edge Functions needed?
- Are any new database triggers needed?
- Are any new storage bucket policies needed?

If anything is missing, create the migration file first before implementation.
Run `pnpm db:migrate [description]`, write the SQL, then `pnpm db:reset` and
`pnpm db:types` to regenerate TypeScript types.

---

### Step 7 — Implementation (Claude Code)

**Where:** VS Code with Claude Code  
**Input:** `FEATURE_ARCH.md` in the module folder + `CLAUDE.md` at root

Implementation follows the Feature Architecture document exactly. Claude Code
reads `CLAUDE.md` at session start automatically. At the beginning of each
implementation session, provide the standard session start prompt (see
Document 2 — Feature Implementation Workflow for the prompt template).

Implementation order within a module:

1. Supabase query functions (`lib/` or `modules/[module]/api.ts`)
2. TanStack Query hooks (`modules/[module]/hooks/`)
3. Zod schemas (`modules/[module]/schemas.ts`)
4. Server Component page shells (`app/(admin)/[route]/page.tsx`)
5. Client Component feature components (`modules/[module]/components/`)
6. Wire together and verify data flow end to end

---

### Step 8 — Testing

**Where:** VS Code with Claude Code

Write tests as part of implementation, not after. Co-locate test files next
to source files per the testing strategy.

| Test type | What to test | Tool |
|---|---|---|
| Unit | Utility functions in `lib/`, Zustand store actions | Vitest |
| Integration | Component behaviour — does the right thing render with the right data? | Vitest + Testing Library |
| E2E | Critical user flows — create, edit, delete, status change | Playwright |

Run the full test suite before marking the module complete:

```bash
pnpm type-check
pnpm lint
pnpm test
```

---

### Step 9 — Review and Refactor

Before closing out the module:

- Re-read the Feature Architecture document — is everything implemented?
- Check RBAC — do role restrictions work correctly in the UI?
- Check empty states, loading states, and error states — all handled?
- Check accessibility — keyboard navigation, ARIA labels, focus management
- Check i18n — all strings in locale files, none hardcoded
- Run `tsc --noEmit` — zero errors
- Check for any `console.log` statements left in production code

---

### Step 10 — Close GitHub Issues + Update This Document

- Mark all GitHub issues for this module as closed
- Update the milestone as complete
- Update the **Current State** section in this document (Section 1) to
  reflect the completed module
- Update `CLAUDE.md` — move the module from "In Progress" to "Complete"
- If any design token decisions were made during this module's mockup
  sessions, add them to .claude/decisions/design-tokens.md

## 4. CDS Component Strategy

All CDS components are documented in `docs/cds/` (CDS-01 through CDS-10).
They are implemented in `apps/admin/src/components/ui/` (pure UI, no business
logic) and `apps/admin/src/components/shared/` (domain-aware components).

### Build Strategy: Core Upfront + Pre-Check Per Module

**Before Module 1 (Auth + Layout Shell):**

Build the components that the shell and every subsequent module will need
immediately. These cannot be deferred:

| Component | CDS Reference | Why Needed Immediately |
|---|---|---|
| Button | CDS-03 | Every form, every action |
| IconButton | CDS-03 | Sidebar, topbar, table actions |
| Input | CDS-03 | Every form |
| Spinner | CDS-03 | Every loading state |
| Skeleton | CDS-03 | Every loading state |
| Sidebar | CDS-08 | The shell itself |
| Topbar | CDS-08 | The shell itself |
| PageContainer | CDS-08 | Every page |
| PageHeader | CDS-08 | Every page |
| Toast | CDS-04 | Every mutation feedback |
| Avatar | CDS-03 | Topbar user profile |

**Per Module (at Step 2 of each cycle):**

At the Feature Architecture stage, identify which components the module needs.
Check against what is already built. Build only what is missing.

**Rule:** Never build a component speculatively. Build it when a module
needs it and not before.

## 5. HTML Mockup Workflow

### Process

For each module, produce individual screen mockups first, then a full module
consolidation. All mockups are produced in Claude Web before any code is
written in Claude Code.

```
Screen 1 mockup → Review → Approve
Screen 2 mockup → Review → Approve
...
Full module mockup → Final review → Approve
↓
Implementation begins
```

### What Each Mockup Must Show

- Realistic layout using the CDS design tokens (colours, spacing, typography)
- Real-looking sample data — not "Lorem ipsum" but actual pizza shop data
  (e.g. "Margherita Pizza — Veg — €12.50 — Active")
- The loaded state (data present)
- The empty state (no data, first-use experience)
- The loading skeleton state
- All form fields with placeholder text and validation error examples
- Action buttons in their correct positions
- Filter, sort, search, and pagination controls where applicable

### Feedback and Revision

During review, feedback may be:

- Layout change — revise and re-render
- Data display change — revise and re-render
- New screen discovered — add it to the Feature Architecture document first,
  then produce the mockup

A screen is only approved when you explicitly say so. Ambiguous responses
are treated as "not yet approved."

## 6. CLAUDE.md — Content and Structure

`CLAUDE.md` lives at the monorepo root. Claude Code reads it automatically
at the start of every session. It must be concise — Claude Code reads the
whole file every session, so it should contain only what Claude Code needs
to know, not the full project history.

Below is the ready-to-use content. Copy this into `CLAUDE.md` at the
monorepo root, then keep the **Current Development State** section updated
as modules are completed.

---

```markdown
# CLAUDE.md — Multi-Tenant Commerce Admin Portal

## Project Overview

A multi-tenant food ordering platform admin portal. Currently building
Tenant #1 (Pizza Palace) as the reference implementation.

Monorepo: Turborepo + pnpm workspaces
App: apps/admin — Next.js 16, React 19, TypeScript 5 strict
Backend: Supabase (Postgres + Auth + Storage + Realtime)
Styling: Tailwind CSS 4 + custom CDS component system
State: TanStack Query (server) + Zustand (client)
i18n: next-intl (en, cs, de)

## Monorepo Structure

platform/
├── apps/
│   ├── admin/          ← Active development
│   ├── web/            ← Stubbed, built later
│   └── super-admin/    ← Stubbed, built later
├── packages/
│   ├── ui/             ← Shared CDS components
│   ├── types/          ← Shared TypeScript types
│   └── utils/          ← Shared utilities (cn, formatCurrency, etc.)

## apps/admin Source Structure

src/
  app/                  ← Next.js App Router pages and layouts
    (auth)/             ← Unauthenticated routes (login)
    (admin)/            ← Protected routes (all feature modules)
  components/
    ui/                 ← Pure CDS components — no business logic
    shared/             ← Domain-aware components (OrderStatusBadge, etc.)
  modules/              ← Feature modules
    [module]/
      FEATURE_ARCH.md   ← Read this before implementing anything in this module
      components/       ← Module-specific components
      hooks/            ← TanStack Query hooks for this module
      api.ts            ← Supabase query functions
      schemas.ts        ← Zod schemas
  lib/                  ← Supabase clients, utility functions
  hooks/                ← Global custom hooks
  stores/               ← Zustand stores
  types/                ← Generated Supabase types + shared interfaces
  i18n/                 ← Locale files (en.json, cs.json, de.json)

## Critical Patterns — Always Follow These

### 1. Server Shell → Client Island

Every page is a Server Component that fetches initial data and passes
it to a Client Component via initialData.

// app/(admin)/orders/page.tsx — Server Component
export default async function OrdersPage() {
  const supabase = createServerClient()
  const { data } = await supabase.from('orders').select('...').limit(50)
  return <OrdersTable initialData={data} />
}

// modules/orders/components/OrdersTable.tsx — Client Component
'use client'
export function OrdersTable({ initialData }) {
  const { data } = useQuery({ queryKey: ['orders'], queryFn: fetchOrders, initialData })
}

### 2. No Manual Tenant Filtering

Never add .eq('tenant_id', ...) to any Supabase query.
RLS policies enforce tenant isolation automatically via the JWT claim.
Adding manual filters is redundant and signals a misunderstanding.

### 3. TypeScript Types from Supabase

All database types come from src/types/database.types.ts — auto-generated
by supabase gen types typescript. Never hand-write database types.
Run pnpm db:types after any schema change.

### 4. All Strings in Locale Files

Never hardcode user-facing strings in components. Always use useTranslations()
from next-intl. Keys live in src/i18n/en.json (and cs.json, de.json).

### 5. Component System

All UI components are in src/components/ui/ — fully custom, no shadcn/ui.
Domain status badges are in src/components/shared/.
Check CDS docs in docs/cds/ before building any new component.

### 6. Error and Loading States

Every data-fetching component must handle three states:
- Loading: show Skeleton components
- Error: show Alert component with retry option
- Empty: show EmptyState component

## Before Implementing Any Module

1. Read FEATURE_ARCH.md in the module folder
2. Check which CDS components are needed — build missing ones first
3. Verify Supabase layer is in place (tables, RLS, migrations applied)

## Key Commands

pnpm dev              — Start all apps in development mode
pnpm type-check       — TypeScript check across all workspaces
pnpm lint             — ESLint across all workspaces
pnpm test             — Run Vitest unit + integration tests
pnpm db:start         — Start local Supabase instance
pnpm db:reset         — Wipe and re-run all migrations
pnpm db:types         — Regenerate TypeScript types from schema
pnpm db:migrate NAME  — Create a new migration file

## Reference Documents

docs/frontend-architecture.md     — Server/client patterns, routing, state
docs/backend-architecture/        — RLS conventions, Edge Functions, triggers
docs/cds/                         — Component Design System (CDS-01 to CDS-10)
docs/testing-strategy.md          — Test types, co-location, coverage targets
docs/workflows/                   — Module development and daily workflows

## Current Development State

### Completed Modules
— None yet

### In Progress
— Auth + Layout Shell (Module 1)

### Not Started
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

## 7. GitHub Project Setup

### Repository Setup

The Git repository was initialised during scaffold with two branches:

- `main` — production-ready code only
- `develop` — integration branch; all feature branches merge here

### Branch Naming Convention

```
feature/[module]-[short-description]

Examples:
feature/auth-login-page
feature/catalog-categories-list
feature/catalog-products-create-form
feature/orders-status-workflow
```

### GitHub Project Board

Create one GitHub Project for the admin portal with a Kanban board.

**Columns:**

| Column | Meaning |
|---|---|
| Backlog | Not yet started |
| Feature Architecture | FA document in progress |
| Mockup | HTML mockup in progress |
| In Progress | Implementation underway |
| Testing | Tests being written/run |
| Review | Self-review and refactor |
| Done | Merged to develop, issues closed |

### Labels

Create the following labels in the repository:

| Label | Colour | Use |
|---|---|---|
| `module:auth` | #6366f1 | Auth + Layout Shell |
| `module:catalog` | #f59e0b | Catalog (Categories + Products) |
| `module:customers` | #10b981 | Customers module |
| `module:orders` | #3b82f6 | Orders module |
| `module:addresses` | #8b5cf6 | Addresses module |
| `module:dashboard` | #ec4899 | Dashboard module |
| `module:sales` | #14b8a6 | Sales / Analytics |
| `module:staff` | #f97316 | Staff Management |
| `module:settings` | #64748b | Settings |
| `module:audit` | #ef4444 | Audit Logs |
| `module:notifications` | #a855f7 | Notifications |
| `type:feature` | #22c55e | Feature implementation |
| `type:bug` | #ef4444 | Bug fix |
| `type:cds` | #06b6d4 | CDS component build |
| `type:arch` | #f59e0b | Feature Architecture document |
| `type:mockup` | #8b5cf6 | HTML mockup |

### Milestones

Create one milestone per module, named exactly as the module:

```
Auth + Layout Shell
Catalog — Categories
Catalog — Products
Customers
Orders
Addresses
Dashboard
Sales / Analytics
Staff Management
Settings
Audit Logs
Notifications
```

## 8. GitHub Issue Templates by Module

Use these templates to create issues in GitHub. For each issue, assign the
appropriate label and milestone before saving.

---

### Module 1 — Auth + Layout Shell

```
Title: [Auth] Login page — UI and form
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement the login page at /login.
- Email + password form using FormField, Input, Button components
- Form validation with Zod
- Supabase Auth sign-in on submit
- Loading state on button during sign-in
- Error state for invalid credentials
- Redirect to /dashboard on success
- i18n strings in locale files
Ref: modules/auth/FEATURE_ARCH.md
```

```
Title: [Auth] Middleware and route protection
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement Next.js middleware to protect all (admin) routes.
- Unauthenticated requests redirect to /login
- Authenticated requests to /login redirect to /dashboard
- JWT tenant_id and role claims verified
Ref: modules/auth/FEATURE_ARCH.md
```

```
Title: [Auth] Admin layout shell — Sidebar + Topbar
Labels: module:auth, type:feature
Milestone: Auth + Layout Shell

Implement the (admin) layout with Sidebar and Topbar.
- Sidebar with full navigation menu (collapsible)
- Sidebar collapsed state (icons only)
- Topbar with logo, language selector, user profile, sign out
- PageContainer wrapping all child pages
- Active route highlighted in sidebar
Ref: modules/auth/FEATURE_ARCH.md
```

---

### Module 2 — Catalog: Categories

```
Title: [Catalog] Categories list screen
Labels: module:catalog, type:feature
Milestone: Catalog — Categories

Implement the categories list at /catalog/categories.
- DataTable with columns: Name, Status, Products count, Actions
- Search input (client-side filter)
- Sort by name and status
- Pagination
- Empty state
- Row actions: Edit, Disable/Enable, Delete
Ref: modules/catalog/FEATURE_ARCH.md
```

```
Title: [Catalog] Create category — drawer form
Labels: module:catalog, type:feature
Milestone: Catalog — Categories

Implement the Create Category drawer.
- Drawer opens from list screen
- Fields: Name, Status (Active/Disabled)
- Zod validation
- Supabase insert on submit
- Toast on success/error
- Optimistic update in TanStack Query cache
Ref: modules/catalog/FEATURE_ARCH.md
```

```
Title: [Catalog] Edit category — drawer form
Labels: module:catalog, type:feature
Milestone: Catalog — Categories

Implement the Edit Category drawer.
- Pre-populated with existing category data
- Same fields as Create
- Supabase update on submit
- Toast on success/error
- Optimistic update in TanStack Query cache
Ref: modules/catalog/FEATURE_ARCH.md
```

```
Title: [Catalog] Delete category — confirm dialog
Labels: module:catalog, type:feature
Milestone: Catalog — Categories

Implement delete category with ConfirmDialog.
- ConfirmDialog shows category name
- Warns if products exist in this category
- Supabase delete on confirm
- Toast on success/error
Ref: modules/catalog/FEATURE_ARCH.md
```

---

### Module 3 — Catalog: Products

```
Title: [Products] Products list screen
Labels: module:catalog, type:feature
Milestone: Catalog — Products

Implement the products list at /catalog/products.
- DataTable with columns: Image, Name, Category, Status, Variants count, Actions
- Filter by category and status
- Search by name
- Sort controls
- Pagination
- Export CSV/Excel
Ref: modules/catalog/FEATURE_ARCH.md
```

```
Title: [Products] Product detail page
Labels: module:catalog, type:feature
Milestone: Catalog — Products

Implement product detail at /catalog/products/[id].
- Display all product fields
- Display all variants in a nested table
- Image preview
- Edit and Delete actions
Ref: modules/catalog/FEATURE_ARCH.md
```

```
Title: [Products] Create/Edit product form
Labels: module:catalog, type:feature
Milestone: Catalog — Products

Implement create and edit product.
- Fields: Name, Description, Category (Select), Status, Image upload
- Image upload to Supabase Storage with preview
- Variants section: add/edit/remove variants inline
- Zod validation
- Toast on success/error
Ref: modules/catalog/FEATURE_ARCH.md
```

---

### Module 4 — Customers

```
Title: [Customers] Customers list screen
Labels: module:customers, type:feature
Milestone: Customers

Implement the customers list at /customers.
- DataTable with columns: Avatar, Name, Email, Phone, Status, Orders count, Actions
- Search by name/email
- Filter by status
- Sort controls
- Pagination
- Export CSV/Excel
Ref: modules/customers/FEATURE_ARCH.md
```

```
Title: [Customers] Customer detail page
Labels: module:customers, type:feature
Milestone: Customers

Implement customer detail at /customers/[id].
- Full customer profile display
- Addresses section (up to 4)
- Order history list
- Enable/Disable account action
Ref: modules/customers/FEATURE_ARCH.md
```

```
Title: [Customers] Create/Edit customer form
Labels: module:customers, type:feature
Milestone: Customers

Implement create and edit customer.
- Fields: First name, Last name, Gender, Email, Phone, Status
- Profile picture upload to Supabase Storage
- Zod validation
- Toast on success/error
Ref: modules/customers/FEATURE_ARCH.md
```

```
Title: [Customers] Manage customer addresses
Labels: module:customers, type:feature
Milestone: Customers

Implement address management within customer detail.
- List up to 4 addresses
- Add address form
- Edit address form
- Delete address with confirm dialog
Ref: modules/customers/FEATURE_ARCH.md
```

---

### Module 5 — Orders

```
Title: [Orders] Orders list screen
Labels: module:orders, type:feature
Milestone: Orders

Implement the orders list at /orders.
- DataTable with columns: Order ID, Customer, Status, Payment, Total, Date, Actions
- Filter by status and payment status
- Filter by date range
- Search by order ID or customer name
- Pagination
- Export CSV/Excel
Ref: modules/orders/FEATURE_ARCH.md
```

```
Title: [Orders] Order detail page
Labels: module:orders, type:feature
Milestone: Orders

Implement order detail at /orders/[id].
- Full order summary: items, totals, address, payment
- Order status workflow stepper
- Payment status badge
- Tracking number field
- Notes field
- Invoice PDF generate action
Ref: modules/orders/FEATURE_ARCH.md
```

```
Title: [Orders] Create manual order
Labels: module:orders, type:feature
Milestone: Orders

Implement create order flow.
- Select or create customer
- Add order items (product variant selector)
- Set delivery address
- Set payment method
- Notes field
- Submit creates order in Pending status
Ref: modules/orders/FEATURE_ARCH.md
```

```
Title: [Orders] Order status workflow
Labels: module:orders, type:feature
Milestone: Orders

Implement order status transitions.
- Status buttons: Confirm, Start Preparing, Mark Ready, Out for Delivery, Complete, Cancel
- Only valid next states shown (no going backwards except Cancel)
- Supabase update on transition
- Real-time update via Supabase Realtime
- Toast on success
Ref: modules/orders/FEATURE_ARCH.md
```

```
Title: [Orders] Invoice PDF generation
Labels: module:orders, type:feature
Milestone: Orders

Implement invoice PDF generation for an order.
- Generate PDF from order data
- Include order items, totals, customer info, tenant branding
- Download link returned to user
Ref: modules/orders/FEATURE_ARCH.md
```

---

### Module 6 — Addresses

```
Title: [Addresses] Addresses list screen
Labels: module:addresses, type:feature
Milestone: Addresses

Implement the addresses list at /addresses.
- DataTable with columns: Customer, Type, Address line, City, Postcode, Actions
- Filter by address type
- Search by customer name or postcode
- Sort controls
- Pagination
- Export
Ref: modules/addresses/FEATURE_ARCH.md
```

---

### Module 7 — Dashboard

```
Title: [Dashboard] Dashboard overview screen
Labels: module:dashboard, type:feature
Milestone: Dashboard

Implement the dashboard at /dashboard.
- StatCards: Today's Orders, Today's Revenue
- Top Selling Pizzas widget
- Low Stock Products widget
- Recent Orders table (last 10)
Ref: modules/dashboard/FEATURE_ARCH.md
```

---

### Module 8 — Sales / Analytics

```
Title: [Sales] Revenue analytics screen
Labels: module:sales, type:feature
Milestone: Sales / Analytics

Implement sales analytics at /sales.
- Revenue by day chart
- Revenue by product chart
- Revenue by category chart
- Orders per day chart
- Time filter: Daily, Weekly, Monthly, Yearly
Ref: modules/sales/FEATURE_ARCH.md
```

---

### Module 9 — Staff Management

```
Title: [Staff] Staff list screen
Labels: module:staff, type:feature
Milestone: Staff Management

Implement staff list in Settings or dedicated route.
- DataTable: Name, Email, Role, Status, Last active
- Invite new staff member
- Edit role
- Disable/Enable account
Ref: modules/staff/FEATURE_ARCH.md
```

---

### Module 10 — Settings

```
Title: [Settings] Branding settings
Labels: module:settings, type:feature
Milestone: Settings
Fields: App logo upload, App title
```

```
Title: [Settings] Language settings
Labels: module:settings, type:feature
Milestone: Settings
Fields: Default language selector (en, cs, de)
```

```
Title: [Settings] Payment methods settings
Labels: module:settings, type:feature
Milestone: Settings
Fields: Enable/disable Visa/Credit Card, Cash on delivery
```

```
Title: [Settings] Security settings
Labels: module:settings, type:feature
Milestone: Settings
Fields: Login attempt limit, IP whitelist, IP blacklist
```

---

### Module 11 — Audit Logs

```
Title: [Audit] Audit logs list screen
Labels: module:audit, type:feature
Milestone: Audit Logs

Implement audit logs at /audit-logs.
- DataTable: User, Action, Entity, Timestamp
- Filter by user, action type, date range
- Pagination (read-only, no edit/delete)
Ref: modules/audit/FEATURE_ARCH.md
```

---

### Module 12 — Notifications

```
Title: [Notifications] Notification inbox — topbar
Labels: module:notifications, type:feature
Milestone: Notifications

Implement notification inbox in Topbar.
- Bell icon with unread count badge
- Dropdown list of recent notifications
- Mark as read
- Real-time new notification via Supabase Realtime
Ref: modules/notifications/FEATURE_ARCH.md
```

## 9. Living Document — How to Keep This Updated

This document must stay current as modules are completed. After each module:

**In this document:**

- Move the module from "In Progress" to "Completed Modules" in Section 1
- Update the completion date

**In CLAUDE.md:**

- Move the module from "In Progress" to "Completed Modules"
- Remove it from "Not Started"

**In GitHub:**

- Close all issues for the milestone
- Mark the milestone as complete

**In the repo:**

- The `FEATURE_ARCH.md` for a completed module stays in place permanently —
  it serves as documentation of what was built and why

## 10. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-27 | Initial document created |
