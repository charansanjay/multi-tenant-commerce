# Component Patterns

Read this before building any UI component or module screen.

## Component locations

| Type | Location | Rule |
|---|---|---|
| Design system primitives | `src/components/ui/` | No business logic, no Supabase, no stores |
| Layout components | `src/components/layout/` | Sidebar, Topbar, PageContainer |
| Shared domain components | `src/components/shared/` | DataTable, EmptyState, PageHeader, StatusBadge |
| Module-specific components | `src/modules/{name}/components/` | Only used within that module |

Cross-module component imports are forbidden.
If two modules need the same component, it moves to `components/shared/`.

## Variant pattern — always use Record lookups

```tsx
// ✅ Correct
const variantStyles: Record<ButtonVariant, string> = {
  primary:     'bg-primary text-primary-foreground hover:bg-primary-hover',
  secondary:   'bg-secondary text-secondary-foreground',
  ghost:       'bg-transparent text-foreground hover:bg-muted',
  destructive: 'bg-destructive text-destructive-foreground',
  outline:     'border border-border bg-transparent text-foreground',
}
const classes = variantStyles[variant]

// ❌ Never use inline ternaries for variants
className={variant === 'primary' ? 'bg-primary' : variant === 'ghost' ? '...' : '...'}
```

## Server shell → Client island pattern

```tsx
// app/(admin)/orders/page.tsx — Server Component
export default async function OrdersPage() {
  const supabase = createServerClient()
  const { data: initialOrders } = await supabase
    .from('orders')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(50)

  return <OrdersTable initialData={initialOrders} />
}

// modules/orders/components/OrdersTable.tsx — Client Component
'use client'
export function OrdersTable({ initialData }: { initialData: Order[] }) {
  const { data } = useQuery({
    queryKey: ['orders'],
    queryFn: fetchOrders,
    initialData,  // ← hydrated from server, no client waterfall
  })
}
```

## TanStack Query conventions

Query keys — always structured arrays, general to specific:

```ts
['orders']                          // all orders
['orders', { status: 'pending' }]  // filtered
['orders', orderId]                 // single record
['categories']
['products']
['customers']
```

Never include `tenant_id` in query keys — RLS scopes data automatically.
TanStack Query cache is in-memory per session — no cross-tenant pollution risk.

Stale time: 30 seconds (configured globally in QueryClient).
Always pass `initialData` from Server Component when available.

## Zustand stores — client state only

Zustand owns UI state only — never server/database state:

```ts
// ✅ In Zustand
sidebarCollapsed, notifications panel open, selected table rows, open modal ID

// ❌ Never in Zustand
orders list, customer data, anything from Supabase
```

Store files live in `src/stores/`. Import with `useUIStore()` etc.

## Form pattern — every form follows this exactly

```tsx
// 1. Zod schema defines shape and validation
const Schema = z.object({
  name:   z.string().min(1, 'Name is required'),
  status: z.enum(['active', 'inactive']),
})

// 2. React Hook Form manages field state
const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
  resolver: zodResolver(Schema),
})

// 3. Server Action handles mutation — validates again server-side
const onSubmit = async (data) => {
  const result = await createCategory(data)
  if (!result.success) toast.error(result.error)
  else { toast.success('Category created'); onClose() }
}

// 4. Button shows loading state during submit
<Button type="submit" loading={isSubmitting}>Save</Button>
```

## DataTable pattern

All list screens use `DataTable` from `components/shared/DataTable.tsx`.
Never build ad-hoc tables. DataTable wraps TanStack Table v8.

```tsx
<DataTable
  columns={columns}
  data={data}
  isLoading={isLoading}
  pagination={pagination}
  onPaginationChange={setPagination}
  emptyState={<EmptyState title="No categories" description="Create your first category." action={<Button onClick={openCreate}>Create category</Button>} />}
/>
```

## Accessibility — non-negotiable

Every interactive component must:

- Be keyboard operable (Tab, Enter, Space, Escape, Arrow keys where applicable)
- Have an `aria-label` if it has no visible text (IconButton, icon-only links)
- Use semantic HTML (`<button>` not `<div onclick>`, `<nav>` for navigation)
- Have focus ring visible on keyboard focus (`focus-visible:ring-2`)

Overlays (Modal, Drawer, DropdownMenu) must:

- Trap focus while open
- Return focus to trigger on close
- Close on Escape
- Have `role="dialog"` and `aria-modal="true"` where applicable

Do not ship a component without its accessibility contract. See CDS-10.
