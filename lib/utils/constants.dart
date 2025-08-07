class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Database Tables
  static const String machinesTable = 'machines';
  static const String usageLogsTable = 'usage_logs';
  static const String movementsTable = 'movements';
  static const String sitesTable = 'sites';
  
  // Storage Buckets
  static const String machinePhotosBucket = 'machine-photos';
  static const String fuelBillsBucket = 'fuel-bills';
  
  // Machine Types
  static const List<String> machineTypes = [
    'Excavator',
    'Roller',
    'Bulldozer',
    'Crane',
    'Grader',
  ];
  
  // Fuel Efficiency Thresholds
  static const double maxFuelEfficiency = 10.0; // liters per hour
  static const double minFuelEfficiency = 0.5;  // liters per hour
  
  // Offline Storage Keys
  static const String offlineMachinesKey = 'offline_machines';
  static const String offlineUsageLogsKey = 'offline_usage_logs';
  static const String offlineMovementsKey = 'offline_movements';
  static const String pendingSyncKey = 'pending_sync';
  
  // User Roles
  static const String fieldEngineerRole = 'field_engineer';
  static const String managerRole = 'manager';
  
  // App Settings
  static const int syncIntervalMinutes = 15;
  static const int maxRetryAttempts = 3;
  static const Duration requestTimeout = Duration(seconds: 30);
}