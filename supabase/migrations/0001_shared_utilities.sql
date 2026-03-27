-- =============================================================================
-- Migration: 0001_shared_utilities
-- Description: Shared enums, utility functions, and the JWT auth hook
--              Must run first — all subsequent migrations depend on these.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------------

CREATE TYPE tenant_plan AS ENUM ('free', 'starter', 'pro');

CREATE TYPE staff_role AS ENUM ('admin', 'manager', 'staff');

CREATE TYPE customer_gender AS ENUM ('male', 'female', 'other');

CREATE TYPE customer_source AS ENUM ('website', 'phone', 'walk_in', 'admin_created');

CREATE TYPE product_status AS ENUM ('active', 'out_of_stock', 'disabled');

CREATE TYPE discount_type AS ENUM ('percentage', 'fixed_amount');

CREATE TYPE order_source AS ENUM ('website', 'phone', 'walk_in', 'admin_created');

CREATE TYPE order_status AS ENUM (
  'pending', 'preparing', 'ready', 'out_for_delivery', 'completed', 'cancelled'
);

CREATE TYPE payment_method AS ENUM ('card', 'cash_on_delivery');

CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');

CREATE TYPE audit_action AS ENUM (
  'created', 'updated', 'deleted', 'enabled', 'disabled',
  'login', 'logout', 'exported', 'status_changed'
);

CREATE TYPE notification_severity AS ENUM ('info', 'warning', 'error');


-- ---------------------------------------------------------------------------
-- SHARED UTILITY FUNCTION: update_updated_at
-- Used by triggers on every table that has an updated_at column.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


