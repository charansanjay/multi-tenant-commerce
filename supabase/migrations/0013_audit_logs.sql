-- =============================================================================
-- Migration: 0013_audit_logs
-- Description: Immutable, append-only audit trail. No FK constraints on
--              tenant_id or staff_id — rows must survive tenant/staff deletion.
--              UPDATE and DELETE are blocked by triggers (not by absence of policy).
--              GIN indexes on old_values/new_values support jsonb queries.
-- =============================================================================

CREATE TABLE audit_logs (
  id           uuid          PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Tenant context — stored as plain uuid, NO FK constraint.
  -- Audit trail must survive tenant purge for legal/compliance reasons.
  tenant_id    uuid,
  tenant_name  varchar(255),  -- snapshot at log time

  -- Actor — stored as plain uuid, NO FK constraint.
  -- Audit trail must survive staff account deletion.
  staff_id     uuid,
  staff_name   varchar(200),  -- snapshot at log time
  staff_email  varchar(255),  -- snapshot at log time
  staff_role   varchar(50),   -- snapshot at log time

  -- Action performed
  action       audit_action  NOT NULL,

  -- Affected entity (generic reference pattern — no FK)
  entity_type  varchar(100)  NOT NULL,
  entity_id    uuid,
  entity_label varchar(255),

  -- Before/after state snapshots
  old_values   jsonb,
  new_values   jsonb,

  -- Request context
  ip_address   inet,
  user_agent   text,
  notes        text,

  created_at   timestamptz   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_audit_logs_tenant_id  ON audit_logs (tenant_id);
CREATE INDEX idx_audit_logs_staff_id   ON audit_logs (staff_id);
CREATE INDEX idx_audit_logs_entity     ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_action     ON audit_logs (action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at DESC);
CREATE INDEX idx_audit_logs_new_values ON audit_logs USING GIN (new_values);
CREATE INDEX idx_audit_logs_old_values ON audit_logs USING GIN (old_values);

-- ---------------------------------------------------------------------------
-- Trigger function: enforce immutability
-- UPDATE and DELETE raise an exception regardless of who is calling.
-- RLS alone is not sufficient — this makes immutability absolute.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION protect_audit_logs()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are immutable and cannot be modified or deleted';
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER no_update_audit_logs
BEFORE UPDATE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION protect_audit_logs();

CREATE TRIGGER no_delete_audit_logs
BEFORE DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION protect_audit_logs();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Admins can read audit logs within their own tenant
CREATE POLICY "tenant_admins_read_audit_logs"
ON audit_logs FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);

-- All authenticated staff can insert audit logs within their tenant
CREATE POLICY "tenant_staff_insert_audit_logs"
ON audit_logs FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- No UPDATE policy — immutability enforced by trigger (not just policy absence)
-- No DELETE policy — immutability enforced by trigger (not just policy absence)
