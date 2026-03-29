# CDS-01 — Overview & Architecture Decisions

**Project:** Multi-Tenant Commerce - Admin portal
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What is this Design System?](#1-what-is-this-design-system)
2. [Why a Design System before scaffolding?](#2-why-a-design-system-before-scaffolding)
3. [Full Custom — The Decision and Why](#3-full-custom--the-decision-and-why)
4. [Why shadcn/ui Is Excluded](#4-why-shadcnui-is-excluded)
5. [Positioning Logic — DIY first](#5-positioning-logic--diy-first)
6. [Variant Pattern — Record Lookups](#6-variant-pattern--record-lookups)
7. [Accessibility — WCAG AA from Day One](#7-accessibility--wcag-aa-from-day-one)
8. [Summary of All Decisions](#8-summary-of-all-decisions)
9. [Document Index](#9-document-index)

## 1. What is this Design System?

The Component Design System is the **shared visual and behavioural language** of the Multi-Tenant Commerce Administrator Portal. It defines:

- The design tokens (colours, typography, spacing, radius, shadows) that every component references
- The full inventory of shared components with their props API as TypeScript interfaces
- The accessibility contract every component must honour
- The patterns and conventions that keep every module consistent

This is not a component library in the npm package sense. Every component is **owned directly in the codebase** — there is no external dependency to update or break. The components live in `src/components/ui/` and are fully editable.

The goal is that when a developer opens any module — Orders, Customers, Catalog, Settings — they already have a vocabulary of components to work with. They do not make one-off styling decisions. They do not reinvent a table toolbar. They reach into the design system and compose.

## 2. Why a Design System before Scaffolding?

This step comes before project scaffold (Step 9) deliberately.

If you scaffold the project first and start building Module 1 without a design system, every developer makes their own micro-decisions: how big should this button be? What colour is a warning badge? How does this dropdown behave on keyboard? By Module 3, the UI is already drifting. Fixing visual inconsistency after the fact is significantly more expensive than defining the system upfront.

The design system session is a one-time investment that pays back on every module. Once it is done:

- Developers have a component vocabulary before writing a single line of feature code
- Design decisions are not re-litigated per module
- Visual consistency is structural, not reliant on discipline

## 3. Full Custom — The Decision and Why

### The question

The question raised during planning was: since we will invest significant time
building these components, should they use shadcn/ui as a foundation, use Radix
UI primitives directly, or be built fully from scratch?

Each option is legitimate. The answer depends on what you are optimising for.

### What each option actually gives you

**shadcn/ui** is not a runtime dependency — it copies source code into your
project via CLI and you own every file. But it brings two things with it: a
specific visual design language with its own conventions, and Radix UI as the
accessibility foundation underneath. Both create implicit coupling. The visual
layer fights your own design system. The Radix dependency travels into every
future project that uses your components.

**Radix UI** is a headless accessibility primitives library — no visual opinions
whatsoever, just battle-tested behaviour: focus trapping in modals, keyboard
navigation in dropdowns, ARIA roles in selects, screen reader announcements in
toasts. It is a runtime dependency, but a narrow and stable one. It does not
dictate how anything looks.

**Full custom** means you own everything — the visual layer and the behaviour
layer. No external lineage, no inherited conventions, no dependency chain.

### The decision

**Default: full custom.** The component system is built from scratch with no
shadcn and no Radix. This is the primary approach for all components.

**Conditional fallback: Radix UI for Tier 3 components only.** The hard
interactive components — Modal, Select, Combobox, DatePicker, DropdownMenu —
require significant accessibility work: focus trapping, keyboard navigation,
ARIA contracts, viewport-aware positioning. If building any of these to WCAG AA
standard from scratch proves too costly during implementation, Radix primitives
are used as the behaviour foundation for that specific component. The visual
layer is still built fully custom on top. Radix handles the plumbing; we own
the design.

**Excluded entirely: shadcn/ui.** It is not used at any point. Its visual
conventions would conflict with this design system, and its presence would
anchor every future use of these components to its dependency chain.

### Why this is the right balance

The components that carry real project value — `DataTable`, `Modal`,
`ConfirmDialog`, `FormField`, `PageHeader`, `StatusBadge`, `StatCard` — are
valuable because they encode *your* design language, *your* props API, *your*
variant system. That layer is genuinely portable regardless of what handles
focus trapping underneath.

Spending weeks perfecting WCAG-compliant keyboard navigation on a `DatePicker`
from scratch, when Radix already solves that problem correctly, is not a
principled stance — it is waste. The conditional fallback exists to protect
implementation time without compromising the ownership of the design layer.

The tradeoff is honest: full custom is more work than shadcn. The accessibility
contract in CDS-10 is explicit about which components require the most care,
and which are straightforward to build correctly without any external help.

## 4. Why shadcn/ui Is Excluded

shadcn/ui is excluded entirely — not because it is a poor tool, but because it
is the wrong fit for this specific goal.

Even though shadcn copies source into your project and you technically "own"
each file, it carries two things that conflict with this design system: a
pre-built visual language with its own conventions, and Radix UI as an implicit
foundational dependency baked into every component. Fighting the shadcn visual
layer to match your own design tokens is friction that compounds across every
component. And every future project that uses your component library would carry
Radix not as a deliberate choice but as inherited baggage.

Radix UI itself is a different matter — it is a deliberate, scoped fallback for
Tier 3 components where WCAG AA compliance from scratch is genuinely costly.
That is a conscious decision, not an inherited one. See Section 3 for the full
decision breakdown.

## 5. Positioning Logic — DIY First

Dropdowns, tooltips, popovers, and select lists all require **floating element positioning**: placing a panel relative to its trigger without overflowing the viewport.

This is genuinely non-trivial. You need to:

- Calculate available space above, below, left, right of the trigger
- Flip the panel to the opposite side if the preferred side overflows
- Reposition on scroll and resize
- Handle edge cases at screen corners

[Floating UI](https://floating-ui.com/) is a tiny, framework-agnostic library that handles exactly this problem. It is not a component library — it is a positioning math utility. Radix, Material UI, and Headless UI all use it internally.

**Our decision:** DIY positioning first. If the viewport collision detection logic becomes genuinely complex during implementation, reach for Floating UI at that point. It is a narrow, well-scoped utility that does not compromise the "full custom" principle — it is closer to using `date-fns` for date math than to adopting a component library.

## 6. Variant Pattern — Record Lookups

All component variants (button styles, badge colours, sizes) are defined using plain TypeScript `Record<Variant, string>` lookups.

### Why not inline conditionals?

```tsx
// ❌ Inline conditionals — gets unreadable fast
className={`btn ${size === 'sm' ? 'px-3 py-1' : size === 'lg' ? 'px-5 py-3' : 'px-4 py-2'} ${variant === 'destructive' ? 'bg-red-600' : variant === 'ghost' ? 'bg-transparent' : 'bg-blue-600'}`}
```

This is fine for one-off cases. As a system-wide pattern across 30+ components it becomes unreadable and error-prone.

### Why not CVA (class-variance-authority)?

CVA is a small library that provides a structured API for defining variants. It is well-designed. But it is an additional dependency, and everything it does can be expressed cleanly with plain TypeScript.

### The Record pattern

```tsx
type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'destructive' | 'outline'

const variantStyles: Record<ButtonVariant, string> = {
  primary:     'bg-primary text-primary-foreground hover:bg-primary-hover',
  secondary:   'bg-secondary text-secondary-foreground border border-border',
  ghost:       'bg-transparent text-foreground hover:bg-muted',
  destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive-hover',
  outline:     'border border-border bg-transparent text-foreground hover:bg-muted',
}

// Usage
const classes = variantStyles[variant]
```

This is fully type-safe (TypeScript will error if you use an undefined variant), readable, easy to extend, and has zero dependencies. It is the pattern used across every component in this system.

## 7. Accessibility — WCAG AA from Day One

Accessibility is not a feature to add later. It is a structural decision made at the component level.

The NFR document requires WCAG 2.1 AA compliance. This means:

- All interactive elements are keyboard-operable
- Colour contrast meets 4.5:1 minimum for normal text
- Screen readers can navigate and understand all content
- No information is conveyed by colour alone

The reason this must be decided at the design system level — not left to individual module developers — is that accessibility on complex components (modals, dropdowns, selects, date pickers) requires specific implementation patterns. A developer building an Orders feature should not need to research focus trapping. The `Modal` component should handle it correctly so the developer never thinks about it.

This is the most honest reason why full custom is harder than using shadcn as a
foundation: Radix handles WCAG AA on all its primitives out of the box. For
simple components — Button, Badge, Input, Spinner — we implement accessibility
ourselves, which is straightforward. For complex Tier 3 components where the
accessibility work is genuinely costly, Radix is available as a deliberate
fallback (see Section 3). We have tiered the accessibility contract in CDS-10
to be explicit about which components require the most careful implementation
and which are candidates for the Radix fallback.

### Why "from day one" matters

Retrofitting accessibility is significantly more expensive than building it in. It often requires restructuring component internals, not just adding `aria-label` attributes. Starting with the correct semantic structure, focus management, and ARIA contract from the first version means the component is correct for its entire lifetime.

## 8. Summary of All Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Component foundation | Full custom — no shadcn; Radix as conditional fallback only | Maximum portability; Radix reserved for Tier 3 components if WCAG AA cost is too high from scratch |
| Positioning library | DIY first; Floating UI if complexity demands | Avoid dependency for straightforward cases; fallback available |
| Variant definition pattern | `Record<Variant, string>` TypeScript lookups | Type-safe, readable, zero dependencies, scales well |
| Accessibility commitment | WCAG 2.1 AA from day one | NFR requirement; retrofitting is expensive |
| Styling system | Tailwind CSS 4 + CSS custom properties | Token-based theming, no config file required |
| Icon library | Lucide React | Tree-shakeable, consistent stroke style |
| Theme | Warm & approachable + classic admin feel | Professional, functional, not fatiguing for all-day use |
| Primary colour | `blue-700` — `#1D4ED8` | Trust, professionalism; shiftable to amber later via token |
| Dark mode | Both light and dark; light is default | Staff comfort; required by NFR |
| Typography | Geist via `next/font` | Modern, clean; self-hosted, zero layout shift |
| Body text size | 13px sm / 15px base — compact scale | Data-dense admin UI; consistent with Linear, Vercel, GitHub |
| Border radius | Subtle — `sm` 4px, `md` 6px, `lg` 8px | Slightly softened, professional; not sharp, not bubbly |
| Button loading width | Maintains original width | No layout shift during async actions |
| IconButton | Separate component from Button | Different shape (square), different usage context |
| DataTable toolbar | Compound component pattern | Composable, readable, flexible without being a free-for-all |
| Modal vs ConfirmDialog | Two separate components | ConfirmDialog's minimal API is too valuable to collapse into Modal |
| Form layout | Single column | Simple, consistent, no cognitive overhead |
| Drawer sizes | Configurable — `sm` / `md` / `lg` / `full` | Order detail needs `md`; other use cases may need more |

## 9. Document Index

| Document | Contents |
|---|---|
| **CDS-01** — This document | Overview, decisions, rationale |
| **CDS-02** — Design Tokens | Colours, typography, spacing, radius, shadows, dark mode |
| **CDS-03** — Primitives | Button, IconButton, Badge, Input, Textarea, Checkbox, RadioGroup, Switch, Label, Spinner, Skeleton, Divider, Avatar |
| **CDS-04** — Feedback Components | Toast, Alert, StatusBadge, ProgressBar |
| **CDS-05** — Overlay Components | Modal, ConfirmDialog, Drawer, Tooltip, Popover, DropdownMenu |
| **CDS-06** — Form Components | FormField, Select, Combobox, DatePicker |
| **CDS-07** — Data Display | DataTable, Pagination, EmptyState, Card, StatCard |
| **CDS-08** — Navigation & Layout | Sidebar, Topbar, PageContainer, PageHeader, Tabs, Breadcrumb |
| **CDS-09** — Domain Components | OrderStatusBadge, PaymentStatusBadge, ProductStatusBadge, RoleBadge |
| **CDS-10** — Accessibility Contract | Tier breakdown, ARIA contracts, focus ring, colour contrast |
