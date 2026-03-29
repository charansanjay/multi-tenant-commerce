# Module 01 — Auth + Layout Shell

## Current step: 7 — Implementation

## Step progress

- [x] Step 1 — Feature Architecture written
- [x] Step 2 — CDS component pre-check done
- [x] Step 3 — Screen mockups approved (login + shell)
- [x] Step 4 — Full module mockup approved
- [x] Step 5 — Go / No-Go: **GO**
- [ ] Step 6 — Supabase layer review
- [ ] Step 7 — Implementation
- [ ] Step 8 — Testing
- [ ] Step 9 — Review and refactor
- [ ] Step 10 — Close issues, update roadmap

## Feature Architecture

`apps/admin/modules/auth/FEATURE_ARCH.md`

Read this before implementing anything. It defines every file, every
component, every Server Action, every Supabase query for this module.

## Approved mockups

Open these in a browser before implementing any component.
Pixel-match the approved mockups — do not deviate without explicit approval.

| Screen | File |
|---|---|
| Login page (all 5 states) | `.claude/modules/01_auth/mockups/01_login.html` |
| Admin layout shell | `.claude/modules/01_auth/mockups/02_admin_shell.html` |

## CDS components — build order for Step 7

Build these before the module features that depend on them:

1. `FormField` (CDS-06) — login form field wrapper
2. `Select` (CDS-06) — language selector in Topbar
3. `Tooltip` (CDS-05) — sidebar flyout item labels on keyboard focus
4. `DropdownMenu` (CDS-05) — Topbar user menu

Then implement module features in this order:

1. `LoginForm` — uses Button, Input, FormField, Spinner
2. `proxy.ts` — route guard, no CDS components
3. `Sidebar` — uses Tooltip, reads `useUIStore`, role-filtered nav
4. `Topbar` — uses Avatar, Select, DropdownMenu, IconButton
5. `app/(admin)/layout.tsx` — composes Sidebar + Topbar + PageContainer
6. `signOut.ts` Server Action
7. `setLocale.ts` Server Action
8. `useUIStore` Zustand store
9. `useCurrentUser` hook
10. Placeholder `/dashboard` page — uses PageHeader

## Key design decisions (locked — do not change without approval)

### Sidebar

- Background: `#2a2a36` (warm purple-grey) — token: `--sidebar-bg`
- Always 72px wide — never collapses
- Unselected item text/icon: `#c8c8d4` — token: `--sidebar-item-text`
- Hover: bg `#20202b`, text `#e5e5ef`
- Active: bg `#20202b`, amber `#fcd34d` text, `#f59e0b` left border (3px)
- Item labels: `text-transform: capitalize`, 11px
- Catalog nav: flyout panel on hover, not inline expand
- Sidebar stays dark regardless of page dark mode toggle

### Topbar

- Height: 58px, white background, 1px bottom border
- Left: logo mark + "Admin Portal" title + tenant name + separator + breadcrumb
- Right: language selector (EN/CS/DE) + dark mode toggle + notification bell + user pill
- Dark mode toggle affects content area only — sidebar always stays dark

### Primary colour

- Amber `#f59e0b` — token: `--primary`
- Hover: `#d97706` — token: `--primary-hover`
- All buttons, focus rings, active states use this

### Typography

- Body default: 15px (`text-sm`)
- Meta / labels: 13px (`text-xs`)
- Page titles: 22px (`text-xl`)

## GitHub issues

| Issue | Title | Status |
|---|---|---|
| #12 | [Auth] Login page — UI and form | Open |
| #13 | [Auth] Proxy — route protection and role guards | Open |
| #14 | [Auth] Admin layout shell — Sidebar + Topbar + PageContainer | Open |

## Files this module creates

```text
src/
├── app/
│   ├── (auth)/login/page.tsx
│   ├── (admin)/layout.tsx
│   └── (admin)/dashboard/page.tsx        ← placeholder only
├── components/layout/
│   ├── Sidebar.tsx
│   ├── Topbar.tsx
│   └── PageContainer.tsx
├── components/ui/
│   ├── FormField.tsx                      ← new (CDS-06)
│   ├── Select.tsx                         ← new (CDS-06)
│   ├── Tooltip.tsx                        ← new (CDS-05)
│   └── DropdownMenu.tsx                   ← new (CDS-05)
├── modules/auth/
│   ├── components/LoginForm.tsx
│   └── actions/
│       ├── signOut.ts
│       └── setLocale.ts
├── hooks/useCurrentUser.ts
├── stores/ui.store.ts
└── i18n/
    ├── en.json                            ← auth + nav namespaces added
    ├── cs.json
    └── de.json
```

## When Step 7 is complete

Run before marking done:

```bash
pnpm type-check   # zero errors
pnpm lint         # zero warnings
pnpm test         # all passing
```

Then update this file:

- Check off Step 7, 8, 9, 10 as they complete
- Change "Current step" at the top
- Close GitHub issues #12, #13, #14
- Update `CLAUDE.md` Module index row: status → ✅ Complete
