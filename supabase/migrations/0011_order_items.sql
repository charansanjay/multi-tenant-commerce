-- =============================================================================
-- Migration: 0011_order_items
-- Description: Line items for each order. Fully immutable after insert —
--              no UPDATE policy, no DELETE policy (cascade from orders only).
--              Stores complete product/variant/price snapshots at order time.
--              row_total is enforced to equal unit_price × quantity by CHECK.
-- =============================================================================

CREATE TABLE order_items (
  id                   uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id            uuid          NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  order_id             uuid          NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id           uuid          REFERENCES products(id) ON DELETE SET NULL,
  variant_id           uuid          REFERENCES product_variants(id) ON DELETE SET NULL,

  -- Product & variant snapshots (immutable record of what was ordered)
  product_name         varchar(150)  NOT NULL,
  variant_name         varchar(100)  NOT NULL,
  variant_option       varchar(50)   NOT NULL,
  sku                  varchar(100),

  -- Price snapshots (locked at order time)
  base_price           numeric(10,2) NOT NULL CHECK (base_price > 0),
  discount_percentage  numeric(5,2)  NOT NULL DEFAULT 0
                         CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
  unit_price           numeric(10,2) NOT NULL CHECK (unit_price >= 0),
  quantity             integer       NOT NULL CHECK (quantity > 0),
  row_total            numeric(10,2) NOT NULL CHECK (row_total >= 0),
  currency             varchar(10)   NOT NULL DEFAULT 'CZK',

  notes                text,
  created_at           timestamptz   NOT NULL DEFAULT now(),

  -- Enforce mathematical integrity: row_total must equal unit_price × quantity
  CONSTRAINT valid_row_total
    CHECK (row_total = unit_price * quantity)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_order_items_tenant_id  ON order_items (tenant_id);
CREATE INDEX idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);
CREATE INDEX idx_order_items_variant_id ON order_items (variant_id);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- All staff roles can read order items within their tenant
CREATE POLICY "tenant_staff_read_order_items"
ON order_items FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- All staff roles can insert order items within their tenant
CREATE POLICY "tenant_staff_insert_order_items"
ON order_items FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- No UPDATE policy — order items are immutable after insert
-- No DELETE policy — deletion only via CASCADE from parent orders
