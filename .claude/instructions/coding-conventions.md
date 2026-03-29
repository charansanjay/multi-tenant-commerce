# Coding Conventions

Read this before writing any code in this project.

## TypeScript

- Strict mode is on — no `any`, no `as unknown as X`, no `@ts-ignore`
- Always type function return values explicitly on Server Actions and query functions
- Use `type` for object shapes, `interface` for component props
- Generated Supabase types live in `src/types/database.types.ts` — import from there,
  never redefine what already exists
- Prefer `const` everywhere. `let` only when reassignment is genuinely needed.

## File naming

| Thing | Convention | Example |
|---|---|---|
| Components | PascalCase | `LoginForm.tsx` |
| Hooks | camelCase with `use` prefix | `useCurrentUser.ts` |
| Stores | camelCase with `.store` suffix | `ui.store.ts` |
| Server Actions | camelCase | `signOut.ts`, `setLocale.ts` |
| Query functions | camelCase with `fetch` prefix | `fetchOrders.ts` |
| Types files | camelCase | `types.ts` |

## Import order (enforced by ESLint)

```ts
// 1. React
import { useState, useEffect } from 'react'

// 2. Next.js
import { redirect } from 'next/navigation'
import { cookies } from 'next/headers'

// 3. External packages
import { useQuery } from '@tanstack/react-query'
import { z } from 'zod'

// 4. Internal — absolute (path aliases)
import { Button } from '@/components/ui/Button'
import { createServerClient } from '@/lib/supabase/server'

// 5. Internal — types
import type { Database } from '@/types/database.types'

// 6. Relative
import { LoginForm } from './LoginForm'
```

## Server vs Client Components

Default is Server Component. Add `"use client"` only for:

- Components using React hooks (`useState`, `useEffect`, `useRef`, etc.)
- Components using browser APIs
- Components using Zustand stores
- Components using TanStack Query hooks
- Components with event handlers passed as props to interactive elements

Never put `"use client"` on a layout or a page that only passes data down.
Use the Server shell → Client island pattern instead.

```tsx
// ✅ Correct pattern
// page.tsx (Server) fetches → passes initialData to Client Component
// ClientComponent.tsx uses useQuery({ initialData }) — no waterfall
```

## Server Actions

- Always in `modules/{name}/actions/` folder
- Always start with `'use server'`
- Always validate input with Zod before touching Supabase
- Always use the **server client** (`createServerClient`) — never the browser client
- Never return raw Supabase errors to the client — return typed result objects

```ts
// Standard Server Action shape
export async function createCategory(input: unknown): Promise<ActionResult> {
  const parsed = CategorySchema.safeParse(input)
  if (!parsed.success) return { success: false, error: 'Invalid input' }

  const supabase = createServerClient()
  const { error } = await supabase.from('categories').insert(parsed.data)
  if (error) return { success: false, error: 'Failed to create category' }

  revalidatePath('/catalog/categories')
  return { success: true }
}
```

## Supabase queries

- **Never** add a `tenant_id` filter to any query — RLS enforces it automatically
- Use the server client in Server Components and Server Actions
- Use the browser client in Client Components and TanStack Query functions
- Never use the admin client except where explicitly documented

## Component props

- Every component must have an explicit TypeScript interface for its props
- No inline prop types (`function Foo({ bar }: { bar: string })`)
- Required props first, optional props after, each on its own line

```tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:  ButtonVariant
  size?:     ButtonSize
  loading?:  boolean
  leftIcon?: React.ReactNode
}
```

## Styling

- Tailwind utility classes only — no inline `style={{}}` except for dynamic
  values that cannot be expressed as Tailwind classes
- All colours, sizes, and radii reference CSS custom property tokens — never
  hardcode hex values in components
- Use the `cn()` utility from `@/lib/utils` for conditional class merging
- Never use `!important` in component code

## i18n

- Zero hardcoded user-facing strings in components
- All copy lives in `src/i18n/en.json` (and cs.json, de.json with matching keys)
- Keys are namespaced by module: `auth.signIn`, `nav.dashboard`, `orders.title`
- Use `useTranslations('namespace')` in Client Components
- Use `getTranslations('namespace')` in Server Components

## Error and loading states

Every data-fetching component must handle all three states:

- **Loading** — Skeleton or Spinner appropriate to the component
- **Error** — ErrorBoundary or inline error message
- **Empty** — EmptyState component with contextual message

Never leave a component that fetches data without all three states handled.

## What never goes in `app/`

The `app/` directory contains only:

- `page.tsx` files (thin, mostly just imports and passes data down)
- `layout.tsx` files
- `loading.tsx` files
- `error.tsx` files
- `not-found.tsx`

No business logic. No Supabase calls beyond initial data fetch for `initialData`.
No utility functions. No component definitions.
