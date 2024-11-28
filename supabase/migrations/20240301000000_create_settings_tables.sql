-- Create preset_values table
CREATE TABLE preset_values (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  default_height NUMERIC NOT NULL DEFAULT 30,
  default_width NUMERIC NOT NULL DEFAULT 24,
  default_depth NUMERIC NOT NULL DEFAULT 24,
  labor_rate NUMERIC NOT NULL DEFAULT 75,
  material_markup NUMERIC NOT NULL DEFAULT 30,
  tax_rate NUMERIC NOT NULL DEFAULT 13,
  delivery_fee NUMERIC NOT NULL DEFAULT 150,
  installation_fee NUMERIC NOT NULL DEFAULT 500,
  storage_fee NUMERIC NOT NULL DEFAULT 25,
  minimum_order NUMERIC NOT NULL DEFAULT 1000,
  rush_order_fee NUMERIC NOT NULL DEFAULT 15,
  shipping_rate NUMERIC NOT NULL DEFAULT 2.5,
  import_tax_rate NUMERIC NOT NULL DEFAULT 5,
  exchange_rate NUMERIC NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create template_settings table
CREATE TABLE template_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_info JSONB NOT NULL DEFAULT '{
    "name": "Your Company Name",
    "address": "123 Business Street\nCity, State 12345",
    "phone": "(555) 123-4567",
    "email": "contact@company.com",
    "website": "www.company.com"
  }',
  layout JSONB NOT NULL DEFAULT '{
    "primaryColor": "#4F46E5",
    "fontFamily": "Inter",
    "showLogo": true,
    "showCompanyInfo": true,
    "showClientInfo": true,
    "showProjectDetails": true,
    "showValidityPeriod": true,
    "showTaxDetails": true,
    "showFooterNotes": true,
    "showContactButtons": true
  }',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add RLS policies for settings tables
ALTER TABLE preset_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_settings ENABLE ROW LEVEL SECURITY;

-- Everyone can view settings
CREATE POLICY "Everyone can view preset values"
  ON preset_values
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Everyone can view template settings"
  ON template_settings
  FOR SELECT
  TO authenticated
  USING (true);

-- Only admin can modify settings
CREATE POLICY "Only admin can modify preset values"
  ON preset_values
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Only admin can modify template settings"
  ON template_settings
  FOR ALL
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_preset_values_updated_at
  BEFORE UPDATE ON preset_values
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_template_settings_updated_at
  BEFORE UPDATE ON template_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert default values
INSERT INTO preset_values DEFAULT VALUES;
INSERT INTO template_settings DEFAULT VALUES;