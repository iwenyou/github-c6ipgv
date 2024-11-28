-- Drop and recreate the quotes insert policy
DROP POLICY IF EXISTS "Sales and admin can create quotes" ON quotes;

CREATE POLICY "Sales and admin can create quotes"
  ON quotes
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND (
        auth.users.raw_user_meta_data->>'role' IN ('admin', 'sales')
      )
    )
  );

-- Drop and recreate the quotes update policy
DROP POLICY IF EXISTS "Sales and admin can update quotes" ON quotes;

CREATE POLICY "Sales and admin can update quotes"
  ON quotes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND (
        auth.users.raw_user_meta_data->>'role' IN ('admin', 'sales')
      )
    )
  );