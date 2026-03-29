# CDS-05 — Overlay Components

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Overlay Components?](#1-what-are-overlay-components)
2. [The Accessibility Challenge with Overlays](#2-the-accessibility-challenge-with-overlays)
3. [Modal](#3-modal)
4. [ConfirmDialog](#4-confirmdialog)
5. [Drawer](#5-drawer)
6. [Tooltip](#6-tooltip)
7. [Popover](#7-popover)
8. [DropdownMenu](#8-dropdownmenu)

## 1. What are Overlay Components?

Overlay components render **above the main page content** — they interrupt or extend the current view without navigating away. This project uses them extensively:

- Creating and editing any entity (product, order, customer) happens in a **Modal**
- Deleting any entity requires a **ConfirmDialog**
- Viewing full order detail without leaving the order list uses a **Drawer**
- Table row actions (edit, view, delete) are exposed via **DropdownMenu**
- Additional context on truncated values uses **Tooltip**

These are the most complex components in the system. They are complex not because their visual design is elaborate, but because their **interaction behaviour** — focus management, keyboard navigation, layering, scroll control — requires careful implementation to be correct and accessible.

## 2. The Accessibility Challenge with Overlays

This is the honest reason why full custom overlay components are hard, and why Radix UI has value: **focus management in overlays is non-trivial to implement correctly**.

When a Modal opens, the following must happen:

1. **Focus moves** into the modal automatically (to the first focusable element or the dialog title)
2. **Focus is trapped** — Tab and Shift+Tab cycle only through elements inside the modal, never reaching elements behind it
3. **Scroll is locked** on `<body>` — the page behind cannot scroll while the modal is open
4. When the modal closes, **focus returns** to the element that triggered it
5. Pressing **Escape** closes the modal from anywhere inside it

If any of these are missing, keyboard and screen reader users can get lost — focus can escape to a background element, or the page can become unexpectedly scrollable.

Every overlay component in this system implements the full focus management contract. The implementation details are noted per component below.

### Focus Trap Implementation

All overlays use the same focus trap utility:

```ts
// src/lib/utils/focusTrap.ts

export function getFocusableElements(container: HTMLElement): HTMLElement[] {
  return Array.from(
    container.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), ' +
      'select:not([disabled]), textarea:not([disabled]), ' +
      '[tabindex]:not([tabindex="-1"])'
    )
  )
}

export function trapFocus(container: HTMLElement, event: KeyboardEvent) {
  const focusable = getFocusableElements(container)
  const first = focusable[0]
  const last  = focusable[focusable.length - 1]

  if (event.key === 'Tab') {
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }
}
```

## 3. Modal

General-purpose modal dialog. Used for all create and edit forms across the portal.

### Design Decision: Two components — Modal + ConfirmDialog

We deliberately split Modal and ConfirmDialog into separate components rather than a single component with a `variant` prop. The reason: ConfirmDialog is used so frequently (every delete, every cancel, every irreversible action) that it deserves a minimal, purpose-built API where you only provide `title`, `description`, `onConfirm`, and `onCancel`. Collapsing this into Modal would mean passing empty `footer` slots and working around the full Modal API for simple confirmations.

### Props Interface

```tsx
type ModalSize = 'sm' | 'md' | 'lg' | 'xl'

interface ModalProps {
  open:                  boolean
  onClose:               () => void
  title:                 string
  description?:          string
  size?:                 ModalSize          // default: 'md'
  children:              React.ReactNode    // modal body (scrollable)
  footer?:               React.ReactNode    // Save + Cancel buttons
  closeOnOverlayClick?:  boolean            // default: true
  closeOnEscape?:        boolean            // default: true
  initialFocusRef?:      React.RefObject<HTMLElement>  // override focus target
}
```

### Size Widths

```tsx
const sizeStyles: Record<ModalSize, string> = {
  sm: 'max-w-sm',    // ~384px — simple confirmations if not using ConfirmDialog
  md: 'max-w-lg',    // ~512px — standard create/edit forms
  lg: 'max-w-2xl',   // ~672px — complex forms (order creation)
  xl: 'max-w-4xl',   // ~896px — wide content (product preview)
}
```

### Implementation Notes

```tsx
export function Modal({
  open, onClose, title, description, size = 'md',
  children, footer, closeOnOverlayClick = true, closeOnEscape = true,
  initialFocusRef,
}: ModalProps) {
  const titleId       = useId()
  const descriptionId = useId()
  const dialogRef     = useRef<HTMLDivElement>(null)
  const triggerRef    = useRef<Element | null>(null)

  // Store trigger element before opening so focus can return on close
  useEffect(() => {
    if (open) {
      triggerRef.current = document.activeElement
    }
  }, [open])

  // Focus management — move focus into modal on open
  useEffect(() => {
    if (open && dialogRef.current) {
      const target = initialFocusRef?.current
        ?? getFocusableElements(dialogRef.current)[0]
      target?.focus()
    }
    // Return focus on close
    if (!open && triggerRef.current instanceof HTMLElement) {
      triggerRef.current.focus()
    }
  }, [open])

  // Keyboard handler — focus trap + Escape
  useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && closeOnEscape) { onClose(); return }
      if (e.key === 'Tab' && dialogRef.current) trapFocus(dialogRef.current, e)
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [open, closeOnEscape, onClose])

  // Scroll lock
  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : ''
    return () => { document.body.style.overflow = '' }
  }, [open])

  if (!open) return null

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Overlay */}
      <div
        className="absolute inset-0 bg-black/50"
        aria-hidden="true"
        onClick={closeOnOverlayClick ? onClose : undefined}
      />
      {/* Dialog */}
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        aria-describedby={description ? descriptionId : undefined}
        className={cn(
          'relative z-10 w-full bg-surface rounded-[--radius-lg]',
          'shadow-xl flex flex-col max-h-[90vh]',
          sizeStyles[size],
        )}
      >
        {/* Header */}
        <div className="flex items-start justify-between px-6 pt-6 pb-4 border-b border-border">
          <div>
            <h2 id={titleId} className="text-xl font-semibold text-foreground">{title}</h2>
            {description && (
              <p id={descriptionId} className="mt-1 text-sm text-foreground-muted">{description}</p>
            )}
          </div>
          <IconButton icon={<X size={16} />} label="Close dialog" variant="ghost" size="sm" onClick={onClose} />
        </div>

        {/* Body — scrollable */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
            {footer}
          </div>
        )}
      </div>
    </div>,
    document.body,
  )
}
```

### Accessibility Contract

- `role="dialog"`, `aria-modal="true"`
- `aria-labelledby` → modal title
- `aria-describedby` → modal description (when present)
- Focus trapped inside while open
- Focus returns to trigger element on close
- Escape closes (configurable)
- Body scroll locked while open
- Overlay click closes (configurable)

### Usage

```tsx
<Modal
  open={isCreateOpen}
  onClose={() => setIsCreateOpen(false)}
  title="Create Product"
  description="Add a new pizza to the catalog."
  size="lg"
  footer={
    <>
      <Button variant="outline" onClick={() => setIsCreateOpen(false)}>Cancel</Button>
      <Button variant="primary" loading={isSubmitting} onClick={handleSubmit}>Save Product</Button>
    </>
  }
>
  <ProductForm />
</Modal>
```

## 4. ConfirmDialog

Purpose-built for destructive confirmations. Minimal API — the developer provides only what matters.

### Why the Default Focus is on Cancel

When ConfirmDialog opens, focus lands on the **Cancel button**, not Confirm. This is intentional.

For destructive actions — "Delete this product?", "Cancel this order?" — the safe default is inaction. If a keyboard user accidentally triggers the dialog and presses Enter, the action is cancelled, not confirmed. Putting focus on the destructive action by default would mean accidental Enter presses cause irreversible damage.

### Props Interface

```tsx
interface ConfirmDialogProps {
  open:           boolean
  onClose:        () => void
  onConfirm:      () => void
  title:          string
  description:    string
  confirmLabel?:  string    // default: 'Confirm'
  cancelLabel?:   string    // default: 'Cancel'
  isDestructive?: boolean   // default: true — confirm button uses destructive variant
  loading?:       boolean   // loading state on confirm button
}
```

### Usage

```tsx
<ConfirmDialog
  open={showDeleteDialog}
  onClose={() => setShowDeleteDialog(false)}
  onConfirm={handleDelete}
  title="Delete product?"
  description="Margherita (Large) will be permanently removed from the catalog. This cannot be undone."
  confirmLabel="Delete product"
  loading={isDeleting}
/>

// Non-destructive confirmation
<ConfirmDialog
  open={showPublishDialog}
  onClose={() => setShowPublishDialog(false)}
  onConfirm={handlePublish}
  title="Publish all changes?"
  description="This will make the updated menu visible to customers immediately."
  confirmLabel="Publish"
  isDestructive={false}
/>
```

## 5. Drawer

Side-panel that slides in from the right (or left). Used for the order detail view — staff can inspect a full order without leaving the orders list, which allows them to quickly move to the next order.

### Props Interface

```tsx
type DrawerSize = 'sm' | 'md' | 'lg' | 'full'
type DrawerSide = 'right' | 'left'

interface DrawerProps {
  open:          boolean
  onClose:       () => void
  title:         string
  description?:  string
  size?:         DrawerSize    // default: 'md'
  side?:         DrawerSide    // default: 'right'
  children:      React.ReactNode
  footer?:       React.ReactNode
}
```

### Size Widths

```tsx
const sizeStyles: Record<DrawerSize, string> = {
  sm:   'w-80',        // 320px — narrow detail panels
  md:   'w-[560px]',   // standard order detail
  lg:   'w-[720px]',   // wide content with multiple columns
  full: 'w-full',      // full-screen on mobile
}
```

### Animation

The drawer slides in via CSS transform, not opacity, to avoid repaints:

```css
/* Enter */
.drawer-enter { transform: translateX(100%); }
.drawer-enter-active { transform: translateX(0); transition: transform 250ms ease-out; }

/* Exit */
.drawer-exit { transform: translateX(0); }
.drawer-exit-active { transform: translateX(100%); transition: transform 200ms ease-in; }
```

### Accessibility

Same contract as Modal: `role="dialog"`, `aria-modal`, focus trap, return focus on close, Escape closes, scroll lock.

### Usage

```tsx
<Drawer
  open={!!selectedOrderId}
  onClose={() => setSelectedOrderId(null)}
  title={`Order #${selectedOrder?.order_number}`}
  description={`Placed on ${formatDate(selectedOrder?.created_at)}`}
  size="md"
  footer={
    <Button variant="outline" onClick={() => setSelectedOrderId(null)}>Close</Button>
  }
>
  <OrderDetailView orderId={selectedOrderId} />
</Drawer>
```

## 6. Tooltip

Short contextual label on hover and focus. Used for icon-only buttons (table row actions, topbar icons) where the visible label is omitted for space reasons.

### Props Interface

```tsx
type TooltipSide = 'top' | 'right' | 'bottom' | 'left'

interface TooltipProps {
  content:   React.ReactNode      // tooltip text
  children:  React.ReactElement   // single focusable element (trigger)
  side?:     TooltipSide          // default: 'top'
  delay?:    number               // hover delay ms, default: 300
  disabled?: boolean
}
```

### Positioning

Tooltip uses DIY positioning with `getBoundingClientRect()` and viewport boundary detection. If the preferred `side` would overflow the viewport, it flips to the opposite side. If Floating UI is adopted for other overlays, Tooltip will use it too.

### Accessibility

A tooltip must appear on **both hover and keyboard focus** — not just hover. Keyboard-only users and screen reader users must have equal access to the tooltip content.

```tsx
// Tooltip appears when trigger is hovered OR focused
<span
  role="tooltip"
  id={tooltipId}
  aria-hidden={!isVisible}
>
  {content}
</span>

// Trigger clones the child and injects aria-describedby
React.cloneElement(children, {
  'aria-describedby': tooltipId,
  onMouseEnter: handleShow,
  onMouseLeave: handleHide,
  onFocus:      handleShow,
  onBlur:       handleHide,
})
```

Pressing Escape dismisses the tooltip.

### Usage

```tsx
<Tooltip content="Edit order">
  <IconButton icon={<Pencil size={15} />} label="Edit order" variant="ghost" />
</Tooltip>

<Tooltip content="This coupon has expired" side="right">
  <AlertCircle size={14} className="text-destructive" />
</Tooltip>
```

## 7. Popover

Floating panel anchored to a trigger. Richer than a Tooltip — can contain interactive content like filter panels, colour pickers, or inline forms.

### Props Interface

```tsx
interface PopoverProps {
  trigger:       React.ReactElement
  children:      React.ReactNode
  side?:         'top' | 'right' | 'bottom' | 'left'   // default: 'bottom'
  align?:        'start' | 'center' | 'end'             // default: 'start'
  open?:         boolean                                // controlled mode
  onOpenChange?: (open: boolean) => void
  className?:    string
}
```

### Accessibility

Unlike Tooltip (which is `role="tooltip"`), Popover that contains interactive content uses `role="dialog"` or no role (depending on content complexity). The trigger has `aria-expanded` and `aria-controls`. Focus moves into the popover on open; Escape closes it.

### Usage

```tsx
// Filter panel
<Popover
  trigger={
    <Button variant="outline" size="sm" rightIcon={<SlidersHorizontal size={14} />}>
      Filters
    </Button>
  }
  side="bottom"
  align="start"
>
  <div className="p-4 w-72 flex flex-col gap-3">
    <Select options={STATUS_OPTIONS} placeholder="Order status" onChange={setStatusFilter} />
    <DatePicker value={dateFrom} onChange={setDateFrom} placeholder="From date" />
    <DatePicker value={dateTo} onChange={setDateTo} placeholder="To date" />
    <Button variant="secondary" size="sm" onClick={clearFilters}>Clear filters</Button>
  </div>
</Popover>
```

## 8. DropdownMenu

Contextual action menu triggered by a button. Used extensively in DataTable rows for per-row actions (View, Edit, Delete).

### Props Interface

```tsx
interface DropdownMenuItem {
  label:        string
  icon?:        React.ReactNode
  onClick?:     () => void
  disabled?:    boolean
  destructive?: boolean           // red text colour
  separator?:   boolean           // renders a divider line before this item
}

interface DropdownMenuProps {
  trigger:   React.ReactElement
  items:     DropdownMenuItem[]
  align?:    'start' | 'end'      // default: 'end'
  side?:     'bottom' | 'top'     // default: 'bottom'
}
```

### Keyboard Navigation

DropdownMenu is a Tier 3 accessibility component. Full keyboard contract:

| Key | Behaviour |
|---|---|
| Enter / Space | Opens menu; selects focused item |
| Arrow Down | Moves focus to next item (wraps from last to first) |
| Arrow Up | Moves focus to previous item (wraps from first to last) |
| Home | Moves focus to first item |
| End | Moves focus to last item |
| A–Z | Type-ahead: moves to next item starting with typed character |
| Escape | Closes menu, returns focus to trigger |
| Tab | Closes menu (does not trap focus — menus are not dialogs) |

```tsx
const variantStyles: Record<'default' | 'destructive', string> = {
  default:     'text-foreground hover:bg-muted',
  destructive: 'text-destructive hover:bg-destructive/10',
}
```

### Accessibility

- `role="menu"` on the dropdown panel
- `role="menuitem"` on each item
- `aria-expanded` on trigger
- `aria-haspopup="menu"` on trigger
- Disabled items have `aria-disabled="true"` and `tabindex="-1"`
- Separator items are `role="separator"`

### Usage

```tsx
// Standard table row actions
<DropdownMenu
  trigger={
    <IconButton icon={<MoreHorizontal size={15} />} label="Row actions" />
  }
  items={[
    {
      label: 'View order',
      icon:  <Eye size={14} />,
      onClick: () => setSelectedOrderId(order.id),
    },
    {
      label: 'Edit order',
      icon:  <Pencil size={14} />,
      onClick: () => setEditOrderId(order.id),
    },
    {
      separator:   true,
      label:       'Cancel order',
      icon:        <XCircle size={14} />,
      destructive: true,
      onClick:     () => setConfirmCancelId(order.id),
    },
  ]}
/>
```
