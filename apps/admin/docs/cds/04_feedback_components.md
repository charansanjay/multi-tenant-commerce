# CDS-04 — Feedback Components

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Feedback Components?](#1-what-are-feedback-components)
2. [Toast](#2-toast)
3. [Alert](#3-alert)
4. [StatusBadge](#4-statusbadge)
5. [ProgressBar](#5-progressbar)

## 1. What are Feedback Components?

Feedback components communicate the **result of an action or the current state of the system** to the user. They answer questions like: Did my save succeed? Is this order in a warning state? How much of this process is complete?

In an admin portal used by staff all day, feedback quality directly impacts operational efficiency. Poor feedback — or no feedback — means staff are left wondering whether an action succeeded, leading to double-submissions, confusion, and errors. Good feedback is immediate, clear, and non-intrusive.

There are two categories:

**Transient feedback** — appears in response to an action, then disappears. `Toast` is the primary example. Staff clicks "Save Order", a toast appears confirming success, and it auto-dismisses after 4 seconds.

**Persistent feedback** — stays visible until the condition it describes is resolved. `Alert` is the example — a low-stock warning stays on a product page until the stock is replenished.

`StatusBadge` and `ProgressBar` are a third type: they are not reactions to actions but **continuous state indicators** embedded in data views.

## 2. Toast

Toast notifications are the system's primary mechanism for confirming actions and reporting errors. Every create, update, delete, and status-change operation in the portal produces a toast.

### Architecture

Toast is managed via a global `useToast()` hook and a `<ToastProvider>` mounted at the app root. This means any component anywhere in the tree can call `toast()` without prop drilling.

```tsx
// src/app/(admin)/layout.tsx
import { ToastProvider } from '@/components/ui/feedback/ToastProvider'

export default function AdminLayout({ children }) {
  return (
    <>
      {children}
      <ToastProvider />
    </>
  )
}
```

The provider renders the toast container (fixed, bottom-right by default) and manages the queue of active toasts. The `useToast` hook connects components to the global toast store.

### Props Interface

```tsx
type ToastVariant = 'default' | 'success' | 'warning' | 'destructive'

interface ToastOptions {
  title:        string
  description?: string
  variant?:     ToastVariant    // default: 'default'
  duration?:    number          // ms before auto-dismiss, default: 4000. 0 = persist
  action?: {
    label:   string
    onClick: () => void
  }
}

interface UseToast {
  toast:      (options: ToastOptions) => string   // returns toast id
  dismiss:    (id: string) => void
  dismissAll: () => void
}
```

### Behaviour Details

**Queue management:** Multiple toasts stack vertically. Maximum 3 visible at once — older toasts are pushed down as new ones arrive.

**Auto-dismiss:** Default 4 seconds. Destructive/error toasts default to 6 seconds (more time to read). `duration: 0` persists until manually dismissed.

**Pause on hover:** Auto-dismiss timer pauses when the cursor is over the toast. This prevents toasts from disappearing while the user is reading them.

**Pause on focus:** Timer also pauses when any element inside the toast receives keyboard focus — important for users navigating via keyboard or screen reader who need to interact with a toast action button.

### Accessibility

This is a Tier 2 component with deliberate accessibility requirements:

- The toast container has `role="status"` and `aria-live="polite"` — new toasts are announced by screen readers without interrupting what the user is currently doing
- Destructive/error toasts use `aria-live="assertive"` — errors are announced immediately, interrupting the current screen reader flow because the user needs to know right away
- Each toast has a close button with a descriptive `aria-label="Dismiss notification"`
- Close button is keyboard-focusable; toast dismisses on Escape key

### Usage

```tsx
const { toast, dismiss } = useToast()

// Success confirmation
toast({
  title: 'Order updated',
  description: 'Order #1042 has been marked as Confirmed.',
  variant: 'success',
})

// Error with retry action
toast({
  title: 'Failed to save product',
  description: 'A network error occurred. Your changes were not saved.',
  variant: 'destructive',
  duration: 0,
  action: {
    label: 'Retry',
    onClick: handleRetry,
  },
})

// Warning (non-critical)
toast({
  title: 'Coupon expiring soon',
  description: 'SUMMER10 expires in 2 days.',
  variant: 'warning',
})

// Programmatic dismiss
const id = toast({ title: 'Processing...' })
// ... after operation
dismiss(id)
```

### Variant Icons

Each variant renders a leading icon for rapid visual scanning:

| Variant | Icon | Colour |
|---|---|---|
| `default` | `Info` | `--foreground-muted` |
| `success` | `CheckCircle` | `--success` |
| `warning` | `AlertTriangle` | `--warning` |
| `destructive` | `XCircle` | `--destructive` |

## 3. Alert

Inline contextual message. Unlike Toast, Alert is **not transient** — it sits persistently in the page layout to communicate an ongoing condition.

### When to use Alert vs Toast

| Situation | Component |
|---|---|
| "Your save succeeded" | Toast |
| "This product has 2 units left" | Alert |
| "An error occurred submitting the form" | Alert (inline, near the form) |
| "Order status updated" | Toast |
| "You don't have permission to view this" | Alert (page-level) |

The mental model: Toast is a reaction to a user action. Alert is a description of a state.

### Props Interface

```tsx
type AlertVariant = 'info' | 'success' | 'warning' | 'destructive'

interface AlertProps {
  variant?:     AlertVariant      // default: 'info'
  title?:       string
  children:     React.ReactNode   // the message body
  dismissible?: boolean           // shows close button
  onDismiss?:   () => void        // called when dismissed
  icon?:        React.ReactNode   // overrides default variant icon
  className?:   string
}
```

### Accessibility

- `role="alert"` for `destructive` and `warning` variants — announced immediately by screen readers
- `role="status"` for `info` and `success` — announced politely
- Dismiss button: `aria-label="Dismiss"`, keyboard accessible

### Usage

```tsx
// Low stock warning on product page
<Alert variant="warning" title="Low stock">
  Margherita (Small) has only 2 units remaining. Consider restocking soon.
</Alert>

// Permission error
<Alert variant="destructive" title="Access denied">
  You don't have permission to manage staff accounts.
</Alert>

// Informational — dismissible
<Alert
  variant="info"
  title="New feature"
  dismissible
  onDismiss={() => setShowBanner(false)}
>
  You can now export order data to CSV from the orders table toolbar.
</Alert>

// Success state after a settings save
<Alert variant="success">
  Settings saved successfully.
</Alert>
```

## 4. StatusBadge

The generic status badge primitive. Domain-specific wrappers (`OrderStatusBadge`, `PaymentStatusBadge`, `ProductStatusBadge`) in CDS-09 are built on top of this component. StatusBadge itself is used when you need a status badge outside of those three domains.

### Why StatusBadge is a Primitive

The domain badges are thin wrappers that map a status string to `StatusBadge` props. Having a shared primitive means all status badges have the same padding, font size, radius, and inline-flex layout — they can only differ in colour. This consistency is important: staff scan status badges constantly, and consistent visual structure aids comprehension.

### Props Interface

```tsx
interface StatusBadgeProps {
  label:      string              // always visible text — never rely on colour alone
  bgColor:    string              // CSS variable reference, e.g. 'var(--status-delivered-bg)'
  textColor:  string              // CSS variable reference
  icon?:      React.ReactNode     // optional leading icon (14px, aria-hidden)
  className?: string
}
```

### Implementation

```tsx
export function StatusBadge({ label, bgColor, textColor, icon, className }: StatusBadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 px-2 py-0.5',
        'rounded-[--radius-sm] text-xs font-medium',
        className,
      )}
      style={{
        backgroundColor: bgColor,
        color: textColor,
      }}
    >
      {icon && <span aria-hidden="true">{icon}</span>}
      {label}
    </span>
  )
}
```

### Accessibility Contract

**The most important rule: colour alone must never be the sole conveyor of status.**

The `label` text is always rendered and always visible. A colour-blind user who cannot distinguish between green and red must still be able to read "Delivered" and "Cancelled" as text.

This is a WCAG 1.4.1 (Use of Colour) requirement. It is enforced structurally — `label` is a required prop with no default.

### Usage

```tsx
// Direct usage (unusual — prefer domain badges)
<StatusBadge
  label="Custom status"
  bgColor="var(--status-confirmed-bg)"
  textColor="var(--status-confirmed-text)"
/>
```

## 5. ProgressBar

Used in dashboard metric cards and anywhere a completion percentage is relevant.

### Props Interface

```tsx
type ProgressVariant = 'default' | 'success' | 'warning' | 'destructive'
type ProgressSize    = 'sm' | 'md'

interface ProgressBarProps {
  value:       number           // 0–100
  max?:        number           // default: 100
  label?:      string           // aria-label for screen readers
  showValue?:  boolean          // renders "72%" text alongside bar
  size?:       ProgressSize     // default: 'md'
  variant?:    ProgressVariant  // default: 'default'
  className?:  string
}
```

### Variant Fill Colours

```tsx
const variantStyles: Record<ProgressVariant, string> = {
  default:     'bg-primary',
  success:     'bg-success',
  warning:     'bg-warning',
  destructive: 'bg-destructive',
}
```

### Accessibility

```tsx
<div
  role="progressbar"
  aria-valuenow={value}
  aria-valuemin={0}
  aria-valuemax={max}
  aria-label={label}
>
  <div style={{ width: `${(value / max) * 100}%` }} />
</div>
```

### Usage

```tsx
// Dashboard metric with percentage
<ProgressBar
  value={72}
  label="Order fulfilment rate"
  showValue
  variant="success"
/>

// Warning threshold
<ProgressBar
  value={88}
  label="Storage usage"
  showValue
  variant="warning"
/>

// Simple bar without value display
<ProgressBar value={45} size="sm" label="Loading" />
```
