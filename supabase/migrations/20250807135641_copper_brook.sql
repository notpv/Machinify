/*
  # Create Triggers and Functions

  1. Functions
    - Update machine assigned_site_id when movement is completed
    - Calculate fuel efficiency automatically
    - Update updated_at timestamps
    - Validate fuel efficiency thresholds

  2. Triggers
    - Auto-update machine site assignment on movement completion
    - Auto-calculate fuel efficiency on usage log insert/update
    - Auto-update timestamps on record changes
    - Validate fuel efficiency and set is_validated flag
*/

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to calculate fuel efficiency
CREATE OR REPLACE FUNCTION calculate_fuel_efficiency()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate fuel efficiency (liters per hour)
  IF NEW.hours_run > 0 THEN
    NEW.fuel_efficiency = NEW.diesel_consumed / NEW.hours_run;
    
    -- Validate fuel efficiency (0.5 to 10.0 L/hour is considered normal)
    IF NEW.fuel_efficiency < 0.5 OR NEW.fuel_efficiency > 10.0 THEN
      NEW.is_validated = false;
    ELSE
      NEW.is_validated = true;
    END IF;
  ELSE
    NEW.fuel_efficiency = 0;
    NEW.is_validated = false;
  END IF;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to update machine site assignment when movement is completed
CREATE OR REPLACE FUNCTION update_machine_site_on_movement()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update when movement status changes to 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    UPDATE machines 
    SET assigned_site_id = NEW.to_site_id,
        updated_at = now()
    WHERE machine_id = NEW.machine_id;
  END IF;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to validate movement data
CREATE OR REPLACE FUNCTION validate_movement()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure from_site and to_site are different
  IF NEW.from_site_id = NEW.to_site_id THEN
    RAISE EXCEPTION 'From site and to site cannot be the same';
  END IF;
  
  -- Ensure movement date is not in the future (more than 1 day)
  IF NEW.movement_date > CURRENT_DATE + INTERVAL '1 day' THEN
    RAISE EXCEPTION 'Movement date cannot be more than 1 day in the future';
  END IF;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to validate usage log data
CREATE OR REPLACE FUNCTION validate_usage_log()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure usage date is not in the future
  IF NEW.date > CURRENT_DATE THEN
    RAISE EXCEPTION 'Usage date cannot be in the future';
  END IF;
  
  -- Ensure usage date is not more than 30 days old
  IF NEW.date < CURRENT_DATE - INTERVAL '30 days' THEN
    RAISE EXCEPTION 'Usage date cannot be more than 30 days old';
  END IF;
  
  -- Ensure hours_run is reasonable (max 24 hours per day)
  IF NEW.hours_run > 24 THEN
    RAISE EXCEPTION 'Hours run cannot exceed 24 hours per day';
  END IF;
  
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_sites_updated_at
  BEFORE UPDATE ON sites
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_machines_updated_at
  BEFORE UPDATE ON machines
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usage_logs_updated_at
  BEFORE UPDATE ON usage_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_movements_updated_at
  BEFORE UPDATE ON movements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for fuel efficiency calculation
CREATE TRIGGER calculate_fuel_efficiency_trigger
  BEFORE INSERT OR UPDATE ON usage_logs
  FOR EACH ROW
  EXECUTE FUNCTION calculate_fuel_efficiency();

-- Create trigger for machine site assignment update
CREATE TRIGGER update_machine_site_trigger
  AFTER INSERT OR UPDATE ON movements
  FOR EACH ROW
  EXECUTE FUNCTION update_machine_site_on_movement();

-- Create trigger for movement validation
CREATE TRIGGER validate_movement_trigger
  BEFORE INSERT OR UPDATE ON movements
  FOR EACH ROW
  EXECUTE FUNCTION validate_movement();

-- Create trigger for usage log validation
CREATE TRIGGER validate_usage_log_trigger
  BEFORE INSERT OR UPDATE ON usage_logs
  FOR EACH ROW
  EXECUTE FUNCTION validate_usage_log();