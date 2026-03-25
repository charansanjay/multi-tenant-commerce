# Multi-Tenant Commerce Platform

A multi-tenant food ordering platform built with Next.js 16, Supabase, and Turborepo. The platform serves multiple restaurant tenants from a single codebase — each tenant gets their own isolated data, branding, and configuration.

## What's in This Repository

This is a **pnpm monorepo** managed by Turborepo. It contains three applications and three shared packages.

### Applications

| App | Path | Status | Description |
|---|---|---|---|
| Admin Portal | `apps/admin` | 🚧 Active | Internal management portal for restaurant staff |
| Customer Site | `apps/web` | 🔜 Planned | Customer-facing ordering website |
| Super Admin | `apps/super-admin` | 🔜 Planned | Platform operator portal for managing tenants |

### Shared Packages

| Package | Path | Description |
|---|---|---|
| `@platform/ui` | `packages/ui` | Shared component library (custom design system) |
| `@platform/types` | `packages/types` | Shared TypeScript types including database types |
| `@platform/utils` | `packages/utils` | Shared utilities (formatting, class merging, etc.) |

## The Admin Portal

The first app being built. It is the internal management interface used by restaurant staff — not accessible to customers.

**Modules:**

- **Dashboard** — today's orders, revenue, top products, low stock alerts
- **Catalog** — manage products (pizzas), variants, and categories
- **Orders** — track and process orders through their full lifecycle
- **Customers** — manage customer records and addresses
- **Sales** — analytics and revenue reporting
- **Settings** — tenant branding, payment methods, email templates
- **Audit Logs** — full immutable activity log

**Roles:**

| Role | Access |
|---|---|
| `admin` | Full access — restaurant owner |
| `manager` | Orders, customers, catalog — no settings or analytics |
| `staff` | Order operations and customer lookups only |

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Next.js 16 (App Router, Turbopack) |
| Language | TypeScript 5 |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| Styling | Tailwind CSS 4 |
| Server state | TanStack Query v5 |
| Client state | Zustand |
| Forms | React Hook Form + Zod |
| Tables | TanStack Table v8 |
| i18n | next-intl (English, Czech, German) |
| Testing | Vitest + Playwright |
| Monorepo | Turborepo + pnpm workspaces |

## Getting Started

### Prerequisites

- Node.js v24.6.0+
- pnpm v9+
- Docker (for local Supabase)

### Install dependencies

```bash
pnpm install
```

### Set up environment variables

```bash
cp apps/admin/.env.example apps/admin/.env.local
```

Fill in your Supabase URL and keys in `apps/admin/.env.local`.

### Start local Supabase

```bash
supabase start
```

### Run the dev server

```bash
pnpm dev
```

This starts all apps in parallel via Turborepo. The admin portal runs at `http://localhost:3000`.

## Common Commands

All commands run from the **monorepo root** via Turborepo unless noted.

| Command | What it does |
|---|---|
| `pnpm dev` | Start all apps in dev mode |
| `pnpm build` | Build all apps and packages |
| `pnpm lint` | Lint all workspaces |
| `pnpm type-check` | TypeScript check across all workspaces |
| `pnpm test` | Run Vitest unit and integration tests |
| `supabase start` | Start local Supabase instance |
| `supabase stop` | Stop local Supabase instance |

To run a command in a specific workspace:

```bash
pnpm --filter @platform/admin dev
pnpm --filter @platform/ui type-check
```

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code. Protected. No direct commits. |
| `develop` | Integration branch. All feature work merges here first. |
| `feature/*` | Feature branches cut from `develop`. |
| `hotfix/*` | Urgent fixes cut from `main`, merged back to `develop`. |

## Project Documentation

All architecture and design decisions are documented in the `/docs` folder (or project knowledge base). Key documents:

- **PRD** — Product Requirements Document
- **Tech Stack** — Full dependency rationale
- **Frontend Architecture** — Folder structure, routing, state, Supabase clients
- **Backend Architecture** — RLS policies, Auth Hook, Edge Functions, Realtime
- **CDS (Component Design System)** — Design tokens, component API, accessibility contract
- **Database Schema** — All 13 tables with full SQL definitions and RLS
- **Testing Strategy** — Vitest + Playwright conventions and coverage targets
