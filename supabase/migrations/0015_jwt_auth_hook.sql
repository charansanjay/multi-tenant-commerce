-- =============================================================================
-- Migration: 0015_jwt_auth_hook
-- Description: Custom JWT claims hook. Must run AFTER all tables are created
--              because the function body references staff_profiles%ROWTYPE and
--              tenants%ROWTYPE — PostgreSQL resolves these at function creation time.
--
-- After applying: register in Supabase Dashboard → Authentication → Hooks
--                 Hook type: Custom Access Token
--                 Function:  custom_jwt_claims
-- =============================================================================

CREATE OR REPLACE FUNCTION custom_jwt_claims()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_staff   staff_profiles%ROWTYPE;
  v_tenant  tenants%ROWTYPE;
  v_claims  jsonb;
BEGIN
  -- Look up the staff member
  SELECT * INTO v_staff
  FROM staff_profiles
  WHERE id = auth.uid();

  -- Block: no staff profile found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Account does not exist or has been removed';
  END IF;

  -- Block: staff account deactivated
  IF v_staff.is_active = false THEN
    RAISE EXCEPTION 'Account has been deactivated';
  END IF;

  -- Look up the tenant
  SELECT * INTO v_tenant
  FROM tenants
  WHERE id = v_staff.tenant_id;

  -- Block: tenant not found
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Tenant account not found';
  END IF;

  -- Block: tenant suspended
  IF v_tenant.is_active = false THEN
    RAISE EXCEPTION 'Account access has been suspended';
  END IF;

  -- Build custom claims
  v_claims := jsonb_build_object(
    'role',        v_staff.role::text,
    'tenant_id',   v_staff.tenant_id::text,
    'tenant_name', v_tenant.name,
    'staff_name',  v_staff.first_name || ' ' || v_staff.last_name
  );

  RETURN v_claims;
END;
$$;
