import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/machine.dart';
import '../models/usage_log.dart';
import '../models/movement.dart';
import '../models/site.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Authentication Methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  
  String? get currentUserId => _client.auth.currentUser?.id;

  // Machine Methods
  Future<List<Machine>> getMachines({String? siteId}) async {
    try {
      var query = _client
          .from(AppConstants.machinesTable)
          .select('''
            *,
            sites!assigned_site_id(site_name)
          ''')
          .eq('is_active', true);

      if (siteId != null) {
        query = query.eq('assigned_site_id', siteId);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((json) {
        final machine = Machine.fromJson(json);
        if (json['sites'] != null) {
          machine.siteName = json['sites']['site_name'];
        }
        return machine;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch machines: ${e.toString()}');
    }
  }

  Future<Machine> createMachine(Machine machine) async {
    try {
      final response = await _client
          .from(AppConstants.machinesTable)
          .insert(machine.toJson())
          .select()
          .single();
      
      return Machine.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create machine: ${e.toString()}');
    }
  }

  Future<Machine> updateMachine(Machine machine) async {
    try {
      final response = await _client
          .from(AppConstants.machinesTable)
          .update(machine.toJson())
          .eq('machine_id', machine.machineId)
          .select()
          .single();
      
      return Machine.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update machine: ${e.toString()}');
    }
  }

  Future<Machine?> getMachineByQrCode(String qrCode) async {
    try {
      final response = await _client
          .from(AppConstants.machinesTable)
          .select('''
            *,
            sites!assigned_site_id(site_name)
          ''')
          .eq('qr_code', qrCode)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final machine = Machine.fromJson(response);
      if (response['sites'] != null) {
        machine.siteName = response['sites']['site_name'];
      }
      return machine;
    } catch (e) {
      throw Exception('Failed to fetch machine by QR code: ${e.toString()}');
    }
  }

  // Usage Log Methods
  Future<List<UsageLog>> getUsageLogs({
    String? machineId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from(AppConstants.usageLogsTable)
          .select('''
            *,
            machines!machine_id(type, model)
          ''');

      if (machineId != null) {
        query = query.eq('machine_id', machineId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);
      
      return (response as List).map((json) {
        final log = UsageLog.fromJson(json);
        if (json['machines'] != null) {
          log.machineType = json['machines']['type'];
          log.machineModel = json['machines']['model'];
        }
        return log;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch usage logs: ${e.toString()}');
    }
  }

  Future<UsageLog> createUsageLog(UsageLog log) async {
    try {
      final response = await _client
          .from(AppConstants.usageLogsTable)
          .insert(log.toJson())
          .select()
          .single();
      
      return UsageLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create usage log: ${e.toString()}');
    }
  }

  // Movement Methods
  Future<List<Movement>> getMovements({String? machineId}) async {
    try {
      var query = _client
          .from(AppConstants.movementsTable)
          .select('''
            *,
            from_site:sites!from_site_id(site_name),
            to_site:sites!to_site_id(site_name),
            machines!machine_id(type, model)
          ''');

      if (machineId != null) {
        query = query.eq('machine_id', machineId);
      }

      final response = await query.order('movement_date', ascending: false);
      
      return (response as List).map((json) {
        final movement = Movement.fromJson(json);
        if (json['from_site'] != null) {
          movement.fromSiteName = json['from_site']['site_name'];
        }
        if (json['to_site'] != null) {
          movement.toSiteName = json['to_site']['site_name'];
        }
        if (json['machines'] != null) {
          movement.machineType = json['machines']['type'];
          movement.machineModel = json['machines']['model'];
        }
        return movement;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch movements: ${e.toString()}');
    }
  }

  Future<Movement> createMovement(Movement movement) async {
    try {
      final response = await _client
          .from(AppConstants.movementsTable)
          .insert(movement.toJson())
          .select()
          .single();
      
      return Movement.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create movement: ${e.toString()}');
    }
  }

  // Site Methods
  Future<List<Site>> getSites() async {
    try {
      final response = await _client
          .from(AppConstants.sitesTable)
          .select('*')
          .eq('is_active', true)
          .order('site_name');
      
      return (response as List).map((json) => Site.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sites: ${e.toString()}');
    }
  }

  Future<Site> createSite(Site site) async {
    try {
      final response = await _client
          .from(AppConstants.sitesTable)
          .insert(site.toJson())
          .select()
          .single();
      
      return Site.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create site: ${e.toString()}');
    }
  }

  // File Upload Methods
  Future<String> uploadMachinePhoto(String machineId, File imageFile) async {
    try {
      final fileName = '${machineId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from(AppConstants.machinePhotosBucket)
          .upload(fileName, imageFile);
      
      final publicUrl = _client.storage
          .from(AppConstants.machinePhotosBucket)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload machine photo: ${e.toString()}');
    }
  }

  Future<String> uploadFuelBill(String logId, File imageFile) async {
    try {
      final fileName = '${logId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from(AppConstants.fuelBillsBucket)
          .upload(fileName, imageFile);
      
      final publicUrl = _client.storage
          .from(AppConstants.fuelBillsBucket)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload fuel bill: ${e.toString()}');
    }
  }

  // Dashboard Analytics Methods
  Future<Map<String, dynamic>> getDashboardStats({
    String? siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get machine count
      var machineQuery = _client
          .from(AppConstants.machinesTable)
          .select('machine_id', const FetchOptions(count: CountOption.exact))
          .eq('is_active', true);

      if (siteId != null) {
        machineQuery = machineQuery.eq('assigned_site_id', siteId);
      }

      final machineCount = await machineQuery.count();

      // Get fuel consumption trends
      var fuelQuery = _client
          .from(AppConstants.usageLogsTable)
          .select('diesel_consumed, hours_run, date');

      if (startDate != null) {
        fuelQuery = fuelQuery.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        fuelQuery = fuelQuery.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final fuelData = await fuelQuery;

      double totalFuel = 0;
      double totalHours = 0;
      for (final record in fuelData) {
        totalFuel += (record['diesel_consumed'] ?? 0.0).toDouble();
        totalHours += (record['hours_run'] ?? 0.0).toDouble();
      }

      return {
        'machine_count': machineCount,
        'total_fuel_consumed': totalFuel,
        'total_hours_run': totalHours,
        'average_fuel_efficiency': totalHours > 0 ? totalFuel / totalHours : 0.0,
        'fuel_data': fuelData,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToMachines(Function(List<Machine>) onUpdate) {
    return _client
        .channel('machines')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.machinesTable,
          callback: (payload) async {
            final machines = await getMachines();
            onUpdate(machines);
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToMovements(Function(List<Movement>) onUpdate) {
    return _client
        .channel('movements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.movementsTable,
          callback: (payload) async {
            final movements = await getMovements();
            onUpdate(movements);
          },
        )
        .subscribe();
  }
}