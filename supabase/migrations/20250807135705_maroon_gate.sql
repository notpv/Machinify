/*
  # Create Custom Functions

  1. Utility Functions
    - Generate QR code string for machines
    - Get machine statistics
    - Get fuel efficiency analytics
    - Get movement analytics

  2. Dashboard Functions
    - Get dashboard statistics
    - Get fuel consumption trends
    - Get machine utilization data
*/

-- Function to generate QR code for machines
CREATE OR REPLACE FUNCTION generate_machine_qr_code(
  machine_type text,
  machine_id text
)
RETURNS text AS $$
DECLARE
  type_code text;
  timestamp_part text;
  random_part text;
BEGIN
  -- Get type code
  type_code := CASE 
    WHEN UPPER(machine_type) = 'EXCAVATOR' THEN 'EX'
    WHEN UPPER(machine_type) = 'ROLLER' THEN 'RL'
    WHEN UPPER(machine_type) = 'BULLDOZER' THEN 'BD'
    WHEN UPPER(machine_type) = 'CRANE' THEN 'CR'
    WHEN UPPER(machine_type) = 'GRADER' THEN 'GR'
    ELSE 'MC'
  END;
  
  -- Get timestamp part (last 6 digits of epoch)
  timestamp_part := RIGHT(EXTRACT(epoch FROM now())::text, 6);
  
  -- Generate random 4-digit number
  random_part := LPAD((RANDOM() * 9999)::int::text, 4, '0');
  
  -- Return formatted QR code
  RETURN 'MACH-' || type_code || '-' || machine_id || '-' || random_part || '-' || timestamp_part;
END;
$$ LANGUAGE plpgsql;

-- Function to get machine statistics
CREATE OR REPLACE FUNCTION get_machine_statistics()
RETURNS TABLE(
  total_machines bigint,
  active_machines bigint,
  machines_by_type jsonb,
  machines_by_site jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM machines) as total_machines,
    (SELECT COUNT(*) FROM machines WHERE is_active = true) as active_machines,
    (
      SELECT jsonb_object_agg(type, count)
      FROM (
        SELECT type, COUNT(*) as count
        FROM machines 
        WHERE is_active = true
        GROUP BY type
      ) t
    ) as machines_by_type,
    (
      SELECT jsonb_object_agg(site_name, count)
      FROM (
        SELECT s.site_name, COUNT(m.*) as count
        FROM sites s
        LEFT JOIN machines m ON s.site_id = m.assigned_site_id AND m.is_active = true
        GROUP BY s.site_name
      ) t
    ) as machines_by_site;
END;
$$ LANGUAGE plpgsql;

-- Function to get fuel efficiency analytics
CREATE OR REPLACE FUNCTION get_fuel_efficiency_analytics(
  start_date date DEFAULT CURRENT_DATE - INTERVAL '30 days',
  end_date date DEFAULT CURRENT_DATE
)
RETURNS TABLE(
  total_fuel_consumed numeric,
  total_hours_run numeric,
  average_efficiency numeric,
  min_efficiency numeric,
  max_efficiency numeric,
  inefficient_logs_count bigint,
  efficiency_by_machine jsonb,
  efficiency_by_operator jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(ul.diesel_consumed), 0) as total_fuel_consumed,
    COALESCE(SUM(ul.hours_run), 0) as total_hours_run,
    CASE 
      WHEN SUM(ul.hours_run) > 0 THEN SUM(ul.diesel_consumed) / SUM(ul.hours_run)
      ELSE 0
    END as average_efficiency,
    COALESCE(MIN(ul.fuel_efficiency), 0) as min_efficiency,
    COALESCE(MAX(ul.fuel_efficiency), 0) as max_efficiency,
    COUNT(*) FILTER (WHERE ul.fuel_efficiency > 10.0 OR ul.fuel_efficiency < 0.5) as inefficient_logs_count,
    (
      SELECT jsonb_object_agg(machine_id, avg_efficiency)
      FROM (
        SELECT 
          machine_id,
          ROUND((SUM(diesel_consumed) / SUM(hours_run))::numeric, 2) as avg_efficiency
        FROM usage_logs 
        WHERE date BETWEEN start_date AND end_date
        GROUP BY machine_id
        HAVING SUM(hours_run) > 0
      ) t
    ) as efficiency_by_machine,
    (
      SELECT jsonb_object_agg(operator_name, avg_efficiency)
      FROM (
        SELECT 
          operator_name,
          ROUND((SUM(diesel_consumed) / SUM(hours_run))::numeric, 2) as avg_efficiency
        FROM usage_logs 
        WHERE date BETWEEN start_date AND end_date
        GROUP BY operator_name
        HAVING SUM(hours_run) > 0
      ) t
    ) as efficiency_by_operator
  FROM usage_logs ul
  WHERE ul.date BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get movement analytics
CREATE OR REPLACE FUNCTION get_movement_analytics(
  start_date date DEFAULT CURRENT_DATE - INTERVAL '30 days',
  end_date date DEFAULT CURRENT_DATE
)
RETURNS TABLE(
  total_movements bigint,
  pending_movements bigint,
  in_transit_movements bigint,
  completed_movements bigint,
  movements_by_machine jsonb,
  movements_by_transporter jsonb,
  popular_routes jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_movements,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_movements,
    COUNT(*) FILTER (WHERE status = 'in_transit') as in_transit_movements,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_movements,
    (
      SELECT jsonb_object_agg(machine_id, count)
      FROM (
        SELECT machine_id, COUNT(*) as count
        FROM movements 
        WHERE movement_date BETWEEN start_date AND end_date
        GROUP BY machine_id
        ORDER BY count DESC
        LIMIT 10
      ) t
    ) as movements_by_machine,
    (
      SELECT jsonb_object_agg(transporter_name, count)
      FROM (
        SELECT transporter_name, COUNT(*) as count
        FROM movements 
        WHERE movement_date BETWEEN start_date AND end_date
        GROUP BY transporter_name
        ORDER BY count DESC
        LIMIT 10
      ) t
    ) as movements_by_transporter,
    (
      SELECT jsonb_object_agg(route, count)
      FROM (
        SELECT 
          fs.site_name || ' → ' || ts.site_name as route,
          COUNT(*) as count
        FROM movements m
        JOIN sites fs ON m.from_site_id = fs.site_id
        JOIN sites ts ON m.to_site_id = ts.site_id
        WHERE m.movement_date BETWEEN start_date AND end_date
        GROUP BY fs.site_name, ts.site_name
        ORDER BY count DESC
        LIMIT 10
      ) t
    ) as popular_routes
  FROM movements
  WHERE movement_date BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get dashboard summary
CREATE OR REPLACE FUNCTION get_dashboard_summary()
RETURNS TABLE(
  machine_stats jsonb,
  fuel_stats jsonb,
  movement_stats jsonb,
  recent_activity jsonb
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT to_jsonb(t) FROM get_machine_statistics() t) as machine_stats,
    (SELECT to_jsonb(t) FROM get_fuel_efficiency_analytics() t) as fuel_stats,
    (SELECT to_jsonb(t) FROM get_movement_analytics() t) as movement_stats,
    (
      SELECT jsonb_build_object(
        'recent_usage_logs', (
          SELECT jsonb_agg(
            jsonb_build_object(
              'log_id', ul.log_id,
              'machine_id', ul.machine_id,
              'date', ul.date,
              'hours_run', ul.hours_run,
              'diesel_consumed', ul.diesel_consumed,
              'operator_name', ul.operator_name,
              'fuel_efficiency', ul.fuel_efficiency
            )
          )
          FROM (
            SELECT * FROM usage_logs 
            ORDER BY created_at DESC 
            LIMIT 5
          ) ul
        ),
        'recent_movements', (
          SELECT jsonb_agg(
            jsonb_build_object(
              'movement_id', m.movement_id,
              'machine_id', m.machine_id,
              'from_site', fs.site_name,
              'to_site', ts.site_name,
              'movement_date', m.movement_date,
              'status', m.status,
              'transporter_name', m.transporter_name
            )
          )
          FROM (
            SELECT * FROM movements 
            ORDER BY created_at DESC 
            LIMIT 5
          ) m
          JOIN sites fs ON m.from_site_id = fs.site_id
          JOIN sites ts ON m.to_site_id = ts.site_id
        )
      )
    ) as recent_activity;
END;
$$ LANGUAGE plpgsql;

-- Function to get fuel consumption trends (daily data for charts)
CREATE OR REPLACE FUNCTION get_fuel_consumption_trends(
  machine_id_param text DEFAULT NULL,
  days_back integer DEFAULT 30
)
RETURNS TABLE(
  date date,
  total_fuel numeric,
  total_hours numeric,
  efficiency numeric,
  log_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ul.date,
    SUM(ul.diesel_consumed) as total_fuel,
    SUM(ul.hours_run) as total_hours,
    CASE 
      WHEN SUM(ul.hours_run) > 0 THEN SUM(ul.diesel_consumed) / SUM(ul.hours_run)
      ELSE 0
    END as efficiency,
    COUNT(*) as log_count
  FROM usage_logs ul
  WHERE 
    ul.date >= CURRENT_DATE - (days_back || ' days')::interval
    AND (machine_id_param IS NULL OR ul.machine_id = machine_id_param)
  GROUP BY ul.date
  ORDER BY ul.date;
END;
$$ LANGUAGE plpgsql;