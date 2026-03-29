# CLAUDE.md

Multi-Tenant Commerce — Admin Portal.
This file is permanent and never changes between modules. It tells you how
to navigate the project. Per-module instructions live in `.claude/modules/`.

## 1. What this project is

A multi-tenant admin portal for commerce operations — orders, catalog,
customers, addresses, sales analytics, staff management, and settings.
Each tenant is a separate business. Staff authenticate and see only their
own tenant's data via Supabase RLS.

Full product context: `apps/admin/docs/prd.md`
Entity relationships: `platform/docs/Entity_Relationship_Map__ERM_.md`

## 2. Before starting any session

Run these steps in order — do not skip any:

1. Find the current active module in `.claude/modules/` — read its `STATUS.md`
2. Read the module's `FEATURE_ARCH.md` (path is listed in STATUS.md)
3. If implementing UI — open the mockups listed in STATUS.md before writing any component
4. Read `.claude/instructions/coding-conventions.md`
5. Read the relevant instruction file for the task (see Section 4)

## 3. Project commands

```bash
pnpm dev              # start dev server
pnpm build            # production build
pnpm type-check       # tsc --noEmit — must pass before any commit
pnpm lint             # eslint — must pass before any commit
pnpm test             # vitest
pnpm test:e2e         # playwright
```

All commands run from the repo root via Turborepo.
Per-workspace: `pnpm --filter @platform/admin <command>`

## 4. Instruction files — read before writing code

| Task | Read this first |
|---|---|
| Any implementation | `.claude/instructions/coding-conventions.md` |
| Using colours, spacing, or radius | Check `apps/admin/src/styles/tokens.css` first — use token names, never hardcode hex values |
| Component / UI work | `.claude/instructions/component-patterns.md` |
| Supabase queries / actions | `.claude/instructions/supabase-patterns.md` |
| Writing tests | `.claude/instructions/testing-conventions.md` |

## 5. Design system

- All UI components live in `src/components/ui/` — fully custom, no shadcn
- CDS documentation: `apps/admin/docs/cds/` (CDS-01 through CDS-10)
- Design tokens (actual values): `apps/admin/src/styles/tokens.css`
- Design token decision log (why, not what): `.claude/decisions/design-tokens.md``
- Never install a UI component library. Never use shadcn. Never use MUI.

## 6. Folder structure (abbreviated)

```text
apps/admin/src/
├── app/                  ← Next.js App Router pages and layouts only
├── components/           ← Shared UI (ui/, layout/, shared/)
├── modules/              ← Feature modules (all business logic lives here)
├── lib/                  ← Supabase clients, utilities, constants
├── hooks/                ← Shared React hooks
├── stores/               ← Zustand stores
├── types/                ← Generated Supabase types + shared interfaces
└── i18n/                 ← en.json, cs.json, de.json
```

Full folder structure: `apps/admin/docs/frontend-architecture.md` Section 1.

## 7. Key rules — non-negotiable

- `app/` contains only routing files. No business logic, no direct Supabase calls.
- Cross-module imports are forbidden. Shared logic goes in `lib/` or `components/`.
- Never filter by `tenant_id` in queries — RLS enforces it automatically.
- Never hardcode user-facing strings — all copy lives in `i18n/*.json`.
- `pnpm type-check` and `pnpm lint` must both pass before marking any step done.
- Server Components are the default. Use `"use client"` only when necessary.

## 8. Module development cycle (10 steps)

Every module follows this exact cycle. Current status of each module is
tracked in `.claude/modules/XX_name/STATUS.md`.

```text
Step 1  — Feature Architecture (Claude Web) → FEATURE_ARCH.md
Step 2  — CDS component pre-check (Claude Web)
Step 3  — Screen mockups, one by one (Claude Web)
Step 4  — Full module mockup (Claude Web)
Step 5  — Go / No-Go (Claude Web)
Step 6  — Supabase layer review (Claude Web)
Step 7  — Implementation ← Claude Code works here
Step 8  — Testing
Step 9  — Review and refactor
Step 10 — Close GitHub issues, update STATUS.md, update roadmap
```

---

## 9. Module index

| # | Module | Status | STATUS.md |
|---|---|---|---|
| 01 | Auth + Layout Shell | 🔄 Step 5 — Go approved | `.claude/modules/01_auth/STATUS.md` |
| 02 | Catalog — Categories | ⏳ Not started | `.claude/modules/02_catalog_categories/STATUS.md` |
| 03 | Catalog — Products | ⏳ Not started | `.claude/modules/03_catalog_products/STATUS.md` |
| 04 | Customers | ⏳ Not started | `.claude/modules/04_customers/STATUS.md` |
| 05 | Orders | ⏳ Not started | `.claude/modules/05_orders/STATUS.md` |
| 06 | Addresses | ⏳ Not started | `.claude/modules/06_addresses/STATUS.md` |
| 07 | Dashboard | ⏳ Not started | `.claude/modules/07_dashboard/STATUS.md` |
| 08 | Sales / Analytics | ⏳ Not started | `.claude/modules/08_sales/STATUS.md` |
| 09 | Staff Management | ⏳ Not started | `.claude/modules/09_staff/STATUS.md` |
| 10 | Settings | ⏳ Not started | `.claude/modules/10_settings/STATUS.md` |
| 11 | Audit Logs | ⏳ Not started | `.claude/modules/11_audit_logs/STATUS.md` |
| 12 | Notifications | ⏳ Not started | `.claude/modules/12_notifications/STATUS.md` |
