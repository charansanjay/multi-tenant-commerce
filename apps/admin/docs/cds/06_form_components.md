# CDS-06 — Form Components

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [Form Architecture](#1-form-architecture)
2. [Form Layout Decision — Single Column](#2-form-layout-decision--single-column)
3. [FormField](#3-formfield)
4. [Select](#4-select)
5. [Combobox](#5-combobox)
6. [DatePicker](#6-datepicker)

## 1. Form Architecture

Forms in this portal follow a consistent three-layer pattern:

```text
Zod schema          ← defines shape, types, validation rules
React Hook Form     ← manages field state, triggers validation
Server Action       ← receives validated data, re-validates, writes to DB
```

The form components in this document are the **UI layer** — they are the visual building blocks that React Hook Form controls. They do not contain validation logic. They receive error state from React Hook Form via the `FormField` wrapper and render it consistently.

This separation means:

- Validation rules live in one place (the Zod schema)
- Components never need to know about business validation rules
- The same component (e.g. `Select`) works identically in every form

## 2. Form Layout Decision — Single Column

All forms in this system use a **single column layout** — one field per row, full width.

This was a deliberate choice over the alternative (two-column grid with related fields side by side).

### Why single column for an admin portal?

Two-column forms feel efficient on paper but introduce cognitive overhead. The eye has to scan both horizontally and vertically to find the next field. In a fast-paced operational context where staff are filling in forms repeatedly (creating orders, editing products), single column is faster — the next field is always directly below the current one.

Single column also scales better to varying window sizes and is simpler to implement consistently. There are no decisions about which fields share a row, no edge cases with an odd number of fields.

The only exception: fields where the relationship is visually inseparable (e.g. a date range with From/To pickers side by side) may be placed inline within a single `FormField` using a flex row layout. This is handled per-field, not at the form layout level.

## 3. FormField

The wrapper that gives every form field consistent structure: label, control, error message, and helper text.

### Why FormField is Essential

Without a FormField wrapper, each developer makes their own decisions about how to lay out a label and its input, where to show errors, and how to space things. Over 11 modules with multiple forms each, this produces visible inconsistency.

FormField enforces:

- Label always above the control
- Error message always below in destructive red
- Helper text always below in muted grey (hidden when error is shown)
- Consistent vertical spacing between fields

### Props Interface

```tsx
interface FormFieldProps {
  label:        string
  htmlFor:      string           // must match the id of the child input
  required?:    boolean          // shows asterisk on label
  error?:       string           // error message string from React Hook Form
  helperText?:  string           // shown when no error
  children:     React.ReactNode  // the input control
  className?:   string
}
```

### Implementation

```tsx
export function FormField({
  label, htmlFor, required, error, helperText, children, className,
}: FormFieldProps) {
  const errorId  = `${htmlFor}-error`
  const helperId = `${htmlFor}-helper`

  return (
    <div className={cn('flex flex-col gap-1.5', className)}>
      <Label htmlFor={htmlFor} required={required}>
        {label}
      </Label>

      {/* Clone child to inject aria-describedby */}
      {React.cloneElement(children as React.ReactElement, {
        'aria-describedby': error ? errorId : helperText ? helperId : undefined,
      })}

      {error && (
        <p id={errorId} className="text-xs text-destructive" role="alert" aria-live="polite">
          {error}
        </p>
      )}

      {!error && helperText && (
        <p id={helperId} className="text-xs text-foreground-subtle">
          {helperText}
        </p>
      )}
    </div>
  )
}
```

### Accessibility

- `Label` is associated with the control via `htmlFor`/`id`
- Error message uses `role="alert"` and `aria-live="polite"` — screen readers announce validation errors as they appear without moving focus
- `aria-describedby` on the input points to either the error or helper text ID, giving screen readers additional context when the field is focused

### Usage

```tsx
// With React Hook Form
const { register, formState: { errors } } = useForm<ProductSchema>()

<FormField
  label="Product Name"
  htmlFor="product-name"
  required
  error={errors.name?.message}
  helperText="Maximum 200 characters."
>
  <Input
    id="product-name"
    {...register('name')}
    error={!!errors.name}
  />
</FormField>

<FormField
  label="Category"
  htmlFor="category"
  required
  error={errors.category_id?.message}
>
  <Select
    id="category"
    options={categoryOptions}
    value={watch('category_id')}
    onChange={(val) => setValue('category_id', val)}
    error={!!errors.category_id}
  />
</FormField>

<FormField
  label="Description"
  htmlFor="description"
  helperText="Optional. Shown to customers on the menu."
>
  <Textarea id="description" {...register('description')} rows={3} />
</FormField>
```

### Form Layout Pattern

Fields are stacked vertically using a `flex flex-col gap-4` container:

```tsx
<form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
  <FormField label="First Name" htmlFor="first-name" required error={errors.first_name?.message}>
    <Input id="first-name" {...register('first_name')} error={!!errors.first_name} />
  </FormField>

  <FormField label="Last Name" htmlFor="last-name" required error={errors.last_name?.message}>
    <Input id="last-name" {...register('last_name')} error={!!errors.last_name} />
  </FormField>

  <FormField label="Email" htmlFor="email" error={errors.email?.message}>
    <Input id="email" type="email" {...register('email')} error={!!errors.email} />
  </FormField>

  <div className="flex justify-end gap-3 pt-2">
    <Button variant="outline" type="button" onClick={onClose}>Cancel</Button>
    <Button variant="primary" type="submit" loading={isSubmitting}>Save</Button>
  </div>
</form>
```

## 4. Select

Custom single-value select. Renders a trigger button + dropdown list. Built from scratch — no native `<select>` element.

### Why Not Native Select

Native `<select>` has inconsistent styling across browsers and operating systems. It cannot be styled to match the design system. The custom Select gives full visual control while implementing the correct ARIA semantics manually.

### Props Interface

```tsx
interface SelectOption {
  value:     string
  label:     string
  disabled?: boolean
}

interface SelectProps {
  options:        SelectOption[]
  value?:         string
  defaultValue?:  string
  onChange?:      (value: string) => void
  placeholder?:   string
  disabled?:      boolean
  error?:         boolean
  id?:            string
  className?:     string
}
```

### Keyboard Navigation

| Key | Behaviour |
|---|---|
| Enter / Space | Opens dropdown when trigger focused; selects option when list open |
| Arrow Down | Opens dropdown; moves to next option |
| Arrow Up | Moves to previous option |
| Home | Moves to first option |
| End | Moves to last option |
| A–Z | Type-ahead selection |
| Escape | Closes dropdown |
| Tab | Closes dropdown, moves to next focusable element |

### Accessibility

```
role="combobox" on trigger
  aria-expanded         — true/false
  aria-haspopup="listbox"
  aria-controls         — references listbox id

role="listbox" on dropdown
  aria-label            — "Options"

role="option" on each item
  aria-selected         — true for current value
  aria-disabled         — true for disabled options

aria-activedescendant on trigger — references the currently focused option id
```

### Usage

```tsx
// Controlled (with React Hook Form)
<Select
  id="status"
  options={[
    { value: 'active',   label: 'Active' },
    { value: 'inactive', label: 'Inactive' },
  ]}
  value={watch('status')}
  onChange={(val) => setValue('status', val as ProductStatus)}
  error={!!errors.status}
/>

// Standalone filter
<Select
  options={ORDER_STATUS_OPTIONS}
  value={statusFilter}
  onChange={setStatusFilter}
  placeholder="All statuses"
/>
```

## 5. Combobox

Select with text search/filter. Used when the option list is long or when users need to search rather than scroll — for example, selecting a customer when creating an order.

### Combobox vs Select

| Use | Component |
|---|---|
| Short list (< 10 options), user knows options | `Select` |
| Long list, or user needs to search | `Combobox` |
| Async server search (customer lookup, product search) | `Combobox` with `onSearch` |

### Props Interface

```tsx
interface ComboboxProps {
  options:       SelectOption[]
  value?:        string
  onChange?:     (value: string) => void
  onSearch?:     (query: string) => void    // for async server-side search
  placeholder?:  string
  loading?:      boolean                    // shows spinner while searching
  empty?:        string                     // "No results" message, default: 'No results found'
  disabled?:     boolean
  error?:        boolean
  id?:           string
  className?:    string
}
```

### Implementation Notes

For **async search** (`onSearch` provided):

- Input value is uncontrolled locally for typing
- `onSearch` is debounced 300ms before firing
- `loading` shows a spinner in the dropdown while results load
- `options` are replaced with new results when they arrive

For **local search** (`onSearch` not provided):

- Filtering runs client-side against the full `options` array
- Case-insensitive substring match on `option.label`

### Accessibility

Same as Select plus:

- `aria-autocomplete="list"` on input
- `aria-busy="true"` on listbox while loading
- When results update, a live region announces: `"X results available"` — so screen reader users know the list changed without needing to navigate into it

### Usage

```tsx
// Customer selection in order form — async
<Combobox
  id="customer"
  options={customerResults}
  value={watch('customer_id')}
  onChange={(val) => setValue('customer_id', val)}
  onSearch={handleCustomerSearch}
  loading={isSearchingCustomers}
  placeholder="Search by name or email..."
  empty="No customers found. Try a different search."
  error={!!errors.customer_id}
/>

// Product variant selection — local filter
<Combobox
  id="variant"
  options={variantOptions}
  value={selectedVariantId}
  onChange={setSelectedVariantId}
  placeholder="Select size..."
/>
```

## 6. DatePicker

Single date selection. Uses `date-fns` for all calendar logic and locale-aware formatting.

### Why DatePicker is Complex

DatePicker is a Tier 3 accessibility component. The calendar is a `role="grid"` with keyboard navigation across days, months, and years. Getting this right from scratch is genuinely involved — see the accessibility section below.

### Props Interface

```tsx
interface DatePickerProps {
  value?:        Date
  onChange?:     (date: Date | undefined) => void
  placeholder?:  string
  minDate?:      Date
  maxDate?:      Date
  disabled?:     boolean
  error?:        boolean
  locale?:       Locale      // date-fns Locale, default: enUS
  id?:           string
  className?:    string
}
```

### Locale Awareness

DatePicker renders month names, weekday names, and date formats according to the active locale. This satisfies NFR-I-02 (locale-aware date formatting):

```tsx
import { cs, de, enUS } from 'date-fns/locale'

const localeMap = { en: enUS, cs: cs, de: de }

// Inside DatePicker
const activeLocale = localeMap[currentAppLocale] ?? enUS

// Format the trigger button display
format(value, 'PPP', { locale: activeLocale })
// en: "March 23rd, 2026"
// cs: "23. března 2026"
// de: "23. März 2026"
```

### Calendar Structure

```text
DatePicker
├── Trigger (Input-style button showing formatted date or placeholder)
└── CalendarPanel (Popover)
    ├── Header
    │   ├── PrevMonth button (aria-label="Previous month")
    │   ├── MonthYear heading (aria-live="polite" — announces month changes)
    │   └── NextMonth button (aria-label="Next month")
    └── Grid (role="grid")
        ├── Weekday headers (role="columnheader", aria-label="Monday" etc.)
        └── Day cells (role="gridcell")
            └── Day button (role="button", aria-selected, aria-disabled for out-of-range)
```

### Keyboard Navigation

| Key | Behaviour |
|---|---|
| Enter / Space | Opens calendar; selects focused day |
| Arrow Right | Next day |
| Arrow Left | Previous day |
| Arrow Down | Same day next week |
| Arrow Up | Same day previous week |
| Page Down | Next month |
| Page Up | Previous month |
| Home | First day of current week |
| End | Last day of current week |
| Escape | Closes calendar without selecting |

### Accessibility

- Calendar panel is `role="dialog"` with `aria-label="Choose date"`
- The grid is `role="grid"`, rows are `role="row"`, cells are `role="gridcell"`
- Each day button has `aria-label` with full date: `"Monday, March 23, 2026"` (locale-formatted)
- `aria-selected="true"` on the selected day
- `aria-disabled="true"` on days outside `minDate`/`maxDate`
- Month header uses `aria-live="polite"` — screen readers announce the new month name when the user navigates between months
- Focus is managed: opening the calendar focuses the selected date (or today); closing returns focus to the trigger

### Usage

```tsx
// Coupon expiry date
<FormField
  label="Expiry Date"
  htmlFor="expiry-date"
  error={errors.valid_until?.message}
  helperText="Leave empty for no expiry."
>
  <DatePicker
    id="expiry-date"
    value={watch('valid_until') ? new Date(watch('valid_until')) : undefined}
    onChange={(date) => setValue('valid_until', date?.toISOString())}
    minDate={new Date()}
    placeholder="No expiry"
    locale={currentDateFnsLocale}
    error={!!errors.valid_until}
  />
</FormField>

// Order date filter
<DatePicker
  value={dateFilter}
  onChange={setDateFilter}
  placeholder="Filter by date"
  locale={currentDateFnsLocale}
/>
```
