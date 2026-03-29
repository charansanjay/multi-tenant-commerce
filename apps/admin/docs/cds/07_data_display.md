# CDS-07 — Data Display

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Data Display Components?](#1-what-are-data-display-components)
2. [DataTable](#2-datatable)
3. [Pagination](#3-pagination)
4. [EmptyState](#4-emptystate)
5. [Card](#5-card)
6. [StatCard](#6-statcard)

## 1. What are Data Display Components?

Data display components are how the portal surfaces information to staff. Most of the portal's time is spent here: viewing orders, browsing the product catalog, scanning customer records, reading audit logs.

These components are the difference between a portal that helps staff work quickly and one that slows them down. A well-designed DataTable with fast search, reliable filtering, and clear row actions means an operator can process 50 orders in a session without friction. A poorly designed one means every action requires extra clicks and orientation.

## 2. DataTable

The most important shared component in the entire portal. Used in every module: Orders, Customers, Products, Categories, Addresses, Audit Logs, Staff management.

### Why Compound Component Pattern

The DataTable toolbar was the most considered API decision in this system. Three options were on the table:

**Slot-based** (`toolbar` prop as ReactNode) — fully flexible, but inconsistent. Every module's table toolbar would look and behave differently because there are no constraints.

**Config-based** (`toolbarConfig` object) — consistent but rigid. Adding an unusual toolbar element (e.g. a bulk action button only on the Orders table) requires either hacking the config or a special-case prop.

**Compound component** (`<DataTable.Toolbar>`, `<DataTable.Search>` etc.) — the best of both. The building blocks are defined by the system (ensuring visual consistency), but the developer assembles them freely (ensuring flexibility). The Orders table can have a search, status filter, date filter, and export button. The Audit Logs table can have a search and user filter only. Both are built from the same primitives.

The compound pattern also reads like English at the usage site — you can understand what a table toolbar does just by reading the JSX.

### Props Interface

```tsx
interface DataTableProps<TData> {
  columns:     ColumnDef<TData>[]       // TanStack Table column definitions
  data:        TData[]                  // current page of data
  totalCount:  number                   // total matching records (for pagination)
  isLoading?:  boolean                  // shows skeleton rows, default: false
  pagination:  {
    page:         number
    pageSize:     number
    onPageChange: (page: number) => void
  }
  sorting?: {
    sortBy:       string
    sortOrder:    'asc' | 'desc'
    onSortChange: (sortBy: string, order: 'asc' | 'desc') => void
  }
  rowSelection?: {
    selectedIds:       string[]
    onSelectionChange: (ids: string[]) => void
  }
  getRowId?:    (row: TData) => string   // default: (row) => row.id
  emptyState?:  React.ReactNode          // shown when data is empty and not loading
  children?:    React.ReactNode          // DataTable.Toolbar + other slots
}
```

### Compound Sub-Components

```tsx
// Toolbar wrapper — renders above the table
DataTable.Toolbar

// Search input — debounced, fires onChange after 300ms idle
DataTable.Search
  props: { placeholder?: string; onSearch: (value: string) => void; value?: string }

// Filter slot — accepts any filter controls (Select, DatePicker, etc.)
DataTable.Filters
  props: { children: React.ReactNode }

// Action slot — right-aligned buttons (Export, Bulk actions, Create button)
DataTable.Actions
  props: { children: React.ReactNode }

// Bulk action bar — appears when rows are selected
DataTable.BulkActions
  props: { selectedCount: number; children: React.ReactNode }
```

### Loading State

When `isLoading={true}`, the table body renders skeleton rows instead of data rows. The number of skeleton rows matches the `pageSize`. The table header is still rendered so layout remains stable:

```tsx
// Skeleton row — same height as a real row
<tr aria-hidden="true">
  {columns.map((col, i) => (
    <td key={i} className="px-4 py-3">
      <Skeleton className="h-4 w-full" />
    </td>
  ))}
</tr>
```

`aria-busy="true"` is set on the `<table>` element while loading — screen readers announce the table is updating.

### Column Definition Pattern

Column definitions live in `modules/{name}/components/{Name}Columns.tsx`:

```tsx
// modules/orders/components/OrderColumns.tsx
import { ColumnDef } from '@tanstack/react-table'
import { OrderStatusBadge } from '@/components/shared/OrderStatusBadge'
import { formatCurrency } from '@/lib/utils'

export const orderColumns: ColumnDef<Order>[] = [
  {
    id: 'select',
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        indeterminate={table.getIsSomePageRowsSelected()}
        onCheckedChange={(val) => table.toggleAllPageRowsSelected(!!val)}
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(val) => row.toggleSelected(!!val)}
        label={`Select order ${row.original.order_number}`}
      />
    ),
    enableSorting: false,
  },
  {
    accessorKey: 'order_number',
    header: 'Order #',
    enableSorting: true,
  },
  {
    accessorKey: 'customer',
    header: 'Customer',
    cell: ({ row }) => {
      const c = row.original.customer
      return `${c.first_name} ${c.last_name}`
    },
    enableSorting: false,
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => <OrderStatusBadge status={row.original.status} />,
    enableSorting: true,
  },
  {
    accessorKey: 'total_price',
    header: 'Total',
    cell: ({ row }) => formatCurrency(row.original.total_price),
    enableSorting: true,
  },
  {
    id: 'actions',
    cell: ({ row }) => (
      <DropdownMenu
        trigger={<IconButton icon={<MoreHorizontal size={15} />} label={`Actions for order ${row.original.order_number}`} />}
        items={buildOrderRowActions(row.original)}
      />
    ),
    enableSorting: false,
  },
]
```

### Accessibility

- Rendered as a native `<table>` with `<thead>` and `<tbody>`
- Sortable column headers have `aria-sort="ascending"` / `"descending"` / `"none"`
- `aria-busy="true"` on `<table>` during loading
- Row selection checkboxes have descriptive `aria-label` per row
- The table container has `role="region"` and `aria-label` describing what it contains

### Full Usage Example

```tsx
// modules/orders/components/OrdersTable.tsx
'use client'

export function OrdersTable({ initialData }: { initialData: Order[] }) {
  const [page, setPage]             = useState(0)
  const [search, setSearch]         = useState('')
  const [statusFilter, setStatus]   = useState('')
  const [sortBy, setSortBy]         = useState('created_at')
  const [sortOrder, setSortOrder]   = useState<'asc' | 'desc'>('desc')
  const [selectedIds, setSelected]  = useState<string[]>([])

  const { data, isLoading } = useOrders({ page, search, status: statusFilter, sortBy, sortOrder })

  return (
    <DataTable
      columns={orderColumns}
      data={data?.orders ?? initialData}
      totalCount={data?.count ?? 0}
      isLoading={isLoading}
      pagination={{ page, pageSize: 50, onPageChange: setPage }}
      sorting={{ sortBy, sortOrder, onSortChange: (by, order) => { setSortBy(by); setSortOrder(order) } }}
      rowSelection={{ selectedIds, onSelectionChange: setSelected }}
      emptyState={
        <EmptyState
          icon={<ShoppingCart size={32} />}
          title="No orders found"
          description="Try adjusting your filters."
        />
      }
    >
      <DataTable.Toolbar>
        <DataTable.Search placeholder="Search by order # or customer..." onSearch={setSearch} />
        <DataTable.Filters>
          <Select options={ORDER_STATUS_OPTIONS} value={statusFilter} onChange={setStatus} placeholder="All statuses" />
        </DataTable.Filters>
        <DataTable.Actions>
          <Button variant="outline" size="sm" leftIcon={<Download size={14} />}>
            Export CSV
          </Button>
        </DataTable.Actions>
      </DataTable.Toolbar>

      {selectedIds.length > 0 && (
        <DataTable.BulkActions selectedCount={selectedIds.length}>
          <Button variant="destructive" size="sm" onClick={handleBulkCancel}>
            Cancel selected
          </Button>
        </DataTable.BulkActions>
      )}
    </DataTable>
  )
}
```

## 3. Pagination

Server-side pagination controls. Always paired with DataTable.

### Props Interface

```tsx
interface PaginationProps {
  page:         number              // 0-indexed current page
  pageSize:     number
  totalCount:   number
  onPageChange: (page: number) => void
  showTotal?:   boolean             // "Showing 1–50 of 243 results", default: true
  className?:   string
}
```

### Display Logic

```tsx
const from  = page * pageSize + 1
const to    = Math.min((page + 1) * pageSize, totalCount)
const total = totalCount
// "Showing 1–50 of 243 results"

const totalPages = Math.ceil(totalCount / pageSize)
// Page buttons: First, Prev, [window of 5 pages], Next, Last
```

Page button window: shows 5 page numbers centered on the current page, with ellipsis when the range does not include page 1 or the last page.

### Accessibility

- `<nav aria-label="Pagination">`
- Current page button has `aria-current="page"`
- Previous/Next/First/Last buttons have descriptive `aria-label`
- Disabled buttons have `aria-disabled="true"`

### Usage

```tsx
<Pagination
  page={page}
  pageSize={50}
  totalCount={totalOrders}
  onPageChange={setPage}
/>
```

## 4. EmptyState

Shown when a table or list has no data to display. Communicates clearly that the absence of content is intentional (no results matching filters) rather than a loading failure.

### EmptyState vs Loading vs Error

| State | Component |
|---|---|
| Data loading | Skeleton rows inside DataTable (`isLoading={true}`) |
| No data | `EmptyState` passed as `emptyState` prop to DataTable |
| Error loading | Module-level `error.tsx` boundary or inline `Alert` |

### Props Interface

```tsx
interface EmptyStateProps {
  icon?:        React.ReactNode    // illustrative icon (32–40px)
  title:        string             // primary message, e.g. "No orders found"
  description?: string            // secondary message, e.g. "Try adjusting your filters"
  action?:      React.ReactNode   // optional CTA, e.g. "Create first product" Button
  className?:   string
}
```

### Usage

```tsx
// No search results
<EmptyState
  icon={<SearchX size={36} className="text-foreground-subtle" />}
  title="No results found"
  description='No orders match "pizza margherita". Try a different search.'
/>

// Module first-use state
<EmptyState
  icon={<Package size={36} className="text-foreground-subtle" />}
  title="No products yet"
  description="Add your first pizza to get started."
  action={
    <Button variant="primary" leftIcon={<Plus size={14} />} onClick={() => setCreateOpen(true)}>
      Add product
    </Button>
  }
/>
```

## 5. Card

Generic surface container. Used for grouping related content on dashboard pages, detail views, and settings panels.

### Props Interface

```tsx
type CardPadding = 'none' | 'sm' | 'md' | 'lg'

interface CardProps {
  children:   React.ReactNode
  padding?:   CardPadding     // default: 'md'
  className?: string
}

// Sub-components
interface CardHeaderProps { children: React.ReactNode; className?: string }
interface CardBodyProps   { children: React.ReactNode; className?: string }
interface CardFooterProps { children: React.ReactNode; className?: string }
```

### Padding Styles

```tsx
const paddingStyles: Record<CardPadding, string> = {
  none: '',
  sm:   'p-3',
  md:   'p-5',
  lg:   'p-6',
}
```

### Usage

```tsx
// Simple card
<Card>
  <Card.Header>
    <h2 className="text-lg font-medium">Recent Orders</h2>
  </Card.Header>
  <Card.Body>
    <OrdersTable />
  </Card.Body>
</Card>

// Settings panel
<Card padding="lg">
  <Card.Header>
    <h3 className="text-base font-semibold">Notification Preferences</h3>
    <p className="text-sm text-foreground-muted">Choose what events trigger staff notifications.</p>
  </Card.Header>
  <Card.Body>
    {/* Settings fields */}
  </Card.Body>
  <Card.Footer>
    <Button variant="primary" type="submit">Save preferences</Button>
  </Card.Footer>
</Card>

// No sub-components needed for simple content
<Card padding="md" className="text-sm text-foreground-muted">
  Last updated 3 minutes ago
</Card>
```

## 6. StatCard

Dashboard metric tile. Displays a single KPI with an optional change indicator and icon.

### Props Interface

```tsx
interface StatCardChange {
  value:  number     // positive or negative, e.g. +12.5 or -3.2
  period: string     // e.g. "vs yesterday", "vs last week"
}

interface StatCardProps {
  title:     string
  value:     string | number     // formatted value, e.g. "€1,284" or "142"
  change?:   StatCardChange
  icon?:     React.ReactNode     // 18–20px icon
  loading?:  boolean             // shows Skeleton for value and change
  className?: string
}
```

### Change Indicator

The change value displays with a coloured indicator:
- Positive (> 0): green text with `TrendingUp` icon
- Negative (< 0): red text with `TrendingDown` icon
- Zero: muted text, no icon

### Implementation

```tsx
export function StatCard({ title, value, change, icon, loading, className }: StatCardProps) {
  return (
    <Card className={className}>
      <div className="flex items-start justify-between">
        <div className="flex flex-col gap-1">
          <span className="text-sm text-foreground-muted">{title}</span>
          {loading
            ? <Skeleton className="h-8 w-24" />
            : <span className="text-2xl font-semibold text-foreground">{value}</span>
          }
          {change && !loading && (
            <span className={cn(
              'flex items-center gap-1 text-xs font-medium',
              change.value > 0 && 'text-success',
              change.value < 0 && 'text-destructive',
              change.value === 0 && 'text-foreground-muted',
            )}>
              {change.value > 0 && <TrendingUp size={12} aria-hidden />}
              {change.value < 0 && <TrendingDown size={12} aria-hidden />}
              {change.value > 0 ? '+' : ''}{change.value}% {change.period}
            </span>
          )}
        </div>
        {icon && (
          <div className="p-2 rounded-[--radius-md] bg-primary/10 text-primary" aria-hidden>
            {icon}
          </div>
        )}
      </div>
    </Card>
  )
}
```

### Usage

```tsx
// Dashboard grid
<div className="grid grid-cols-4 gap-4">
  <StatCard
    title="Today's Revenue"
    value="€1,284"
    change={{ value: +12.5, period: 'vs yesterday' }}
    icon={<EuroSign size={18} />}
  />
  <StatCard
    title="Orders Today"
    value={42}
    change={{ value: +8, period: 'vs yesterday' }}
    icon={<ShoppingBag size={18} />}
  />
  <StatCard
    title="Pending Orders"
    value={7}
    icon={<Clock size={18} />}
  />
  <StatCard
    title="Avg Order Value"
    value="€30.57"
    change={{ value: -2.1, period: 'vs last week' }}
    icon={<TrendingUp size={18} />}
  />
</div>

// Loading state
<StatCard title="Today's Revenue" value="" loading />
```
