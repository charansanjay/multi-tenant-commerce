# Backend Architecture — 04: Edge Functions

**Project:** Multi-Tenant Commerce  
**Version:** 2.0  
**Status:** Finalized  

## Table of Contents

- [1. Overview](#1-overview)
- [2. How Edge Functions Are Called](#2-how-edge-functions-are-called)
- [3. Security Convention](#3-security-convention)
- [4. Standard Response Shape](#4-standard-response-shape)
- [5. The Three Edge Functions](#5-the-three-edge-functions)
  - [5.1. `generate-order-number`](#51-generate-order-number)
  - [5.2. `increment-coupon-usage`](#52-increment-coupon-usage)
  - [5.3. `generate-invoice-pdf`](#53-generate-invoice-pdf)
- [6. Folder Structure](#6-folder-structure)
- [7. Changelog](#7-changelog)

## 1. Overview

Edge Functions are small programs that run on Supabase's own infrastructure
— not in the Next.js application and not in the browser. They are the
correct tool for three specific scenarios:

1. **Atomic operations** — where two simultaneous requests must not produce
   an incorrect result
2. **Privileged operations** — where the Service Role Key is required but
   must never reach the browser
3. **Pure backend operations** — where the frontend only needs a result
   back, with no UI involvement

This project uses exactly three Edge Functions, each matching one of the
above scenarios.

## 2. How Edge Functions Are Called

Edge Functions are never called directly from Client Components. The call
chain is always:

```text
Client Component
      ↓
Server Action (server-side, authenticated)
      ↓
Edge Function (Supabase infrastructure)
      ↓
Returns result to Server Action
      ↓
Server Action returns result to Client Component
```

This ensures:

- The Service Role Key never reaches the browser
- The calling user's identity and tenant can be verified before the
  function runs
- All Edge Function calls are traceable through Server Actions

## 3. Security Convention

Every Edge Function performs **three checks** before executing any logic:

**Check 1 — Is the caller authenticated?**
The function verifies that a valid JWT token was passed in the request
headers. If no token or an invalid token is present, the function returns
`401 Unauthorized` immediately.

**Check 2 — Does the caller have the required role?**
The function reads the `role` claim from the JWT and checks it against the
permitted roles for that function. If the role is insufficient, the
function returns `403 Forbidden`.

**Check 3 — Does the operation belong to the caller's tenant?**
The function reads `tenant_id` from the JWT and verifies that the entity
being operated on (order counter, coupon, invoice) belongs to the same
tenant. A staff member cannot generate an order number for a different
tenant's sequence, increment another tenant's coupon, or generate an
invoice for another tenant's order.

Only after all three checks pass does the function execute its main logic.

## 4. Standard Response Shape

Every Edge Function returns the same structure:

**On success:**

```json
{
  "data": { ... },
  "error": null
}
```

**On failure:**

```json
{
  "data": null,
  "error": "A clear description of what went wrong"
}
```

## 5. The Three Edge Functions

### 5.1. `generate-order-number`

| Attribute | Value |
|---|---|
| **Purpose** | Generate a unique, sequential, human-readable order number per tenant |
| **Permitted roles** | `admin`, `manager`, `staff` |
| **Uses admin client** | Yes — requires atomic counter increment |
| **Called from** | Order creation Server Action |

**Why an Edge Function:**
Order numbers must be unique and sequential per tenant (e.g.
`ORD-2026-00142`). If two orders are created at the exact same millisecond,
a naive implementation could assign the same number to both. The Edge
Function uses a database-level atomic increment to guarantee uniqueness
regardless of concurrency.

In multi-tenant design, each tenant has their own independent counter.
`ORD-2026-00001` can exist in both Tenant A and Tenant B — they are
different orders in different tenants. The function maintains a
per-tenant sequence keyed by `tenant_id`.

**Inputs:**

```json
{
  "tenant_id": "uuid-of-the-tenant"
}
```

**Output:**

```json
{
  "data": { "order_number": "ORD-2026-00142" },
  "error": null
}
```

**Tenant validation:** The function verifies that the `tenant_id` in the
input matches the `tenant_id` claim in the caller's JWT. A staff member
cannot generate an order number for a different tenant's sequence.

---

### 5.2. `increment-coupon-usage`

| Attribute | Value |
|---|---|
| **Purpose** | Atomically increment a coupon's `usage_count` and validate against `max_usage` |
| **Permitted roles** | `admin`, `manager`, `staff` |
| **Uses admin client** | Yes — requires atomic read-increment-write |
| **Called from** | Order creation Server Action (when a coupon is applied) |

**Why an Edge Function:**
If two customers apply the same coupon at the exact same time, a
non-atomic check-then-increment could allow both to succeed even if only
one usage remained. The Edge Function performs the check and increment as
a single atomic database operation, making over-use impossible.

**Inputs:**

```json
{
  "coupon_id": "uuid-of-the-coupon",
  "tenant_id": "uuid-of-the-tenant"
}
```

**Tenant validation:** The function fetches the coupon and verifies its
`tenant_id` matches both the input `tenant_id` and the caller's JWT
`tenant_id` claim. This prevents a staff member from applying a coupon
belonging to a different tenant.

**Output on success:**

```json
{
  "data": { "usage_count": 5, "max_usage": 10 },
  "error": null
}
```

**Output when coupon is exhausted:**

```json
{
  "data": null,
  "error": "Coupon has reached its maximum usage limit"
}
```

**Output on tenant mismatch:**

```json
{
  "data": null,
  "error": "Coupon does not belong to this tenant"
}
```

---

### 5.3. `generate-invoice-pdf`

| Attribute | Value |
|---|---|
| **Purpose** | Generate a PDF invoice for a given order |
| **Permitted roles** | `admin`, `manager` |
| **Uses admin client** | Yes — fetches full order data across multiple tables |
| **Called from** | Order detail Server Action |

**Why an Edge Function:**
PDF generation requires fetching complete order data across multiple tables
— order, order items, customer, address, payment, and product details.
This fetch uses the admin client (Service Role Key) to guarantee all data
is available. The Service Role Key must never reach the browser, making an
Edge Function the only appropriate location for this logic.

**Inputs:**

```json
{
  "order_id": "uuid-of-the-order",
  "tenant_id": "uuid-of-the-tenant"
}
```

**Tenant validation:** The function fetches the order and verifies its
`tenant_id` matches the caller's JWT `tenant_id` claim. A staff member
cannot generate an invoice for another tenant's order even if they somehow
know its UUID.

**Output on success:**

```json
{
  "data": { "pdf_url": "https://..." },
  "error": null
}
```

The PDF is stored in Supabase Storage under the tenant's path prefix and
a signed URL is returned. The URL expires after 60 minutes.

**Output on permission failure:**

```json
{
  "data": null,
  "error": "Insufficient permissions to generate invoice"
}
```

**Output on tenant mismatch:**

```json
{
  "data": null,
  "error": "Order does not belong to this tenant"
}
```

## 6. Folder Structure

```text
supabase/
  functions/
    generate-order-number/
      index.ts
    increment-coupon-usage/
      index.ts
    generate-invoice-pdf/
      index.ts
```

Each function is a self-contained TypeScript file deployed independently
via the Supabase CLI.

## 7. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial Edge Functions design finalized |
| 2.0 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 2.0 | 2026-03-23 | Security convention expanded — three checks now (added tenant validation) |
| 2.0 | 2026-03-23 | `generate-order-number` updated — now takes `tenant_id` input, maintains per-tenant counter |
| 2.0 | 2026-03-23 | `increment-coupon-usage` updated — now takes `tenant_id` input, validates coupon belongs to caller's tenant |
| 2.0 | 2026-03-23 | `generate-invoice-pdf` updated — now takes `tenant_id` input, validates order belongs to caller's tenant |
| 2.0 | 2026-03-23 | All three functions return tenant mismatch error responses |
