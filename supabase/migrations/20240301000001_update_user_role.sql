-- Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(user_id UUID, new_role TEXT)
RETURNS void AS $$
BEGIN
  -- Validate role
  IF new_role NOT IN ('admin', 'sales', 'visitor') THEN
    RAISE EXCEPTION 'Invalid role. Must be admin, sales, or visitor';
  END IF;

  -- Update auth.users metadata
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    to_jsonb(new_role)
  )
  WHERE id = user_id;

  -- Update users table
  UPDATE users
  SET role = new_role
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_user_role TO authenticated;

-- Example usage (run this in SQL editor):
-- SELECT update_user_role('a319c24a-fe98-47b9-b97a-aecded03e29a', 'admin');