# CDS-02 — Design Tokens

**Project:** Multi-Tenant Commerce - Admin portal  
**Series:** Component Design System  
**Version:** 1.0  
**Date:** 2026-03-23

## Table of Contents

1. [What are Design Tokens and Why They Matter](#1-what-are-design-tokens-and-why-they-matter)
2. [How Tokens Work in This Stack](#2-how-tokens-work-in-this-stack)
3. [Colour Tokens](#3-colour-tokens)
4. [Status Colour Tokens](#4-status-colour-tokens)
5. [Typography Tokens](#5-typography-tokens)
6. [Spacing & Radius Tokens](#6-spacing--radius-tokens)
7. [Shadow Tokens](#7-shadow-tokens)
8. [Dark Mode](#8-dark-mode)
9. [Accent Colour Swapping](#9-accent-colour-swapping)

## 1. What are Design Tokens and Why They Matter

Design tokens are named variables that represent visual decisions — colours, sizes, spacing, radius, shadows. Instead of writing `bg-blue-700` in a component, you write `bg-primary`. The token `--primary` resolves to `blue-700` today, and can be changed to `amber-600` tomorrow without touching a single component.

This matters for three reasons:

**Consistency.** Every component that needs the primary colour references the same token. It is impossible for one component to use `blue-600` while another uses `blue-700` by accident. The token is the single source of truth.

**Dark mode.** When the theme switches to dark, the token values change. `--background` shifts from white to near-black. Components do not change — only the token definitions do.

**Future flexibility.** The primary colour decision was made as blue-700. If the business later decides on an orange brand identity for the pizza shop, changing two lines in the token file repaints the entire application. This is not hypothetical — brand colours change, and when they do, you will be glad the system was token-based.

## 2. How Tokens Work in This Stack

Tokens are defined as **CSS custom properties** in `src/styles/tokens.css`. Tailwind CSS 4 references them via `@theme` — no `tailwind.config.js` required.

```text
src/styles/
├── tokens.css    ← All CSS custom properties (light + dark)
└── globals.css   ← @import tokens.css, base resets, font loading
```

Tailwind utility classes map to tokens:

```css
/* In tokens.css */
:root {
  --primary: 29 78 216;
}

/* In @theme block */
@theme {
  --color-primary: rgb(var(--primary));
}

/* Usage in components */
className="bg-primary text-primary-foreground"
```

The RGB channel format (`29 78 216` instead of `#1D4ED8`) allows Tailwind's opacity modifier to work correctly:

```tsx
className="bg-primary/10"   /* 10% opacity primary — works because of RGB channel format */
```

## 3. Colour Tokens

Full `tokens.css` — light mode (`:root`) and dark mode (`.dark`):

```css
/* src/styles/tokens.css */

@layer base {
  :root {

    /* ─────────────────────────────
       Background
    ───────────────────────────── */
    --background:          255 255 255;   /* #FFFFFF — main page background */
    --background-subtle:   249 248 247;   /* #F9F8F7 — warm off-white, sidebar bg */
    --background-muted:    243 242 240;   /* #F3F2F0 — table row hover, input bg */

    /* ─────────────────────────────
       Surface (cards, modals, overlays)
    ───────────────────────────── */
    --surface:             255 255 255;
    --surface-raised:      249 248 247;   /* cards slightly elevated */
    --surface-overlay:     255 255 255;   /* modals, dropdowns */

    /* ─────────────────────────────
       Border
    ───────────────────────────── */
    --border:              229 227 224;   /* warm gray-200 — default borders */
    --border-strong:       209 206 202;   /* warm gray-300 — stronger separation */

    /* ─────────────────────────────
       Text
    ───────────────────────────── */
    --foreground:          28 25 23;      /* warm near-black — primary text */
    --foreground-muted:    87 83 78;      /* warm gray-600 — secondary text */
    --foreground-subtle:   120 113 108;   /* warm gray-500 — placeholder, meta */
    --foreground-disabled: 168 162 158;   /* warm gray-400 — disabled state text */

/* ─────────────────────────────
       Primary — amber-500 (#F59E0B)
    ───────────────────────────── */
    --primary:             245 158 11;    /* amber-500 */
    --primary-hover:       217 119 6;     /* amber-600 — hover state */
    --primary-subtle:      254 243 199;   /* amber-100 — backgrounds, highlights */
    --primary-foreground:  255 255 255;   /* text on primary bg */

    /* ─────────────────────────────
       Secondary
    ───────────────────────────── */
    --secondary:           243 242 240;
    --secondary-hover:     229 227 224;
    --secondary-foreground: 28 25 23;

    /* ─────────────────────────────
       Destructive — red-600
    ───────────────────────────── */
    --destructive:         220 38 38;
    --destructive-hover:   185 28 28;     /* red-700 */
    --destructive-subtle:  254 226 226;   /* red-100 */
    --destructive-foreground: 255 255 255;

    /* ─────────────────────────────
       Semantic — Success
    ───────────────────────────── */
    --success:             22 163 74;     /* green-600 */
    --success-subtle:      220 252 231;   /* green-100 */
    --success-foreground:  20 83 45;      /* green-900 */

    /* ─────────────────────────────
       Semantic — Warning
    ───────────────────────────── */
    --warning:             217 119 6;     /* amber-600 */
    --warning-subtle:      254 243 199;   /* amber-100 */
    --warning-foreground:  120 53 15;     /* amber-900 */

    /* ─────────────────────────────
       Semantic — Info
    ───────────────────────────── */
    --info:                59 130 246;    /* blue-500 — info is now independent of primary */
    --info-subtle:         219 234 254;   /* blue-100 */
    --info-foreground:     30 58 138;     /* blue-900 */

    /* ─────────────────────────────
       Muted
    ───────────────────────────── */
    --muted:               243 242 240;
    --muted-foreground:    120 113 108;

    /* ─────────────────────────────
       Focus ring
    ───────────────────────────── */
    --ring:                245 158 11;    /* amber-500 — matches primary */
    --ring-offset:         255 255 255;

    /* ─────────────────────────────
       Sidebar
       Warm purple-grey dark chrome.
       Intentionally distinct from the
       page background — always dark
       regardless of light/dark mode.
    ───────────────────────────── */
    --sidebar-bg:          42 42 54;      /* #2A2A36 — warm purple-grey base */
    --sidebar-active-bg:   32 32 43;      /* #20202B — darker active item bg */
    --sidebar-accent:      245 158 11;    /* #F59E0B — amber-500, active border + icon */
    --sidebar-active-text: 252 211 77;    /* #FCD34D — amber-300, active item text */
    --sidebar-muted-text:  145 145 160;   /* #9191A0 — inactive item text / icons */
    --sidebar-border:      56 56 74;      /* #38384A — purple-tinted dividers */
    --sidebar-flyout-bg:   26 26 35;      /* #1A1A23 — flyout panel background */
  }

  /* ─────────────────────────────────────
     Dark mode
  ───────────────────────────────────── */
  .dark {
    --background:          12 10 9;       /* warm near-black */
    --background-subtle:   28 25 23;
    --background-muted:    41 37 36;

    --surface:             28 25 23;
    --surface-raised:      41 37 36;
    --surface-overlay:     41 37 36;

    --border:              63 57 53;
    --border-strong:       87 83 78;

    --foreground:          250 250 249;   /* warm near-white */
    --foreground-muted:    168 162 158;
    --foreground-subtle:   120 113 108;
    --foreground-disabled: 87 83 78;

   /* Primary lightens in dark mode for readability on dark backgrounds */
    --primary:             251 191 36;    /* amber-400 */
    --primary-hover:       252 211 77;    /* amber-300 */
    --primary-subtle:      120 53 15;     /* amber-900 */
    --primary-foreground:  12 10 9;

    --secondary:           41 37 36;
    --secondary-hover:     63 57 53;
    --secondary-foreground: 250 250 249;

    --destructive:         248 113 113;   /* red-400 */
    --destructive-hover:   252 165 165;   /* red-300 */
    --destructive-subtle:  127 29 29;     /* red-900 */
    --destructive-foreground: 12 10 9;

    --success:             74 222 128;    /* green-400 */
    --success-subtle:      20 83 45;      /* green-900 */
    --success-foreground:  240 253 244;

    --warning:             251 191 36;    /* amber-400 */
    --warning-subtle:      120 53 15;     /* amber-900 */
    --warning-foreground:  255 251 235;

    --info:                96 165 250;    /* blue-400 — unchanged, info stays blue */
    --info-subtle:         30 58 138;
    --info-foreground:     219 234 254;

    --muted:               41 37 36;
    --muted-foreground:    120 113 108;

    --ring:                251 191 36;    /* amber-400 — matches dark mode primary */
    --ring-offset:         12 10 9;
  }
}
```

## 4. Status Colour Tokens

Staff read status badges dozens of times per shift. The colour decisions here are intentional and functional — not decorative.

### Design Principles for Status Colours

- **Instantly distinguishable** — no two statuses share a colour family
- **Semantically meaningful** — amber = attention needed, green = complete, red = problem
- **WCAG AA compliant** — all light-bg/dark-text pairings and their dark mode equivalents meet 4.5:1 contrast
- **Text always present** — colour alone never conveys status (CDS-10 accessibility contract)

### Order Status Colour Rationale

| Status | Colour | Why |
|---|---|---|
| `pending` | Amber | Needs attention — amber is universally understood as "waiting" |
| `confirmed` | Blue | Acknowledged — matches primary, implies system has accepted it |
| `preparing` | Violet | In progress — distinct from blue/confirmed, implies active work |
| `ready` | Cyan | Done, awaiting pickup — distinct from green/delivered, implies almost-complete |
| `delivered` | Green | Successful completion — universal positive signal |
| `cancelled` | Red | Terminal negative — universal problem signal |

```css
:root {
  /* ─────────────────────────────
     Order status colours
  ───────────────────────────── */
  --status-pending-bg:      254 243 199;   /* amber-100 */
  --status-pending-text:    120 53  15;    /* amber-900 */

  --status-confirmed-bg:    219 234 254;   /* blue-100 */
  --status-confirmed-text:  30  58  138;   /* blue-900 */

  --status-preparing-bg:    237 233 254;   /* violet-100 */
  --status-preparing-text:  76  29  149;   /* violet-900 */

  --status-ready-bg:        207 250 254;   /* cyan-100 */
  --status-ready-text:      22  78  99;    /* cyan-900 */

  --status-delivered-bg:    220 252 231;   /* green-100 */
  --status-delivered-text:  20  83  45;    /* green-900 */

  --status-cancelled-bg:    254 226 226;   /* red-100 */
  --status-cancelled-text:  127 29  29;    /* red-900 */

  /* ─────────────────────────────
     Payment status colours
  ───────────────────────────── */
  --status-paid-bg:         220 252 231;   /* green-100 */
  --status-paid-text:       20  83  45;    /* green-900 */

  --status-payment-pending-bg:   254 243 199;
  --status-payment-pending-text: 120 53  15;

  --status-failed-bg:       254 226 226;   /* red-100 */
  --status-failed-text:     127 29  29;    /* red-900 */

  --status-refunded-bg:     241 245 249;   /* slate-100 */
  --status-refunded-text:   30  41  59;    /* slate-900 */

  /* ─────────────────────────────
     Product status colours
  ───────────────────────────── */
  --status-active-bg:       220 252 231;   /* green-100 */
  --status-active-text:     20  83  45;    /* green-900 */

  --status-inactive-bg:     241 245 249;   /* slate-100 */
  --status-inactive-text:   30  41  59;    /* slate-900 */

  --status-out-of-stock-bg:   255 237 213; /* orange-100 */
  --status-out-of-stock-text: 124 45  18;  /* orange-900 */
}
```

### Dark Mode Status Colours

Status colours invert in dark mode — the subtle background becomes the dark-toned version (e.g. `green-900`) and the text becomes the light-toned version (e.g. `green-100`):

```css
.dark {
  --status-pending-bg:    120 53  15;    /* amber-900 */
  --status-pending-text:  254 243 199;   /* amber-100 */

  --status-confirmed-bg:  30  58  138;   /* blue-900 */
  --status-confirmed-text: 219 234 254;  /* blue-100 */

  --status-preparing-bg:  76  29  149;   /* violet-900 */
  --status-preparing-text: 237 233 254;  /* violet-100 */

  --status-ready-bg:      22  78  99;    /* cyan-900 */
  --status-ready-text:    207 250 254;   /* cyan-100 */

  --status-delivered-bg:  20  83  45;    /* green-900 */
  --status-delivered-text: 220 252 231;  /* green-100 */

  --status-cancelled-bg:  127 29  29;    /* red-900 */
  --status-cancelled-text: 254 226 226;  /* red-100 */

  --status-paid-bg:       20  83  45;
  --status-paid-text:     220 252 231;

  --status-payment-pending-bg:   120 53  15;
  --status-payment-pending-text: 254 243 199;

  --status-failed-bg:     127 29  29;
  --status-failed-text:   254 226 226;

  --status-refunded-bg:   30  41  59;    /* slate-900 */
  --status-refunded-text: 241 245 249;   /* slate-100 */

  --status-active-bg:     20  83  45;
  --status-active-text:   220 252 231;

  --status-inactive-bg:   30  41  59;
  --status-inactive-text: 241 245 249;

  --status-out-of-stock-bg:   124 45  18;   /* orange-900 */
  --status-out-of-stock-text: 255 237 213;  /* orange-100 */
}
```

## 5. Typography Tokens

### Font Loading

Geist is loaded via `next/font` in the root layout. This self-hosts the font automatically — no Google Fonts request, no flash of unstyled text, zero layout shift.

```tsx
// src/app/layout.tsx
import { GeistSans, GeistMono } from 'geist/font'

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable}`}>
      <body>{children}</body>
    </html>
  )
}
```

```css
/* tokens.css */
:root {
  --font-sans: var(--font-geist-sans), system-ui, sans-serif;
  --font-mono: var(--font-geist-mono), 'Fira Code', monospace;
}
```

### Why Geist

Geist is the typeface built by Vercel for their own products. It was chosen here because:

- It is modern and clean without being trendy
- It has excellent legibility at small sizes — critical for a data-dense admin UI at 13px
- It pairs well with warm neutral backgrounds
- It is maintained and self-hostable

### Type Scale

The scale is **compact** — sized for an admin portal where information density matters, not a marketing site with generous whitespace.

15px (`text-sm`) as the default body text is intentional. The original 13px scale was reconsidered during the Module 1 mockup phase — the Magento-style dark sidebar and overall portal aesthetic require more visual weight and breathing room than a developer-tool UI like Linear or Vercel. 15px reads comfortably at arm's length, reduces eye strain during long shifts, and gives the sidebar navigation labels the presence they need at 64px width.

| Token       | Size | Line height | Weight | Usage                                                     |
| ----------- | ---- | ----------- | ------ | --------------------------------------------------------- |
| `text-xs`   | 13px | 18px        | 400    | Timestamps, meta, helper text, table secondary info       |
| `text-sm`   | 15px | 22px        | 400    | **Default body** — table cells, form labels, descriptions |
| `text-base` | 17px | 26px        | 400    | Longer body text, card descriptions                       |
| `text-lg`   | 19px | 28px        | 500    | Card titles, section headings                             |
| `text-xl`   | 22px | 30px        | 600    | Page titles (`PageHeader`)                                |
| `text-2xl`  | 26px | 34px        | 600    | Dashboard stat numbers                                    |
| `text-3xl`  | 32px | 40px        | 700    | Large metric displays                                     |

```css
/* In @theme block — Tailwind 4 */
@theme {
  --font-size-xs:   0.8125rem;   /* 13px */
  --font-size-sm:   0.9375rem;   /* 15px */
  --font-size-base: 1.0625rem;   /* 17px */
  --font-size-lg:   1.1875rem;   /* 19px */
  --font-size-xl:   1.375rem;    /* 22px */
  --font-size-2xl:  1.625rem;    /* 26px */
  --font-size-3xl:  2rem;        /* 32px */
}
```

## 6. Spacing & Radius Tokens

### Spacing

All spacing uses the **8px base grid** — every layout value is a multiple of 4 or 8. This makes spacing decisions automatic rather than arbitrary.

```text
4px  → micro gaps (icon-to-label, badge padding)
8px  → small gaps (form field spacing within a group)
12px → medium gaps (between related elements)
16px → standard gap (between form fields)
24px → section gap (between card sections)
32px → large gap (between page sections)
```

Tailwind's default spacing scale (4 = 1rem = 16px) is not modified. The base unit remains the Tailwind default. The 8px grid is a convention, not a token.

### Radius

```css
:root {
  --radius-sm:   4px;      /* inputs, badges, chips, small elements */
  --radius-md:   6px;      /* buttons, cards, dropdowns — primary usage */
  --radius-lg:   8px;      /* modals, sheets, larger containers */
  --radius-full: 9999px;   /* pill badges, avatars, toggle switches */
}
```

**Why subtle radius (4–6px)?**

The radius choice reflects the "warm & approachable + classic admin" feel. Sharp corners (0px) read as very enterprise/utilitarian. Very rounded corners (12px+) read as consumer/playful. 4–6px sits in the middle: softened enough to feel modern, professional enough for an internal tool that staff use all day.

## 7. Shadow Tokens

```css
:root {
  --shadow-sm:  0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md:  0 4px 6px -1px rgb(0 0 0 / 0.08),
                0 2px 4px -2px rgb(0 0 0 / 0.06);
  --shadow-lg:  0 10px 15px -3px rgb(0 0 0 / 0.08),
                0 4px 6px -4px rgb(0 0 0 / 0.05);
  --shadow-xl:  0 20px 25px -5px rgb(0 0 0 / 0.08),
                0 8px 10px -6px rgb(0 0 0 / 0.04);
}
```

Shadows are intentionally **subtle** — lower opacity than Tailwind defaults. The warm neutral background palette means heavy shadows would look harsh. Usage:

| Shadow | Used on |
|---|---|
| `shadow-sm` | Table rows on hover, input focus, small cards |
| `shadow-md` | Cards, dropdowns, select panels |
| `shadow-lg` | Modals, drawers, popovers |
| `shadow-xl` | Command palette, elevated overlays |

## 8. Dark Mode

Dark mode is implemented via the `.dark` class on the `<html>` element (not via `prefers-color-scheme` media query alone). This gives user preference stored in the session explicit control.

**Why `.dark` class instead of media query only?**

The Settings module allows admins to set a system-wide default mode. Staff personal preference may override it. Both require programmatic control — media query alone cannot handle this.

```tsx
// Theme toggling — sets class on <html> and persists preference
function setTheme(theme: 'light' | 'dark') {
  document.documentElement.classList.toggle('dark', theme === 'dark')
  // persist to user session via Server Action
}
```

**Default:** Light mode. Dark mode available from day one.

All token values are defined for both `:root` (light) and `.dark` (dark) in `tokens.css`. No component needs to know about the current theme — they always reference tokens, and the tokens resolve correctly for the active mode.

## 9. Accent Colour Swapping

The primary colour is `amber-500` (`#F59E0B`). This was chosen to give the
portal a warm, distinctive identity that feels appropriate for a food-oriented
business context, while remaining professional and legible across all components.

The sidebar uses its own dedicated token set (`--sidebar-*`) so it can be
restyled independently of the page-level primary if needed.

If a future tenant's brand identity requires a different primary accent,
the change is **two lines** in `tokens.css`:

```css
/* Change this: */
--primary:       245 158 11;    /* amber-500 */
--primary-hover: 217 119 6;     /* amber-600 */

/* To this (example — blue): */
--primary:       59  130 246;   /* blue-500 */
--primary-hover: 37  99  235;   /* blue-600 */
```

The sidebar accent can be updated separately if the sidebar chrome should
also follow the brand colour:

```css
--sidebar-accent:      245 158 11;   /* change to match new primary if desired */
--sidebar-active-text: 252 211 77;   /* adjust to a lighter shade of new accent */
```

Every button, link, focus ring, and active nav item updates automatically.
No component files need to change.
