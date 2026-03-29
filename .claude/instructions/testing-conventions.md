# Testing Conventions

Read this before writing any tests.

## Test types and tools

| Type | Tool | What to test |
|---|---|---|
| Unit | Vitest | Utility functions in `lib/`, Zod schemas, Zustand store actions |
| Integration | Vitest + Testing Library | Component behaviour — renders correctly, interactions work |
| E2E | Playwright | Critical user flows — login, create, edit, delete, status changes |

## What must be tested in every module

Before marking Step 8 (Testing) complete, the following must exist:

**Unit tests:**

- Every Zod schema — valid inputs pass, invalid inputs produce correct errors
- Every utility function used by the module
- Zustand store actions (if the module adds any)

**Integration tests:**

- The main list component renders correctly with mock data
- The main list component renders the EmptyState when data is empty
- The create/edit form shows validation errors on invalid submit
- Role-based conditional rendering — admin sees X, staff does not

**E2E tests:**

- The primary happy path (create an entity end to end)
- The primary error path (form validation prevents bad data)
- For Module 1 specifically: login flow, redirect after login, sign out flow

## Test file location

```text
src/modules/auth/
├── components/
│   ├── LoginForm.tsx
│   └── LoginForm.test.tsx        ← integration test sits next to the component
├── actions/
│   ├── signOut.ts
│   └── signOut.test.ts           ← unit test for the action
└── __tests__/
    └── auth.e2e.ts               ← Playwright E2E (or in /e2e at root)
```

Unit and integration tests live next to the file they test.
E2E tests live in `/e2e` at the project root.

## Vitest — integration test pattern

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { LoginForm } from './LoginForm'

describe('LoginForm', () => {
  it('shows validation errors when submitted empty', async () => {
    render(<LoginForm />)
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }))
    await waitFor(() => {
      expect(screen.getByText(/valid email/i)).toBeInTheDocument()
      expect(screen.getByText(/password is required/i)).toBeInTheDocument()
    })
  })

  it('shows loading state during submission', async () => {
    // mock supabase signInWithPassword
    // fill form, submit, assert button shows spinner
  })
})
```

## Playwright — E2E pattern

```ts
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('staff can log in and reach dashboard', async ({ page }) => {
  await page.goto('/login')
  await page.fill('[type="email"]', 'jan@pizzapalace.cz')
  await page.fill('[type="password"]', 'correct-password')
  await page.click('button[type="submit"]')
  await expect(page).toHaveURL('/dashboard')
  await expect(page.getByText('Dashboard')).toBeVisible()
})

test('wrong credentials shows error message', async ({ page }) => {
  await page.goto('/login')
  await page.fill('[type="email"]', 'jan@pizzapalace.cz')
  await page.fill('[type="password"]', 'wrong-password')
  await page.click('button[type="submit"]')
  await expect(page.getByText(/invalid email or password/i)).toBeVisible()
})
```

## Mocking Supabase in tests

Use `vi.mock` to mock the Supabase client in unit and integration tests.
Never make real Supabase calls in unit or integration tests.

```ts
vi.mock('@/lib/supabase/client', () => ({
  createBrowserClient: () => ({
    from: () => ({
      select: () => ({ data: mockOrders, error: null }),
    }),
  }),
}))
```

E2E tests run against a real Supabase test project (separate from production).
Test credentials are stored in `.env.test` — never in `.env.local`.

## Before marking testing complete

```bash
pnpm type-check    # zero TypeScript errors
pnpm lint          # zero lint warnings
pnpm test          # all unit + integration tests passing
pnpm test:e2e      # all E2E tests passing
```

All four must pass. Do not mark Step 8 complete with any failures.
