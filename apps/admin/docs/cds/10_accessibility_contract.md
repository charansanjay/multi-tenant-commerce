# CDS-10 — Accessibility Contract

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [Why Accessibility is Structural, Not Optional](#1-why-accessibility-is-structural-not-optional)
2. [Why From Day One](#2-why-from-day-one)
3. [WCAG 2.1 AA — What It Means in Practice](#3-wcag-21-aa--what-it-means-in-practice)
4. [Focus Ring Standard](#4-focus-ring-standard)
5. [Colour Contrast Standard](#5-colour-contrast-standard)
6. [Tier 1 — Simple Components](#6-tier-1--simple-components)
7. [Tier 2 — Moderate Components](#7-tier-2--moderate-components)
8. [Tier 3 — Complex Components](#8-tier-3--complex-components)
9. [Testing Requirements](#9-testing-requirements)
10. [ARIA Reference Quick Sheet](#10-aria-reference-quick-sheet)

## 1. Why Accessibility is Structural, Not Optional

Accessibility is not a feature added to components after they work. It is a structural property of each component — one that either exists from the start or requires rebuilding internals to add later.

Consider a custom Select component. If built correctly:

- It uses `role="combobox"` on the trigger and `role="listbox"` on the dropdown
- `aria-activedescendant` tracks the currently highlighted option
- Arrow keys navigate options, Home/End jump to first/last, type-ahead matches by character
- Screen readers announce the selected value and the number of options

If built without this contract — just a `<div>` that opens and closes — retrofitting accessibility means restructuring the DOM, adding ARIA, and implementing a keyboard event handler. That is not a minor addition. It is close to a rewrite.

This is why the accessibility contract is defined here, at the component system level, before a single module component is written. Every developer implementing a Tier 3 component knows exactly what they need to build.

## 2. Why From Day One

There is a tempting argument that accessibility can be done "later" — after the features are built and the business is running. This argument fails in practice for three reasons:

**Retrofitting is expensive.** As described above, adding accessibility to an already-shipped custom component often means restructuring it. The later you do it, the more code depends on the existing structure, and the more expensive the change.

**Staff are users too.** The portal is used by staff — some of whom may have visual impairments, motor disabilities, or use assistive technology. An inaccessible internal tool is a workplace equity issue, not just a legal one.

**WCAG AA is an NFR.** It is in the non-functional requirements document. It is not aspirational — it is a requirement. Building to spec from the start is always cheaper than building, shipping, and rebuilding.

## 3. WCAG 2.1 AA — What It Means in Practice

WCAG 2.1 AA covers four principles: Perceivable, Operable, Understandable, Robust. For this portal, the most directly relevant criteria are:

| Criterion | Level | What it means for us |
|---|---|---|
| 1.3.1 Info and Relationships | A | Semantic HTML — headings, lists, tables, labels. Not just visually structured, but structurally structured. |
| 1.4.1 Use of Colour | A | Colour alone cannot convey information. Status badges must have text labels. |
| 1.4.3 Contrast (Minimum) | AA | 4.5:1 for normal text, 3:1 for large text and UI components. |
| 1.4.4 Resize Text | AA | UI must be usable at 200% browser zoom. |
| 2.1.1 Keyboard | A | All functionality operable via keyboard. No mouse-only interactions. |
| 2.1.2 No Keyboard Trap | A | Focus must not be permanently trapped — except modals (which trap intentionally and release on close). |
| 2.4.3 Focus Order | A | Tab order must be logical and predictable. |
| 2.4.7 Focus Visible | AA | Keyboard focus indicator must be visible. |
| 3.2.2 On Input | A | UI must not change context unexpectedly on user input. |
| 4.1.2 Name, Role, Value | A | All UI components must have accessible name, role, and state/value. |
| 4.1.3 Status Messages | AA | Status messages (toasts, alerts) must be conveyed without requiring focus. |

## 4. Focus Ring Standard

Every interactive element must have a visible focus ring when navigated to via keyboard. This satisfies WCAG 2.4.7.

### The Rule

```css
/* Applied globally in globals.css */
:focus-visible {
  outline: 2px solid rgb(var(--ring));
  outline-offset: 2px;
}
```

**`focus-visible` not `focus`** — this is intentional. `focus-visible` only applies the ring during keyboard navigation. Mouse clicks do not show the ring. This is the correct modern pattern — sighted mouse users do not need a focus ring after clicking, but keyboard users absolutely do.

The `--ring` token resolves to `blue-700` in light mode and `blue-400` in dark mode — both meeting 3:1 contrast against their backgrounds as required by WCAG 2.4.11 (Focus Appearance, AA).

### Component-Level Focus

Some components require additional focus handling beyond the global rule:

- **Input/Textarea/Select:** Use `focus-visible:ring-2 focus-visible:ring-[--ring]` in place of the default browser outline for visual consistency
- **Checkbox/Switch:** The visually hidden native input's focus ring must be visually proxied on the custom visual element
- **Tabs:** Only the active tab has `tabIndex={0}` — inactive tabs are not in the tab order (use arrow keys)
- **DropdownMenu items:** Items are focusable via arrow key, not Tab — managed with `tabIndex={-1}` and `focus()` calls

## 5. Colour Contrast Standard

All text must meet 4.5:1 contrast ratio against its background (WCAG 1.4.3 AA for normal text).

### Token Contrast Pairs (Light Mode)

| Text token | Background | Contrast | Pass |
|---|---|---|---|
| `--foreground` (28 25 23) | `--background` (255 255 255) | ~18:1 | ✅ |
| `--foreground-muted` (87 83 78) | `--background` | ~7:1 | ✅ |
| `--foreground-subtle` (120 113 108) | `--background` | ~4.7:1 | ✅ |
| `--primary-foreground` (white) | `--primary` (29 78 216) | ~6.8:1 | ✅ |
| `--destructive-foreground` (white) | `--destructive` (220 38 38) | ~5.1:1 | ✅ |

### Status Badge Contrast (Light Mode)

All status badge text/background pairs were selected to meet 4.5:1:

| Badge | Text | Background | Contrast |
|---|---|---|---|
| Order pending | amber-900 | amber-100 | ~9.2:1 ✅ |
| Order confirmed | blue-900 | blue-100 | ~10.1:1 ✅ |
| Order preparing | violet-900 | violet-100 | ~10.4:1 ✅ |
| Order ready | cyan-900 | cyan-100 | ~8.6:1 ✅ |
| Order delivered | green-900 | green-100 | ~9.4:1 ✅ |
| Order cancelled | red-900 | red-100 | ~9.8:1 ✅ |

Dark mode pairs (inverted) achieve equivalent ratios.

### Important: Colour Never Alone

WCAG 1.4.1 prohibits using colour as the only visual means of conveying information. Every status badge includes a text label. No component in this system conveys status through colour alone — this is enforced structurally by making `label` a required prop on `StatusBadge`.

## 6. Tier 1 — Simple Components

These components use native HTML elements that carry accessibility semantics automatically. The accessibility overhead is minimal — correct HTML structure is sufficient.

| Component | Key requirements |
|---|---|
| `Button` | Native `<button>`, `aria-busy` during loading, `aria-disabled` when disabled |
| `IconButton` | Native `<button>`, `aria-label` is required (enforced by TypeScript) |
| `Input` | Native `<input>`, `aria-invalid` on error, `aria-describedby` to error/helper |
| `Textarea` | Same as Input |
| `Label` | Native `<label>` with `htmlFor` — correct association is the entire contract |
| `Spinner` | `role="status"`, `aria-label` |
| `Skeleton` | `aria-hidden="true"` — not announced to screen readers |
| `Divider` | `role="separator"`, `aria-orientation` |
| `Avatar` | `alt` on `<img>` when src present; initials are `aria-hidden` if alt is provided |
| `Badge` | Plain `<span>` — text content is the accessible name |
| `ProgressBar` | `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-label` |

## 7. Tier 2 — Moderate Components

These components require deliberate accessibility implementation beyond what native HTML provides.

### DataTable

```
<table aria-label="Orders" aria-busy={isLoading}>
  <thead>
    <tr>
      <th aria-sort="ascending">Order #</th>   ← sortable column
      <th aria-sort="none">Customer</th>
      <th>Status</th>                           ← non-sortable
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        <Checkbox label="Select order #1042" />  ← descriptive label per row
      </td>
      ...
    </tr>
  </tbody>
</table>
```

`aria-sort` values: `"ascending"`, `"descending"`, `"none"`. Remove the attribute entirely from non-sortable columns.

When `isLoading` changes to `true`, `aria-busy="true"` on `<table>` causes screen readers to announce the table is updating. When loading completes, `aria-busy` is removed (or set to false).

### Toast

```tsx
// Polite — for success/info/warning (does not interrupt)
<div role="status" aria-live="polite" aria-atomic="true">
  {toasts.filter(t => t.variant !== 'destructive').map(renderToast)}
</div>

// Assertive — for errors (interrupts immediately)
<div role="alert" aria-live="assertive" aria-atomic="true">
  {toasts.filter(t => t.variant === 'destructive').map(renderToast)}
</div>
```

`aria-atomic="true"` means the entire toast is announced as a unit when it appears, not word-by-word.

### Alert

- `role="alert"` for `destructive` / `warning` — immediate announcement
- `role="status"` for `info` / `success` — polite announcement

### Tabs

- `role="tablist"` on the container
- `role="tab"` on each tab button, `aria-selected`, `aria-controls`
- `role="tabpanel"` on each panel, `aria-labelledby`
- `tabIndex={0}` on active tab only; `tabIndex={-1}` on inactive tabs
- Arrow key navigation (not Tab) between tabs

### Pagination

- `<nav aria-label="Pagination">`
- `aria-current="page"` on the current page button
- Descriptive `aria-label` on Prev/Next/First/Last buttons: `"Go to previous page"` not `"Previous"`

### StatusBadge (all variants)

- Text label always visible — structural enforcement
- Colour never sole conveyor of status — structural enforcement (required `label` prop)

## 8. Tier 3 — Complex Components

These components require the most careful implementation. Build and test these first when starting implementation, as getting them wrong is expensive to fix later.

### Modal / ConfirmDialog / Drawer

All three share the same accessibility contract:

```
role="dialog"
aria-modal="true"
aria-labelledby → title element id
aria-describedby → description element id (when present)

On open:
  - Store reference to trigger element (document.activeElement)
  - Move focus to first focusable element OR initialFocusRef target
  - Lock body scroll

While open:
  - Trap focus — Tab and Shift+Tab cycle only inside the dialog
  - Escape key closes

On close:
  - Restore focus to stored trigger element
  - Unlock body scroll
```

**ConfirmDialog specific:** Default focus lands on the **Cancel button**. This is intentional — for destructive actions, the safe default is inaction.

### Select

```
Trigger element:
  role="combobox"
  aria-expanded
  aria-haspopup="listbox"
  aria-controls → listbox id
  aria-activedescendant → id of currently highlighted option

Dropdown:
  role="listbox"
  id (referenced by trigger's aria-controls)

Each option:
  role="option"
  id (referenced by trigger's aria-activedescendant)
  aria-selected → true for current value
  aria-disabled → true for disabled options
```

Keyboard contract:

- Arrow Down/Up: navigate options
- Home/End: jump to first/last
- Type-ahead: match by first character
- Enter/Space: select focused option
- Escape: close without selecting
- Tab: close (focus moves to next element)

### Combobox

Same as Select, plus:

- `aria-autocomplete="list"` on the input
- `aria-busy="true"` on listbox while async results load
- Live region announces result count: `"3 results available"` — this is important for screen reader users who cannot see the list populate

### DropdownMenu

```
Trigger:
  aria-haspopup="menu"
  aria-expanded
  aria-controls → menu id

Menu:
  role="menu"
  id

Each item:
  role="menuitem"
  aria-disabled for disabled items (tabIndex="-1")

Separator:
  role="separator"
```

Keyboard contract:

- Arrow Down/Up: navigate items
- Home/End: jump to first/last
- A–Z: type-ahead to next item starting with that character
- Enter/Space: activate item
- Escape: close, return focus to trigger
- Tab: close (focus moves on naturally — menus do not trap focus)

### Tooltip

```
Trigger:
  aria-describedby → tooltip id

Tooltip content:
  role="tooltip"
  id
```

Critical: Tooltip must appear on **both hover AND keyboard focus**. Focus-only trigger is a common bug — always add both `onFocus`/`onBlur` handlers alongside `onMouseEnter`/`onMouseLeave`.

Dismiss on Escape when visible.

### DatePicker

Calendar as `role="grid"`:

```
Calendar panel:
  role="dialog"
  aria-label="Choose date"

Calendar grid:
  role="grid"

Week rows:
  role="row"

Day cells:
  role="gridcell"

Day buttons:
  aria-label="Monday, March 23, 2026"  ← full locale-formatted date
  aria-selected="true" for selected date
  aria-disabled="true" for out-of-range dates

Month heading:
  aria-live="polite"  ← announces new month name when navigating
```

Keyboard contract:

- Arrow Right/Left: next/previous day
- Arrow Down/Up: same day next/previous week
- Page Down/Up: next/previous month
- Home/End: first/last day of current week
- Enter/Space: select day
- Escape: close without selecting

## 9. Testing Requirements

### Automated Testing

Run on every PR via CI:

```bash
# Axe accessibility scan on component stories/pages
npx axe --include='.admin-layout' --exit

# Playwright a11y checks on critical flows
test('Orders table is accessible', async ({ page }) => {
  await page.goto('/orders')
  const results = await new AxeBuilder({ page }).analyze()
  expect(results.violations).toEqual([])
})
```

### Manual Testing

Per release, spot-check with:

| Tool | What to test |
|---|---|
| Keyboard only (no mouse) | All Tier 2 and Tier 3 components: open/close modals, navigate dropdowns, use date picker, submit forms |
| NVDA (Windows) + Chrome | Toast announcements, table updates, form errors, modal opening |
| VoiceOver (macOS) + Safari | Same as NVDA coverage |
| Browser zoom 200% | All pages — nothing should overflow or become unusable |
| Colour contrast analyser | Status badges, primary buttons, muted text on backgrounds |

### Focus Management Checklist

For every Modal/Drawer/Dialog implementation, verify:

- [ ] Focus moves into the overlay on open
- [ ] Tab cycles only through elements inside the overlay
- [ ] Shift+Tab wraps correctly
- [ ] Escape closes
- [ ] Focus returns to trigger on close
- [ ] Body does not scroll while overlay is open
- [ ] Screen reader announces dialog title on open

## 10. ARIA Reference Quick Sheet

A quick reference for the ARIA patterns used most frequently in this system:

```text
Live regions:
  aria-live="polite"     — announces when user is idle (toasts, status updates)
  aria-live="assertive"  — announces immediately, interrupting (errors, alerts)
  aria-atomic="true"     — announce the whole region, not just changed parts

Dialogs:
  role="dialog"          — identifies a dialog container
  aria-modal="true"      — tells AT that background content is inert
  aria-labelledby        — references the dialog title element id
  aria-describedby       — references the dialog description element id

Buttons:
  aria-label             — accessible name when no visible text (IconButton)
  aria-expanded          — true/false for toggle buttons (dropdowns, accordions)
  aria-pressed           — true/false for toggle/switch semantics
  aria-busy              — true when action is in progress (Button loading)
  aria-disabled          — communicates disabled state to AT (use with tabIndex="-1")

Forms:
  aria-invalid           — true when field has a validation error
  aria-required          — true for required fields
  aria-describedby       — references error message or helper text id

Tables:
  aria-sort              — "ascending" | "descending" | "none" on sortable headers
  aria-busy              — true on <table> while data is loading

Lists / Menus:
  role="menu"            — interactive menu (DropdownMenu)
  role="menuitem"        — individual menu option
  role="listbox"         — selection list (Select, Combobox dropdown)
  role="option"          — individual selectable option
  aria-selected          — true for selected option in listbox
  aria-activedescendant  — tracks keyboard focus within a managed container

Tabs:
  role="tablist"         — container for tabs
  role="tab"             — individual tab
  role="tabpanel"        — content panel associated with a tab
  aria-selected          — true for active tab
  aria-controls          — tab → panel id reference
  aria-labelledby        — panel → tab id reference

Combobox:
  role="combobox"        — combined input + listbox (Select, Combobox trigger)
  aria-autocomplete      — "list" when dropdown filters based on input
  aria-haspopup          — "listbox" | "menu" | "dialog"

Landmarks:
  <nav aria-label="..."> — named navigation regions (Sidebar, Breadcrumb, Pagination)
  <main>                 — primary page content
  role="region" aria-label="..." — named content region (if <section> not appropriate)
```
