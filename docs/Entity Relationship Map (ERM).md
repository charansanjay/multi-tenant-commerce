# Platform — Entity Relationship Map (ERM)

**Version:** 2.0
**Date:** 2026-03-23
**Status:** Finalized — updated for multi-tenant platform architecture

## Table of Contents

- [1. Core System Entities](#1-core-system-entities)
- [2. High-Level Data Flow](#2-high-level-data-flow)
- [3. Entity Relationship Map (System Level)](#3-entity-relationship-map-system-level)
- [4. Relationship Explanation](#4-relationship-explanation)
- [5. Visual ER Diagram (Simplified)](#5-visual-er-diagram-simplified)
- [6. Important Architecture Decisions](#6-important-architecture-decisions)
- [7. Changelog](#7-changelog)

## 1. Core System Entities

The platform is a multi-tenant system. Every entity below belongs to a
tenant. The `tenants` table is the root — it is the only entity with no
`tenant_id` column because it *is* the tenant.

| Entity | Purpose |
|---|---|
| `tenants` | Platform accounts — one row per restaurant or business |
| `staff_profiles` | Admin (owner) / manager / staff accounts per tenant |
| `customers` | Customer records per tenant |
| `addresses` | Customer delivery addresses per tenant |
| `categories` | Product categories per tenant (hierarchical) |
| `products` | Sellable items per tenant |
| `product_variants` | Purchasable options of a product (size, portion, etc.) |
| `coupons` | Discount codes per tenant |
| `orders` | Customer orders per tenant |
| `order_items` | Line items within an order |
| `payments` | Payment attempts against an order |
| `audit_logs` | Immutable record of every staff action per tenant |
| `notifications` | Operational alerts for staff per tenant |

## 2. High-Level Data Flow

### Platform level

```text
tenants
   ↓
owns everything below
```

### Business flow within a tenant

```text
Customer
   ↓
Address (selected at checkout)
   ↓
Order
   ↓
Order Items ──────────────────────┐
   ↓                              │
Product Variants        also references
   ↓                              │
Products               Products (soft ref)
   ↓
Categories
```

### Payments

```text
Order
   ↓
Payments (1 → many attempts)
```

### Staff management

```text
Staff (admin / manager / staff)
   ↓
Manages: Products, Orders, Customers,
         Categories, Coupons, Notifications
   ↓
Every action →  Audit Logs
```

### Discounts

```text
Coupons
   ↓ applied at checkout
Orders (coupon snapshotted — no live FK dependency)
```

## 3. Entity Relationship Map (System Level)

```text
tenants
   │
   │ 1 → many (all entities below belong to a tenant)
   ├──────────────────────────────────────────────────────┐
   │                                                      │
   ▼                                                      ▼
staff_profiles                                        customers
   │                                                      │
   │ performs actions                            1 → many │
   ▼                                                      ├── addresses
audit_logs                                               │
                                                          └── orders
                                                               │
                                                    1 → many   ├── payments (1 → many)
                                                               │
                                                    1 → many   └── order_items
                                                                       │
                                                          many → 1     ├── product_variants
                                                          (soft ref)   │         │
                                                          many → 1     └── products
                                                                                 │
                                                                      many → 1   ▼
                                                                             categories
                                                                         (self-referencing
                                                                          parent_id)
```

## 4. Relationship Explanation

### 4.1. Tenants → Everything

Relationship:

```
tenants 1 → many (all other tables)
```

Every row in every table carries a `tenant_id` FK back to `tenants`. This
is the foundation of tenant isolation. Staff from Tenant A can never see
data belonging to Tenant B — enforced by RLS policies on every table.

The `admin` role in `staff_profiles` represents the tenant owner —
the restaurant operator who owns the account on the platform.

---

### 4.2. Staff → Audit Logs

Relationship:

```text
staff_profiles 1 → many audit_logs
```

One staff member can perform many actions. Each action becomes an audit
log record. `audit_logs` has no FK constraint on `staff_id` — logs survive
staff deletion. `tenant_id` on audit logs also has no FK — logs survive
tenant purges.

Example:

```text
Admin created product
Manager updated order status
Staff exported customer data (GDPR)
```

---

### 4.3. Customer → Addresses

Relationship:

```text
customers 1 → many addresses (max 4 active per customer)
```

A customer can have up to 4 active delivery addresses. Addresses are never
directly referenced by orders — orders store a full address snapshot.

Example:

```text
Jana Dvorak
   ├ Home  — Náměstí Míru 12, Praha
   ├ Work  — Wenceslas Square 1, Praha
   └ Other — Brno centre
```

---

### 4.4. Customer → Orders

Relationship:

```text
customers 1 → many orders
```

A customer can place many orders. `customer_id` is nullable on `orders` —
walk-in and guest orders have no registered customer. Customer details are
always snapshotted onto the order at creation time.

Example:

```text
Customer: Pavel Novak
   ├ ORD-2026-00001
   ├ ORD-2026-00014
   └ ORD-2026-00031
```

---

### 4.5. Orders → Order Items

Relationship:

```text
orders 1 → many order_items
```

Each order contains one or more line items. Order items are immutable once
placed — they are the financial record.

Example:

```text
ORD-2026-00001
   ├ Margherita Pizza — Large (32cm) × 2
   ├ Pepperoni Pizza  — Medium (26cm) × 1
   └ Coke — 330ml × 2
```

---

### 4.6. Order Items → Product Variants

Relationship:

```text
order_items many → 1 product_variants  (soft FK — ON DELETE SET NULL)
```

Order items reference the variant, not the base product. This ensures
correct pricing per size/option at order time. If the variant is later
deleted, the FK goes NULL but the price snapshot on the order item remains
accurate.

Example:

```text
Margherita Pizza
   ├ Small  (20cm) — 120 CZK
   ├ Medium (26cm) — 170 CZK
   └ Large  (32cm) — 198 CZK  ← order item references this variant
```

---

### 4.7. Order Items → Products

Relationship:

```text
order_items many → 1 products  (soft FK — ON DELETE SET NULL)
```

`product_id` was added to `order_items` to enable direct product-level
analytics (e.g. best-selling products) without joining through
`product_variants`. Soft reference — `product_name` snapshot ensures the
order item remains readable even if the product is later deleted.

---

### 4.8. Product Variants → Products

Relationship:

```text
product_variants many → 1 products  (ON DELETE CASCADE)
```

A product is the base entity. Variants are its purchasable options — each
with its own `option_name` (e.g. `small`, `large`, `slice`, `whole`),
price, and stock. Pricing lives on variants, never on the base product.

Example:

```text
Chocolate Cake (product)
   ├ Single Slice  — 85 CZK
   └ Whole Cake    — 490 CZK (5% discount → actual 465.50 CZK)
```

---

### 4.9. Products → Categories

Relationship:

```
products many → 1 categories  (ON DELETE RESTRICT)
```

Every product must belong to a category. A category cannot be deleted while
products are assigned to it. Each tenant has their own category tree.
Categories are hierarchical via self-referencing `parent_id`.

Example:

```text
Food (root level)
   ├── Pizza
   │     ├ Margherita
   │     └ Pepperoni
   ├── Desserts
   │     └ Chocolate Cake
   └── Drinks
         └ Coke
```

---

### 4.10. Orders → Payments

Relationship:

```text
orders 1 → many payments
```

Multiple payment attempts are supported per order. Each failed attempt
creates a new row. Only one successful payment can exist per order —
enforced by a partial unique index. `payments` is the authoritative source
for payment status — `orders.payment_status` is a denormalised copy synced
by trigger.

Example:

```text
ORD-2026-00002
   ├ Attempt 1 — failed  (Insufficient funds)
   ├ Attempt 2 — failed  (Card declined)
   └ Attempt 3 — paid ✓  (ch_3MqmkL2eZvKYlo2C)
```

---

### 4.11. Coupons → Orders

Relationship:

```text
coupons 1 → many orders  (soft FK — ON DELETE SET NULL)
```

A coupon can be applied to many orders over its lifetime. When applied, the
coupon code and discount amount are snapshotted onto the order. The live
`coupon_id` FK is a soft analytics reference only — modifying or deleting
a coupon has no impact on historical orders.

---

### 4.12. Staff → Notifications

Relationship:

```text
staff_profiles 1 → many notifications  (ON DELETE CASCADE)
```

Notifications can be targeted (`staff_id = specific user`) or broadcast
(`staff_id = NULL`) to all staff within the same tenant. Personal
notifications are removed when a staff account is deleted. Broadcast
notifications are unaffected.

## 5. Visual ER Diagram (Simplified)

```text
                    tenants
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
   staff_profiles   customers    categories
          │            │              │
          │         ┌──┴──┐          ▼
          │         │     │        products
          ▼         ▼     ▼           │
     audit_logs  addresses orders     ▼
                        │       product_variants
                   ┌────┴────┐        │
                   │         │        │ (soft refs)
                   ▼         ▼        │
                payments  order_items─┘
                              │
                           coupons (snapshot on orders)
                           notifications (staff inbox)
```

## 6. Important Architecture Decisions

### 6.1. Tenants as root entity

All data is scoped to a tenant. The `tenants` table is the single root.
Adding a new restaurant to the platform is inserting one row into `tenants`
and running the provisioning sequence (Root category seed, first admin
account). No schema changes required.

---

### 6.2. Variants are the purchasable unit

Customers never buy a `product` directly — they buy a `product_variant`.
This means pricing, stock, and availability are always per-option, not
per-product. The `option_name` column (replacing the old `size` enum)
is free-form — works for pizzas, cakes, drinks, clothing, or anything else.

---

### 6.3. Snapshot pattern throughout

Three entities use the snapshot pattern to ensure historical accuracy:

- **Orders** snapshot: customer details, delivery address, financial totals,
  coupon, VAT, delivery fee — all at order creation time
- **Order items** snapshot: product name, variant name, option, all prices
  — at order creation time
- **Audit logs** snapshot: staff name, email, role, tenant name
  — at log creation time

Once snapshotted, these values are immutable. Live data can change freely
without affecting history.

---

### 6.4. No global settings table

The original design included a global `settings` table for VAT rate, default
currency, delivery fee, and branding. In the multi-tenant design this is
replaced by `tenants.settings` jsonb — each tenant has their own
configuration. The global `settings` table does not exist.

---

### 6.5. Order items gain product_id

`order_items` references both `variant_id` (for variant-level analytics)
and `product_id` (for product-level analytics). Both are soft FKs —
`ON DELETE SET NULL`. All display data is snapshotted, so losing either
reference does not affect order accuracy or invoice generation.

---

### 6.6. Orders → Payments is 1→many, not 1→1

Each order can have multiple payment attempts. Failed card payments create
new attempt rows rather than overwriting the previous one. This gives a
complete payment audit trail per order. Only one `is_successful = true`
row is allowed per order — enforced by partial unique index.

---

### 6.7. Categories are hierarchical and per-tenant

Categories use a self-referencing `parent_id` for unlimited nesting depth.
Each tenant manages their own independent category tree. The Root category
is seeded per-tenant during provisioning — there is no global root.

## 7. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2024-03-18 | Initial ERM finalized |
| 2.0 | 2026-03-23 | Added `tenants` as root entity — all other entities now belong to a tenant |
| 2.0 | 2026-03-23 | `product_variants.size` enum replaced with `option_name varchar` — platform-generic |
| 2.0 | 2026-03-23 | `order_items → products` soft reference added — enables direct product analytics |
| 2.0 | 2026-03-23 | `orders → payments` corrected from 1→1 to 1→many — multiple payment attempts supported |
| 2.0 | 2026-03-23 | `coupons` relationship added — previously undocumented in ERM |
| 2.0 | 2026-03-23 | `notifications` relationship added — previously undocumented in ERM |
| 2.0 | 2026-03-23 | Global `settings` table removed — replaced by `tenants.settings` jsonb |
| 2.0 | 2026-03-23 | Categories updated — hierarchical, per-tenant, Root category per-tenant |
| 2.0 | 2026-03-23 | Entity descriptions updated from pizza-specific to platform-generic |
| 2.0 | 2026-03-23 | Section 7 "What We Will Do Next" replaced with Changelog — tables are done |
