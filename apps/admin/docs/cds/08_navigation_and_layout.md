# CDS-08 — Navigation & Layout

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [The Layout System](#1-the-layout-system)
2. [Sidebar](#2-sidebar)
3. [Topbar](#3-topbar)
4. [PageContainer](#4-pagecontainer)
5. [PageHeader](#5-pageheader)
6. [Tabs](#6-tabs)
7. [Breadcrumb](#7-breadcrumb)

## 1. The Layout System

The admin portal has a fixed, predictable layout that never changes between modules. Staff learn it once and navigate confidently for the rest of their sessions.

```text
┌─────────────────────────────────────────────────────────┐
│  Topbar (fixed, full width, z-10)                       │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │  PageContainer                               │
│ (fixed,  │    PageHeader (title, description, actions)  │
│ left)    │    ──────────────────────────────────────    │
│          │    Module content                            │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

The layout components work together:

- `Sidebar` — fixed left column, collapsible, role-aware navigation
- `Topbar` — fixed top bar, global actions (notifications, language, user menu)
- `PageContainer` — constrains the content area width and provides consistent padding
- `PageHeader` — every page's first content element (title + actions)

This structure is defined in `app/(admin)/layout.tsx` and applies to every page in the admin portal. Individual module pages only need to render `PageHeader` + their content — the surrounding chrome is always there.

## 2. Sidebar

The sidebar is the primary navigation mechanism. Staff use it hundreds of times per day — it must be fast, clear, and predictable.

### Props Interface

```tsx
type UserRole = 'admin' | 'manager' | 'staff'

interface SidebarProps {
  role:      UserRole     // determines which menu items are visible
  collapsed: boolean      // drives expanded/collapsed state
  onToggle:  () => void   // calls useUIStore toggle
}
```

### State

Collapsed state lives in `useUIStore` (Zustand), not in component state. This means the collapse preference persists across page navigations within the session.

```ts
// stores/ui.store.ts
interface UIStore {
  sidebarCollapsed: boolean
  toggleSidebar:    () => void
}
```

### Menu Structure

```tsx
interface NavItem {
  label:     string
  href:      string
  icon:      React.ReactNode
  roles:     UserRole[]          // only shown for these roles
  children?: NavItem[]           // nested items (Catalog)
}

const navItems: NavItem[] = [
  // Active state: bg --sidebar-active-bg, border-left --sidebar-accent, text --sidebar-active-text
  // Inactive state: text/icon --sidebar-muted-text
  { label: 'Dashboard',  href: '/dashboard',           icon: <LayoutDashboard size={18} />, roles: ['admin', 'manager', 'staff'] },
  { label: 'Orders',     href: '/orders',               icon: <ShoppingBag size={18} />,     roles: ['admin', 'manager', 'staff'] },
  { label: 'Customers',  href: '/customers',            icon: <Users size={18} />,           roles: ['admin', 'manager', 'staff'] },
  {
    label: 'Catalog', href: '/catalog', icon: <Pizza size={18} />, roles: ['admin', 'manager', 'staff'],
    children: [
      { label: 'Categories', href: '/catalog/categories', icon: <Tag size={16} />,     roles: ['admin', 'manager', 'staff'] },
      { label: 'Products',   href: '/catalog/products',   icon: <Package size={16} />, roles: ['admin', 'manager', 'staff'] },
    ],
  },
  { label: 'Addresses',  href: '/addresses',            icon: <MapPin size={18} />,          roles: ['admin', 'manager'] },
  { label: 'Sales',      href: '/sales',                icon: <BarChart3 size={18} />,       roles: ['admin'] },
  { label: 'Settings',   href: '/settings',             icon: <Settings size={18} />,        roles: ['admin'] },
  { label: 'Audit Logs', href: '/audit-logs',           icon: <ScrollText size={18} />,      roles: ['admin'] },
]
```

### Collapsed Behaviour

- **Expanded:** Icon + label text visible
- **Collapsed:** Icon only, 64px wide. Labels hidden but available via Tooltip on hover/focus

The Tooltip on collapsed nav items is critical for usability and accessibility — a keyboard-only user navigating a collapsed sidebar must still be able to identify each item via its tooltip.

### Active State

Active route detected via Next.js `usePathname()`. Active item uses `--sidebar-active-bg` for its background, a 3px left border in `--sidebar-accent`, and text/icon in `--sidebar-active-text`. Inactive items use `--sidebar-muted-text`. For nested items (Catalog), the parent is highlighted if any child route is active. The sidebar palette uses dedicated `--sidebar-*` tokens and is always dark regardless of the page light/dark mode toggle.

### Role Filtering

Items are filtered at render time by comparing `navItem.roles` against the `role` prop. Items not in the current user's role are not rendered at all — not just hidden. This prevents role-mismatched navigation via URL manipulation (which is enforced by RLS, but the UI should be clean regardless).

### Accessibility

- `<nav aria-label="Main navigation">`
- Active link has `aria-current="page"`
- Collapse toggle button: `aria-label="Collapse sidebar"` / `"Expand sidebar"` (updates with state)
- Nested nav groups use `<ul>` / `<li>` structure with `aria-expanded` on the parent item
- Collapsed mode tooltips appear on focus for keyboard users

## 3. Topbar

The topbar provides global system actions that apply regardless of the current module.

### Props Interface

```tsx
type AppLocale = 'en' | 'cs' | 'de'

interface TopbarProps {
  user: {
    full_name:   string
    avatar_url?: string
    role:        UserRole
  }
  unreadCount:          number
  onNotificationsClick: () => void
  onSignOut:            () => void
  currentLocale:        AppLocale
  onLocaleChange:       (locale: AppLocale) => void
}
```

### Layout (left to right)

```text
[Logo / App name]  ─────────────────  [Language]  [Notifications]  [User menu]
```

- **Logo:** Application name or logo mark. Links to `/dashboard`.
- **Language selector:** Compact `Select` showing current locale flag + code (EN / CS / DE). Calling `onLocaleChange` triggers a Server Action that updates the locale cookie.
- **Notification bell:** `IconButton` with a count badge overlay (`unreadCount > 0`). Clicking opens the notification Drawer.
- **User menu:** `Avatar` + name. `DropdownMenu` with "My profile" and "Sign out" items.

### Notification Count Badge

```tsx
{unreadCount > 0 && (
  <span
    className="absolute -top-1 -right-1 h-4 min-w-4 px-1 flex items-center justify-center
               rounded-full bg-destructive text-destructive-foreground text-xs font-medium"
    aria-label={`${unreadCount} unread notifications`}
  >
    {unreadCount > 99 ? '99+' : unreadCount}
  </span>
)}
```

The `aria-label` on the badge ensures screen readers announce the unread count rather than just reading a number floating in the layout.

## 4. PageContainer

Constrains the content area to a maximum width and provides consistent horizontal padding and vertical spacing. Every module page is wrapped in PageContainer — it is applied automatically by the admin layout, not by individual pages.

```tsx
interface PageContainerProps {
  children: React.ReactNode
}

export function PageContainer({ children }: PageContainerProps) {
  return (
    <div className="mx-auto max-w-screen-2xl w-full px-6 py-8">
      {children}
    </div>
  )
}
```

`max-w-screen-2xl` (1536px) means the content never stretches to full width on very large screens, which would make line lengths unreadable and form fields comically wide.

## 5. PageHeader

Every module page begins with a PageHeader. It provides:

- A consistent visual entry point to each section
- The page title for orientation and screen reader heading hierarchy
- A place for primary page-level actions (e.g. "Create Order")
- Optional breadcrumb navigation

### Props Interface

```tsx
interface PageHeaderProps {
  title:        string
  description?: string
  actions?:     React.ReactNode   // primary action buttons, right-aligned
  breadcrumb?:  React.ReactNode   // <Breadcrumb> component, shown above title
  className?:   string
}
```

### Implementation

```tsx
export function PageHeader({ title, description, actions, breadcrumb, className }: PageHeaderProps) {
  return (
    <div className={cn('mb-6', className)}>
      {breadcrumb && <div className="mb-2">{breadcrumb}</div>}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-foreground">{title}</h1>
          {description && (
            <p className="mt-1 text-sm text-foreground-muted">{description}</p>
          )}
        </div>
        {actions && (
          <div className="flex items-center gap-2 flex-shrink-0">
            {actions}
          </div>
        )}
      </div>
    </div>
  )
}
```

### Heading Hierarchy

`PageHeader` renders an `<h1>`. This is the only `<h1>` on the page. Section headings within the page (e.g. inside Card headers) use `<h2>`. Sub-sections use `<h3>`. This hierarchy must be maintained across all modules — screen reader users navigate by heading.

### Usage

```tsx
// Simple page with action
<PageHeader
  title="Orders"
  description="View and manage all customer orders."
  actions={
    <Button variant="primary" leftIcon={<Plus size={14} />} onClick={() => setCreateOpen(true)}>
      New Order
    </Button>
  }
/>

// With breadcrumb (detail pages)
<PageHeader
  title="Margherita"
  description="Classic tomato and mozzarella"
  breadcrumb={
    <Breadcrumb items={[
      { label: 'Catalog', href: '/catalog' },
      { label: 'Products', href: '/catalog/products' },
      { label: 'Margherita' },
    ]} />
  }
  actions={
    <>
      <Button variant="outline" onClick={() => setEditOpen(true)}>Edit</Button>
      <Button variant="destructive" onClick={() => setDeleteOpen(true)}>Delete</Button>
    </>
  }
/>
```

## 6. Tabs

Used to segment content within a page into related views without navigating away. Used in the Settings module (General, Notifications, Appearance tabs) and the Sales module (Revenue, Orders, Products tabs).

### Props Interface

```tsx
interface Tab {
  value:     string
  label:     string
  disabled?: boolean
  count?:    number     // optional badge with count (e.g. "Pending (7)")
}

interface TabsProps {
  tabs:          Tab[]
  value:         string
  onValueChange: (value: string) => void
  variant?:      'underline' | 'pill'    // default: 'underline'
  className?:    string
}
```

### Variants

**Underline** — tab list with a bottom border, active tab has a primary-coloured underline indicator. Used for top-level page tabs (Settings, Sales).

**Pill** — active tab has a filled background. Used for sub-section switching inside a card or panel.

### Keyboard Navigation

Per ARIA Tabs pattern:

| Key | Behaviour |
|---|---|
| Arrow Right | Move focus to next tab |
| Arrow Left | Move focus to previous tab |
| Home | Move focus to first tab |
| End | Move focus to last tab |
| Enter / Space | Activate focused tab |

Tab selection is **activated on focus** (not requiring Enter) for the common case. This is the recommended pattern for admin UIs where speed matters.

### Accessibility

```tsx
// Tab list
<div role="tablist" aria-label={label}>

// Individual tab
<button
  role="tab"
  aria-selected={value === tab.value}
  aria-controls={`${tab.value}-panel`}
  id={`${tab.value}-tab`}
  tabIndex={value === tab.value ? 0 : -1}
>

// Tab panel
<div
  role="tabpanel"
  id={`${activeTab}-panel`}
  aria-labelledby={`${activeTab}-tab`}
  tabIndex={0}
>
```

Only the active tab has `tabIndex={0}` — inactive tabs have `tabIndex={-1}`. This means Tab key moves focus into the tab list, and arrow keys navigate between tabs, without requiring multiple Tab presses to get through a 6-tab list.

### Usage

```tsx
// Settings page
<Tabs
  tabs={[
    { value: 'general',       label: 'General' },
    { value: 'notifications', label: 'Notifications' },
    { value: 'appearance',    label: 'Appearance' },
  ]}
  value={activeTab}
  onValueChange={setActiveTab}
  variant="underline"
/>

{activeTab === 'general'       && <GeneralSettings />}
{activeTab === 'notifications' && <NotificationSettings />}
{activeTab === 'appearance'    && <AppearanceSettings />}

// With counts
<Tabs
  tabs={[
    { value: 'pending',   label: 'Pending',   count: 7 },
    { value: 'confirmed', label: 'Confirmed', count: 23 },
    { value: 'all',       label: 'All' },
  ]}
  value={activeTab}
  onValueChange={setActiveTab}
  variant="pill"
/>
```

## 7. Breadcrumb

Shows the user's location within the page hierarchy. Used on detail and nested pages where the path context is useful (e.g. Catalog > Products > Margherita).

### Props Interface

```tsx
interface BreadcrumbItem {
  label:  string
  href?:  string    // omit for the current page (non-linked, aria-current)
}

interface BreadcrumbProps {
  items:      BreadcrumbItem[]
  className?: string
}
```

### Implementation

```tsx
export function Breadcrumb({ items, className }: BreadcrumbProps) {
  return (
    <nav aria-label="Breadcrumb" className={className}>
      <ol className="flex items-center gap-1.5 text-xs text-foreground-muted">
        {items.map((item, index) => {
          const isLast = index === items.length - 1
          return (
            <li key={index} className="flex items-center gap-1.5">
              {isLast || !item.href ? (
                <span
                  className={isLast ? 'text-foreground font-medium' : ''}
                  aria-current={isLast ? 'page' : undefined}
                >
                  {item.label}
                </span>
              ) : (
                <a href={item.href} className="hover:text-foreground transition-colors">
                  {item.label}
                </a>
              )}
              {!isLast && (
                <ChevronRight size={12} aria-hidden className="flex-shrink-0" />
              )}
            </li>
          )
        })}
      </ol>
    </nav>
  )
}
```

### Accessibility

- `<nav aria-label="Breadcrumb">`
- `<ol>` list structure (ordered, because the hierarchy sequence matters)
- Current page item has `aria-current="page"`
- Separator chevrons are `aria-hidden`

### Usage

```tsx
<Breadcrumb items={[
  { label: 'Catalog',  href: '/catalog' },
  { label: 'Products', href: '/catalog/products' },
  { label: 'Margherita' },    // no href = current page
]} />
```
