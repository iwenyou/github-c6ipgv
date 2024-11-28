-- Create spaces table
CREATE TABLE IF NOT EXISTS spaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quote_id UUID NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
);

-- Create items table
CREATE TABLE IF NOT EXISTS items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  space_id UUID NOT NULL,
  product_id TEXT,
  material TEXT,
  width NUMERIC NOT NULL,
  height NUMERIC NOT NULL,
  depth NUMERIC NOT NULL,
  price NUMERIC NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for spaces
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

CREATE POLICY "Users can insert spaces"
  ON spaces
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Users can update spaces"
  ON spaces
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Users can delete spaces"
  ON spaces
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

-- Create RLS policies for items
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

CREATE POLICY "Users can insert items"
  ON items
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Users can update items"
  ON items
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

CREATE POLICY "Users can delete items"
  ON items
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM spaces
      JOIN quotes ON quotes.id = spaces.quote_id
      WHERE spaces.id = space_id
      AND (quotes.user_id = auth.uid() OR auth.jwt()->>'role' IN ('admin', 'sales'))
    )
  );

-- Add updated_at triggers
CREATE TRIGGER update_spaces_updated_at
  BEFORE UPDATE ON spaces
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at
  BEFORE UPDATE ON items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes
CREATE INDEX idx_spaces_quote_id ON spaces(quote_id);
CREATE INDEX idx_items_space_id ON items(space_id);