# Global Non-Functional Requirements

**Project:** Multi-Tenant Commerce  
**Version:** 1.1  
**Scope:** Global — applies to all modules. Feature-level NFRs are defined per-module during feature architecture.  
**Status:** Finalized  
**Date:** 2026-03-23

## Table of Contents

- [1. Performance](#1-performance)
  - [1.1. NFR-P-01 — Initial page load 🔴](#11-nfr-p-01--initial-page-load-)
  - [1.2. NFR-P-02 — API and mutation response time 🔴](#12-nfr-p-02--api-and-mutation-response-time-)
  - [1.3. NFR-P-03 — Table rendering on large datasets 🔴](#13-nfr-p-03--table-rendering-on-large-datasets-)
  - [1.4. NFR-P-04 — Initial JS bundle size 🟡](#14-nfr-p-04--initial-js-bundle-size-)
- [2. Security](#2-security)
  - [2.1. NFR-S-01 — Authentication 🔴](#21-nfr-s-01--authentication-)
  - [2.2. NFR-S-02 — Role-based access control 🔴](#22-nfr-s-02--role-based-access-control-)
  - [2.3. NFR-S-03 — Input validation 🔴](#23-nfr-s-03--input-validation-)
  - [2.4. NFR-S-04 — Secrets management 🔴](#24-nfr-s-04--secrets-management-)
  - [2.5. NFR-S-05 — Login security controls 🟡](#25-nfr-s-05--login-security-controls-)
- [3. Reliability](#3-reliability)
  - [3.1. NFR-R-01 — Service uptime 🔴](#31-nfr-r-01--service-uptime-)
  - [3.2. NFR-R-02 — Graceful error handling in the UI 🔴](#32-nfr-r-02--graceful-error-handling-in-the-ui-)
  - [3.3. NFR-R-03 — Data backup 🔴](#33-nfr-r-03--data-backup-)
  - [3.4. NFR-R-04 — Optimistic UI rollback 🟡](#34-nfr-r-04--optimistic-ui-rollback-)
- [4. Scalability](#4-scalability)
  - [4.1. NFR-SC-01 — Concurrent user sessions 🔴](#41-nfr-sc-01--concurrent-user-sessions-)
  - [4.2. NFR-SC-02 — Real-time subscription management 🔴](#42-nfr-sc-02--real-time-subscription-management-)
  - [4.3. NFR-SC-03 — Database query performance at scale 🔴](#43-nfr-sc-03--database-query-performance-at-scale-)
- [5. Maintainability](#5-maintainability)
  - [5.1. NFR-M-01 — End-to-end type safety 🔴](#51-nfr-m-01--end-to-end-type-safety-)
  - [5.2. NFR-M-02 — Code quality gates 🔴](#52-nfr-m-02--code-quality-gates-)
  - [5.3. NFR-M-03 — Test coverage on core logic 🟡](#53-nfr-m-03--test-coverage-on-core-logic-)
  - [5.4. NFR-M-04 — Feature module isolation 🟡](#54-nfr-m-04--feature-module-isolation-)
- [6. Accessibility](#6-accessibility)
  - [6.1. NFR-A-01 — Keyboard navigation 🔴](#61-nfr-a-01--keyboard-navigation-)
  - [6.2. NFR-A-02 — Colour contrast 🔴](#62-nfr-a-02--colour-contrast-)
  - [6.3. NFR-A-03 — Screen reader support 🟡](#63-nfr-a-03--screen-reader-support-)
- [7. Internationalisation](#7-internationalisation)
  - [7.1. NFR-I-01 — Multi-language UI 🔴](#71-nfr-i-01--multi-language-ui-)
  - [7.2. NFR-I-02 — Locale-aware date and number formatting 🔴](#72-nfr-i-02--locale-aware-date-and-number-formatting-)
- [8. Observability](#8-observability)
  - [8.1. NFR-O-01 — Audit logging 🔴](#81-nfr-o-01--audit-logging-)
  - [8.2. NFR-O-02 — Error logging and monitoring 🟡](#82-nfr-o-02--error-logging-and-monitoring-)
- [9. Summary Table](#9-summary-table)
- [10. Changelog](#10-changelog)

## Priority Legend

| Symbol | Label | Meaning |
|--------|-------|---------|
| 🔴 | **Must have** | Non-negotiable. Blocks release if missing. |
| 🟡 | **Should have** | Strong expectation. Requires justification to defer. |
| 🟢 | **Nice to have** | Desirable. Can be deferred to a later iteration. |

## 1. Performance

> The portal is a staff-facing operational tool. Sluggishness directly hurts throughput during peak order hours.

### 1.1. NFR-P-01 — Initial page load 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | LCP < 2 seconds on fast 3G |
| **Measurement** | Lighthouse / Web Vitals via Vercel Analytics |

Next.js 16 Server Components handle initial Supabase data fetches server-side, eliminating client-side waterfalls. No page should require a client round-trip before rendering its primary content. Route-based code splitting ensures each module loads only what it needs.

**Implemented via:** Next.js 16 App Router · Server Components · Vercel Edge Network

### 1.2. NFR-P-02 — API and mutation response time 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | p95 < 300ms for Server Actions |
| **Measurement** | Vercel function logs |

Order status updates, product edits, and customer saves must feel instant. Optimistic mutations via TanStack Query update the UI before the server confirms, so the perceived latency is near-zero. The 300ms target applies to the actual server round-trip.

**Implemented via:** TanStack Query v5 · Supabase REST · Optimistic update pattern

---

### 1.3. NFR-P-03 — Table rendering on large datasets 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | 60 fps scroll on 10 000+ rows |
| **Measurement** | Chrome DevTools frame rate profiler |

All data tables (orders, customers, audit logs) must remain smooth at large row counts. Server-side pagination caps each page at ≤ 100 rows. TanStack Virtual is used for audit logs and any unbounded list, rendering only the visible rows in the DOM regardless of dataset size.

**Implemented via:** TanStack Table v8 · TanStack Virtual · Server-side pagination

---

### 1.4. NFR-P-04 — Initial JS bundle size 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | < 200 kB gzipped per initial route |
| **Measurement** | `next build` bundle analyser |

Route-based code splitting keeps per-route bundles small. Only icons actually imported are bundled (Lucide is fully tree-shakeable). No speculative dependencies are included in the stack.

**Implemented via:** Next.js code splitting · Lucide tree-shaking · Lean dependency policy

## 2. Security

> The portal is an internal tool with no public access. Security failures here directly expose customer data and business operations.

### 2.1. NFR-S-01 — Authentication 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | JWT sessions with optional MFA for admins |
| **Measurement** | Auth flow E2E test suite |

All staff must authenticate before accessing any route. Sessions are managed by Supabase Auth. JWT custom claims carry the staff `role` (`admin`, `manager`, `staff`) and `tenant_id` — both stamped by the Auth Hook at login. MFA is available for admin accounts. Unauthenticated requests to any page are redirected to the login screen via the Next.js proxy (`proxy.ts`).

**Implemented via:** Supabase Auth · `@supabase/ssr` · Next.js proxy route guard

---

### 2.2. NFR-S-02 — Role-based access control 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | Zero unauthorised data access, enforced at two layers |
| **Measurement** | RLS policy tests · E2E role enforcement tests |

Access control is enforced at three independent layers:

- **Frontend layer** — Next.js proxy and route guards hide restricted pages from lower-privilege roles.
- **Database layer — role** — Supabase RLS policies enforce role-based access. No staff member can bypass the UI and query data above their permission level.
- **Database layer — tenant isolation** — Every RLS policy also enforces `tenant_id` scoping. A staff member from one tenant can never access another tenant's data — even with a valid JWT.

Both the `role` and `tenant_id` JWT claims are the source of truth for the database layer.

**Implemented via:** Supabase RLS · JWT custom claims · Next.js proxy

---

### 2.3. NFR-S-03 — Input validation 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | 100% of form submissions validated before reaching Supabase |
| **Measurement** | Zod schema unit tests covering all edge cases |

Every form submission is validated client-side with Zod schemas before being sent. Server Actions re-validate on the server before any DB write. This prevents malformed data, injection attempts, and invalid state transitions (e.g. setting an order to `Completed` when payment is `Pending`).

**Implemented via:** Zod · React Hook Form · Server Action re-validation

---

### 2.4. NFR-S-04 — Secrets management 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | Zero server-only secrets exposed to the client bundle |
| **Measurement** | Bundle audit · Code review checklist |

`SUPABASE_SERVICE_ROLE_KEY` is server-only and never referenced in client components. `NEXT_PUBLIC_*` variables contain only the anon key, which is safe when RLS policies are active. No API routes proxy credentials — Server Components and Server Actions call Supabase directly.

**Implemented via:** Vercel environment variables · Next.js `server-only` module restriction

---

### 2.5. NFR-S-05 — Login security controls 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | Configurable rate limits and IP filtering |
| **Measurement** | Settings module integration test |

Maximum login attempts, IP whitelist, and IP blacklist are configurable in the Settings module by admins. These settings are stored in Supabase and enforced on each authentication attempt via an Edge Function hook.

**Implemented via:** Settings module · Supabase Edge Functions · IP filtering logic

## 3. Reliability

> Staff depend on this portal to process orders in real time. Downtime or silent failures directly block business operations.

### 3.1. NFR-R-01 — Service uptime 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | 99.9% monthly availability |
| **Measurement** | Vercel + Supabase uptime dashboards |

Uptime is inherited from Vercel and Supabase cloud SLAs. No additional infrastructure requires management. Vercel deployments are atomic — the previous version serves traffic until the new version is fully promoted, ensuring zero-downtime releases.

**Implemented via:** Vercel hosting · Supabase cloud · Atomic deployments

---

### 3.2. NFR-R-02 — Graceful error handling in the UI 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | No blank screens or unhandled rejections in production |
| **Measurement** | Error boundary coverage review · Vercel error dashboard |

Every async operation — data fetch, mutation, file upload — must have three states: loading, success, and error. TanStack Query provides these states for all server data. Next.js `error.tsx` boundaries catch unexpected failures at the route level. All user-visible errors surface as toast notifications via Sonner.

**Implemented via:** TanStack Query error states · Next.js `error.tsx` · Sonner toasts

---

### 3.3. NFR-R-03 — Data backup 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | Daily automated backups with point-in-time recovery |
| **Measurement** | Supabase backup dashboard |

Database backups run daily via Supabase's automated backup feature. Product images, staff avatars, and category images stored in Supabase Storage are covered under the same backup policy. No custom backup scripts are required.

**Implemented via:** Supabase automated backups · Supabase Storage backup policy

---

### 3.4. NFR-R-04 — Optimistic UI rollback 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | Automatic cache revert on any mutation error |
| **Measurement** | Unit tests for TanStack Query mutation `onError` handlers |

When an optimistic update fails — due to a network error, RLS rejection, or validation error — TanStack Query automatically reverts the query cache to its pre-mutation state. The user sees an error toast explaining what happened; the UI returns to its last confirmed state.

**Implemented via:** TanStack Query `onError` + `onMutate` · Cache rollback pattern

## 4. Scalability

> The system must handle the operational growth of a pizza business — increasing orders, customers, and staff — without requiring architectural changes.

### 4.1. NFR-SC-01 — Concurrent user sessions 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | ≥ 50 simultaneous staff sessions without degradation |
| **Measurement** | Load test against staging environment |

The portal is designed for ≥ 50 concurrent sessions per tenant. As a multi-tenant platform, total concurrent sessions across all tenants will be higher — Supabase's PgBouncer connection pooling handles the database connection load at platform scale. Vercel's serverless function model scales horizontally per request.

**Implemented via:** Supabase PgBouncer connection pooling · Vercel serverless

---

### 4.2. NFR-SC-02 — Real-time subscription management 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | One Realtime channel per active session, cleaned up on sign-out |
| **Measurement** | Supabase Realtime dashboard · Connection leak test |

Each logged-in staff member opens exactly one Supabase Realtime channel with two listeners — one for personal notifications and one for tenant-scoped broadcast notifications. Channels are explicitly unsubscribed and cleaned up on sign-out to prevent connection leaks. No module subscribes independently — notifications are centralised. RLS enforces tenant isolation on broadcast notifications automatically

**Implemented via:** Supabase Realtime · Zustand notification store · Sign-out cleanup hook

---

### 4.3. NFR-SC-03 — Database query performance at scale 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | All FK and filter columns indexed; no full-table scans on high-frequency queries |
| **Measurement** | PostgreSQL `EXPLAIN ANALYZE` on key queries during development |

All foreign key columns and commonly filtered fields — order status, customer email, product category, created timestamps — have database indexes. Query plans are reviewed during development using `EXPLAIN ANALYZE` to confirm index usage before deployment.

**Implemented via:** PostgreSQL indexes · Supabase schema design · Query plan review process

## 5. Maintainability

> The codebase must remain clean and navigable as modules are added and the team grows.

### 5.1. NFR-M-01 — End-to-end type safety 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | TypeScript strict mode throughout; DB types auto-generated |
| **Measurement** | `tsc --noEmit` passes in CI with zero errors |

TypeScript types are generated directly from the Supabase schema using `supabase gen types typescript`. Any mismatch between what the database returns and what the frontend expects is caught at compile time. This is the primary defence against runtime data errors.

**Implemented via:** TypeScript 5 strict mode · `supabase gen types` · Zod runtime validation

---

### 5.2. NFR-M-02 — Code quality gates 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | Zero lint errors on every commit; format enforced automatically |
| **Measurement** | Husky pre-commit hook · CI lint check |

ESLint and Prettier run on staged files via Husky + lint-staged before every commit. The CI pipeline blocks merges on any lint failure. Prettier with `prettier-plugin-tailwindcss` enforces Tailwind class order automatically — no manual style decisions.

**Implemented via:** ESLint 9 · Prettier 3 · Husky + lint-staged

---

### 5.3. NFR-M-03 — Test coverage on core logic 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | ≥ 80% unit test coverage on business logic; 6 critical E2E flows |
| **Measurement** | Vitest coverage report · Playwright CI run |

Unit tests cover: Zod validation schemas, price calculations, coupon discount logic, order number generation, date formatting utilities, and Zustand store actions. End-to-end tests cover the 6 critical flows defined in the tech stack document.

**Implemented via:** Vitest · Playwright · `@testing-library/react`

---

### 5.4. NFR-M-04 — Feature module isolation 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | Each module self-contained; no direct cross-module imports |
| **Measurement** | Import graph review during code review |

Each feature module (orders, customers, catalog, sales, etc.) lives under `/modules/{name}` with its own components, hooks, types, and query functions. Cross-module dependencies are routed through `/lib` only. This prevents tight coupling and makes it possible to work on one module without understanding the others.

**Implemented via:** Next.js App Router · Feature folder convention (`/modules`)

## 6. Accessibility

> The portal must be usable by staff with varied abilities and assistive technologies. This is a legal and ethical requirement.

### 6.1. NFR-A-01 — Keyboard navigation 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | WCAG 2.1 AA — all interactive elements keyboard-operable |
| **Measurement** | Manual keyboard audit per module · Axe automated scan |

Every button, form control, table row action, dropdown, and modal must be fully operable via keyboard alone. Tab order must be logical and predictable. Focus must be trapped within open modals and restored to the trigger element on close.

**Implemented via:** Radix UI primitives · Custom component system · Focus management patterns

---

### 6.2. NFR-A-02 — Colour contrast 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | ≥ 4.5:1 contrast ratio for normal text in all themes |
| **Measurement** | Axe browser extension · Figma contrast plugin |

All text and background colour combinations meet WCAG AA minimum contrast in both light and dark mode. Status badge colours — order states, payment states, product states — are tested independently as they use custom colour pairings.

**Implemented via:** CDS design tokens · Tailwind CSS 4 colour system

---

### 6.3. NFR-A-03 — Screen reader support 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | ARIA roles and live regions on all custom components |
| **Measurement** | NVDA / VoiceOver spot-check per release |

ARIA roles, labels, and descriptions are provided for custom components not covered by native HTML semantics. Status updates — order saved, error occurred, notification received — use `aria-live` regions so screen reader users are informed without requiring focus changes.

**Implemented via:** Radix UI · ARIA attributes · `aria-live` regions

## 7. Internationalisation

> The portal must be operable in English, Czech, and German from day one. No hardcoded user-facing strings are permitted.

### 7.1. NFR-I-01 — Multi-language UI 🔴

| Attribute | Value |
|-----------|-------|
| **Supported locales** | English (`en`), Czech (`cs`), German (`de`) |
| **Measurement** | i18n key audit — zero hardcoded UI strings |

All user-facing strings are externalised into locale files under `/i18n/{locale}.json`. Language is selectable per user session via the top navigation bar. A system-wide default language is configurable in the Settings module by admins.

**Implemented via:** next-intl · `/i18n` locale files · Settings module default language

---

### 7.2. NFR-I-02 — Locale-aware date and number formatting 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | Dates, currencies, and numbers formatted per active locale |
| **Measurement** | Manual review in Czech and German locales |

Czech and German use different decimal separators, date formats, and currency positions compared to English. All formatting uses `date-fns` with the active locale and the native `Intl` API — no manual format strings.

**Implemented via:** date-fns v3 locale support · `Intl` API · next-intl number formatting

## 8. Observability

> When something goes wrong, the team must be able to find out what happened, when, and who caused it.

### 8.1. NFR-O-01 — Audit logging 🔴

| Attribute | Value |
|-----------|-------|
| **Target** | 100% of write operations logged with user, action, entity, and timestamp |
| **Measurement** | Audit log coverage review — every Server Action that writes to the DB must produce a log entry |

Every create, update, delete, and status-change action performed by any staff member is recorded in the `audit_logs` table. This is enforced at the architecture level: all mutations go through Server Actions, which are responsible for writing the audit entry before or after the main DB operation.

**Logged fields:** `tenant_id` · `tenant_name` · `staff_id` · `staff_name` · `staff_role` · `action` · `entity_type` · `entity_id` · `old_values` (JSON) · `new_values` (JSON) · `created_at`

**Implemented via:** `audit_logs` table · Supabase DB triggers (secondary) · Server Actions (primary)

---

### 8.2. NFR-O-02 — Error logging and monitoring 🟡

| Attribute | Value |
|-----------|-------|
| **Target** | All unhandled server errors captured and surfaced in a dashboard |
| **Measurement** | Vercel error dashboard · Zero silent failures in production |

Unhandled errors in Server Components, Server Actions, and Supabase Edge Functions are automatically captured in Vercel's runtime error dashboard. Client-side errors are caught by Next.js `error.tsx` boundaries and can be forwarded to an external error tracker in a future iteration.

**Implemented via:** Vercel error dashboard · Next.js `error.tsx` · Supabase Edge Function logs

## 9. Summary Table

| ID | Requirement | Category | Priority |
|----|-------------|----------|----------|
| NFR-P-01 | Initial page load < 2s LCP | Performance | 🔴 Must |
| NFR-P-02 | API/mutation p95 < 300ms | Performance | 🔴 Must |
| NFR-P-03 | 60 fps on 10k+ row tables | Performance | 🔴 Must |
| NFR-P-04 | Bundle < 200 kB gzip per route | Performance | 🟡 Should |
| NFR-S-01 | JWT auth + optional MFA | Security | 🔴 Must |
| NFR-S-02 | Two-layer RBAC (UI + RLS) | Security | 🔴 Must |
| NFR-S-03 | 100% form input validation | Security | 🔴 Must |
| NFR-S-04 | Zero server secrets leaked to client | Security | 🔴 Must |
| NFR-S-05 | Configurable login rate limiting + IP filter | Security | 🟡 Should |
| NFR-R-01 | 99.9% monthly uptime | Reliability | 🔴 Must |
| NFR-R-02 | Graceful error handling — no blank screens | Reliability | 🔴 Must |
| NFR-R-03 | Daily automated data backups | Reliability | 🔴 Must |
| NFR-R-04 | Optimistic UI auto-rollback on failure | Reliability | 🟡 Should |
| NFR-SC-01 | ≥ 50 concurrent sessions | Scalability | 🔴 Must |
| NFR-SC-02 | One Realtime channel per session | Scalability | 🔴 Must |
| NFR-SC-03 | Indexed FK + filter columns | Scalability | 🔴 Must |
| NFR-M-01 | TypeScript strict + auto-generated DB types | Maintainability | 🔴 Must |
| NFR-M-02 | Pre-commit lint + format gates | Maintainability | 🔴 Must |
| NFR-M-03 | ≥ 80% unit coverage + 6 E2E flows | Maintainability | 🟡 Should |
| NFR-M-04 | Feature module isolation | Maintainability | 🟡 Should |
| NFR-A-01 | WCAG 2.1 AA keyboard navigation | Accessibility | 🔴 Must |
| NFR-A-02 | ≥ 4.5:1 colour contrast in all themes | Accessibility | 🔴 Must |
| NFR-A-03 | ARIA roles + screen reader support | Accessibility | 🟡 Should |
| NFR-I-01 | English / Czech / German UI | i18n | 🔴 Must |
| NFR-I-02 | Locale-aware date and number formatting | i18n | 🔴 Must |
| NFR-O-01 | 100% write operation audit logging | Observability | 🔴 Must |
| NFR-O-02 | Centralised server error monitoring | Observability | 🟡 Should |

## 10. Changelog

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-03-19 | — | Initial global NFRs finalized |
| 1.1 | 2026-03-23 | — | Upgraded Next.js 15 → 16 references throughout. NFR-P-01: updated App Router version. NFR-S-01: replaced "middleware" with "proxy (`proxy.ts`)". NFR-S-02: replaced "middleware and route guards" with "proxy and route guards". NFR-A-01/A-02: replaced "shadcn/ui" references with "Custom component system / CDS design tokens". |
| 1.2 | 2026-03-23 | — | Project renamed to Multi-Tenant Food Ordering Platform |
| 1.2 | 2026-03-23 | — | NFR-S-01: JWT now stamps both `role` and `tenant_id` claims |
| 1.2 | 2026-03-23 | — | NFR-S-02: Access control expanded to three layers — frontend, role RLS, tenant isolation RLS |
| 1.2 | 2026-03-23 | — | NFR-SC-01: Concurrent session target clarified as per-tenant |
| 1.2 | 2026-03-23 | — | NFR-SC-02: Realtime subscription updated — two listeners (personal + broadcast), RLS enforces tenant isolation |
| 1.2 | 2026-03-23 | — | NFR-O-01: Logged fields updated — `tenant_id`, `tenant_name`, `staff_name`, `staff_role` added |

---

*Feature-level NFRs are defined separately during per-module architecture sessions.*
