# Daily Dev & Deployment Flow

**Project:** Multi-Tenant Commerce — Admin Portal  
**Document:** `docs/workflows/03_daily_dev_deployment_flow.md`  
**Version:** 1.0  
**Date:** 2026-03-27  
**Status:** Active

## Table of Contents

1. [Overview](#1-overview)
2. [Branch Strategy](#2-branch-strategy)
3. [Starting a Dev Session](#3-starting-a-dev-session)
4. [The Daily Development Loop](#4-the-daily-development-loop)
5. [Making a Schema Change](#5-making-a-schema-change)
6. [Committing and Pushing](#6-committing-and-pushing)
7. [Finishing a Feature — PR and Merge to Develop](#7-finishing-a-feature--pr-and-merge-to-develop)
8. [What the CI Pipeline Does Automatically](#8-what-the-ci-pipeline-does-automatically)
9. [Ending a Dev Session](#9-ending-a-dev-session)
10. [Production Deployment](#10-production-deployment)
11. [One-Time Production Setup](#11-one-time-production-setup)
12. [Quick Reference — All Commands](#12-quick-reference--all-commands)

## 1. Overview

This document covers everything that happens outside of writing feature code —
starting and stopping your environment, committing safely, merging branches,
and deploying to production. These steps are as important as the code itself.
Skipping them or doing them out of order causes the class of problems documented
in the DB Migrations Setup Guide troubleshooting section.

There are two distinct environments:

| Environment    | Where                                      | Purpose                                          |
| -------------- | ------------------------------------------ | ------------------------------------------------ |
| **Local**      | Your machine                               | All development happens here                     |
| **Staging**    | Vercel + Supabase cloud (`develop` branch) | Integration testing, pre-production verification |
| **Production** | Vercel + Supabase cloud (`main` branch)    | Live system, real data                           |

During active module development you work entirely in local. Staging becomes
relevant when a module is complete and ready for integration verification.
Production is the final destination after staging is confirmed.

## 2. Branch Strategy

The repository has two permanent branches and one branch per feature.

```text
main
  └── develop
        ├── feature/auth-login-page
        ├── feature/catalog-categories-list
        ├── feature/catalog-categories-create-form
        └── feature/[module]-[description]
```

### Branch rules

| Branch      | Purpose                                                   | Who pushes here                    | Protected?                |
| ----------- | --------------------------------------------------------- | ---------------------------------- | ------------------------- |
| `main`      | Production-ready code only                                | Merge from `develop` via PR        | Yes — never push directly |
| `develop`   | Integration — all completed features land here            | Merge from feature branches via PR | Yes — never push directly |
| `feature/*` | One branch per screen or closely related group of screens | You — push freely                  | No                        |

### Why never push directly to `develop` or `main`

Even as a solo developer, always going through a PR for `develop` and `main`
means the CI pipeline runs before the code lands. This is what catches broken
types, failing tests, and lint errors before they affect the branch everyone
(and every deployment) works from.

### Feature branch naming

```text
feature/[module]-[short-description]

Good:
  feature/auth-login-page
  feature/catalog-categories-list
  feature/catalog-categories-create-form
  feature/orders-status-workflow
  feature/orders-invoice-pdf

Avoid:
  feature/wip
  feature/fix
  feature/new-stuff
```

One feature branch per screen is a good default. Group two screens into
one branch only if they are so tightly coupled that separating them
would leave either in a broken state (e.g. create form and its list screen
when the list has no empty state without the form).

## 3. Starting a Dev Session

Run these two commands every time you open a new dev session. Order matters —
Supabase must be running before Next.js starts, because the app connects to
Supabase on startup.

```bash
# 1. Start local Supabase (Docker containers)
pnpm db:start

# 2. Start Next.js dev server
pnpm dev
```

**Why `db:start` before `dev`:**
Next.js reads `NEXT_PUBLIC_SUPABASE_URL` at startup. If Supabase is not yet
running, the client initialises against a non-responsive endpoint and you
get confusing auth errors that disappear once Supabase is up. Always start
in this order.

**Verify everything is running:**

```bash
pnpm db:status
# Should show: API URL, DB URL, Studio URL, all containers healthy
```

Local Supabase Studio is available at `http://localhost:54323` — useful for
inspecting data during development without writing queries.

### If Supabase fails to start

The most common cause on Windows is orphaned Docker containers from a
previous session that did not stop cleanly.

```bash
# Remove orphaned containers
docker ps -a --filter "name=multi-tenant-commerce" --format "{{.Names}}" | xargs docker rm -f

# Then start again
pnpm db:start
```

## 4. The Daily Development Loop

This is the loop you are in for the majority of every development session.
No ceremony — just the rhythm of writing code, checking it works, and
committing when something is complete.

```text
Write code
    ↓
Save file → Husky + lint-staged runs on staged files automatically on commit
    ↓
Check in browser → does it work?
    ↓
TypeScript error? → fix before continuing (never suppress with @ts-ignore)
    ↓
Something complete (a function, a component, a screen)?
    ↓
Commit it (see Section 6)
    ↓
Continue
```

### Checking types at any time

```bash
pnpm type-check
```

Run this whenever you want confidence that the whole workspace is clean,
not just the file you are in. TypeScript errors in one file can hide
type errors in another that the editor does not surface immediately.

### Running tests during development

```bash
# Run all unit and integration tests once
pnpm test

# Run tests in watch mode (re-runs on file save)
pnpm test --watch

# Run a specific test file
pnpm test modules/catalog/components/CategoriesList.test.tsx
```

Do not save tests for the end of a feature. Write them as you build each
piece — query functions first, then components.

## 5. Making a Schema Change

A schema change is any modification to the database — adding a column,
creating a new table, changing an index, updating an RLS policy, adding
a trigger. Schema changes must always go through a migration file. Never
make changes directly in Supabase Studio and leave them undocumented —
they will be lost when `db:reset` is run and will not exist in staging
or production.

### The schema change sequence

```bash
# Step 1 — Create a new timestamped migration file
pnpm db:migrate [description]

# Example:
pnpm db:migrate add_tracking_number_to_orders
# Creates: supabase/migrations/[timestamp]_add_tracking_number_to_orders.sql
```

```bash
# Step 2 — Write the SQL in the generated file
# Open supabase/migrations/[timestamp]_add_tracking_number_to_orders.sql
# Write your SQL:
#   ALTER TABLE orders ADD COLUMN tracking_number text;
```

```bash
# Step 3 — Apply locally (wipes DB and reruns all migrations from scratch)
pnpm db:reset
```

Why `db:reset` and not an incremental apply? During early development
before any real data exists, resetting is safer and simpler than
incremental applies. It guarantees the migration sequence is clean and
no orphaned state exists from previous sessions.

```bash
# Step 4 — Regenerate TypeScript types
pnpm db:types
```

This overwrites `apps/admin/src/types/database.types.ts` with types
generated directly from the live local schema. After this step, the new
column is immediately available as a TypeScript type. If you skip this
step, TypeScript will not know the column exists and you will get type
errors when you try to use it.

```bash
# Step 5 — Verify
pnpm type-check   # should pass with zero errors
```

### What NOT to do

Never edit `apps/admin/src/types/database.types.ts` by hand. It is
auto-generated and your edits will be overwritten on the next `pnpm db:types`
run. If the types don't reflect the schema you want, fix the migration SQL
and regenerate.

Never make schema changes in Supabase Studio without creating a migration
file. Studio changes are ephemeral — they do not survive `db:reset` and
will not be in the remote database when you push.

## 6. Committing and Pushing

### Commit discipline

Commit often. Each commit should represent one logical, working unit.
Not every commit needs to be a finished screen — a working query function,
a finished component, a passing test suite — these are all good commit
boundaries. Small commits make it easy to identify exactly where something
broke and roll back precisely.

### What happens automatically on commit

When you run `git commit`, Husky triggers lint-staged on your staged files:

```text
git commit
  → Husky pre-commit hook fires
  → lint-staged runs on staged .ts and .tsx files:
      → ESLint --fix (auto-fixes what it can, fails commit on unfixable errors)
      → Prettier --write (formats the file)
  → If all pass: commit proceeds
  → If any fail: commit is blocked, errors shown in terminal
```

This means you never push code with lint errors. The gate is at the commit,
not the push.

### Commit message format

Use conventional commit format. It keeps the git log readable and makes
it obvious what changed at a glance.

```text
[type]: [short description]

Types:
  feat      — new feature or screen
  fix       — bug fix
  chore     — config, tooling, dependency update
  docs      — documentation change
  test      — adding or updating tests
  refactor  — code change that neither fixes a bug nor adds a feature
  style     — formatting, missing semicolons, whitespace

Examples:
  feat: add categories list screen with DataTable and pagination
  feat: create category drawer form with Zod validation
  fix: correct RLS policy not filtering by tenant_id on categories
  chore: regenerate database types after adding tracking_number column
  test: add integration tests for CategoriesList component
  docs: update FEATURE_ARCH.md to reflect drawer instead of modal
```

### Pushing a feature branch

```bash
# First push (creates the remote branch)
git push -u origin feature/catalog-categories-list

# Subsequent pushes
git push
```

Push at the end of every dev session at minimum — even if the feature is
not complete. This is your off-site backup. A machine failure loses at
most one session of uncommitted work, never more.

## 7. Finishing a Feature — PR and Merge to Develop

When a screen or module is complete and the feature done checklist
(Document 2, Section 10) has been run, open a PR to merge the feature
branch into `develop`.

### Opening the PR

On GitHub, open a PR from `feature/[name]` → `develop`.

**PR description template:**

```markdown
## What this PR does
[One paragraph — what screen or feature was built]

## GitHub Issue
Closes #[issue number]

## Feature Architecture
`apps/admin/src/modules/[module]/FEATURE_ARCH.md`

## Screenshots
[Optional but helpful — before/after or key screens]

## Checklist
- [ ] pnpm type-check passes
- [ ] pnpm lint passes
- [ ] pnpm test passes
- [ ] Empty, loading, error states all handled
- [ ] RBAC enforced
- [ ] i18n strings in locale files
- [ ] FEATURE_ARCH.md updated if anything changed
```

### What happens after you open the PR

The CI pipeline runs automatically (see Section 8). If it passes, merge
the PR. If it fails, fix the failures on the feature branch and push again
— the CI re-runs on every push.

### Merging

Use **Squash and Merge** for feature branches into `develop`. This keeps
the `develop` branch history clean — one commit per feature rather than
every small commit made during development.

After merging:

```bash
# Switch back to develop and pull the latest
git checkout develop
git pull

# Delete the feature branch locally
git branch -d feature/[name]
```

## 8. What the CI Pipeline Does Automatically

The CI pipeline is defined in `.github/workflows/ci.yml` and runs
without any manual action from you. Understanding what it does at
each trigger point tells you what you can rely on and what you must
check manually.

### On every push to any branch

```text
TypeScript check    → tsc --noEmit across all workspaces (zero errors required)
ESLint              → zero errors required
```

Why: This is the fastest feedback — catches type errors and lint failures
before they stack up. Runs in under a minute.

### On every PR opened or updated (targeting any branch)

```text
TypeScript check    → same as above
ESLint              → same as above
Unit + Integration  → Vitest runs all tests across all workspaces
Coverage report     → Generated for src/lib/ and src/stores/
```

Why: Unit and integration tests are fast enough to run on every PR.
This catches component regressions and business logic errors before
the code is reviewed.

### On merge to `develop`

```text
Full E2E suite      → Playwright runs all 6 critical flows
                      (local Supabase instance started, db:reset run, tests execute)
```

Why: E2E is too slow for every push. Running it on merge to `develop` ensures
the integration branch is always in a working state before it can be promoted
to `main`.

### On merge to `main`

```text
Full E2E suite      → same as develop merge
Coverage report     → Final report generated and stored as CI artifact
```

Why: This is the production gate. Everything that reaches `main` has passed
type checks, lint, unit tests, integration tests, E2E tests, and coverage
thresholds.

### CI failures

If CI fails on a PR, the merge button is blocked on GitHub. Fix the
failure on your feature branch, push again, and CI re-runs automatically.
Never merge a PR with a failing CI by bypassing the branch protection rules.

## 9. Ending a Dev Session

```bash
# Stop the Next.js dev server
Ctrl+C in the terminal running pnpm dev

# Stop local Supabase containers
pnpm db:stop
```

**Why stop Supabase explicitly:**
Supabase runs as Docker containers. Closing the terminal does not stop them —
they keep running in the background and consume memory. `pnpm db:stop` shuts
them down cleanly. If you skip this and start a new session later, you may
get "container name already in use" errors.

**Before ending a session — always:**

```bash
# Push your current branch even if the feature is not complete
git push
```

Never end a session with uncommitted or unpushed work. You lose nothing
if the machine fails. You resume the next session with `git pull` and
everything is exactly where you left it.

## 10. Production Deployment

Production is Vercel (Next.js app) + Supabase cloud (database, auth, storage,
edge functions). Deployment is largely automated once the one-time setup
in Section 11 is complete.

### How production deployment works

```text
You merge a PR to main
        ↓
CI pipeline runs (full E2E suite + coverage)
        ↓
CI passes
        ↓
Vercel auto-deploys the new build to production
(previous version serves traffic until new build is promoted — zero downtime)
        ↓
You manually push migrations to Supabase cloud (see below)
        ↓
Done
```

### Why migrations are manual (not automatic)

Database migrations are deliberately not run automatically on merge to `main`.
Running a migration against a production database with live data is a
consequential operation — a bad migration can corrupt data or lock tables.
You should always push migrations manually, with intention, after confirming
the build deployed successfully on Vercel.

### Deploying migrations to production

```bash
# Confirm local Supabase is linked to the remote project
supabase status

# Push all pending migrations to the remote Supabase project
pnpm db:push
```

`pnpm db:push` pushes only the migrations that have not yet been applied to
the remote database. It does not wipe production data — it applies only the
delta since the last push. This is safe for production.

### After pushing migrations to production

```bash
# Regenerate types from the remote schema to confirm they match local
supabase gen types typescript --project-id <your-project-ref> \
  > apps/admin/src/types/database.types.ts

# Run type-check to confirm generated types are consistent
pnpm type-check
```

If `type-check` passes, the production schema and the TypeScript types
are in sync. This is the confirmation that the migration was applied
correctly.

### Deploying Edge Functions to production

Edge Functions (generate-order-number, increment-coupon-usage,
generate-invoice-pdf) are deployed separately from the Next.js app.

```bash
# Deploy all Edge Functions
supabase functions deploy generate-order-number
supabase functions deploy increment-coupon-usage
supabase functions deploy generate-invoice-pdf
```

Deploy Edge Functions whenever their logic changes. They are independent
of the Next.js deploy — you can deploy a function fix without redeploying
the full app.

### Staging (develop branch)

Vercel creates a preview deployment automatically for every push to
`develop`. This staging environment uses the Supabase cloud project
(same as production by default for a solo developer) but with preview
environment variables if you configure them.

For a solo developer, staging is primarily used as a final visual check
before merging to `main`. It does not require manual migration pushes
if you are pushing migrations to the single Supabase cloud project —
migrations pushed for `develop` are already applied by the time you
merge to `main`.

### Production deployment sequence — complete checklist

Use this checklist every time you merge to `main`.

```text
Before merging to main:
  [ ] All feature PRs for this release are merged to develop
  [ ] Full E2E suite passes on develop
  [ ] Staging preview URL checked visually — key screens work
  [ ] Any new migrations tested on staging

Merging to main:
  [ ] PR from develop → main opened
  [ ] CI pipeline passes
  [ ] PR merged (Squash and Merge)

After merging to main:
  [ ] Vercel build completes successfully (check Vercel dashboard)
  [ ] pnpm db:push — migrations pushed to Supabase cloud
  [ ] pnpm type-check — types confirmed consistent with production schema
  [ ] Any new Edge Functions deployed (supabase functions deploy [name])
  [ ] Production URL checked visually — key screens work
  [ ] CLAUDE.md updated — completed modules moved to Completed section
  [ ] GitHub milestone for the released module(s) marked as complete
```

## 11. One-Time Production Setup

This section is run once when you are ready to go live. Not during active
module development. Steps are listed in the order they must be done.

### Step 1 — Create the Supabase cloud project

Go to <https://supabase.com> → New Project. Give it a name matching the
monorepo project. Note the Project Reference ID (visible in the URL and
in Project Settings).

### Step 2 — Link the local CLI to the remote project

```bash
supabase link --project-ref <your-project-ref>
```

You will be prompted for the database password you set when creating the
project. After this, `pnpm db:push` knows which remote project to target.

### Step 3 — Push all migrations to the remote project

```bash
pnpm db:push
```

This applies all 15 migrations (and any you have added during development)
to the empty remote database in order. Verify in Supabase Dashboard →
Table Editor that all tables are present.

### Step 4 — Register the JWT Auth Hook in the cloud dashboard

Local development uses `config.toml` for the JWT hook. The cloud dashboard
requires manual registration — it does not read `config.toml`.

Go to: Supabase Dashboard → Your Project → **Authentication → Hooks**
→ Custom Access Token Hook → Enable → Select `custom_jwt_claims` function.

**This step is easy to forget and breaks authentication entirely if missed.**
Staff cannot log in without it. Do this immediately after migrations are pushed.

### Step 5 — Set environment variables in Vercel

Connect your GitHub repository to Vercel (New Project → Import Git Repository).
In the Vercel project settings → Environment Variables, add:

```text
NEXT_PUBLIC_SUPABASE_URL        → From Supabase Dashboard → Project Settings → API
NEXT_PUBLIC_SUPABASE_ANON_KEY   → From Supabase Dashboard → Project Settings → API
SUPABASE_SERVICE_ROLE_KEY       → From Supabase Dashboard → Project Settings → API
                                   (mark as server-only — never expose to client)
```

Set these for all three environments: Production, Preview, Development.

### Step 6 — Configure Vercel deployment branches

In Vercel project settings → Git:

| Branch           | Environment                       |
| ---------------- | --------------------------------- |
| `main`           | Production — auto-deploy on merge |
| `develop`        | Preview — auto-deploy on push     |
| Feature branches | Preview — per-PR preview URL      |

### Step 7 — Trigger first production deployment

Merge the current state of `develop` into `main`. Vercel detects the push
and begins the first production build. Monitor in the Vercel dashboard.

### Step 8 — Deploy Edge Functions

```bash
supabase functions deploy generate-order-number
supabase functions deploy increment-coupon-usage
supabase functions deploy generate-invoice-pdf
```

### Step 9 — Verify production

- Open the production URL from Vercel dashboard
- Log in with a staff account
- Confirm the JWT hook is working (role and tenant appear correctly)
- Confirm at least one module loads data from the database
- Check Vercel error dashboard — no server errors

## 12. Quick Reference — All Commands

### Daily commands

```bash
pnpm db:start                    # Start local Supabase
pnpm db:stop                     # Stop local Supabase
pnpm db:status                   # Check Supabase container status
pnpm dev                         # Start Next.js dev server
pnpm type-check                  # TypeScript check across all workspaces
pnpm lint                        # ESLint across all workspaces
pnpm test                        # Run Vitest unit + integration tests
pnpm test --watch                # Run tests in watch mode
```

### Schema change commands

```bash
pnpm db:migrate [description]    # Create a new migration file
pnpm db:reset                    # Wipe local DB and reapply all migrations
pnpm db:types                    # Regenerate TypeScript types from local schema
```

### Git commands (daily)

```bash
git checkout -b feature/[name]   # Create and switch to new feature branch
git add .                        # Stage all changes
git commit -m "feat: [message]"  # Commit (triggers Husky pre-commit hook)
git push                         # Push to remote
git push -u origin feature/[name] # First push of a new branch
```

### Production commands

```bash
supabase link --project-ref [ref]          # Link CLI to remote Supabase project (once)
pnpm db:push                               # Push pending migrations to remote
supabase functions deploy [function-name]  # Deploy an Edge Function
supabase gen types typescript \
  --project-id [ref] \
  > apps/admin/src/types/database.types.ts # Regenerate types from remote schema
```

### Supabase Studio (local)

```text
http://localhost:54323   # Supabase Studio — inspect tables, run SQL, check auth
```

## Changelog

| Version | Date       | Change                   |
| ------- | ---------- | ------------------------ |
| 1.0     | 2026-03-27 | Initial document created |
