-- RLS Policies for all tables

-- Users policies
CREATE POLICY "Users can view their own profile"
  ON users
  FOR SELECT
  USING (auth.uid() = id OR auth.jwt()->>'role' = 'admin');

CREATE POLICY "Only admin can modify users"
  ON users
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Categories policies
CREATE POLICY "Everyone can view categories"
  ON categories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify categories"
  ON categories
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Materials policies
CREATE POLICY "Everyone can view materials"
  ON materials
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify materials"
  ON materials
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Products policies
CREATE POLICY "Everyone can view products"
  ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify products"
  ON products
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Product materials policies
CREATE POLICY "Everyone can view product materials"
  ON product_materials
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify product materials"
  ON product_materials
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Quotes policies
CREATE POLICY "Users can view their quotes"
  ON quotes
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role IN ('admin', 'sales')
    )
  );

CREATE POLICY "Sales and admin can create quotes"
  ON quotes
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id 
    AND 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role IN ('admin', 'sales')
    )
  );

CREATE POLICY "Sales and admin can update quotes"
  ON quotes
  FOR UPDATE
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role IN ('admin', 'sales')
    )
  );

CREATE POLICY "Admin can delete quotes"
  ON quotes
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role = 'admin'
    )
  );

-- Spaces policies
CREATE POLICY "Users can view spaces"
  ON spaces
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Sales and admin can modify spaces"
  ON spaces
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

-- Items policies
CREATE POLICY "Users can view items"
  ON items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Sales and admin can modify items"
  ON items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

-- Orders policies
CREATE POLICY "Users can view their orders"
  ON orders
  FOR SELECT
  USING (
    user_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role IN ('admin', 'sales')
    )
  );

CREATE POLICY "Sales and admin can modify orders"
  ON orders
  FOR ALL
  USING (
    auth.jwt()->>'role' IN ('admin', 'sales')
  );

-- Receipts policies
CREATE POLICY "Users can view receipts"
  ON receipts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_id
      AND (orders.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Sales and admin can modify receipts"
  ON receipts
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_id
      AND auth.jwt()->>'role' IN ('admin', 'sales')
    )
  );

-- Preset values policies
CREATE POLICY "Everyone can view preset values"
  ON preset_values
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify preset values"
  ON preset_values
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Template settings policies
CREATE POLICY "Everyone can view template settings"
  ON template_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Only admin can modify template settings"
  ON template_settings
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');