-- =============================================================================
-- Migration: 0012_payments
-- Description: Payment attempts per order. Multiple attempts allowed.
--              attempt_number is auto-set by trigger (no manual input needed).
--              Only one successful payment per order enforced by partial unique index.
--              sync_order_payment_status trigger keeps orders.payment_status in sync.
-- =============================================================================

CREATE TABLE payments (
  id               uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        uuid            NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  order_id         uuid            NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  attempt_number   integer         NOT NULL DEFAULT 1 CHECK (attempt_number > 0),
  status           payment_status  NOT NULL DEFAULT 'pending',
  payment_method   payment_method  NOT NULL,
  amount           numeric(10,2)   NOT NULL CHECK (amount > 0),
  currency         varchar(10)     NOT NULL DEFAULT 'CZK',
  transaction_ref  varchar(255),
  payment_gateway  varchar(100),
  is_successful    boolean         NOT NULL DEFAULT false,
  paid_at          timestamptz,
  refunded_at      timestamptz,
  refund_reason    text,
  failure_reason   text,
  notes            text,
  created_at       timestamptz     NOT NULL DEFAULT now(),
  updated_at       timestamptz     NOT NULL DEFAULT now(),

  -- attempt_number unique per order
  CONSTRAINT unique_attempt_per_order
    UNIQUE (order_id, attempt_number),

  -- paid_at is required when status = 'paid'
  CONSTRAINT paid_at_required_when_paid
    CHECK (status != 'paid' OR paid_at IS NOT NULL),

  -- Both refunded_at and refund_reason required when status = 'refunded'
  CONSTRAINT refund_fields_required
    CHECK (status != 'refunded' OR (refunded_at IS NOT NULL AND refund_reason IS NOT NULL)),

  -- failure_reason required when status = 'failed'
  CONSTRAINT failure_reason_required
    CHECK (status != 'failed' OR failure_reason IS NOT NULL),

  -- is_successful can only be true when status = 'paid'
  CONSTRAINT successful_only_when_paid
    CHECK (is_successful = false OR status = 'paid'),

  -- Cash on delivery payments must not have a gateway reference
  CONSTRAINT no_gateway_for_cash
    CHECK (payment_method != 'cash_on_delivery' OR payment_gateway IS NULL)
);

-- Only one successful payment per order (partial unique index)
CREATE UNIQUE INDEX one_successful_payment_per_order
  ON payments (order_id)
  WHERE is_successful = true;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_payments_tenant_id ON payments (tenant_id);
CREATE INDEX idx_payments_order_id  ON payments (order_id);
CREATE INDEX idx_payments_status    ON payments (status);

-- ---------------------------------------------------------------------------
-- Trigger functions
-- ---------------------------------------------------------------------------

-- Auto-increment attempt_number per order (no manual input required)
CREATE OR REPLACE FUNCTION set_payment_attempt_number()
RETURNS TRIGGER AS $$
BEGIN
  SELECT COALESCE(MAX(attempt_number), 0) + 1
  INTO NEW.attempt_number
  FROM payments
  WHERE order_id = NEW.order_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Sync orders.payment_status when a payment succeeds or fails
CREATE OR REPLACE FUNCTION sync_order_payment_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Propagate successful payment status to parent order
  IF NEW.is_successful = true THEN
    UPDATE orders SET payment_status = NEW.status
    WHERE id = NEW.order_id;
  END IF;

  -- Propagate failed status only if no successful payment exists
  IF NEW.status = 'failed' THEN
    IF NOT EXISTS (
      SELECT 1 FROM payments
      WHERE order_id = NEW.order_id
      AND is_successful = true
    ) THEN
      UPDATE orders SET payment_status = 'failed'
      WHERE id = NEW.order_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER auto_attempt_number
BEFORE INSERT ON payments
FOR EACH ROW EXECUTE FUNCTION set_payment_attempt_number();

CREATE TRIGGER sync_payment_status
AFTER INSERT OR UPDATE OF status, is_successful
ON payments
FOR EACH ROW EXECUTE FUNCTION sync_order_payment_status();

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON payments
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Admins and managers can read payments within their tenant
CREATE POLICY "tenant_admins_managers_read_payments"
ON payments FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- All staff can insert payment attempts within their tenant
CREATE POLICY "tenant_staff_insert_payments"
ON payments FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- Admins and managers can update payment status within their tenant
CREATE POLICY "tenant_admins_managers_update_payments"
ON payments FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager')
);

-- Only admins can delete payment records within their tenant
CREATE POLICY "tenant_admins_delete_payments"
ON payments FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
