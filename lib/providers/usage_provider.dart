import 'package:flutter/material.dart';
import '../models/usage_log.dart';
import '../models/machine.dart';
import '../services/offline_service.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class UsageProvider extends ChangeNotifier {
  final OfflineService _offlineService = OfflineService.instance;
  final Uuid _uuid = const Uuid();

  List<UsageLog> _usageLogs = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UsageLog> get usageLogs => _usageLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get usage logs for a specific machine
  List<UsageLog> getUsageLogsByMachine(String machineId) {
    return _usageLogs.where((log) => log.machineId == machineId).toList();
  }

  // Get usage logs for a date range
  List<UsageLog> getUsageLogsByDateRange(DateTime startDate, DateTime endDate) {
    return _usageLogs.where((log) {
      return log.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
             log.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get fuel efficiency statistics
  Map<String, double> get fuelEfficiencyStats {
    if (_usageLogs.isEmpty) {
      return {
        'average': 0.0,
        'minimum': 0.0,
        'maximum': 0.0,
        'total_fuel': 0.0,
        'total_hours': 0.0,
      };
    }

    double totalFuel = 0.0;
    double totalHours = 0.0;
    double minEfficiency = double.infinity;
    double maxEfficiency = 0.0;

    for (final log in _usageLogs) {
      totalFuel += log.dieselConsumed;
      totalHours += log.hoursRun;
      
      final efficiency = log.calculateFuelEfficiency();
      if (efficiency > 0) {
        if (efficiency < minEfficiency) minEfficiency = efficiency;
        if (efficiency > maxEfficiency) maxEfficiency = efficiency;
      }
    }

    final averageEfficiency = totalHours > 0 ? totalFuel / totalHours : 0.0;

    return {
      'average': averageEfficiency,
      'minimum': minEfficiency == double.infinity ? 0.0 : minEfficiency,
      'maximum': maxEfficiency,
      'total_fuel': totalFuel,
      'total_hours': totalHours,
    };
  }

  // Get logs with fuel efficiency issues
  List<UsageLog> get inefficientLogs {
    return _usageLogs.where((log) => !log.isFuelEfficiencyValid()).toList();
  }

  // Get recent logs (last 30 days)
  List<UsageLog> get recentLogs {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _usageLogs.where((log) => log.date.isAfter(thirtyDaysAgo)).toList();
  }

  // Initialize and load data
  Future<void> initialize() async {
    await loadUsageLogs();
  }

  // Load usage logs
  Future<void> loadUsageLogs({
    String? machineId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _usageLogs = await _offlineService.getUsageLogs(
        machineId: machineId,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load usage logs: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create new usage log
  Future<UsageLog?> createUsageLog({
    required String machineId,
    required DateTime date,
    required double hoursRun,
    required double dieselConsumed,
    required String operatorName,
    String? fuelBillUrl,
    String? remarks,
    Machine? machine, // For offline denormalization
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate input
      if (hoursRun <= 0) {
        throw Exception('Hours run must be greater than 0');
      }
      
      if (dieselConsumed <= 0) {
        throw Exception('Diesel consumed must be greater than 0');
      }

      // Calculate fuel efficiency
      final fuelEfficiency = dieselConsumed / hoursRun;
      
      // Check if fuel efficiency is within acceptable range
      final isValidated = fuelEfficiency >= AppConstants.minFuelEfficiency &&
                         fuelEfficiency <= AppConstants.maxFuelEfficiency;

      final usageLog = UsageLog(
        logId: _uuid.v4(),
        machineId: machineId,
        date: date,
        hoursRun: hoursRun,
        dieselConsumed: dieselConsumed,
        operatorName: operatorName,
        fuelBillUrl: fuelBillUrl,
        fuelEfficiency: fuelEfficiency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        remarks: remarks,
        isValidated: isValidated,
      );

      // Set machine details for offline use
      if (machine != null) {
        usageLog.machineType = machine.type;
        usageLog.machineModel = machine.model;
      }

      final createdLog = await _offlineService.createUsageLog(usageLog);
      
      // Add to local list
      _usageLogs.insert(0, createdLog);
      notifyListeners();

      return createdLog;
    } catch (e) {
      _setError('Failed to create usage log: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update usage log
  Future<bool> updateUsageLog(UsageLog log) async {
    _setLoading(true);
    _clearError();

    try {
      // Recalculate fuel efficiency
      final fuelEfficiency = log.dieselConsumed / log.hoursRun;
      final isValidated = fuelEfficiency >= AppConstants.minFuelEfficiency &&
                         fuelEfficiency <= AppConstants.maxFuelEfficiency;

      final updatedLog = log.copyWith(
        fuelEfficiency: fuelEfficiency,
        isValidated: isValidated,
        updatedAt: DateTime.now(),
      );

      // Update in offline service
      await _offlineService.createUsageLog(updatedLog); // Using create for upsert behavior
      
      // Update local list
      final index = _usageLogs.indexWhere((l) => l.logId == log.logId);
      if (index != -1) {
        _usageLogs[index] = updatedLog;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update usage log: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get usage log by ID
  UsageLog? getUsageLogById(String logId) {
    try {
      return _usageLogs.firstWhere((log) => log.logId == logId);
    } catch (e) {
      return null;
    }
  }

  // Search usage logs
  List<UsageLog> searchUsageLogs(String query) {
    if (query.isEmpty) return _usageLogs;
    
    final lowercaseQuery = query.toLowerCase();
    return _usageLogs.where((log) {
      return log.machineId.toLowerCase().contains(lowercaseQuery) ||
             log.operatorName.toLowerCase().contains(lowercaseQuery) ||
             (log.machineType?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (log.machineModel?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (log.remarks?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get daily fuel consumption for a machine
  Map<DateTime, double> getDailyFuelConsumption(String machineId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = getUsageLogsByMachine(machineId);
    
    if (startDate != null) {
      logs = logs.where((log) => log.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }
    
    if (endDate != null) {
      logs = logs.where((log) => log.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    final dailyConsumption = <DateTime, double>{};
    
    for (final log in logs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      dailyConsumption[date] = (dailyConsumption[date] ?? 0.0) + log.dieselConsumed;
    }

    return dailyConsumption;
  }

  // Get machine utilization (hours per day)
  Map<DateTime, double> getMachineUtilization(String machineId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var logs = getUsageLogsByMachine(machineId);
    
    if (startDate != null) {
      logs = logs.where((log) => log.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }
    
    if (endDate != null) {
      logs = logs.where((log) => log.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    final dailyHours = <DateTime, double>{};
    
    for (final log in logs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      dailyHours[date] = (dailyHours[date] ?? 0.0) + log.hoursRun;
    }

    return dailyHours;
  }

  // Get operator performance
  Map<String, Map<String, double>> getOperatorPerformance() {
    final operatorStats = <String, Map<String, double>>{};
    
    for (final log in _usageLogs) {
      if (!operatorStats.containsKey(log.operatorName)) {
        operatorStats[log.operatorName] = {
          'total_hours': 0.0,
          'total_fuel': 0.0,
          'log_count': 0.0,
        };
      }
      
      operatorStats[log.operatorName]!['total_hours'] = 
          operatorStats[log.operatorName]!['total_hours']! + log.hoursRun;
      operatorStats[log.operatorName]!['total_fuel'] = 
          operatorStats[log.operatorName]!['total_fuel']! + log.dieselConsumed;
      operatorStats[log.operatorName]!['log_count'] = 
          operatorStats[log.operatorName]!['log_count']! + 1;
    }
    
    // Calculate average efficiency for each operator
    operatorStats.forEach((operator, stats) {
      final totalHours = stats['total_hours']!;
      final totalFuel = stats['total_fuel']!;
      stats['avg_efficiency'] = totalHours > 0 ? totalFuel / totalHours : 0.0;
    });

    return operatorStats;
  }

  // Refresh data
  Future<void> refresh() async {
    await loadUsageLogs();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}