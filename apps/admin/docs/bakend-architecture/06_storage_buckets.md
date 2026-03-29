# Backend Architecture — 06: Storage Bucket Structure

**Project:** Multi-Tenant Commerce  
**Version:** 2.0  
**Status:** Finalized  

## Table of Contents

- [1. Overview](#1-overview)
- [2. The Four Buckets](#2-the-four-buckets)
- [3. Public vs Private](#3-public-vs-private)
- [4. File Naming Convention](#4-file-naming-convention)
- [5. Tenant Isolation in Storage](#5-tenant-isolation-in-storage)
- [6. Upload & Delete Permissions](#6-upload--delete-permissions)
- [7. Storage Policy Pattern](#7-storage-policy-pattern)
- [8. Signed URLs for Private Buckets](#8-signed-urls-for-private-buckets)
- [9. Summary](#9-summary)
- [10. Changelog](#10-changelog)

## 1. Overview

Supabase Storage handles all file assets — product images, category images,
staff avatars, and customer avatars. Storage is organised into buckets.
Each bucket has its own access rules (public or private) and upload/delete
permissions tied to the staff role system.

In the multi-tenant design, **all file paths are prefixed with
`{tenant_id}/`**. This ensures complete tenant isolation at the storage
level — one tenant's files can never collide with or be accessible to
another tenant's staff.

## 2. The Four Buckets

| Bucket | Contents | Public |
|---|---|---|
| `product-images` | Product photos | ✅ Yes |
| `category-images` | Category photos | ✅ Yes |
| `staff-avatars` | Staff profile photos | 🔒 No |
| `customer-avatars` | Customer profile photos | 🔒 No |

The bucket structure is unchanged from v1.0. Tenant isolation is achieved
through file path prefixes, not separate buckets per tenant.

## 3. Public vs Private

### 3.1. Public Buckets — `product-images`, `category-images`

Files are accessible to anyone with the URL — no authentication required.
Appropriate for product and category images because:

- They are display assets shown in the admin UI and customer-facing site
- They contain no sensitive information
- Direct URL access is not a security concern

Although the bucket is public, the `tenant_id` prefix in the path means
a user would need to know the correct tenant UUID to construct a valid URL.
This is obscurity, not security — the files are genuinely public once the
URL is known.

---

### 3.2. Private Buckets — `staff-avatars`, `customer-avatars`

Files require an authenticated request. Supabase generates short-lived
signed URLs for access.

- **Staff avatars** — internal, only authenticated tenant staff should view
- **Customer avatars** — personal data, restricted to authenticated staff

## 4. File Naming Convention

All file paths are prefixed with `{tenant_id}/` to enforce tenant isolation
at the storage level. This prevents cross-tenant path collisions and makes
per-tenant storage management straightforward.

| Bucket | File path pattern | Example |
|---|---|---|
| `product-images` | `{tenant_id}/{product_id}/{variant_id}.{ext}` | `a1b2.../abc-123/def-456.webp` |
| `category-images` | `{tenant_id}/{category_id}.{ext}` | `a1b2.../ghi-789.webp` |
| `staff-avatars` | `{tenant_id}/{staff_id}.{ext}` | `a1b2.../jkl-012.webp` |
| `customer-avatars` | `{tenant_id}/{customer_id}.{ext}` | `a1b2.../mno-345.webp` |

**Notes:**

- The `tenant_id` prefix is the full UUID of the tenant, not a slug
- UUIDs for all IDs guarantee global uniqueness
- When a file is replaced, the new file uploads to the same path,
  overwriting the previous file
- Extensions should be standardised to `webp` for optimal compression

## 5. Tenant Isolation in Storage

The `tenant_id` prefix serves two purposes:

**1. Path isolation:** Two tenants can both have a product with the same
UUID (theoretically possible across different tenants). The `tenant_id`
prefix ensures their images never collide.

**2. Policy enforcement:** Storage policies check that the `tenant_id` in
the file path matches the caller's JWT `tenant_id` claim. A staff member
from Tenant A cannot upload to or read from Tenant B's path prefix.

```sql
-- The path prefix check used in storage policies
-- Extracts the first path segment and compares to JWT tenant_id
(storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')
```

## 6. Upload & Delete Permissions

### 6.1. `product-images`

| Operation | Permitted roles |
|---|---|
| Upload | `admin`, `manager` (own tenant only) |
| Delete | `admin` only (own tenant only) |

### 6.2. `category-images`

| Operation | Permitted roles |
|---|---|
| Upload | `admin`, `manager` (own tenant only) |
| Delete | `admin` only (own tenant only) |

### 6.3. `staff-avatars`

| Operation | Permitted roles |
|---|---|
| Upload | Any role — own avatar only |
| Delete | `admin` only (own tenant only) |

Staff can upload and replace their own avatar only. The storage policy
checks that the file path matches both the caller's `tenant_id` and their
own `staff_id`.

### 6.4. `customer-avatars`

| Operation | Permitted roles |
|---|---|
| Upload | `admin`, `manager` (own tenant only) |
| Delete | `admin` only (own tenant only) |

## 7. Storage Policy Pattern

Storage policies follow the same JWT claims pattern as RLS policies.
The `tenant_id` prefix check is added to every policy.

```sql
-- Allow admin and manager to upload product images for their own tenant
CREATE POLICY "tenant_upload_product_images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'product-images'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Allow admin and manager to delete product images for their own tenant
CREATE POLICY "tenant_delete_product_images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'product-images'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')
  AND auth.jwt() ->> 'role' = 'admin'
);
```

For staff avatar own-upload restriction (tenant + own staff_id check):

```sql
-- Allow staff to upload only their own avatar within their tenant
CREATE POLICY "tenant_upload_own_avatar"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'staff-avatars'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')
  AND (storage.filename(name)) = auth.uid()::text || '.' || storage.extension(name)
);
```

For reading private files (own tenant check):

```sql
-- Allow authenticated staff to read private files within their tenant
CREATE POLICY "tenant_read_staff_avatars"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'staff-avatars'
  AND (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')
);
```

## 8. Signed URLs for Private Buckets

When displaying a private file (staff or customer avatar), a signed URL
must be generated server-side. The path now includes `tenant_id`.

```typescript
// Server Action — generate a signed URL for a private avatar
const tenantId = user?.app_metadata?.tenant_id
const staffId = '<staff-uuid>'

const { data } = await supabase.storage
  .from('staff-avatars')
  .createSignedUrl(`${tenantId}/${staffId}.webp`, 3600) // expires in 1 hour

// data.signedUrl is passed to the component for display
```

Signed URLs must be generated at page load time in Server Components and
passed as props to Client Components. Never generate them in Client
Components using the admin client.

## 9. Summary

| Bucket | Public | Upload | Delete | Path prefix |
|---|---|---|---|---|
| `product-images` | ✅ | `admin`, `manager` | `admin` | `{tenant_id}/{product_id}/` |
| `category-images` | ✅ | `admin`, `manager` | `admin` | `{tenant_id}/` |
| `staff-avatars` | 🔒 | Own avatar only | `admin` | `{tenant_id}/` |
| `customer-avatars` | 🔒 | `admin`, `manager` | `admin` | `{tenant_id}/` |

## 10. Changelog

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-03-20 | Initial storage bucket structure finalized |
| 2.0 | 2026-03-23 | Project renamed to Multi-Tenant Food Ordering Platform |
| 2.0 | 2026-03-23 | All file paths now prefixed with `{tenant_id}/` for tenant isolation |
| 2.0 | 2026-03-23 | New Section 5 — Tenant Isolation in Storage — explains prefix strategy |
| 2.0 | 2026-03-23 | All storage policies updated — `tenant_id` path prefix check added |
| 2.0 | 2026-03-23 | Signed URL example updated — path now includes `tenant_id` prefix |
| 2.0 | 2026-03-23 | Summary table updated — path prefix column added |
