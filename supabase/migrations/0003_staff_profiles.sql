-- =============================================================================
-- Migration: 0003_staff_profiles
-- Description: Staff accounts. PK mirrors auth.users(id).
--              Role-based RLS — admins manage all, staff can only read/update own.
-- =============================================================================

CREATE TABLE staff_profiles (
  id          uuid          PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id   uuid          NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  first_name  varchar(100)  NOT NULL,
  last_name   varchar(100)  NOT NULL,
  email       varchar(255)  NOT NULL,
  phone       varchar(20),
  role        staff_role    NOT NULL DEFAULT 'staff',
  avatar_url  text,
  is_active   boolean       NOT NULL DEFAULT true,
  created_by  uuid          REFERENCES staff_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz   NOT NULL DEFAULT now(),
  updated_at  timestamptz   NOT NULL DEFAULT now(),

  CONSTRAINT staff_profiles_tenant_email_key UNIQUE (tenant_id, email)
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX staff_profiles_tenant_id_idx ON staff_profiles (tenant_id);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON staff_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE staff_profiles ENABLE ROW LEVEL SECURITY;

-- Admins can read all staff within their tenant
CREATE POLICY "admins_read_tenant_staff"
ON staff_profiles FOR SELECT
USING (
  auth.jwt() ->> 'role' = 'admin'
  AND tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Managers can read all staff within their tenant
CREATE POLICY "managers_read_tenant_staff"
ON staff_profiles FOR SELECT
USING (
  auth.jwt() ->> 'role' = 'manager'
  AND tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Any staff can read their own profile
CREATE POLICY "staff_read_own_profile"
ON staff_profiles FOR SELECT
USING (auth.uid() = id);

-- Only admins can create new staff within their tenant
CREATE POLICY "admins_insert_tenant_staff"
ON staff_profiles FOR INSERT
WITH CHECK (
  auth.jwt() ->> 'role' = 'admin'
  AND tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Admins can update any staff profile within their tenant
CREATE POLICY "admins_update_tenant_staff"
ON staff_profiles FOR UPDATE
USING (
  auth.jwt() ->> 'role' = 'admin'
  AND tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
);

-- Any staff can update their own profile
CREATE POLICY "staff_update_own_profile"
ON staff_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Hard deletes are blocked for all roles (use is_active = false)
-- No DELETE policy defined intentionally
