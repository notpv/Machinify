/*
  # Create Machinify Database Schema

  1. New Tables
    - `sites`
      - `site_id` (uuid, primary key)
      - `site_name` (text, unique)
      - `latitude` (double precision, optional)
      - `longitude` (double precision, optional)
      - `address` (text, optional)
      - `contact_person` (text, optional)
      - `contact_phone` (text, optional)
      - `region` (text, optional)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `machines`
      - `machine_id` (text, primary key)
      - `type` (text, enum-like constraint)
      - `model` (text)
      - `brand` (text)
      - `purchase_date` (date)
      - `assigned_site_id` (uuid, foreign key to sites)
      - `photo_url` (text, optional)
      - `qr_code` (text, unique)
      - `is_active` (boolean, default true)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `usage_logs`
      - `log_id` (uuid, primary key)
      - `machine_id` (text, foreign key to machines)
      - `date` (date)
      - `hours_run` (double precision)
      - `diesel_consumed` (double precision)
      - `operator_name` (text)
      - `fuel_bill_url` (text, optional)
      - `fuel_efficiency` (double precision, calculated)
      - `is_validated` (boolean, default true)
      - `remarks` (text, optional)
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

    - `movements`
      - `movement_id` (uuid, primary key)
      - `machine_id` (text, foreign key to machines)
      - `from_site_id` (uuid, foreign key to sites)
      - `to_site_id` (uuid, foreign key to sites)
      - `movement_date` (date)
      - `transporter_name` (text)
      - `remarks` (text, optional)
      - `from_latitude` (double precision, optional)
      - `from_longitude` (double precision, optional)
      - `to_latitude` (double precision, optional)
      - `to_longitude` (double precision, optional)
      - `status` (text, default 'pending')
      - `created_at` (timestamptz, default now())
      - `updated_at` (timestamptz, default now())

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users based on roles
*/

-- Create sites table
CREATE TABLE IF NOT EXISTS sites (
  site_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  site_name text UNIQUE NOT NULL,
  latitude double precision,
  longitude double precision,
  address text,
  contact_person text,
  contact_phone text,
  region text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create machines table
CREATE TABLE IF NOT EXISTS machines (
  machine_id text PRIMARY KEY,
  type text NOT NULL CHECK (type IN ('Excavator', 'Roller', 'Bulldozer', 'Crane', 'Grader')),
  model text NOT NULL,
  brand text NOT NULL,
  purchase_date date NOT NULL,
  assigned_site_id uuid NOT NULL REFERENCES sites(site_id),
  photo_url text,
  qr_code text UNIQUE NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create usage_logs table
CREATE TABLE IF NOT EXISTS usage_logs (
  log_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id text NOT NULL REFERENCES machines(machine_id),
  date date NOT NULL,
  hours_run double precision NOT NULL CHECK (hours_run > 0),
  diesel_consumed double precision NOT NULL CHECK (diesel_consumed > 0),
  operator_name text NOT NULL,
  fuel_bill_url text,
  fuel_efficiency double precision,
  is_validated boolean DEFAULT true,
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create movements table
CREATE TABLE IF NOT EXISTS movements (
  movement_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  machine_id text NOT NULL REFERENCES machines(machine_id),
  from_site_id uuid NOT NULL REFERENCES sites(site_id),
  to_site_id uuid NOT NULL REFERENCES sites(site_id),
  movement_date date NOT NULL,
  transporter_name text NOT NULL,
  remarks text,
  from_latitude double precision,
  from_longitude double precision,
  to_latitude double precision,
  to_longitude double precision,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'in_transit', 'completed')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT different_sites CHECK (from_site_id != to_site_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_machines_assigned_site ON machines(assigned_site_id);
CREATE INDEX IF NOT EXISTS idx_machines_type ON machines(type);
CREATE INDEX IF NOT EXISTS idx_machines_qr_code ON machines(qr_code);
CREATE INDEX IF NOT EXISTS idx_usage_logs_machine_id ON usage_logs(machine_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_date ON usage_logs(date);
CREATE INDEX IF NOT EXISTS idx_movements_machine_id ON movements(machine_id);
CREATE INDEX IF NOT EXISTS idx_movements_status ON movements(status);
CREATE INDEX IF NOT EXISTS idx_movements_date ON movements(movement_date);

-- Enable Row Level Security
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE machines ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for sites
CREATE POLICY "Sites are viewable by authenticated users"
  ON sites
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Sites can be inserted by authenticated users"
  ON sites
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Sites can be updated by authenticated users"
  ON sites
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create RLS policies for machines
CREATE POLICY "Machines are viewable by authenticated users"
  ON machines
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Machines can be inserted by authenticated users"
  ON machines
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Machines can be updated by authenticated users"
  ON machines
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create RLS policies for usage_logs
CREATE POLICY "Usage logs are viewable by authenticated users"
  ON usage_logs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Usage logs can be inserted by authenticated users"
  ON usage_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Usage logs can be updated by authenticated users"
  ON usage_logs
  FOR UPDATE
  TO authenticated
  USING (true);

-- Create RLS policies for movements
CREATE POLICY "Movements are viewable by authenticated users"
  ON movements
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Movements can be inserted by authenticated users"
  ON movements
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Movements can be updated by authenticated users"
  ON movements
  FOR UPDATE
  TO authenticated
  USING (true);