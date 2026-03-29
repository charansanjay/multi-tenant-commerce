# CDS-03 — Primitives

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Primitives?](#1-what-are-primitives)
2. [Button](#2-button)
3. [IconButton](#3-iconbutton)
4. [Badge](#4-badge)
5. [Input](#5-input)
6. [Textarea](#6-textarea)
7. [Checkbox](#7-checkbox)
8. [RadioGroup](#8-radiogroup)
9. [Switch](#9-switch)
10. [Label](#10-label)
11. [Spinner](#11-spinner)
12. [Skeleton](#12-skeleton)
13. [Divider](#13-divider)
14. [Avatar](#14-avatar)

## 1. What are Primitives?

Primitives are the atoms of the design system — the lowest-level UI components from which everything else is composed. They have no dependencies on other components in the system (except Label, which is used inside FormField).

A few important properties of all primitives:

- **No application logic** — they are pure UI. They do not import from modules, do not call Supabase, do not read from stores.
- **Fully typed** — every prop is typed via TypeScript interface. No implicit any.
- **Accessible by default** — where the underlying HTML element provides semantics, we use it correctly. Where custom behaviour is needed (Checkbox, Switch), we implement the ARIA contract explicitly.
- **Token-referenced** — all colours, sizes, and radii reference CSS custom properties from `tokens.css`, never hardcoded values.

## 2. Button

The most used component in the entire system. Every form submission, every table action, every modal confirmation goes through Button. Getting its API right is worth the investment.

### Why Button is a separate document section

Button has five visual variants, three sizes, a loading state, icon support, and full-width mode. More importantly, the **loading state decision** has a concrete UX impact: when a form is submitting, the button must not change width (which would cause layout shift and feel janky). The spinner appears centered on the button while the label text is made invisible but still occupies its space.

### Props Interface

```tsx
type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'destructive' | 'outline'
type ButtonSize    = 'sm' | 'md' | 'lg'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:   ButtonVariant       // default: 'primary'
  size?:      ButtonSize          // default: 'md'
  loading?:   boolean             // shows spinner, disables, maintains width
  leftIcon?:  React.ReactNode     // icon before label
  rightIcon?: React.ReactNode     // icon after label
  fullWidth?: boolean             // w-full
}
```

### Variant & Size Styles

```tsx
const variantStyles: Record<ButtonVariant, string> = {
  primary:     'bg-primary text-primary-foreground hover:bg-primary-hover',
  secondary:   'bg-secondary text-secondary-foreground hover:bg-secondary-hover border border-border',
  ghost:       'bg-transparent text-foreground hover:bg-muted',
  destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive-hover',
  outline:     'border border-border bg-transparent text-foreground hover:bg-muted',
}

const sizeStyles: Record<ButtonSize, string> = {
  sm: 'h-7  px-3 text-xs  gap-1.5 rounded-[--radius-sm]',
  md: 'h-9  px-4 text-sm  gap-2   rounded-[--radius-md]',
  lg: 'h-11 px-5 text-base gap-2  rounded-[--radius-md]',
}
```

### Loading State Implementation

```tsx
export function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  leftIcon,
  rightIcon,
  fullWidth = false,
  children,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      disabled={disabled || loading}
      aria-busy={loading}
      aria-disabled={disabled || loading}
      className={cn(
        'relative inline-flex items-center justify-center font-medium',
        'transition-colors duration-150',
        'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[--ring]',
        'disabled:pointer-events-none disabled:opacity-50',
        variantStyles[variant],
        sizeStyles[size],
        fullWidth && 'w-full',
      )}
    >
      {/* Left icon — hidden during loading */}
      {leftIcon && (
        <span className={loading ? 'invisible' : ''}>{leftIcon}</span>
      )}

      {/* Label — invisible during loading but maintains layout width */}
      <span className={loading ? 'invisible' : ''}>{children}</span>

      {/* Right icon — hidden during loading */}
      {rightIcon && (
        <span className={loading ? 'invisible' : ''}>{rightIcon}</span>
      )}

      {/* Spinner — centered absolutely, only visible during loading */}
      {loading && (
        <span className="absolute inset-0 flex items-center justify-center">
          <Spinner size="sm" label="Loading" />
        </span>
      )}
    </button>
  )
}
```

### Accessibility

- Uses native `<button>` — inherits all browser accessibility behaviours
- `aria-busy="true"` during loading informs screen readers the action is processing
- `aria-disabled` (not just `disabled`) ensures screen readers announce the disabled state
- Focus ring via `focus-visible` — only appears for keyboard navigation, not mouse clicks

### Usage

```tsx
// Standard submit button
<Button variant="primary" size="md" loading={isSubmitting}>
  Save Order
</Button>

// Destructive action with icon
<Button variant="destructive" leftIcon={<Trash2 size={14} />}>
  Delete Product
</Button>

// Secondary with right icon
<Button variant="secondary" rightIcon={<ChevronDown size={14} />}>
  Export
</Button>

// Full width in a form footer
<Button variant="primary" fullWidth loading={isSubmitting}>
  Create Account
</Button>
```

## 3. IconButton

Square button for icon-only actions. Separate from Button because it has a different shape (aspect-ratio 1:1), different sizing logic, and a **required** `label` prop for accessibility.

### Why a Separate Component

If IconButton were a variant of Button, developers would be tempted to use it without providing an accessible label. Making it a separate component with `label` as a required prop makes the accessibility contract enforced at the TypeScript level — it simply will not compile without it.

### Props Interface

```tsx
type IconButtonVariant = 'ghost' | 'outline' | 'destructive'
type IconButtonSize    = 'sm' | 'md' | 'lg'

interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon:     React.ReactNode     // required — the icon to render
  label:    string              // required — aria-label (MUST describe the action)
  variant?: IconButtonVariant   // default: 'ghost'
  size?:    IconButtonSize      // default: 'md'
  loading?: boolean
}
```

### Size Styles

```tsx
const sizeStyles: Record<IconButtonSize, string> = {
  sm: 'h-7 w-7',
  md: 'h-9 w-9',
  lg: 'h-11 w-11',
}
```

### Accessibility

The `label` prop maps to `aria-label`. It must describe the **action**, not the icon:

```tsx
// ✅ Correct — describes what happens
<IconButton icon={<Pencil size={15} />} label="Edit product" />

// ❌ Wrong — describes the icon
<IconButton icon={<Pencil size={15} />} label="Pencil" />
```

### Usage

```tsx
// Table row actions
<IconButton icon={<Eye size={15} />}    label="View order"    variant="ghost" />
<IconButton icon={<Pencil size={15} />} label="Edit product"  variant="ghost" />
<IconButton icon={<Trash2 size={15} />} label="Delete product" variant="destructive" />

// Topbar actions
<IconButton icon={<Bell size={18} />}   label="Open notifications" variant="ghost" size="md" />
```

## 4. Badge

Generic badge for labels, counts, and tags. Not for status display — use `StatusBadge` (CDS-04) or domain-specific badges (CDS-09) for status values.

### Props Interface

```tsx
type BadgeVariant = 'default' | 'secondary' | 'outline' | 'destructive'

interface BadgeProps {
  children:   React.ReactNode
  variant?:   BadgeVariant      // default: 'default'
  className?: string
}
```

### Variant Styles

```tsx
const variantStyles: Record<BadgeVariant, string> = {
  default:     'bg-primary/10 text-primary border-transparent',
  secondary:   'bg-muted text-muted-foreground border-transparent',
  outline:     'bg-transparent text-foreground border border-border',
  destructive: 'bg-destructive/10 text-destructive border-transparent',
}
```

### Usage

```tsx
<Badge variant="default">New</Badge>
<Badge variant="secondary">Draft</Badge>
<Badge variant="outline">Beta</Badge>
<Badge variant="destructive">Deprecated</Badge>
```

## 5. Input

### Props Interface

```tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?:         boolean           // applies red ring
  leftElement?:   React.ReactNode   // icon or text inside left edge
  rightElement?:  React.ReactNode   // icon or text inside right edge
}
```

### Implementation Notes

`leftElement` and `rightElement` are positioned absolutely inside a relative wrapper, with padding applied to the input to prevent text from overlapping the elements:

```tsx
export function Input({ error, leftElement, rightElement, className, ...props }: InputProps) {
  return (
    <div className="relative flex items-center">
      {leftElement && (
        <span className="absolute left-3 flex items-center pointer-events-none text-foreground-subtle">
          {leftElement}
        </span>
      )}
      <input
        {...props}
        aria-invalid={error ? 'true' : undefined}
        className={cn(
          'w-full h-9 rounded-[--radius-md] border border-border bg-background',
          'px-3 py-2 text-sm text-foreground',
          'placeholder:text-foreground-subtle',
          'transition-colors duration-150',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[--ring]',
          'disabled:cursor-not-allowed disabled:opacity-50',
          error && 'border-destructive focus-visible:ring-destructive',
          leftElement  && 'pl-9',
          rightElement && 'pr-9',
          className,
        )}
      />
      {rightElement && (
        <span className="absolute right-3 flex items-center pointer-events-none text-foreground-subtle">
          {rightElement}
        </span>
      )}
    </div>
  )
}
```

### Accessibility

- Always paired with `<Label>` via `FormField` — the `htmlFor`/`id` association is enforced at the `FormField` level
- `aria-invalid="true"` when `error={true}` — screen readers announce the field is invalid
- Error message is associated via `aria-describedby` (handled by `FormField`)

### Usage

```tsx
// Search input with icon
<Input
  type="text"
  placeholder="Search orders..."
  leftElement={<Search size={14} />}
/>

// With right action
<Input
  type="text"
  rightElement={<button onClick={clearInput}><X size={14} /></button>}
/>

// Error state (typically managed by React Hook Form)
<Input
  id="email"
  type="email"
  error={!!errors.email}
  aria-invalid={!!errors.email}
  aria-describedby="email-error"
/>
```

## 6. Textarea

### Props Interface

```tsx
interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?:   boolean
  resize?:  'none' | 'vertical' | 'both'   // default: 'vertical'
}
```

### Usage

```tsx
<Textarea
  id="notes"
  placeholder="Order notes..."
  rows={3}
  resize="vertical"
  error={!!errors.notes}
/>
```

## 7. Checkbox

Custom checkbox with indeterminate support — important for DataTable's select-all behaviour.

### Props Interface

```tsx
interface CheckboxProps {
  checked?:         boolean
  defaultChecked?:  boolean
  onCheckedChange?: (checked: boolean) => void
  disabled?:        boolean
  indeterminate?:   boolean           // for DataTable select-all
  label?:           string            // renders inline label
  id?:              string
  name?:            string
}
```

### Implementation Notes

The visual custom checkbox wraps a visually hidden native `<input type="checkbox">`:

```tsx
export function Checkbox({ checked, indeterminate, onCheckedChange, label, id, ...props }: CheckboxProps) {
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.indeterminate = !!indeterminate
    }
  }, [indeterminate])

  return (
    <label className="inline-flex items-center gap-2 cursor-pointer">
      {/* Visually hidden native input — handles all keyboard/AT interaction */}
      <input
        ref={inputRef}
        type="checkbox"
        id={id}
        checked={checked}
        onChange={(e) => onCheckedChange?.(e.target.checked)}
        aria-checked={indeterminate ? 'mixed' : checked}
        className="sr-only"
        {...props}
      />
      {/* Visual representation — aria-hidden since the real input handles semantics */}
      <span
        aria-hidden="true"
        className={cn(
          'h-4 w-4 rounded-[--radius-sm] border border-border',
          'flex items-center justify-center',
          'transition-colors duration-150',
          (checked || indeterminate) && 'bg-primary border-primary',
        )}
      >
        {indeterminate && <Minus size={10} className="text-white" />}
        {checked && !indeterminate && <Check size={10} className="text-white" />}
      </span>
      {label && <span className="text-sm text-foreground">{label}</span>}
    </label>
  )
}
```

### Accessibility

- Native `<input type="checkbox">` inside, visually hidden via `sr-only`
- All keyboard interaction, AT announcement, and focus management comes from the native input
- The visual custom box is `aria-hidden` — screen readers never interact with it
- `indeterminate` sets `aria-checked="mixed"` via the native input's indeterminate property

### Usage

```tsx
// Standalone
<Checkbox
  checked={isActive}
  onCheckedChange={setIsActive}
  label="Product active"
/>

// DataTable select-all
<Checkbox
  checked={allSelected}
  indeterminate={someSelected && !allSelected}
  onCheckedChange={handleSelectAll}
/>
```

## 8. RadioGroup

### Props Interface

```tsx
interface RadioOption {
  value:     string
  label:     string
  disabled?: boolean
}

interface RadioGroupProps {
  options:        RadioOption[]
  value?:         string
  defaultValue?:  string
  onChange?:      (value: string) => void
  orientation?:   'horizontal' | 'vertical'   // default: 'vertical'
  name:           string                       // required — native radio grouping
  id?:            string
}
```

### Accessibility

RadioGroup renders inside a `<fieldset>`. The `<legend>` is provided by the parent `FormField` via its `label` prop and `<fieldset>` wrapper. Arrow key navigation between options is handled natively by the browser for `<input type="radio">` groups — no custom keyboard handler needed.

### Usage

```tsx
<RadioGroup
  name="order-source"
  value={source}
  onChange={setSource}
  options={[
    { value: 'website',  label: 'Website' },
    { value: 'phone',    label: 'Phone' },
    { value: 'walk_in',  label: 'Walk-in' },
    { value: 'admin_created', label: 'Admin created' },
  ]}
/>
```

## 9. Switch

Toggle switch for boolean settings. Used in product active/inactive toggle, settings toggles.

### Props Interface

```tsx
interface SwitchProps {
  checked?:         boolean
  defaultChecked?:  boolean
  onCheckedChange?: (checked: boolean) => void
  disabled?:        boolean
  label?:           string
  id?:              string
}
```

### Accessibility

- `role="switch"` on the toggle element
- `aria-checked` reflects the current state
- Toggled via Space key (standard for switch role)
- `aria-disabled` when disabled

### Usage

```tsx
<Switch
  checked={product.is_active}
  onCheckedChange={(checked) => updateProductStatus(product.id, checked)}
  label="Product active"
/>
```

## 10. Label

### Props Interface

```tsx
interface LabelProps extends React.LabelHTMLAttributes<HTMLLabelElement> {
  required?:  boolean     // renders red asterisk after label text
  disabled?:  boolean     // muted colour (mirrors associated input)
}
```

### Notes

The asterisk for required fields is `aria-hidden="true"` — screen readers announce "required" via the associated input's `aria-required` attribute, not by reading "*".

### Usage

```tsx
<Label htmlFor="product-name" required>Product Name</Label>
<Label htmlFor="notes">Notes</Label>
```

## 11. Spinner

### Props Interface

```tsx
type SpinnerSize = 'sm' | 'md' | 'lg'

interface SpinnerProps {
  size?:  SpinnerSize   // default: 'md'
  label?: string        // aria-label, default: 'Loading'
}
```

### Size Styles

```tsx
const sizeStyles: Record<SpinnerSize, string> = {
  sm: 'h-3.5 w-3.5 border-[1.5px]',
  md: 'h-5   w-5   border-2',
  lg: 'h-7   w-7   border-2',
}
```

### Accessibility

```tsx
<span
  role="status"
  aria-label={label}
  className={cn('animate-spin rounded-full border-current border-t-transparent', sizeStyles[size])}
/>
```

### Usage

```tsx
<Spinner size="sm" label="Saving order..." />
<Spinner size="lg" label="Loading products" />
```

## 12. Skeleton

Skeleton loaders replace content while data is loading. They prevent layout shift and communicate to the user that content is incoming rather than absent.

### Props Interface

```tsx
interface SkeletonProps {
  className?: string    // controls width, height, radius — required for custom shapes
  lines?:     number    // renders N stacked skeleton lines (convenience prop)
}
```

### Notes

Skeleton is `aria-hidden="true"`. Screen readers should not announce loading skeletons — the `DataTable` component handles the loading announcement via `aria-busy` at the table level.

### Usage

```tsx
// Single skeleton bar
<Skeleton className="h-4 w-48 rounded-[--radius-sm]" />

// Avatar skeleton
<Skeleton className="h-8 w-8 rounded-full" />

// Multiple lines (e.g. text content placeholder)
<Skeleton lines={3} />

// DataTable row skeletons — inside DataTable when isLoading={true}
<Skeleton className="h-9 w-full" />
```

## 13. Divider

### Props Interface

```tsx
interface DividerProps {
  orientation?: 'horizontal' | 'vertical'   // default: 'horizontal'
  label?:       string                       // centred text label
  className?:   string
}
```

### Accessibility

`role="separator"` with `aria-orientation`.

### Usage

```tsx
<Divider />
<Divider label="or continue with" />
<Divider orientation="vertical" className="h-6" />
```

## 14. Avatar

Displays a user's profile image, with an initials fallback when no image is available.

### Props Interface

```tsx
type AvatarSize = 'sm' | 'md' | 'lg'

interface AvatarProps {
  src?:      string       // image URL
  alt?:      string       // image alt text — describe the person
  fallback:  string       // initials when no image (e.g. "JD" for Jane Doe)
  size?:     AvatarSize   // default: 'md'
}
```

### Size Styles

```tsx
const sizeStyles: Record<AvatarSize, string> = {
  sm: 'h-6  w-6  text-xs',
  md: 'h-8  w-8  text-sm',
  lg: 'h-10 w-10 text-base',
}
```

### Usage

```tsx
// With image
<Avatar
  src={user.avatar_url}
  alt="Jane Doe"
  fallback="JD"
  size="md"
/>

// Initials fallback (no src)
<Avatar fallback="AM" size="sm" alt="Admin user" />
```
