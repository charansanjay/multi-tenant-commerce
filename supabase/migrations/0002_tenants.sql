-- =============================================================================
-- Migration: 0002_tenants
-- Description: Root entity table. All other tables FK to tenants(id).
--              No staff-facing RLS policies — service role only.
-- =============================================================================

CREATE TABLE tenants (
  id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  name          varchar(255)  NOT NULL,
  slug          varchar(100)  NOT NULL UNIQUE
                  CHECK (slug ~ '^[a-z0-9-]+$'),
  owner_email   varchar(255)  NOT NULL,
  owner_phone   varchar(20),
  plan          tenant_plan   NOT NULL DEFAULT 'free',
  is_active     boolean       NOT NULL DEFAULT true,
  trial_ends_at timestamptz,
  settings      jsonb         NOT NULL DEFAULT '{}',
  created_at    timestamptz   NOT NULL DEFAULT now(),
  updated_at    timestamptz   NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX tenants_owner_email_idx ON tenants (owner_email);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- No staff-facing policies. All access via service role key from
-- the super-admin application only. Staff JWTs cannot read this table.
-- ---------------------------------------------------------------------------

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
