# Feature Implementation Workflow

**Project:** Multi-Tenant Commerce — Admin Portal  
**Document:** `docs/workflows/02_feature_implementation_workflow.md`  
**Version:** 1.0  
**Date:** 2026-03-27  
**Status:** Active

## Table of Contents

- [1. Overview — Two Tools, Two Roles](#1-overview--two-tools-two-roles)
- [2. Step 1 — Feature Architecture Session (Claude Web)](#2-step-1--feature-architecture-session-claude-web)
- [3. FEATURE_ARCH.md Template](#3-feature_archmd-template)
- [4. Step 2 — HTML Mockup Session (Claude Web)](#4-step-2--html-mockup-session-claude-web)
- [5. Step 3 — Implementation Session (Claude Code)](#5-step-3--implementation-session-claude-code)
- [6. Claude Code Session Start Prompt](#6-claude-code-session-start-prompt)
- [7. Implementation Order Within a Screen](#7-implementation-order-within-a-screen)
- [8. How Claude Web and Claude Code Stay in Sync](#8-how-claude-web-and-claude-code-stay-in-sync)
- [9. Where Everything Lives in the Repo](#9-where-everything-lives-in-the-repo)
- [10. Feature Done Checklist](#10-feature-done-checklist)

## 1. Overview — Two Tools, Two Roles

Every feature goes through two distinct phases using two different tools.
They are never mixed — planning does not happen in Claude Code, and
implementation does not happen in Claude Web.

| Phase     | Tool                        | What happens                                                               |
| --------- | --------------------------- | -------------------------------------------------------------------------- |
| **Plan**  | Claude Web (this interface) | Feature Architecture document produced, HTML mockups reviewed and approved |
| **Build** | Claude Code in VS Code      | Implementation follows the Feature Architecture document exactly           |

The connection between the two is the `FEATURE_ARCH.md` file. Claude Web
produces it. Claude Code consumes it. The file lives in the repo so both
tools and you always have access to the same spec.

```text
Claude Web                         Repo                        Claude Code
──────────────────────────────────────────────────────────────────────────
Feature Architecture session  →  FEATURE_ARCH.md committed  →  Claude Code reads it
HTML Mockup session           →  Mockup approved             →  Implementation starts
                                                             →  Screen built
                                                             →  Tests written
                                                             →  PR opened
```

## 2. Step 1 — Feature Architecture Session (Claude Web)

### When to do this

At the start of every module, before any mockup or implementation work.
One session per module (not per screen — the whole module is planned together).

### How to start the session

Open Claude Web and say:

> "Let's do the Feature Architecture for [Module Name].
> The module is described in the PRD and the relevant DB tables are
> [list the tables]. Produce the FEATURE_ARCH.md for this module."

Claude Web has full context from the project knowledge documents and will
produce the full architecture document. You review it, request changes,
and confirm it before it is saved.

### What Claude Web will produce

A `FEATURE_ARCH.md` covering the entire module — all screens, all
components, all data flows. The structure is flexible based on what the
module needs, but every document must cover the items in the template
in Section 3.

### After the session

1. Copy the produced `FEATURE_ARCH.md` into the correct module folder:
   `apps/admin/src/modules/[module]/FEATURE_ARCH.md`
2. Commit it to the feature branch before any other work begins
3. The GitHub issue for Feature Architecture can now be closed

## 3. FEATURE_ARCH.md Template

This is the starting template. Sections marked **[Required]** must always
be present. Sections marked **[If applicable]** are included only when the
module needs them. Add sections freely if the module has unique concerns
not covered here.

The structure is flexible — a simple module like Addresses will have a
shorter document than a complex module like Orders. What matters is that
every question Claude Code might ask during implementation is answered
somewhere in this file.

```text
# Feature Architecture — [Module Name]

**Module:** [module folder name]  
**Route(s):** [list all URL routes this module owns]  
**Status:** Draft | Approved  
**Date:** [date]

---

## 1. Module Overview [Required]

One paragraph. What does this module do, who uses it, and what are the
core business rules it enforces? Include RBAC — which roles (Admin,
Manager, Staff) can access this module and what can each role do within it.

---

## 2. Screens [Required]

List every screen in this module. For each screen, state its route,
its purpose in one sentence, and whether it is a Server Component page
or a Client Component page.

| Screen | Route         | Purpose | Type                   |
| ------ | ------------- | ------- | ---------------------- |
| List   | /[route]      | ...     | Server → Client island |
| Detail | /[route]/[id] | ...     | Server → Client island |
| Create | drawer/modal  | ...     | Client Component       |
| Edit   | drawer/modal  | ...     | Client Component       |

---

## 3. Component Tree [Required]

For each screen, show the full component hierarchy. Mark each component
as Server (S) or Client (C). Reference the CDS component names where
a CDS component is used.

Example:

### [Screen Name] — /route


[page.tsx] (S)
└── [FeatureNamePage] (C) — modules/[module]/components/[Name].tsx
    ├── PageHeader (CDS) — title, breadcrumb, action button
    ├── DataTable (CDS)
    │   ├── [Column renderers]
    │   └── [RowActions] (C)
    │       ├── IconButton — Edit (CDS)
    │       └── IconButton — Delete (CDS)
    ├── EmptyState (CDS) — shown when no data
    └── Pagination (CDS)


---

## 4. Data Requirements [Required]

For each component that fetches or displays data, state exactly what
data it needs and where it comes from.

| Component | Data needed          | Source                         |
| --------- | -------------------- | ------------------------------ |
| [Name]    | columns from [table] | Supabase query in api.ts       |
| [Name]    | [field] from [table] | TanStack Query, key: ['[key]'] |

---

## 5. Supabase Queries [Required]

Write out the exact Supabase query for every data operation in this
module. These go in `modules/[module]/api.ts`.

// Fetch list
export async function get[Entity]s(supabase: SupabaseClient) {
  const { data, error } = await supabase
    .from('[table]')
    .select('[columns]')
    .order('[column]', { ascending: true })

  if (error) throw error
  return data
}

// Fetch single
export async function get[Entity](supabase: SupabaseClient, id: string) {
  const { data, error } = await supabase
    .from('[table]')
    .select('[columns]')
    .eq('id', id)
    .single()

  if (error) throw error
  return data
}

// Create
export async function create[Entity](
  supabase: SupabaseClient,
  payload: Create[Entity]Payload
) {
  const { data, error } = await supabase
    .from('[table]')
    .insert(payload)
    .select()
    .single()

  if (error) throw error
  return data
}

// Update
export async function update[Entity](
  supabase: SupabaseClient,
  id: string,
  payload: Update[Entity]Payload
) {
  const { data, error } = await supabase
    .from('[table]')
    .update(payload)
    .eq('id', id)
    .select()
    .single()

  if (error) throw error
  return data
}

// Delete
export async function delete[Entity](supabase: SupabaseClient, id: string) {
  const { error } = await supabase
    .from('[table]')
    .delete()
    .eq('id', id)

  if (error) throw error
}

Note: Never add .eq('tenant_id', ...) — RLS handles tenant scoping.

## 6. TanStack Query Keys and Hooks [Required]

Define the query keys and the hooks that wrap the Supabase queries.
These go in `modules/[module]/hooks/`.

// Query keys — centralised in one place
export const [module]Keys = {
  all: ['[module]'] as const,
  list: () => [...[module]Keys.all, 'list'] as const,
  detail: (id: string) => [...[module]Keys.all, 'detail', id] as const,
}

// List hook
export function use[Entity]s(initialData?: [Entity][]) {
  const supabase = createBrowserClient()
  return useQuery({
    queryKey: [module]Keys.list(),
    queryFn: () => get[Entity]s(supabase),
    initialData,
  })
}

// Detail hook
export function use[Entity](id: string, initialData?: [Entity]) {
  const supabase = createBrowserClient()
  return useQuery({
    queryKey: [module]Keys.detail(id),
    queryFn: () => get[Entity](supabase, id),
    initialData,
  })
}

// Mutation hook — create
export function useCreate[Entity]() {
  const supabase = createBrowserClient()
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (payload: Create[Entity]Payload) =>
      create[Entity](supabase, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [module]Keys.list() })
    },
  })
}

## 7. Zod Schemas [Required if module has forms]

Define the Zod schema for every form in this module.
These go in `modules/[module]/schemas.ts`.

export const create[Entity]Schema = z.object({
  name: z.string().min(1, 'Name is required').max(100),
  // ... other fields
})

export type Create[Entity]FormValues = z.infer<typeof create[Entity]Schema>

export const edit[Entity]Schema = create[Entity]Schema.extend({
  // additional fields for edit if different from create
})

export type Edit[Entity]FormValues = z.infer<typeof edit[Entity]Schema>

## 8. Empty, Loading, and Error States [Required]

For every screen that fetches data, define what the user sees in each state.

| Screen | Loading state                    | Empty state                                                         | Error state                                      |
| ------ | -------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------ |
| List   | Skeleton rows (n=5) in DataTable | EmptyState: "[Entity] title", "[message]", "Create [entity]" button | Alert: "Failed to load [entities]", retry button |
| Detail | Skeleton for each field section  | N/A (redirect if not found)                                         | Alert: "Failed to load [entity]", back button    |

## 9. i18n Keys [Required]

List all new translation keys this module introduces. These must be added
to `src/i18n/en.json` (and `cs.json`, `de.json`) before strings are used
in components. Never hardcode user-facing strings.

{
  "[module]": {
    "title": "[Module Name]",
    "empty": {
      "title": "No [entities] yet",
      "description": "Create your first [entity] to get started.",
      "action": "Create [entity]"
    },
    "actions": {
      "create": "Create [entity]",
      "edit": "Edit [entity]",
      "delete": "Delete [entity]",
      "confirm_delete": "Are you sure you want to delete this [entity]?"
    },
    "fields": {
      "name": "Name",
      "status": "Status"
    },
    "toast": {
      "created": "[Entity] created successfully",
      "updated": "[Entity] updated successfully",
      "deleted": "[Entity] deleted successfully",
      "error": "Something went wrong. Please try again."
    }
  }
}

## 10. RBAC Rules [Required]

State explicitly what each role can and cannot do in this module.

| Action      | Admin | Manager | Staff |
| ----------- | ----- | ------- | ----- |
| View list   | ✅     | ✅       | ✅     |
| View detail | ✅     | ✅       | ✅     |
| Create      | ✅     | ✅       | ❌     |
| Edit        | ✅     | ✅       | ❌     |
| Delete      | ✅     | ❌       | ❌     |

How RBAC is enforced in the UI: action buttons are conditionally rendered
based on the `role` from the Zustand auth store. RLS enforces the same
rules at the database level — the UI restriction is for UX, not security.

## 11. Business Rules and Edge Cases [Required]

List every business rule and edge case that affects implementation.
If it is not written here, it will not be implemented.

Examples:
- A category cannot be deleted if it has active products — show warning
- A customer cannot be deleted if they have orders — disable Delete, show tooltip
- Order status can only move forward, never backward, except Cancel which
  is available from any non-completed state
- Product variants must have at least one entry — form blocks submission if empty

## 12. Supabase Layer Changes [If applicable]

If this module requires any new migrations, RLS policy changes, Edge
Functions, triggers, or storage bucket changes, list them here.

| Change        | Type                                                | File/Location | Notes   |
| ------------- | --------------------------------------------------- | ------------- | ------- |
| [description] | Migration / RLS / Edge Function / Trigger / Storage | [path]        | [notes] |

If none: "No Supabase layer changes required for this module."

## 13. Real-time Requirements [If applicable]

Does any screen in this module need live updates via Supabase Realtime?

- Which table(s) are subscribed to?
- What channel name is used?
- What happens in the UI when an event arrives? (invalidate query / optimistic update)
- Where is the subscription set up and cleaned up?

---

## 14. File Upload Requirements [If applicable]

Does this module handle file uploads (images, documents)?

- Which Supabase Storage bucket?
- Accepted file types and size limits
- Upload flow: client-side preview → upload on form submit or immediately?
- How is the public URL stored (in which table column)?
- What happens if upload fails mid-form?

## 15. Open Questions

Any decisions not yet made that will need to be resolved before or during
implementation. Remove items as they are resolved.

- [ ] [Question or decision pending]

```

## 4. Step 2 — HTML Mockup Session (Claude Web)

### When to do this

After the Feature Architecture document is committed to the repo and
before any implementation starts. One session per module, producing
mockups screen by screen.

### How to start the session

> "Let's do the HTML mockups for [Module Name].
> The Feature Architecture is confirmed. Start with the [Screen Name] screen.
> Use the CDS design tokens and realistic Pizza Palace sample data."

### Screen by screen process

```text
Produce screen mockup
      ↓
You review it in the browser
      ↓
Feedback? → Claude Web revises → You review again
      ↓
"Approved" — move to next screen
      ↓
All screens approved?
      ↓
Produce full module mockup (all screens composed together)
      ↓
Final approval
      ↓
Implementation begins
```

### Rules for mockups

- Use the actual CDS colour tokens — no arbitrary colours
- Use realistic data — pizza names, real prices, real Czech addresses
- Show all three states per screen: loaded, empty, skeleton loading
- Show form validation errors on at least one field per form mockup
- Show the correct sidebar navigation item highlighted for this module
- Mockups are HTML files — open directly in the browser, no build step

### Approval is explicit

A screen is not approved until you say "approved" or equivalent. If you
say "looks good but change X" that is a revision request, not an approval.
Claude Web does not proceed to the next screen until the current one is
explicitly approved.

## 5. Step 3 — Implementation Session (Claude Code)

### When to do this

After all mockups are approved. Never before.

### What Claude Code has available

When you open VS Code with Claude Code, it automatically reads `CLAUDE.md`
from the monorepo root. This gives it:

- The full project context
- The folder structure conventions
- All critical patterns (server shell → client island, no manual tenant
  filtering, etc.)
- The current development state (which module is in progress)
- A pointer to the module's `FEATURE_ARCH.md`

Claude Code also has live access to the actual codebase — it reads your
files in real time. It knows what components already exist, what imports
are in place, and what the TypeScript types look like.

### What Claude Code does NOT have

- Memory of previous sessions — every session starts fresh
- The project knowledge documents from Claude Web (PRD, CDS docs, etc.)
  — these are not in the repo unless you copied them to `docs/`
- Any context you discussed in Claude Web — only what is in the files

This is why `CLAUDE.md` and `FEATURE_ARCH.md` must be complete and
committed before any Claude Code session starts. They are the only
persistent context Claude Code has.

## 6. Claude Code Session Start Prompt

Use this template at the start of every Claude Code implementation session.
Fill in the three variables — module name, screen name, and GitHub issue
number — and paste it as your opening message.

```text
We're implementing the [MODULE NAME] module, [SCREEN NAME] screen.
GitHub issue: #[ISSUE NUMBER]

Read FEATURE_ARCH.md at apps/admin/src/modules/[module]/FEATURE_ARCH.md
before starting. Follow all patterns in CLAUDE.md.

Start with [specific first task — e.g. "the Supabase query functions in api.ts"
or "the Server Component page shell" or "the DataTable component"].
```

### Examples

**Starting a new module from scratch:**

```text
We're implementing the Catalog — Categories module, Categories List screen.
GitHub issue: #12

Read FEATURE_ARCH.md at apps/admin/src/modules/catalog/FEATURE_ARCH.md
before starting. Follow all patterns in CLAUDE.md.

Start with the Supabase query functions in api.ts.
```

**Continuing an existing session (next screen):**

```text
We're implementing the Catalog — Categories module, Create Category drawer.
GitHub issue: #13

Read FEATURE_ARCH.md at apps/admin/src/modules/catalog/FEATURE_ARCH.md
before starting. Follow all patterns in CLAUDE.md.

The list screen is complete. Start with the Zod schema in schemas.ts,
then the drawer component.
```

**Continuing mid-screen (returning to unfinished work):**

```text
We're implementing the Orders module, Order Detail page.
GitHub issue: #27

Read FEATURE_ARCH.md at apps/admin/src/modules/orders/FEATURE_ARCH.md
before starting. Follow all patterns in CLAUDE.md.

The order detail data fetching and layout are done. The status workflow
stepper component is incomplete — that's where we left off. The component
file is at modules/orders/components/OrderStatusStepper.tsx.
```

### Tips for Claude Code sessions

- Be specific about where to start — "start with X" is better than
  "implement the screen"
- If something deviates from FEATURE_ARCH.md during implementation,
  update the file and tell Claude Code — don't let the document drift
  from the code
- One screen per session is a good natural boundary — finish a screen,
  commit, start a new session for the next screen
- If Claude Code makes a decision you want to remember, ask it to update
  FEATURE_ARCH.md or add a comment in the code — it won't remember it
  in the next session otherwise

## 7. Implementation Order Within a Screen

Within any single screen, always implement in this order. Each step
produces working, committable code before the next step starts.

```text
1. Supabase query functions     → modules/[module]/api.ts
2. TanStack Query hooks         → modules/[module]/hooks/use[Entity].ts
3. Zod schemas (if form)        → modules/[module]/schemas.ts
4. i18n keys                    → src/i18n/en.json (+ cs.json, de.json)
5. Server Component page shell  → app/(admin)/[route]/page.tsx
6. Client Component(s)          → modules/[module]/components/[Name].tsx
7. Wire data flow end to end    → confirm data renders correctly
8. Empty state                  → confirm EmptyState renders with no data
9. Loading skeleton             → confirm Skeleton renders during fetch
10. Error state                 → confirm Alert renders on query error
11. Unit / integration tests    → [Name].test.tsx co-located
```

Do not jump to step 6 before step 1 is working. A component built before
its query function exists will need to be retrofitted — this wastes time
and creates inconsistency.

## 8. How Claude Web and Claude Code Stay in Sync

This is the most important operational rule in the entire workflow.

**The `FEATURE_ARCH.md` file is the single source of truth.**

| Situation                                               | What to do                                                          |
| ------------------------------------------------------- | ------------------------------------------------------------------- |
| Implementation reveals the architecture needs to change | Update `FEATURE_ARCH.md` first, then implement the change           |
| A new edge case is discovered mid-implementation        | Add it to Section 11 (Business Rules) of `FEATURE_ARCH.md`          |
| A component is built differently from the spec          | Update the component tree in `FEATURE_ARCH.md` to match             |
| You want to discuss a change with Claude Web            | Reference the specific section of `FEATURE_ARCH.md` in your message |
| Claude Code asks a question not answered in the doc     | Answer it, then add the answer to `FEATURE_ARCH.md`                 |

**If `FEATURE_ARCH.md` and the code disagree, update the document.**
The document should always reflect what was actually built, not what was
originally planned.

## 9. Where Everything Lives in the Repo

```text
platform/
├── CLAUDE.md                          ← Claude Code reads this every session
├── docs/                              ← Platform-wide documents
│   ├── roadmap.md
│   ├── tech-stack.md
│   ├── non-functional-requirements.md
│   ├── erm.md
│   └── workflows/
│       ├── 01_module_development_plan.md
│       ├── 02_feature_implementation_workflow.md  ← This document
│       └── 03_daily_dev_deployment_flow.md
└── apps/
└── admin/
├── docs/                      ← Admin-specific documents
│   ├── prd.md
│   ├── frontend-architecture.md
│   ├── testing-strategy.md
│   ├── db-migrations.md
│   ├── BUGS.md
│   ├── TESTING_NOTES.md
│   ├── backend-architecture/
│   │   ├── 01_connection_patterns.md
│   │   ├── 02_rls.md
│   │   ├── 03_jwt_auth_hook.md
│   │   ├── 04_edge_functions.md
│   │   ├── 05_database_triggers.md
│   │   ├── 06_storage_buckets.md
│   │   └── 07_realtime.md
│   └── cds/
│       ├── 01_overview.md
│       ├── 02_design_tokens.md
│       ├── 03_primitives.md
│       ├── 04_feedback_components.md
│       ├── 05_overlay_components.md
│       ├── 06_form_components.md
│       ├── 07_data_display.md
│       ├── 08_navigation_and_layout.md
│       ├── 09_domain_components.md
│       └── 10_accessibility_contract.md
└── src/
└── modules/
├── auth/
│   └── FEATURE_ARCH.md
├── catalog/
│   └── FEATURE_ARCH.md
├── customers/
│   └── FEATURE_ARCH.md
├── orders/
│   └── FEATURE_ARCH.md
└── [module]/
└── FEATURE_ARCH.md
```

### Rule: platform(root)/docs/ vs apps/admin/docs/ vs modules/

- `platform/docs/` — platform-wide documents. Apply across all apps
  (roadmap, tech stack, NFR, ERM, all workflow documents). When `apps/web`
  or `apps/super-admin` is built, these documents govern those apps too.
- `apps/admin/docs/` — admin-specific documents. Specific to this app's
  architecture, components, and implementation details (PRD, frontend
  architecture, CDS, backend architecture, testing strategy, migrations).
- `apps/admin/src/modules/[module]/FEATURE_ARCH.md` — module implementation
  spec. This is what Claude Code reads during implementation of that module.
  Lives inside the source tree, not in docs, because it is part of the
  module itself.

## 10. Feature Done Checklist

Run this checklist before closing any GitHub issue and before opening
a PR for a screen or module.

### Code Quality

- [ ] `pnpm type-check` passes with zero errors
- [ ] `pnpm lint` passes with zero errors
- [ ] No `console.log` statements in production code
- [ ] No hardcoded strings — all in locale files
- [ ] No hardcoded colours — all via CDS tokens
- [ ] No manual `tenant_id` filters in Supabase queries

### Functionality

- [ ] All screens in the module render correctly with real data
- [ ] Empty state renders correctly when there is no data
- [ ] Loading skeleton renders correctly during data fetch
- [ ] Error state renders correctly when a query fails
- [ ] All form validations work — required fields, length limits, types
- [ ] Toast notifications appear on create, update, delete success and error
- [ ] All row actions work — edit opens correct form, delete shows confirm dialog
- [ ] Filters, sort, search, and pagination all work
- [ ] RBAC enforced — restricted actions hidden from lower roles

### Architecture

- [ ] Server Component pages fetch initial data and pass as `initialData`
- [ ] Client Components use TanStack Query with the correct query keys
- [ ] Mutations invalidate the correct query keys on success
- [ ] All query functions are in `api.ts`, not inline in components
- [ ] All hooks are in `hooks/`, not inline in components
- [ ] All Zod schemas are in `schemas.ts`, not inline in components

### Testing

- [ ] Unit tests written for all utility functions in `lib/`
- [ ] Integration tests written for key component behaviours
- [ ] E2E test written or updated for the critical flow in this module
- [ ] `pnpm test` passes with no failures

### Accessibility

- [ ] Keyboard navigation works through all interactive elements
- [ ] All icon buttons have `aria-label`
- [ ] All form fields have associated labels
- [ ] Focus management correct in modals and drawers (trap + restore)
- [ ] No colour-only information (status always has text + colour)

### Documentation

- [ ] `FEATURE_ARCH.md` reflects what was actually built (updated if anything changed)
- [ ] GitHub issue linked in the PR description
- [ ] `CLAUDE.md` current development state updated if module is complete

---

## Changelog

| Version | Date       | Change                   |
| ------- | ---------- | ------------------------ |
| 1.0     | 2026-03-27 | Initial document created |
