-- Add first_name and last_name columns to users table
ALTER TABLE users 
ADD COLUMN first_name TEXT,
ADD COLUMN last_name TEXT;

-- Update the user_metadata function to include names
CREATE OR REPLACE FUNCTION update_user_metadata(
  user_id UUID,
  first_name TEXT,
  last_name TEXT,
  role TEXT
)
RETURNS void AS $$
BEGIN
  -- Validate role
  IF role NOT IN ('admin', 'sales', 'visitor') THEN
    RAISE EXCEPTION 'Invalid role. Must be admin, sales, or visitor';
  END IF;

  -- Update auth.users metadata
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    jsonb_set(
      jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{role}',
        to_jsonb(role)
      ),
      '{first_name}',
      to_jsonb(first_name)
    ),
    '{last_name}',
    to_jsonb(last_name)
  )
  WHERE id = user_id;

  -- Update users table
  UPDATE users
  SET 
    first_name = update_user_metadata.first_name,
    last_name = update_user_metadata.last_name,
    role = update_user_metadata.role
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_user_metadata TO authenticated;