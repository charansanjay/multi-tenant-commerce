# Testing Strategy

**Project:** Multi-Tenant Commerce - Admin portal  
**Version:** 1.0  
**Date:** 2026-03-23  
**Status:** Finalized  

## Table of Contents

1. [Why a Testing Strategy before Scaffold?](#1-why-a-testing-strategy-before-scaffold)
2. [Storybook — Considered and Deferred](#2-storybook--considered-and-deferred)
3. [The Three Test Types](#3-the-three-test-types)
4. [Unit Tests — Vitest](#4-unit-tests--vitest)
5. [Integration Tests — Vitest + Testing Library](#5-integration-tests--vitest--testing-library)
6. [End-to-End Tests — Playwright](#6-end-to-end-tests--playwright)
7. [File Co-location Convention](#7-file-co-location-convention)
8. [What Not to Test](#8-what-not-to-test)
9. [CI Pipeline](#9-ci-pipeline)
10. [Coverage Targets](#10-coverage-targets)
11. [Changelog](#11-changelog)

## 1. Why a Testing Strategy before Scaffold?

The testing strategy is defined before project scaffold deliberately. The
decisions made here affect the folder structure, config files, and CI pipeline
that scaffold sets up. Deciding after scaffold means restructuring things that
are already in place.

Specifically, the co-location convention (test files living next to source
files) and the `e2e/` top-level folder both need to be accounted for in the
scaffold from day one. Every developer who opens the project should immediately
understand where tests live and what kind of test belongs where.

## 2. Storybook — Considered and Deferred

### What Storybook is

Storybook is an isolated component development environment. It runs a separate
browser application where every component in the design system can be viewed in
all its states — loading, error, empty, filled, disabled — without running the
full application or navigating to a specific screen.

### Why companies use it

Storybook is primarily valuable in two scenarios: when a team has designers or
QA people who review components independently of the codebase, and when a
component library is shared across multiple projects and needs living
documentation that non-developers can browse.

### Why it is deferred for this project

This project is built by a solo developer with a fully defined component design
system already documented in CDS-01 through CDS-10. Every component's props
API, variants, states, and accessibility contract are specified in those
documents. Storybook would duplicate that documentation in a different format
and require a story file to be written and maintained alongside every component.

During active component development, maintaining stories adds overhead without
enough payback. The components are still evolving. The design system documents
are the reference, not a Storybook instance.

**The decision: Storybook is not used at project start.**

### When to reconsider

Storybook becomes worth adding under these specific conditions:

- Another developer joins the project and needs a visual reference for
  components without reading CDS documents
- The component library is extracted to a shared package used across multiple
  projects
- A designer or client needs to review and sign off on components visually
  outside of the running application

Storybook can be added to any existing codebase in an afternoon. The decision
to defer it is fully reversible.

## 3. The Three Test Types

This project uses three test types. Each has a distinct job, distinct tooling,
and distinct scope. They do not overlap.

| Type | Tool | What it tests | Speed |
|---|---|---|---|
| Unit | Vitest | Individual functions and store actions in isolation | Milliseconds per test |
| Integration | Vitest + Testing Library | Components and hooks with DOM, state, and user events | Seconds per test |
| End-to-End | Playwright | Complete user flows in a real browser against real Supabase | Minutes per suite |

The pyramid principle applies: many unit tests, a reasonable number of
integration tests, a small set of critical E2E flows. Unit tests are cheap and
fast. E2E tests are expensive and slow. Do not use E2E tests where integration
tests will do.

## 4. Unit Tests — Vitest

```sh
vitest: ^1.0.0
```

Unit tests cover pure logic — functions and store actions that take inputs and
produce outputs with no DOM, no network, and no Supabase involved. These are
the fastest tests in the suite and should run in milliseconds.

### What is unit-tested

| File | What is tested |
|---|---|
| `src/lib/price-utils.ts` | `actual_price` calculation, `grand_total`, VAT, coupon discount logic |
| `src/lib/order-number.ts` | Order number generation format and uniqueness constraints |
| `src/lib/date-utils.ts` | Date formatting, relative time, locale-aware output |
| `src/lib/validation/` | All Zod schemas — required fields, enums, min/max, invalid coupon dates, negative prices |
| `src/stores/*.ts` | All Zustand store actions — state transitions, computed values |

### Rule of thumb

Every utility function and every Zod schema gets a unit test. These are the
core business logic of the system. If a price calculation is wrong or a Zod
schema misses an edge case, it affects real orders and real money.

### Example

```typescript
// src/lib/price-utils.test.ts
import { describe, it, expect } from 'vitest'
import { calculateActualPrice, calculateGrandTotal } from './price-utils'

describe('calculateActualPrice', () => {
  it('returns base price when discount is 0', () => {
    expect(calculateActualPrice(220, 0)).toBe(220)
  })

  it('applies percentage discount correctly', () => {
    expect(calculateActualPrice(220, 10)).toBe(198)
  })

  it('rounds to 2 decimal places', () => {
    expect(calculateActualPrice(100, 3)).toBe(97)
  })
})
```

## 5. Integration Tests — Vitest + Testing Library

```sh
@testing-library/react: ^14.0.0
@testing-library/user-event: ^14.0.0
jsdom: ^24.0.0
```

Integration tests cover components and hooks together with a simulated DOM.
They verify that a component renders correctly, responds to user interactions,
shows the right states, and calls the right functions — without needing a real
browser or a real Supabase instance.

### What is integration-tested

**Components with conditional rendering:**
Any component that renders differently based on props, state, or data — status
badges, empty states, error states, loading skeletons.

**Components with user interaction:**
Any component where the user can click, type, select, or submit — forms, table
actions, modals triggered by buttons, filter inputs.

**Components with form validation:**
Form fields that show error messages, required field indicators, or disable
submission until valid.

**Custom hooks:**
Hooks that encapsulate query logic, form state, or derived state.

| Component / Hook | What is tested |
|---|---|
| `OrderStatusBadge` | Renders correct colour and label for each status value |
| `LoginForm` | Shows validation error when email is empty; disables submit while loading |
| `CouponInput` | Shows error message on invalid code; clears on valid entry |
| `DataTable` | Renders column headers and row data; pagination controls work |
| `ConfirmDialog` | Opens on trigger; calls onConfirm; calls onCancel; closes on Escape |
| `useOrders` hook | Returns correct loading/error/data states |
| `ProductStatusBadge` | Renders correct variant for active, inactive, out_of_stock |

### What does NOT need an integration test

Pure display components with no logic — a component that only renders its props
with no conditional rendering, no interaction, and no state — do not need a
test. Examples: `Divider`, `Skeleton`, `Avatar` with no fallback logic.

### Example

```typescript
// src/modules/orders/components/OrderStatusBadge/OrderStatusBadge.test.tsx
import { render, screen } from '@testing-library/react'
import { OrderStatusBadge } from '.'

describe('OrderStatusBadge', () => {
  it('renders Pending label for pending status', () => {
    render(<OrderStatusBadge status="pending" />)
    expect(screen.getByText('Pending')).toBeInTheDocument()
  })

  it('renders Completed label for completed status', () => {
    render(<OrderStatusBadge status="completed" />)
    expect(screen.getByText('Completed')).toBeInTheDocument()
  })
})
```

## 6. End-to-End Tests — Playwright

```sh
@playwright/test: ^1.40.0
```

E2E tests run complete user flows in a real browser against a local Supabase
instance seeded with test data. They are the only tests that can catch failures
that only emerge when the entire system runs together — auth, RLS, Server
Actions, Realtime, and the UI all at once.

E2E tests are expensive: they are slower to write, slower to run, and more
brittle than unit or integration tests. Use them only for flows where a silent
failure would cause real business damage.

### The 6 critical flows

| Flow | Why it is critical |
|---|---|
| Staff login with role enforcement | RBAC is the security foundation — a role bypass would expose all data |
| Create an order with line items, coupon, and address | The most complex form in the system; most likely to have integration failures |
| Update order status through the full workflow | The core daily operational task for all staff |
| Create a product with variants and images | Multi-step form with Supabase Storage — file upload failures are silent |
| Export orders table to CSV and Excel | GDPR-required audit log entry must be generated on every export |
| Receive a real-time notification | Validates the full Supabase Realtime chain end-to-end |

### Local Supabase setup for E2E

E2E tests run against a local Supabase instance, not the production database.
The instance is seeded before each test run with predictable data: known staff
accounts per role, sample customers, sample products with variants, and sample
orders in various states.

```bash
# Start local Supabase
supabase start

# Apply migrations
supabase db reset

# Run E2E suite
npx playwright test
```

### Example

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('staff role cannot access Settings', async ({ page }) => {
  await page.goto('/login')
  await page.fill('[name="email"]', 'staff@example.com')
  await page.fill('[name="password"]', 'testpassword')
  await page.click('[type="submit"]')

  await page.goto('/settings')
  await expect(page).toHaveURL('/dashboard')
  await expect(page.getByText('Access denied')).toBeVisible()
})
```

## 7. File Co-location Convention

### The rule

Unit and integration test files live **directly next to the file they test**.
This is enforced from day one — not something to tidy up later.

For utility functions and hooks this means a flat `.test.ts` file alongside the
source file. For components, the rule is slightly different.

### Simple primitives — flat

Primitives that are too simple to warrant a test (no logic, no interaction, no
conditional rendering) stay flat with no folder. If they later grow complex
enough to need a test, they get promoted to a folder at that point.

```
src/components/ui/
  Divider.tsx
  Spinner.tsx
  Skeleton.tsx
```

### Components with tests — per-component folder

Any component that has a test file gets its own folder. This keeps the
`components/` directory readable regardless of how many components exist, and
creates a natural home for types and — if Storybook is added later — stories,
without any restructuring.

```
src/components/ui/
  Button/
    index.tsx              ← component implementation
    Button.test.tsx        ← integration test
    Button.types.ts        ← props interface (if extracted)
    Button.stories.tsx     ← Storybook story (if added later)
  DataTable/
    index.tsx
    DataTable.test.tsx
    DataTable.types.ts
  ConfirmDialog/
    index.tsx
    ConfirmDialog.test.tsx
    ConfirmDialog.types.ts
```

The same pattern applies to module-level components:

```
src/modules/orders/components/
  OrderStatusBadge/
    index.tsx
    OrderStatusBadge.test.tsx
    OrderStatusBadge.types.ts
  OrderDetailSheet/
    index.tsx
    OrderDetailSheet.test.tsx
    OrderDetailSheet.types.ts
```

Imports stay clean because of `index.tsx`:

```typescript
import { OrderStatusBadge } from '@/modules/orders/components/OrderStatusBadge'
import { Button } from '@/components/ui/Button'
```

### Utility files and hooks — flat co-location

Utility files and hooks do not need folders. They stay flat with the test file
directly alongside:

```
src/
  lib/
    price-utils.ts
    price-utils.test.ts
    order-number.ts
    order-number.test.ts
    date-utils.ts
    date-utils.test.ts

  stores/
    order-store.ts
    order-store.test.ts
    ui-store.ts
    ui-store.test.ts

  modules/
    orders/
      hooks/
        useOrders.ts
        useOrders.test.ts
```

### E2E tests — top-level folder

E2E tests live in a top-level `e2e/` folder, not inside `src/`. They test
flows, not files, and have no natural source file to live next to.

```
e2e/
  auth.spec.ts
  orders.spec.ts
  products.spec.ts
  exports.spec.ts
  notifications.spec.ts
```

### Summary of the convention

| File type | Convention | Reason |
|---|---|---|
| Utility functions | Flat — `price-utils.ts` + `price-utils.test.ts` | Single file, no siblings needed |
| Hooks | Flat — `useOrders.ts` + `useOrders.test.ts` | Single file, no siblings needed |
| Simple primitives (no test) | Flat — `Spinner.tsx` | Too simple to need a folder |
| Components with tests | Per-component folder with `index.tsx` | Scales cleanly; ready for types and future stories |
| E2E tests | Top-level `e2e/` folder | Tests flows, not files |

### Vitest config to match this convention

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['src/**/*.test.{ts,tsx}'],
    exclude: ['e2e/**'],
    coverage: {
      include: ['src/lib/**', 'src/stores/**'],
      reporter: ['text', 'lcov'],
    },
  },
})
```

## 8. What Not to Test

These are deliberate exclusions. Testing them adds maintenance overhead without
meaningful confidence gain.

| What | Why not |
|---|---|
| Generated Supabase types (`src/types/supabase.ts`) | Auto-generated from the database schema — testing them tests the generator, not the application |
| Third-party library behaviour | Vitest, TanStack Query, Zustand, date-fns are already tested by their own maintainers |
| Pure display components with no logic | A `Skeleton` that renders a grey block has nothing to assert |
| Next.js routing and middleware | Covered by the auth E2E flow; re-testing at the unit level duplicates coverage without adding value |
| Supabase RLS policies directly | Validated implicitly by the E2E auth flow; if RLS is misconfigured, the login role enforcement test fails |
| CSS and visual appearance | Snapshot tests on className strings are brittle and test implementation, not behaviour |

## 9. CI Pipeline

Tests run automatically at different points depending on their cost.

| When | Tests run | Why |
|---|---|---|
| Every commit (pre-commit hook) | TypeScript `tsc --noEmit` + ESLint | Fastest feedback; catches type errors and lint failures before they are pushed |
| Every push / PR open | Unit + Integration (Vitest) | Fast enough to run on every push; catches logic and component regressions |
| PR merge to `develop` | Full E2E suite (Playwright) | E2E is too slow for every commit; runs before code reaches staging |
| PR merge to `main` | Full E2E suite + coverage report | Final gate before production |

```yaml
# .github/workflows/ci.yml (outline)
jobs:
  unit-integration:
    runs-on: ubuntu-latest
    steps:
      - run: npm ci
      - run: tsc --noEmit
      - run: npx vitest run --coverage

  e2e:
    runs-on: ubuntu-latest
    needs: unit-integration
    steps:
      - run: supabase start
      - run: supabase db reset
      - run: npx playwright test
```

## 10. Coverage Targets

Coverage is measured on business logic only — `src/lib/` and `src/stores/`. UI
component coverage is not measured by line count because meaningful component
coverage is determined by behaviour (does the right thing render?) not by how
many lines were executed.

| Scope | Target | Measurement |
|---|---|---|
| `src/lib/` — utility functions | ≥ 80% line coverage | Vitest coverage report |
| `src/stores/` — Zustand actions | ≥ 80% line coverage | Vitest coverage report |
| E2E critical flows | 6 of 6 passing | Playwright CI run |

These targets are defined in NFR-M-03. Coverage below 80% on business logic is
a signal that edge cases are untested — not that the number needs to be hit for
its own sake.

## 11. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-23 | Initial testing strategy finalized |
