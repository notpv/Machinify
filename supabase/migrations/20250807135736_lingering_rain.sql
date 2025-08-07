/*
  # Seed Data for Machinify

  This file contains sample data for testing and development:
  - Sample sites across different regions
  - Sample machines of various types
  - Sample usage logs with realistic data
  - Sample movements between sites
*/

-- Insert sample sites
INSERT INTO sites (site_id, site_name, latitude, longitude, address, contact_person, contact_phone, region) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Mumbai Construction Hub', 19.0760, 72.8777, 'Bandra Kurla Complex, Mumbai, Maharashtra', 'Rajesh Kumar', '+91-9876543210', 'Western'),
  ('550e8400-e29b-41d4-a716-446655440002', 'Delhi Infrastructure Base', 28.6139, 77.2090, 'Connaught Place, New Delhi', 'Priya Sharma', '+91-9876543211', 'Northern'),
  ('550e8400-e29b-41d4-a716-446655440003', 'Bangalore Tech Park Site', 12.9716, 77.5946, 'Electronic City, Bangalore, Karnataka', 'Suresh Reddy', '+91-9876543212', 'Southern'),
  ('550e8400-e29b-41d4-a716-446655440004', 'Chennai Port Project', 13.0827, 80.2707, 'Chennai Port, Tamil Nadu', 'Lakshmi Iyer', '+91-9876543213', 'Southern'),
  ('550e8400-e29b-41d4-a716-446655440005', 'Pune Highway Extension', 18.5204, 73.8567, 'Hinjewadi, Pune, Maharashtra', 'Amit Patil', '+91-9876543214', 'Western'),
  ('550e8400-e29b-41d4-a716-446655440006', 'Kolkata Metro Phase 3', 22.5726, 88.3639, 'Salt Lake, Kolkata, West Bengal', 'Debashish Roy', '+91-9876543215', 'Eastern'),
  ('550e8400-e29b-41d4-a716-446655440007', 'Hyderabad IT Corridor', 17.3850, 78.4867, 'HITEC City, Hyderabad, Telangana', 'Venkat Rao', '+91-9876543216', 'Southern'),
  ('550e8400-e29b-41d4-a716-446655440008', 'Ahmedabad Industrial Zone', 23.0225, 72.5714, 'Sanand, Ahmedabad, Gujarat', 'Kiran Patel', '+91-9876543217', 'Western');

-- Insert sample machines
INSERT INTO machines (machine_id, type, model, brand, purchase_date, assigned_site_id, qr_code) VALUES
  ('EX001234567', 'Excavator', 'PC200-8', 'Komatsu', '2023-01-15', '550e8400-e29b-41d4-a716-446655440001', 'MACH-EX-EX001234567-1234-567890'),
  ('EX001234568', 'Excavator', 'CAT 320D', 'Caterpillar', '2023-02-20', '550e8400-e29b-41d4-a716-446655440002', 'MACH-EX-EX001234568-1235-567891'),
  ('RL001234569', 'Roller', 'BW 211 D-5', 'Bomag', '2023-03-10', '550e8400-e29b-41d4-a716-446655440003', 'MACH-RL-RL001234569-1236-567892'),
  ('BD001234570', 'Bulldozer', 'D6T', 'Caterpillar', '2023-01-25', '550e8400-e29b-41d4-a716-446655440001', 'MACH-BD-BD001234570-1237-567893'),
  ('CR001234571', 'Crane', 'RT 540E', 'Terex', '2023-04-05', '550e8400-e29b-41d4-a716-446655440004', 'MACH-CR-CR001234571-1238-567894'),
  ('GR001234572', 'Grader', '140M', 'Caterpillar', '2023-02-15', '550e8400-e29b-41d4-a716-446655440005', 'MACH-GR-GR001234572-1239-567895'),
  ('EX001234573', 'Excavator', 'JCB JS 205', 'JCB', '2023-03-20', '550e8400-e29b-41d4-a716-446655440006', 'MACH-EX-EX001234573-1240-567896'),
  ('RL001234574', 'Roller', 'CP 274', 'Caterpillar', '2023-04-12', '550e8400-e29b-41d4-a716-446655440007', 'MACH-RL-RL001234574-1241-567897'),
  ('BD001234575', 'Bulldozer', 'D4K2', 'Caterpillar', '2023-01-30', '550e8400-e29b-41d4-a716-446655440008', 'MACH-BD-BD001234575-1242-567898'),
  ('EX001234576', 'Excavator', 'PC 210', 'Komatsu', '2023-05-01', '550e8400-e29b-41d4-a716-446655440002', 'MACH-EX-EX001234576-1243-567899');

-- Insert sample usage logs (last 30 days)
INSERT INTO usage_logs (machine_id, date, hours_run, diesel_consumed, operator_name, remarks) VALUES
  -- Recent logs (last 7 days)
  ('EX001234567', CURRENT_DATE - 1, 8.5, 68.0, 'Ramesh Singh', 'Normal excavation work'),
  ('EX001234567', CURRENT_DATE - 2, 7.2, 57.6, 'Ramesh Singh', 'Foundation digging'),
  ('EX001234568', CURRENT_DATE - 1, 9.0, 72.0, 'Sunil Kumar', 'Road construction'),
  ('RL001234569', CURRENT_DATE - 1, 6.5, 39.0, 'Prakash Yadav', 'Road compaction'),
  ('BD001234570', CURRENT_DATE - 2, 8.0, 88.0, 'Vijay Sharma', 'Land clearing - heavy load'),
  ('CR001234571', CURRENT_DATE - 1, 5.5, 44.0, 'Manoj Gupta', 'Material lifting'),
  ('GR001234572', CURRENT_DATE - 3, 7.8, 62.4, 'Ravi Patel', 'Road grading'),
  
  -- Week 2
  ('EX001234567', CURRENT_DATE - 8, 8.0, 64.0, 'Ramesh Singh', 'Excavation work'),
  ('EX001234568', CURRENT_DATE - 9, 8.5, 68.0, 'Sunil Kumar', 'Trenching'),
  ('RL001234569', CURRENT_DATE - 10, 7.0, 42.0, 'Prakash Yadav', 'Asphalt compaction'),
  ('BD001234570', CURRENT_DATE - 11, 6.5, 71.5, 'Vijay Sharma', 'Bulldozing'),
  ('CR001234571', CURRENT_DATE - 12, 4.5, 36.0, 'Manoj Gupta', 'Light lifting work'),
  ('GR001234572', CURRENT_DATE - 13, 8.2, 65.6, 'Ravi Patel', 'Surface preparation'),
  ('EX001234573', CURRENT_DATE - 14, 7.5, 60.0, 'Ashok Jain', 'Utility trenching'),
  
  -- Week 3
  ('EX001234567', CURRENT_DATE - 15, 9.2, 73.6, 'Ramesh Singh', 'Deep excavation'),
  ('EX001234568', CURRENT_DATE - 16, 7.8, 62.4, 'Sunil Kumar', 'Foundation work'),
  ('RL001234569', CURRENT_DATE - 17, 6.8, 40.8, 'Prakash Yadav', 'Final compaction'),
  ('BD001234570', CURRENT_DATE - 18, 8.5, 93.5, 'Vijay Sharma', 'Heavy clearing work'),
  ('CR001234571', CURRENT_DATE - 19, 6.0, 48.0, 'Manoj Gupta', 'Steel placement'),
  ('GR001234572', CURRENT_DATE - 20, 7.5, 60.0, 'Ravi Patel', 'Road maintenance'),
  ('EX001234573', CURRENT_DATE - 21, 8.8, 70.4, 'Ashok Jain', 'Site preparation'),
  
  -- Week 4
  ('EX001234567', CURRENT_DATE - 22, 8.3, 66.4, 'Ramesh Singh', 'Regular excavation'),
  ('EX001234568', CURRENT_DATE - 23, 7.0, 56.0, 'Sunil Kumar', 'Backfilling'),
  ('RL001234569', CURRENT_DATE - 24, 7.2, 43.2, 'Prakash Yadav', 'Base compaction'),
  ('BD001234570', CURRENT_DATE - 25, 7.8, 85.8, 'Vijay Sharma', 'Site leveling'),
  ('CR001234571', CURRENT_DATE - 26, 5.2, 41.6, 'Manoj Gupta', 'Equipment positioning'),
  ('GR001234572', CURRENT_DATE - 27, 8.0, 64.0, 'Ravi Patel', 'Fine grading'),
  ('EX001234573', CURRENT_DATE - 28, 7.3, 58.4, 'Ashok Jain', 'Drainage work'),
  ('RL001234574', CURRENT_DATE - 29, 6.5, 39.0, 'Dinesh Kumar', 'Initial compaction'),
  ('BD001234575', CURRENT_DATE - 30, 8.7, 95.7, 'Santosh Rao', 'Heavy earthwork');

-- Insert sample movements
INSERT INTO movements (machine_id, from_site_id, to_site_id, movement_date, transporter_name, status, remarks) VALUES
  -- Recent completed movements
  ('EX001234568', '550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', CURRENT_DATE - 15, 'Express Logistics', 'completed', 'Moved for Delhi project'),
  ('RL001234569', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', CURRENT_DATE - 12, 'Heavy Haul Transport', 'completed', 'Required for road work'),
  ('CR001234571', '550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440004', CURRENT_DATE - 10, 'Mega Movers', 'completed', 'Port project requirement'),
  
  -- In-transit movements
  ('GR001234572', '550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440005', CURRENT_DATE - 2, 'Swift Transport', 'in_transit', 'Highway project'),
  ('EX001234573', '550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440006', CURRENT_DATE - 1, 'Reliable Movers', 'in_transit', 'Metro construction'),
  
  -- Pending movements
  ('RL001234574', '550e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440007', CURRENT_DATE + 1, 'Express Logistics', 'pending', 'Scheduled for IT corridor'),
  ('BD001234575', '550e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440008', CURRENT_DATE + 2, 'Heavy Haul Transport', 'pending', 'Industrial zone project'),
  ('EX001234576', '550e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440001', CURRENT_DATE + 3, 'Mega Movers', 'pending', 'Return to Mumbai hub');

-- Update machine assignments based on completed movements
UPDATE machines SET assigned_site_id = '550e8400-e29b-41d4-a716-446655440002' WHERE machine_id = 'EX001234568';
UPDATE machines SET assigned_site_id = '550e8400-e29b-41d4-a716-446655440003' WHERE machine_id = 'RL001234569';
UPDATE machines SET assigned_site_id = '550e8400-e29b-41d4-a716-446655440004' WHERE machine_id = 'CR001234571';