-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'sales', 'visitor')) DEFAULT 'visitor',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create quotes table
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  client_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  project_name TEXT NOT NULL,
  installation_address TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'pending', 'approved', 'rejected')) DEFAULT 'draft',
  total NUMERIC NOT NULL CHECK (total > 0),
  adjustment_type TEXT CHECK (adjustment_type IN ('discount', 'surcharge')),
  adjustment_percentage NUMERIC CHECK (adjustment_percentage BETWEEN 0 AND 100),
  adjusted_total NUMERIC CHECK (adjusted_total > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create spaces table
CREATE TABLE spaces (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quote_id UUID NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
);

-- Create items table
CREATE TABLE items (
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
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for quotes
CREATE POLICY "Users can view their own quotes"
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

CREATE POLICY "Users can insert their own quotes"
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

CREATE POLICY "Users can update their own quotes"
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

CREATE POLICY "Users can delete their own quotes"
  ON quotes
  FOR DELETE
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND role = 'admin'
    )
  );

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

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_quotes_updated_at
  BEFORE UPDATE ON quotes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spaces_updated_at
  BEFORE UPDATE ON spaces
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at
  BEFORE UPDATE ON items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create indexes
CREATE INDEX idx_quotes_user_id ON quotes(user_id);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_spaces_quote_id ON spaces(quote_id);
CREATE INDEX idx_items_space_id ON items(space_id);