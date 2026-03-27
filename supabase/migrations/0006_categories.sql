-- =============================================================================
-- Migration: 0006_categories
-- Description: Product category tree per tenant. Each tenant gets a seeded
--              Root category during provisioning. Root deletion is blocked by trigger.
--              Supports flat or nested structure via self-referencing parent_id.
-- =============================================================================

CREATE TABLE categories (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    uuid          NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  parent_id    uuid          REFERENCES categories(id) ON DELETE SET NULL,
  name         varchar(100)  NOT NULL,
  slug         varchar(100)  NOT NULL,
  description  text,
  image_url    text,
  sort_order   integer       NOT NULL DEFAULT 0,
  is_active    boolean       NOT NULL DEFAULT true,
  created_by   uuid          REFERENCES staff_profiles(id) ON DELETE SET NULL,
  created_at   timestamptz   NOT NULL DEFAULT now(),
  updated_at   timestamptz   NOT NULL DEFAULT now(),

  -- Name and slug are unique per tenant (not globally)
  CONSTRAINT categories_tenant_name_key UNIQUE (tenant_id, name),
  CONSTRAINT categories_tenant_slug_key UNIQUE (tenant_id, slug)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_categories_tenant_id  ON categories (tenant_id);
CREATE INDEX idx_categories_parent_id  ON categories (parent_id);
CREATE INDEX idx_categories_sort_order ON categories (sort_order);

-- ---------------------------------------------------------------------------
-- Trigger functions
-- ---------------------------------------------------------------------------

-- Prevent deletion of the per-tenant Root category
CREATE OR REPLACE FUNCTION protect_root_category()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.name = 'Root' THEN
    RAISE EXCEPTION 'Root category cannot be deleted';
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER prevent_root_category_deletion
BEFORE DELETE ON categories
FOR EACH ROW EXECUTE FUNCTION protect_root_category();

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- All staff roles can read categories within their tenant
CREATE POLICY "tenant_staff_read_categories"
ON categories FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Admins and managers can create categories within their tenant
CREATE POLICY "tenant_admins_managers_insert_categories"
ON categories FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Admins and managers can update categories within their tenant
CREATE POLICY "tenant_admins_managers_update_categories"
ON categories FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Only admins can delete categories within their tenant
-- Root category deletion is additionally blocked by trigger
CREATE POLICY "tenant_admins_delete_categories"
ON categories FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
