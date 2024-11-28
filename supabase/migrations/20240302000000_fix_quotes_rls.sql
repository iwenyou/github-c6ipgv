-- Drop existing RLS policies for quotes
DROP POLICY IF EXISTS "Users can view their own quotes" ON quotes;
DROP POLICY IF EXISTS "Users can insert their own quotes" ON quotes;
DROP POLICY IF EXISTS "Users can update their own quotes" ON quotes;
DROP POLICY IF EXISTS "Users can delete their own quotes" ON quotes;

-- Create improved RLS policies for quotes
CREATE POLICY "Enable read access for authenticated users"
  ON quotes
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND (
      auth.uid() = user_id OR
      auth.jwt() ->> 'role' IN ('admin', 'sales')
    )
  );

CREATE POLICY "Enable insert access for sales and admin users"
  ON quotes
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    auth.uid() = user_id
  );

CREATE POLICY "Enable update access for sales and admin users"
  ON quotes
  FOR UPDATE
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin')
  );

CREATE POLICY "Enable delete access for admin users"
  ON quotes
  FOR DELETE
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' = 'admin'
  );