-- =============================================================================
-- Migration: 0005_addresses
-- Description: Customer delivery addresses. Max 4 active per customer.
--              One active default per customer. Orders snapshot address at order time.
-- =============================================================================

CREATE TABLE addresses (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid          NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  customer_id  uuid          NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  label        varchar(50),
  street       varchar(255)  NOT NULL,
  city         varchar(100)  NOT NULL,
  state        varchar(100),
  postal_code  varchar(20)   NOT NULL,
  country      varchar(100)  NOT NULL,
  notes        text,
  is_default   boolean       NOT NULL DEFAULT false,
  is_active    boolean       NOT NULL DEFAULT true,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  updated_at   timestamptz   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_addresses_tenant_id   ON addresses (tenant_id);
CREATE INDEX idx_addresses_customer_id ON addresses (customer_id);

-- One active default address per customer (partial unique index)
CREATE UNIQUE INDEX one_default_address_per_customer
  ON addresses (customer_id)
  WHERE is_default = true AND is_active = true;

-- ---------------------------------------------------------------------------
-- Trigger functions
-- ---------------------------------------------------------------------------

-- Enforce maximum 4 active addresses per customer
CREATE OR REPLACE FUNCTION check_max_addresses()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    SELECT COUNT(*) FROM addresses
    WHERE customer_id = NEW.customer_id
    AND is_active = true
  ) >= 4 THEN
    RAISE EXCEPTION 'Customer cannot have more than 4 active addresses';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER enforce_max_addresses
BEFORE INSERT ON addresses
FOR EACH ROW EXECUTE FUNCTION check_max_addresses();

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON addresses
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

-- All staff roles can read addresses within their tenant
CREATE POLICY "tenant_staff_read_addresses"
ON addresses FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- All staff roles can create addresses within their tenant
CREATE POLICY "tenant_staff_insert_addresses"
ON addresses FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- All staff roles can update addresses within their tenant
CREATE POLICY "tenant_staff_update_addresses"
ON addresses FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- Only admins and managers can hard delete addresses
CREATE POLICY "tenant_admins_managers_delete_addresses"
ON addresses FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);
