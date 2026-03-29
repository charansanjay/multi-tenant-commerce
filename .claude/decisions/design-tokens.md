# Design Token Decisions

This file records all design token decisions made during the Claude Web
planning sessions. These are locked — do not change without explicit
approval in a Claude Web session followed by an update to this file
and to `CDS_02_Design_Tokens.md`.

## Primary colour — Amber

**Decision:** `--primary: #f59e0b` (amber-500)
**Previous value:** `#1D4ED8` (blue-700)
**Changed:** Module 1 mockup session

**Rationale:** Blue felt generic for a food-oriented admin portal. Amber
gives the portal a warm, distinctive identity appropriate to the business
context while remaining professional and legible on white backgrounds.
The token system means this can be swapped per tenant with two lines.

```css
--primary:          245 158 11;   /* #F59E0B amber-500 */
--primary-hover:    217 119 6;    /* #D97706 amber-600 */
--primary-subtle:   254 243 199;  /* #FEF3C7 amber-100 */
--primary-foreground: 255 255 255;
```

Dark mode:

```css
--primary:          251 191 36;   /* amber-400 */
--primary-hover:    252 211 77;   /* amber-300 */
--primary-subtle:   120 53  15;   /* amber-900 */
```

## Sidebar palette — Warm Purple-Grey

**Decision:** Custom `--sidebar-*` token set, always dark
**Changed:** Module 1 mockup session

**Rationale:** Magento Admin-inspired dark sidebar. Warm purple-grey
(not cold grey, not pure black) with amber accent. The purple warmth
gives it personality and distinguishes it from Magento's colder palette.
Sidebar is always dark regardless of page light/dark mode toggle.

```css
--sidebar-bg:           42 42 54;    /* #2A2A36 warm purple-grey base */
--sidebar-active-bg:    32 32 43;    /* #20202B darker active item bg */
--sidebar-accent:       245 158 11;  /* #F59E0B amber active border + icon */
--sidebar-active-text:  252 211 77;  /* #FCD34D amber-300 active text */
--sidebar-item-text:    200 200 212; /* #C8C8D4 unselected — clearly visible */
--sidebar-item-hover-bg: 32 32 43;  /* #20202B hover bg */
--sidebar-item-hover-text: 229 229 239; /* #E5E5EF hover text */
--sidebar-border:       56 56 74;   /* #38384A purple-tinted dividers */
--sidebar-flyout-bg:    26 26 35;   /* #1A1A23 flyout panel bg */
```

**Sidebar behaviour:**

- Always 72px wide — never collapses
- Hover on items with children opens a flyout panel to the right
- Catalog is the only item with children (Categories, Products)
- Active item: `--sidebar-active-bg` bg + `--sidebar-accent` left border + `--sidebar-active-text` text
- Unselected items: `--sidebar-item-text` (bright enough to read at a glance)
- Item labels: `text-transform: capitalize`, 11px

**Why not copied from Magento:**

- Magento sidebar: cold `#1d1d1d`/`#2d2d2d` with orange-red `#eb5202` accent
- Ours: warm purple-grey `#2a2a36` with amber `#f59e0b` accent
- Different base hue, different accent colour, different item label style

## Typography scale — bumped +2px

**Decision:** Entire scale shifted up 2px uniformly
**Changed:** Module 1 mockup session

**Rationale:** Original 13px base was designed for a developer-tool
aesthetic (Linear, Vercel). This portal has a Magento-style dark sidebar
and serves non-technical staff (managers, order staff) who may be reading
it at arm's length on larger screens. 15px body reads more comfortably
and gives sidebar nav labels appropriate presence at 11px.

```css
--font-size-xs:   0.8125rem;   /* 13px — meta, timestamps, helper text */
--font-size-sm:   0.9375rem;   /* 15px — default body, table cells, form labels */
--font-size-base: 1.0625rem;   /* 17px — card descriptions, longer body */
--font-size-lg:   1.1875rem;   /* 19px — card titles, section headings */
--font-size-xl:   1.375rem;    /* 22px — page titles (PageHeader) */
--font-size-2xl:  1.625rem;    /* 26px — dashboard stat numbers */
--font-size-3xl:  2rem;        /* 32px — large metric displays */
```

## Info colour — decoupled from primary

**Decision:** `--info` is now `blue-500 #3b82f6`, independent of primary
**Changed:** Module 1 token update session

**Rationale:** Info was previously aliased to primary (`blue-700`). When
primary changed to amber, info would have become amber too — which is
wrong semantically (amber = warning in this system). Info stays blue
as a permanently independent semantic colour.

```css
--info:           59 130 246;   /* blue-500 — always blue regardless of primary */
--info-subtle:    219 234 254;  /* blue-100 */
--info-foreground: 30 58 138;   /* blue-900 */
```

## Focus ring — follows primary

**Decision:** `--ring` matches `--primary` (amber)
**Rationale:** Focus rings should feel like part of the brand, not a
foreign blue override. Amber at 3:1 contrast against white backgrounds
meets WCAG 2.4.11 (Focus Appearance AA).

```css
--ring:        245 158 11;   /* amber-500 in light mode */
--ring:        251 191 36;   /* amber-400 in dark mode */
```
