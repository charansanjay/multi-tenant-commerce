-- =============================================================================
-- Migration: 0004_customers
-- Description: Customer records per tenant. No auth.users dependency.
--              Email unique per tenant (not globally). Soft delete only.
-- =============================================================================

CREATE TABLE customers (
  id          uuid              PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid              NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  first_name  varchar(100)      NOT NULL,
  last_name   varchar(100)      NOT NULL,
  email       varchar(255),
  phone       varchar(20),
  gender      customer_gender,
  avatar_url  text,
  source      customer_source   NOT NULL DEFAULT 'admin_created',
  is_active   boolean           NOT NULL DEFAULT true,
  notes       text,
  created_by  uuid              REFERENCES staff_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz       NOT NULL DEFAULT now(),
  updated_at  timestamptz       NOT NULL DEFAULT now(),

  -- At least one contact method required
  CONSTRAINT customer_contact_required
    CHECK (email IS NOT NULL OR phone IS NOT NULL),

  -- Email unique within a tenant (allows same email across different tenants)
  CONSTRAINT customers_tenant_email_key
    UNIQUE (tenant_id, email)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_customers_tenant_id ON customers (tenant_id);
CREATE INDEX idx_customers_phone     ON customers (phone);
CREATE INDEX idx_customers_source    ON customers (source);
CREATE INDEX idx_customers_is_active ON customers (is_active);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- All roles can read customers within their tenant
CREATE POLICY "tenant_staff_read_customers"
ON customers FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- All roles can create customers within their tenant
CREATE POLICY "tenant_staff_insert_customers"
ON customers FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- Admins and managers can update customers within their tenant
CREATE POLICY "tenant_admins_managers_update_customers"
ON customers FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Only admins can hard delete within their tenant (soft delete preferred)
CREATE POLICY "tenant_admins_delete_customers"
ON customers FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
