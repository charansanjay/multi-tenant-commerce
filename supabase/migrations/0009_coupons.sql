-- =============================================================================
-- Migration: 0009_coupons
-- Description: Discount coupons per tenant. usage_count is incremented atomically
--              via Edge Function (not direct UPDATE) to prevent race conditions.
--              Code unique per tenant (not globally).
-- =============================================================================

CREATE TABLE coupons (
  id                uuid           PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid           NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  code              varchar(50)    NOT NULL,
  description       text,
  discount_type     discount_type  NOT NULL,
  discount_value    numeric(10,2)  NOT NULL CHECK (discount_value > 0),
  min_order_amount  numeric(10,2)  CHECK (min_order_amount >= 0),
  max_usage         integer        CHECK (max_usage > 0),
  usage_count       integer        NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
  valid_from        timestamptz,
  valid_until       timestamptz,
  is_active         boolean        NOT NULL DEFAULT true,
  created_by        uuid           REFERENCES staff_profiles(id) ON DELETE SET NULL,
  created_at        timestamptz    NOT NULL DEFAULT now(),
  updated_at        timestamptz    NOT NULL DEFAULT now(),

  -- Code unique per tenant (same code can exist across tenants)
  CONSTRAINT coupons_tenant_code_key
    UNIQUE (tenant_id, code),

  -- Percentage value cannot exceed 100%
  CONSTRAINT valid_percentage_value
    CHECK (discount_type != 'percentage' OR discount_value <= 100),

  -- valid_until must be after valid_from if both are set
  CONSTRAINT valid_date_range
    CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until > valid_from)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_coupons_tenant_id   ON coupons (tenant_id);
CREATE INDEX idx_coupons_is_active   ON coupons (is_active);
CREATE INDEX idx_coupons_valid_until ON coupons (valid_until);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON coupons
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;

-- All staff roles can read coupons within their tenant
CREATE POLICY "tenant_staff_read_coupons"
ON coupons FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Admins and managers can create coupons within their tenant
CREATE POLICY "tenant_admins_managers_insert_coupons"
ON coupons FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Admins and managers can update coupons within their tenant
CREATE POLICY "tenant_admins_managers_update_coupons"
ON coupons FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Only admins can delete coupons within their tenant
CREATE POLICY "tenant_admins_delete_coupons"
ON coupons FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
