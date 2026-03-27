-- =============================================================================
-- Migration: 0007_products
-- Description: Product catalogue per tenant. Includes product_images child table.
--              Max 4 images per product enforced by trigger.
--              product status is synced automatically by variant stock trigger
--              (defined in 0008_product_variants.sql).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------

CREATE TABLE products (
  id                  uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id           uuid            NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  category_id         uuid            NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  name                varchar(150)    NOT NULL,
  slug                varchar(150)    NOT NULL,
  description         text,
  status              product_status  NOT NULL DEFAULT 'active',
  tags                text[],
  max_order_quantity  integer         CHECK (max_order_quantity > 0),
  created_by          uuid            REFERENCES staff_profiles(id) ON DELETE SET NULL,
  updated_by          uuid            REFERENCES staff_profiles(id) ON DELETE SET NULL,
  created_at          timestamptz     NOT NULL DEFAULT now(),
  updated_at          timestamptz     NOT NULL DEFAULT now(),

  -- Name and slug unique per tenant
  CONSTRAINT products_tenant_name_key UNIQUE (tenant_id, name),
  CONSTRAINT products_tenant_slug_key UNIQUE (tenant_id, slug)
);

-- Indexes
CREATE INDEX idx_products_tenant_id   ON products (tenant_id);
CREATE INDEX idx_products_category_id ON products (category_id);
CREATE INDEX idx_products_status      ON products (status);
CREATE INDEX idx_products_tags        ON products USING GIN (tags);

-- Trigger
CREATE TRIGGER set_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_staff_read_products"
ON products FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

CREATE POLICY "tenant_admins_managers_insert_products"
ON products FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

CREATE POLICY "tenant_admins_managers_update_products"
ON products FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

CREATE POLICY "tenant_admins_delete_products"
ON products FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);

-- ---------------------------------------------------------------------------
-- product_images
-- ---------------------------------------------------------------------------

CREATE TABLE product_images (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   uuid        NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  product_id  uuid        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url   text        NOT NULL,
  is_primary  boolean     NOT NULL DEFAULT false,
  sort_order  integer     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- One primary image per product (partial unique index)
CREATE UNIQUE INDEX one_primary_image_per_product
  ON product_images (product_id)
  WHERE is_primary = true;

CREATE INDEX idx_product_images_tenant_id ON product_images (tenant_id);

-- Enforce maximum 4 images per product
CREATE OR REPLACE FUNCTION check_max_product_images()
RETURNS TRIGGER AS $$
BEGIN
  IF (
    SELECT COUNT(*) FROM product_images
    WHERE product_id = NEW.product_id
  ) >= 4 THEN
    RAISE EXCEPTION 'Product cannot have more than 4 images';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_product_images
BEFORE INSERT ON product_images
FOR EACH ROW EXECUTE FUNCTION check_max_product_images();

-- RLS
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tenant_staff_read_product_images"
ON product_images FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

CREATE POLICY "tenant_admins_managers_manage_product_images"
ON product_images FOR ALL
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);
