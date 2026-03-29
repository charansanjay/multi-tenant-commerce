# CDS-09 — Domain-Specific Components

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Domain Components?](#1-what-are-domain-components)
2. [Why Separate from StatusBadge](#2-why-separate-from-statusbadge)
3. [OrderStatusBadge](#3-orderstatusbadge)
4. [PaymentStatusBadge](#4-paymentstatusbadge)
5. [ProductStatusBadge](#5-productstatusbadge)
6. [RoleBadge](#6-rolebadge)
7. [Adding New Domain Components](#7-adding-new-domain-components)

## 1. What are Domain Components?

Domain components are shared UI components that encode **business-specific knowledge** — they know about the pizza shop's order statuses, payment states, product states, and staff roles. They are the bridge between the generic design system and the specific domain model.

They live in `components/shared/` (not `components/ui/`) because they import domain types from the application. Components in `components/ui/` are pure UI with no business knowledge. Components in `components/shared/` are aware of the application's domain.

```text
components/
├── ui/           ← Pure UI, no business logic (portable to any project)
└── shared/       ← Domain-aware, specific to this application
    ├── OrderStatusBadge.tsx
    ├── PaymentStatusBadge.tsx
    ├── ProductStatusBadge.tsx
    └── RoleBadge.tsx
```

## 2. Why Separate from StatusBadge

`StatusBadge` (CDS-04) is a generic primitive that accepts any `bgColor`, `textColor`, and `label`. It has no knowledge of order states or payment states.

The domain badges are thin wrappers that do two things:

1. **Map** a domain status string (`'preparing'`, `'paid'`) to the correct colour tokens
2. **Humanise** the status label if needed (e.g. `'out_of_stock'` → `'Out of stock'`)

This separation means:

- The colour system is defined in one place (the token map inside the domain badge)
- Developers never manually pass colour tokens when rendering a status — they just pass `status={order.status}`
- Changing a status colour means changing one line in one file

The domain badges are used in two places throughout the portal: DataTable column cells and detail view headers. Having a consistent, named component for each means the colour and label are always identical regardless of where the status is displayed.

## 3. OrderStatusBadge

Order status is the most visible status in the portal. Staff scan order statuses hundreds of times per shift — the colour mapping must be instantly recognisable and consistent everywhere.

### Status Values

Defined in `src/lib/constants.ts` and mirrored in the `orders` table CHECK constraint:

```ts
export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'delivered'
  | 'cancelled'
```

### Props Interface

```tsx
interface OrderStatusBadgeProps {
  status:     OrderStatus
  className?: string
}
```

### Colour Map

```tsx
const orderStatusConfig: Record<OrderStatus, { label: string; bgColor: string; textColor: string }> = {
  pending: {
    label:     'Pending',
    bgColor:   'var(--status-pending-bg)',
    textColor: 'var(--status-pending-text)',
  },
  confirmed: {
    label:     'Confirmed',
    bgColor:   'var(--status-confirmed-bg)',
    textColor: 'var(--status-confirmed-text)',
  },
  preparing: {
    label:     'Preparing',
    bgColor:   'var(--status-preparing-bg)',
    textColor: 'var(--status-preparing-text)',
  },
  ready: {
    label:     'Ready',
    bgColor:   'var(--status-ready-bg)',
    textColor: 'var(--status-ready-text)',
  },
  delivered: {
    label:     'Delivered',
    bgColor:   'var(--status-delivered-bg)',
    textColor: 'var(--status-delivered-text)',
  },
  cancelled: {
    label:     'Cancelled',
    bgColor:   'var(--status-cancelled-bg)',
    textColor: 'var(--status-cancelled-text)',
  },
}
```

### Implementation

```tsx
export function OrderStatusBadge({ status, className }: OrderStatusBadgeProps) {
  const config = orderStatusConfig[status]
  return (
    <StatusBadge
      label={config.label}
      bgColor={config.bgColor}
      textColor={config.textColor}
      className={className}
    />
  )
}
```

### Colour Reference

| Status | Colour | Background token | Text token |
|---|---|---|---|
| `pending` | Amber | `--status-pending-bg` | `--status-pending-text` |
| `confirmed` | Blue | `--status-confirmed-bg` | `--status-confirmed-text` |
| `preparing` | Violet | `--status-preparing-bg` | `--status-preparing-text` |
| `ready` | Cyan | `--status-ready-bg` | `--status-ready-text` |
| `delivered` | Green | `--status-delivered-bg` | `--status-delivered-text` |
| `cancelled` | Red | `--status-cancelled-bg` | `--status-cancelled-text` |

### Usage

```tsx
// In DataTable column definition
{
  accessorKey: 'status',
  header: 'Status',
  cell: ({ row }) => <OrderStatusBadge status={row.original.status} />,
}

// In Drawer order detail
<div className="flex items-center gap-2">
  <span className="text-sm text-foreground-muted">Status</span>
  <OrderStatusBadge status={order.status} />
</div>
```

## 4. PaymentStatusBadge

Payment status appears alongside order status in the Orders module and in the dedicated payments view.

### Status Values

```ts
export type PaymentStatus =
  | 'pending'
  | 'paid'
  | 'failed'
  | 'refunded'
```

### Props Interface

```tsx
interface PaymentStatusBadgeProps {
  status:     PaymentStatus
  className?: string
}
```

### Colour Map

```tsx
const paymentStatusConfig: Record<PaymentStatus, { label: string; bgColor: string; textColor: string }> = {
  pending: {
    label:     'Pending',
    bgColor:   'var(--status-payment-pending-bg)',
    textColor: 'var(--status-payment-pending-text)',
  },
  paid: {
    label:     'Paid',
    bgColor:   'var(--status-paid-bg)',
    textColor: 'var(--status-paid-text)',
  },
  failed: {
    label:     'Failed',
    bgColor:   'var(--status-failed-bg)',
    textColor: 'var(--status-failed-text)',
  },
  refunded: {
    label:     'Refunded',
    bgColor:   'var(--status-refunded-bg)',
    textColor: 'var(--status-refunded-text)',
  },
}
```

### Colour Reference

| Status | Colour | Reasoning |
|---|---|---|
| `pending` | Amber | Needs attention — same family as order pending |
| `paid` | Green | Successful — money received |
| `failed` | Red | Problem — requires staff action |
| `refunded` | Slate | Neutral — resolved, neither positive nor negative |

### Usage

```tsx
// Alongside order status in table
<div className="flex items-center gap-2">
  <OrderStatusBadge status={order.status} />
  <PaymentStatusBadge status={order.payment?.status ?? 'pending'} />
</div>

// In order detail drawer
<div className="grid grid-cols-2 gap-3 text-sm">
  <div>
    <span className="text-foreground-muted">Order status</span>
    <OrderStatusBadge status={order.status} />
  </div>
  <div>
    <span className="text-foreground-muted">Payment</span>
    <PaymentStatusBadge status={order.payment.status} />
  </div>
</div>
```

## 5. ProductStatusBadge

Product status appears in the catalog table and product detail pages. It communicates product availability at a glance.

### Status Values

```ts
export type ProductStatus =
  | 'active'
  | 'inactive'
  | 'out_of_stock'
```

### Props Interface

```tsx
interface ProductStatusBadgeProps {
  status:     ProductStatus
  className?: string
}
```

### Colour Map

```tsx
const productStatusConfig: Record<ProductStatus, { label: string; bgColor: string; textColor: string }> = {
  active: {
    label:     'Active',
    bgColor:   'var(--status-active-bg)',
    textColor: 'var(--status-active-text)',
  },
  inactive: {
    label:     'Inactive',
    bgColor:   'var(--status-inactive-bg)',
    textColor: 'var(--status-inactive-text)',
  },
  out_of_stock: {
    label:     'Out of stock',
    bgColor:   'var(--status-out-of-stock-bg)',
    textColor: 'var(--status-out-of-stock-text)',
  },
}
```

### Colour Reference

| Status | Colour | Reasoning |
|---|---|---|
| `active` | Green | Available — positive, on sale |
| `inactive` | Slate | Disabled — neutral, not available but not a problem |
| `out_of_stock` | Orange | Warning — was active but needs restocking |

Note: `out_of_stock` uses orange rather than red because it is a temporary, recoverable state — not a permanent negative like a cancelled order.

### Usage

```tsx
// Catalog table
{
  accessorKey: 'status',
  header: 'Status',
  cell: ({ row }) => <ProductStatusBadge status={row.original.status} />,
}

// Quick status toggle context — badge + switch together
<div className="flex items-center justify-between">
  <ProductStatusBadge status={product.status} />
  <Switch
    checked={product.status === 'active'}
    onCheckedChange={(checked) =>
      updateProductStatus(product.id, checked ? 'active' : 'inactive')
    }
    label="Toggle active"
  />
</div>
```

## 6. RoleBadge

Staff role indicator. Used in the Staff management table and the user's own profile in the topbar.

### Role Values

```ts
export type UserRole = 'admin' | 'manager' | 'staff'
```

### Props Interface

```tsx
interface RoleBadgeProps {
  role:       UserRole
  className?: string
}
```

### Colour Map

Role colours use the semantic colour system rather than dedicated status tokens — roles have a more permanent, identity-like quality than transient order states.

```tsx
const roleConfig: Record<UserRole, { label: string; className: string }> = {
  admin: {
    label:     'Admin',
    className: 'bg-primary/10 text-primary',
  },
  manager: {
    label:     'Manager',
    className: 'bg-violet-100 text-violet-900 dark:bg-violet-900 dark:text-violet-100',
  },
  staff: {
    label:     'Staff',
    className: 'bg-muted text-foreground-muted',
  },
}
```

RoleBadge uses `className` rather than individual bgColor/textColor props because role colours are derived from the semantic colour system, not dedicated status tokens.

### Implementation

```tsx
export function RoleBadge({ role, className }: RoleBadgeProps) {
  const config = roleConfig[role]
  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5',
        'rounded-[--radius-sm] text-xs font-medium',
        config.className,
        className,
      )}
    >
      {config.label}
    </span>
  )
}
```

### Usage

```tsx
// Staff management table
{
  accessorKey: 'role',
  header: 'Role',
  cell: ({ row }) => <RoleBadge role={row.original.role} />,
}

// Topbar user menu
<div className="flex items-center gap-2 px-3 py-2">
  <Avatar src={user.avatar_url} fallback={initials} size="sm" />
  <div className="flex flex-col">
    <span className="text-sm font-medium">{user.full_name}</span>
    <RoleBadge role={user.role} />
  </div>
</div>
```

## 7. Adding New Domain Components

If a new domain entity or status type is added to the system in the future, follow this pattern:

1. Define the status type in `src/lib/constants.ts`
2. Add the corresponding CSS token pairs in `src/styles/tokens.css` (both `:root` and `.dark`)
3. Create a new badge component in `components/shared/` following the same `Record<Status, Config>` pattern
4. Import and use in the relevant module column definitions and detail views

The pattern is intentionally repetitive — each badge file is self-contained and immediately understandable without needing to trace through abstraction layers.
