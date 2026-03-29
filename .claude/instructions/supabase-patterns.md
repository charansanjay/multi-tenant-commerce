# Supabase Patterns

Read this before writing any Supabase query, mutation, or Server Action.

## The three clients — use the right one

| Client | File | Use in | Key used |
|---|---|---|---|
| Server | `lib/supabase/server.ts` | Server Components, Server Actions | Anon + session cookie |
| Browser | `lib/supabase/client.ts` | Client Components, TanStack Query fns | Anon only |
| Proxy | `lib/supabase/proxy.ts` | `proxy.ts` only | Anon + cookie management |

**Default is the server client.** Use the browser client only when you are
inside a `"use client"` component that cannot call a Server Action.
Never use the admin client unless the feature architecture explicitly says so.

## The golden rule — never filter by tenant_id

```ts
// ✅ Correct — RLS handles tenant scoping automatically
const { data } = await supabase.from('orders').select('*')

// ❌ Wrong — redundant and can cause bugs if JWT and filter disagree
const { data } = await supabase.from('orders').select('*').eq('tenant_id', tenantId)
```

RLS policies on every table read `(auth.jwt() ->> 'tenant_id')::uuid` from the
JWT. The server client attaches the session automatically via cookies. The result
is that every query is already scoped — you literally cannot see another tenant's
data even if you try.

## Reading JWT claims

In Server Components and Server Actions:

```ts
const supabase = createServerClient()
const { data: { user } } = await supabase.auth.getUser()

const role     = user?.app_metadata?.role      as 'admin' | 'manager' | 'staff'
const tenantId = user?.app_metadata?.tenant_id as string
const staffName = user?.app_metadata?.staff_name as string
```

In Client Components — use the `useCurrentUser` hook:

```ts
import { useCurrentUser } from '@/hooks/useCurrentUser'
const user = useCurrentUser()  // { role, tenant_id, staff_name }
```

Never read JWT claims from `localStorage` or pass them as props through the
component tree. Always read from the session directly.

## Auth Hook — what is stamped into the JWT

The PostgreSQL Auth Hook stamps these claims into every JWT at login and refresh:

```json
{
  "role":        "admin",
  "tenant_id":   "uuid",
  "tenant_name": "Pizza Palace Praha",
  "staff_name":  "Jan Novák"
}
```

These are available via `user.app_metadata.*`. If any of these are missing,
the account is not properly provisioned — the proxy redirects to `/login?error=account_error`.

## Supabase client initialisation

```ts
// lib/supabase/server.ts — use this in Server Components + Server Actions
import { createServerClient as createSupabaseServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database.types'

export function createServerClient() {
  const cookieStore = cookies()
  return createSupabaseServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { cookies: { get: (name) => cookieStore.get(name)?.value } }
  )
}
```

## Error handling in Server Actions

Never expose raw Supabase error messages to the client.

```ts
// ✅ Correct
const { error } = await supabase.from('categories').insert(data)
if (error) {
  console.error('[createCategory]', error)
  return { success: false, error: 'Failed to create category. Please try again.' }
}
return { success: true }

// ❌ Wrong — leaks internal DB error details
if (error) return { success: false, error: error.message }
```

## Realtime (Module 12 — Notifications only)

Use the browser client for Realtime subscriptions.
Subscriptions go in a dedicated `useNotifications` hook, not in components.
RLS on the `notifications` table ensures staff only receive their own
tenant's notifications. No additional filtering needed.

```ts
// Pattern — set up once in a hook, clean up on unmount
useEffect(() => {
  const channel = supabase
    .channel('notifications')
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, handler)
    .subscribe()
  return () => { supabase.removeChannel(channel) }
}, [])
```

Do not set up Realtime subscriptions outside of Module 12.
