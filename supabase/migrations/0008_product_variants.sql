-- =============================================================================
-- Migration: 0008_product_variants
-- Description: Product variants with pricing, stock tracking, and auto-sync.
--              actual_price is a generated column (base_price - discount).
--              Trigger syncs parent product status and fires low-stock notifications.
--              NOTE: notifications table must exist before this trigger fires.
--              The trigger is defined here but safe because it only fires on DML,
--              not on table creation.
-- =============================================================================

CREATE TABLE product_variants (
  id                   uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            uuid          NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  product_id           uuid          NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name                 varchar(100)  NOT NULL,
  option_name          varchar(50)   NOT NULL,
  sku                  varchar(100),
  base_price           numeric(10,2) NOT NULL CHECK (base_price > 0),
  discount_percentage  numeric(5,2)  NOT NULL DEFAULT 0
                         CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  actual_price         numeric(10,2) GENERATED ALWAYS AS (
                         ROUND(base_price - (base_price * discount_percentage / 100), 2)
                       ) STORED,
  currency             varchar(10)   NOT NULL DEFAULT 'CZK',
  stock_quantity       integer       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  low_stock_threshold  integer       NOT NULL DEFAULT 5 CHECK (low_stock_threshold >= 0),
  is_available         boolean       NOT NULL DEFAULT true,
  is_active            boolean       NOT NULL DEFAULT true,
  sort_order           integer       NOT NULL DEFAULT 0,
  created_at           timestamptz   NOT NULL DEFAULT now(),
  updated_at           timestamptz   NOT NULL DEFAULT now(),

  -- SKU unique per tenant
  CONSTRAINT variants_tenant_sku_key UNIQUE (tenant_id, sku),
  -- One option_name per product (e.g. only one 'large' variant per product)
  CONSTRAINT one_option_per_product  UNIQUE (product_id, option_name)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_variants_tenant_id  ON product_variants (tenant_id);
CREATE INDEX idx_variants_product_id ON product_variants (product_id);
CREATE INDEX idx_variants_is_active  ON product_variants (is_active);

-- ---------------------------------------------------------------------------
-- Trigger function: sync_product_stock_status
-- Fires BEFORE INSERT OR UPDATE on stock_quantity / is_active.
-- 1. Sets is_available based on stock_quantity.
-- 2. Syncs parent product.status to 'out_of_stock' / 'active'.
-- 3. Inserts a low_stock broadcast notification when threshold is crossed.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_product_stock_status()
RETURNS TRIGGER AS $$
DECLARE
  v_tenant_id    uuid;
  v_product_name varchar;
BEGIN
  -- Resolve tenant_id and product name for notification
  SELECT p.tenant_id, p.name INTO v_tenant_id, v_product_name
  FROM products p WHERE p.id = NEW.product_id;

  -- 1. Toggle is_available
  IF NEW.stock_quantity = 0 THEN
    NEW.is_available = false;
  ELSE
    NEW.is_available = true;
  END IF;

  -- 2. Sync parent product status
  IF NOT EXISTS (
    SELECT 1 FROM product_variants
    WHERE product_id = NEW.product_id
    AND is_active = true
    AND stock_quantity > 0
  ) THEN
    UPDATE products SET status = 'out_of_stock'
    WHERE id = NEW.product_id AND status = 'active';
  ELSE
    UPDATE products SET status = 'active'
    WHERE id = NEW.product_id AND status = 'out_of_stock';
  END IF;

  -- 3. Low stock notification (tenant-scoped broadcast)
  --    Fires only when crossing the threshold downward (not on every low-stock update)
  IF NEW.stock_quantity <= NEW.low_stock_threshold
    AND NEW.stock_quantity > 0
    AND (OLD.stock_quantity IS NULL OR OLD.stock_quantity > OLD.low_stock_threshold)
  THEN
    INSERT INTO notifications (
      tenant_id, staff_id, type, severity, title, message,
      entity_type, entity_id, entity_label
    ) VALUES (
      v_tenant_id,
      null,
      'low_stock',
      'warning',
      'Low Stock Alert',
      'Stock for ' || v_product_name || ' (' || NEW.name || ') has dropped to '
        || NEW.stock_quantity || ' units',
      'product_variant',
      NEW.id,
      v_product_name || ' — ' || NEW.name
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER sync_stock_status
BEFORE INSERT OR UPDATE OF stock_quantity, is_active
ON product_variants
FOR EACH ROW EXECUTE FUNCTION sync_product_stock_status();

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON product_variants
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_staff_read_variants"
ON product_variants FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

CREATE POLICY "tenant_admins_managers_insert_variants"
ON product_variants FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

CREATE POLICY "tenant_admins_managers_update_variants"
ON product_variants FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

CREATE POLICY "tenant_admins_delete_variants"
ON product_variants FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
