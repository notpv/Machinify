import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/machine.dart';
import '../models/usage_log.dart';
import '../models/movement.dart';
import '../models/site.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static OfflineService get instance => _instance;

  late Box<Machine> _machinesBox;
  late Box<UsageLog> _usageLogsBox;
  late Box<Movement> _movementsBox;
  late Box<Site> _sitesBox;
  late Box<String> _pendingSyncBox;

  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register Hive adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MachineAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UsageLogAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(MovementAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(SiteAdapter());
      }

      // Open Hive boxes
      _machinesBox = await Hive.openBox<Machine>(AppConstants.offlineMachinesKey);
      _usageLogsBox = await Hive.openBox<UsageLog>(AppConstants.offlineUsageLogsKey);
      _movementsBox = await Hive.openBox<Movement>('offline_movements');
      _sitesBox = await Hive.openBox<Site>('offline_sites');
      _pendingSyncBox = await Hive.openBox<String>(AppConstants.pendingSyncKey);

      _isInitialized = true;

      // Start periodic sync
      _startPeriodicSync();
    } catch (e) {
      throw Exception('Failed to initialize offline service: ${e.toString()}');
    }
  }

  // Connectivity Methods
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }

  // Machine Methods
  Future<List<Machine>> getMachines({String? siteId}) async {
    if (await isOnline()) {
      try {
        final machines = await _supabaseService.getMachines(siteId: siteId);
        await _cacheMachines(machines);
        return machines;
      } catch (e) {
        // Fall back to offline data
        return _getOfflineMachines(siteId: siteId);
      }
    } else {
      return _getOfflineMachines(siteId: siteId);
    }
  }

  List<Machine> _getOfflineMachines({String? siteId}) {
    final machines = _machinesBox.values.where((machine) => machine.isActive).toList();
    
    if (siteId != null) {
      return machines.where((machine) => machine.assignedSiteId == siteId).toList();
    }
    
    return machines;
  }

  Future<void> _cacheMachines(List<Machine> machines) async {
    await _machinesBox.clear();
    for (final machine in machines) {
      await _machinesBox.put(machine.machineId, machine);
    }
  }

  Future<Machine> createMachine(Machine machine) async {
    if (await isOnline()) {
      try {
        final createdMachine = await _supabaseService.createMachine(machine);
        await _machinesBox.put(createdMachine.machineId, createdMachine);
        return createdMachine;
      } catch (e) {
        // Store for later sync
        machine.needsSync = true;
        await _machinesBox.put(machine.machineId, machine);
        await _addToPendingSync('create_machine', machine.toJson());
        return machine;
      }
    } else {
      machine.needsSync = true;
      await _machinesBox.put(machine.machineId, machine);
      await _addToPendingSync('create_machine', machine.toJson());
      return machine;
    }
  }

  Future<Machine?> getMachineByQrCode(String qrCode) async {
    if (await isOnline()) {
      try {
        final machine = await _supabaseService.getMachineByQrCode(qrCode);
        if (machine != null) {
          await _machinesBox.put(machine.machineId, machine);
        }
        return machine;
      } catch (e) {
        // Fall back to offline data
        return _getOfflineMachineByQrCode(qrCode);
      }
    } else {
      return _getOfflineMachineByQrCode(qrCode);
    }
  }

  Machine? _getOfflineMachineByQrCode(String qrCode) {
    return _machinesBox.values.firstWhere(
      (machine) => machine.qrCode == qrCode && machine.isActive,
      orElse: () => throw StateError('Machine not found'),
    );
  }

  // Usage Log Methods
  Future<List<UsageLog>> getUsageLogs({
    String? machineId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await isOnline()) {
      try {
        final logs = await _supabaseService.getUsageLogs(
          machineId: machineId,
          startDate: startDate,
          endDate: endDate,
        );
        await _cacheUsageLogs(logs);
        return logs;
      } catch (e) {
        return _getOfflineUsageLogs(
          machineId: machineId,
          startDate: startDate,
          endDate: endDate,
        );
      }
    } else {
      return _getOfflineUsageLogs(
        machineId: machineId,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  List<UsageLog> _getOfflineUsageLogs({
    String? machineId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = _usageLogsBox.values.toList();

    if (machineId != null) {
      logs = logs.where((log) => log.machineId == machineId).toList();
    }

    if (startDate != null) {
      logs = logs.where((log) => log.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }

    if (endDate != null) {
      logs = logs.where((log) => log.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs;
  }

  Future<void> _cacheUsageLogs(List<UsageLog> logs) async {
    for (final log in logs) {
      await _usageLogsBox.put(log.logId, log);
    }
  }

  Future<UsageLog> createUsageLog(UsageLog log) async {
    if (await isOnline()) {
      try {
        final createdLog = await _supabaseService.createUsageLog(log);
        await _usageLogsBox.put(createdLog.logId, createdLog);
        return createdLog;
      } catch (e) {
        log.needsSync = true;
        await _usageLogsBox.put(log.logId, log);
        await _addToPendingSync('create_usage_log', log.toJson());
        return log;
      }
    } else {
      log.needsSync = true;
      await _usageLogsBox.put(log.logId, log);
      await _addToPendingSync('create_usage_log', log.toJson());
      return log;
    }
  }

  // Movement Methods
  Future<List<Movement>> getMovements({String? machineId}) async {
    if (await isOnline()) {
      try {
        final movements = await _supabaseService.getMovements(machineId: machineId);
        await _cacheMovements(movements);
        return movements;
      } catch (e) {
        return _getOfflineMovements(machineId: machineId);
      }
    } else {
      return _getOfflineMovements(machineId: machineId);
    }
  }

  List<Movement> _getOfflineMovements({String? machineId}) {
    var movements = _movementsBox.values.toList();

    if (machineId != null) {
      movements = movements.where((movement) => movement.machineId == machineId).toList();
    }

    movements.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    return movements;
  }

  Future<void> _cacheMovements(List<Movement> movements) async {
    for (final movement in movements) {
      await _movementsBox.put(movement.movementId, movement);
    }
  }

  Future<Movement> createMovement(Movement movement) async {
    if (await isOnline()) {
      try {
        final createdMovement = await _supabaseService.createMovement(movement);
        await _movementsBox.put(createdMovement.movementId, createdMovement);
        return createdMovement;
      } catch (e) {
        movement.needsSync = true;
        await _movementsBox.put(movement.movementId, movement);
        await _addToPendingSync('create_movement', movement.toJson());
        return movement;
      }
    } else {
      movement.needsSync = true;
      await _movementsBox.put(movement.movementId, movement);
      await _addToPendingSync('create_movement', movement.toJson());
      return movement;
    }
  }

  // Site Methods
  Future<List<Site>> getSites() async {
    if (await isOnline()) {
      try {
        final sites = await _supabaseService.getSites();
        await _cacheSites(sites);
        return sites;
      } catch (e) {
        return _sitesBox.values.where((site) => site.isActive).toList();
      }
    } else {
      return _sitesBox.values.where((site) => site.isActive).toList();
    }
  }

  Future<void> _cacheSites(List<Site> sites) async {
    await _sitesBox.clear();
    for (final site in sites) {
      await _sitesBox.put(site.siteId, site);
    }
  }

  // Sync Methods
  Future<void> _addToPendingSync(String action, Map<String, dynamic> data) async {
    final syncItem = {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final key = '${action}_${DateTime.now().millisecondsSinceEpoch}';
    await _pendingSyncBox.put(key, jsonEncode(syncItem));
  }

  Future<void> syncPendingData() async {
    if (!await isOnline()) return;

    final pendingItems = _pendingSyncBox.values.toList();
    final keysToRemove = <String>[];

    for (int i = 0; i < pendingItems.length; i++) {
      try {
        final item = jsonDecode(pendingItems[i]);
        final action = item['action'] as String;
        final data = item['data'] as Map<String, dynamic>;

        switch (action) {
          case 'create_machine':
            await _supabaseService.createMachine(Machine.fromJson(data));
            break;
          case 'create_usage_log':
            await _supabaseService.createUsageLog(UsageLog.fromJson(data));
            break;
          case 'create_movement':
            await _supabaseService.createMovement(Movement.fromJson(data));
            break;
        }

        keysToRemove.add(_pendingSyncBox.keyAt(i) as String);
      } catch (e) {
        // Log error but continue with other items
        print('Failed to sync item: ${e.toString()}');
      }
    }

    // Remove successfully synced items
    for (final key in keysToRemove) {
      await _pendingSyncBox.delete(key);
    }
  }

  void _startPeriodicSync() {
    // Sync every 15 minutes when online
    Stream.periodic(const Duration(minutes: AppConstants.syncIntervalMinutes))
        .listen((_) async {
      if (await isOnline()) {
        await syncPendingData();
      }
    });

    // Also sync when connectivity is restored
    connectivityStream.listen((isConnected) async {
      if (isConnected) {
        await syncPendingData();
      }
    });
  }

  // Utility Methods
  int get pendingSyncCount => _pendingSyncBox.length;

  Future<void> clearCache() async {
    await _machinesBox.clear();
    await _usageLogsBox.clear();
    await _movementsBox.clear();
    await _sitesBox.clear();
  }

  Future<void> dispose() async {
    await _machinesBox.close();
    await _usageLogsBox.close();
    await _movementsBox.close();
    await _sitesBox.close();
    await _pendingSyncBox.close();
  }
}