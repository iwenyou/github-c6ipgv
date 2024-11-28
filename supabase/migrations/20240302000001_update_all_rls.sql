-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

-- Categories RLS policies
CREATE POLICY "Enable read access for authenticated users on categories"
  ON categories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for admin users on categories"
  ON categories
  FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Materials RLS policies
CREATE POLICY "Enable read access for authenticated users on materials"
  ON materials
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for admin users on materials"
  ON materials
  FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Products RLS policies
CREATE POLICY "Enable read access for authenticated users on products"
  ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for admin users on products"
  ON products
  FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Product Materials RLS policies
CREATE POLICY "Enable read access for authenticated users on product_materials"
  ON product_materials
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable write access for admin users on product_materials"
  ON product_materials
  FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- Spaces RLS policies
CREATE POLICY "Enable read access for authenticated users on spaces"
  ON spaces
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND (
      EXISTS (
        SELECT 1 FROM quotes
        WHERE quotes.id = spaces.quote_id
        AND (quotes.user_id = auth.uid() OR auth.jwt() ->> 'role' IN ('admin', 'sales'))
      )
    )
  );

CREATE POLICY "Enable write access for sales and admin users on spaces"
  ON spaces
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = spaces.quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
    )
  );

-- Items RLS policies
CREATE POLICY "Enable read access for authenticated users on items"
  ON items
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND (
      EXISTS (
        SELECT 1 FROM spaces
        JOIN quotes ON quotes.id = spaces.quote_id
        WHERE spaces.id = items.space_id
        AND (quotes.user_id = auth.uid() OR auth.jwt() ->> 'role' IN ('admin', 'sales'))
      )
    )
  );

CREATE POLICY "Enable write access for sales and admin users on items"
  ON items
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = items.space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
    )
  );

-- Orders RLS policies
CREATE POLICY "Enable read access for authenticated users on orders"
  ON orders
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND (
      user_id = auth.uid() OR auth.jwt() ->> 'role' IN ('admin', 'sales')
    )
  );

CREATE POLICY "Enable write access for sales and admin users on orders"
  ON orders
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    (user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
  );

-- Receipts RLS policies
CREATE POLICY "Enable read access for authenticated users on receipts"
  ON receipts
  FOR SELECT
  USING (
    auth.role() = 'authenticated' AND (
      EXISTS (
        SELECT 1 FROM orders
        WHERE orders.id = receipts.order_id
        AND (orders.user_id = auth.uid() OR auth.jwt() ->> 'role' IN ('admin', 'sales'))
      )
    )
  );

CREATE POLICY "Enable write access for sales and admin users on receipts"
  ON receipts
  FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    auth.jwt() ->> 'role' IN ('admin', 'sales') AND
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = receipts.order_id
      AND (orders.user_id = auth.uid() OR auth.jwt() ->> 'role' = 'admin')
    )
  );