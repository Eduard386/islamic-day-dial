-- visits table for web & iOS analytics
-- Run in Supabase SQL Editor or via: supabase db push

CREATE TABLE IF NOT EXISTS visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  visitor_id text NOT NULL,
  platform text NOT NULL DEFAULT 'web',
  path text,
  referrer text,
  user_agent text,
  screen_width int,
  screen_height int,
  language text,
  os text,
  browser text,
  device_type text,
  country text,
  city text,
  region text,
  timezone text,
  geo_source text
);

-- For existing tables: add new columns if missing
ALTER TABLE visits ADD COLUMN IF NOT EXISTS geo_source text;
ALTER TABLE visits ADD COLUMN IF NOT EXISTS platform text NOT NULL DEFAULT 'web';

-- Enable RLS; allow anonymous insert (anon key)
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anonymous insert" ON visits;
CREATE POLICY "Allow anonymous insert" ON visits
  FOR INSERT
  TO anon
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow service role full access" ON visits;
CREATE POLICY "Allow service role full access" ON visits
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
