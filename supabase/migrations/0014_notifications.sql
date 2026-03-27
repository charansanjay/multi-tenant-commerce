-- =============================================================================
-- Migration: 0014_notifications
-- Description: Operational notification inbox per tenant.
--              Supports targeted (staff_id set) and broadcast (staff_id NULL) modes.
--              Broadcast is tenant-scoped — never platform-wide.
--              Auto-populated by the sync_product_stock_status trigger.
--              Supports Supabase Realtime subscriptions for live inbox.
-- =============================================================================

CREATE TABLE notifications (
  id            uuid                  PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     uuid                  NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  staff_id      uuid                  REFERENCES staff_profiles(id) ON DELETE CASCADE,
  type          varchar(100)          NOT NULL,
  severity      notification_severity NOT NULL DEFAULT 'info',
  title         varchar(255)          NOT NULL,
  message       text                  NOT NULL,
  entity_type   varchar(100),
  entity_id     uuid,
  entity_label  varchar(255),
  read_at       timestamptz,
  is_dismissed  boolean               NOT NULL DEFAULT false,
  expires_at    timestamptz,
  created_at    timestamptz           NOT NULL DEFAULT now(),

  -- read_at must be >= created_at if set
  CONSTRAINT read_at_after_created
    CHECK (read_at IS NULL OR read_at >= created_at),

  -- expires_at must be in the future relative to created_at
  CONSTRAINT valid_expiry
    CHECK (expires_at IS NULL OR expires_at > created_at)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

-- General tenant lookup
CREATE INDEX idx_notifications_tenant_id
  ON notifications (tenant_id);

-- Unread inbox per staff member (partial — only active notifications)
CREATE INDEX idx_notifications_staff_unread
  ON notifications (tenant_id, staff_id)
  WHERE is_dismissed = false;

-- Broadcast notifications per tenant (staff_id IS NULL), newest first
CREATE INDEX idx_notifications_broadcast
  ON notifications (tenant_id, created_at DESC)
  WHERE staff_id IS NULL;

-- Entity-linked notifications
CREATE INDEX idx_notifications_entity
  ON notifications (entity_type, entity_id);

-- Global time-sorted index
CREATE INDEX idx_notifications_created_at
  ON notifications (created_at DESC);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Staff can read their own notifications and tenant-scoped broadcasts
CREATE POLICY "tenant_staff_read_notifications"
ON notifications FOR SELECT
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND (
    staff_id = auth.uid()
    OR staff_id IS NULL  -- broadcast: visible to all staff of the same tenant
  )
);

-- Server Actions / Edge Functions insert notifications on behalf of staff
CREATE POLICY "tenant_staff_insert_notifications"
ON notifications FOR INSERT
WITH CHECK (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' IN ('admin', 'manager', 'staff')
);

-- Staff can mark own notifications as read or dismissed.
-- Broadcast notifications (staff_id IS NULL) can be dismissed by any tenant staff.
CREATE POLICY "tenant_staff_update_notifications"
ON notifications FOR UPDATE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND (
    staff_id = auth.uid()
    OR staff_id IS NULL
  )
);

-- Only admins can hard delete notifications within their tenant
CREATE POLICY "tenant_admins_delete_notifications"
ON notifications FOR DELETE
USING (
  tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
  AND auth.jwt() ->> 'role' = 'admin'
);
