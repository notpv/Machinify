import 'package:flutter/material.dart';
import '../models/movement.dart';
import '../models/machine.dart';
import '../models/site.dart';
import '../services/offline_service.dart';
import 'package:uuid/uuid.dart';

class MovementProvider extends ChangeNotifier {
  final OfflineService _offlineService = OfflineService.instance;
  final Uuid _uuid = const Uuid();

  List<Movement> _movements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Movement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get movements for a specific machine
  List<Movement> getMovementsByMachine(String machineId) {
    return _movements.where((movement) => movement.machineId == machineId).toList();
  }

  // Get movements by status
  List<Movement> getMovementsByStatus(String status) {
    return _movements.where((movement) => movement.status == status).toList();
  }

  // Get recent movements (last 30 days)
  List<Movement> get recentMovements {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _movements.where((movement) => movement.movementDate.isAfter(thirtyDaysAgo)).toList();
  }

  // Get pending movements
  List<Movement> get pendingMovements {
    return _movements.where((movement) => movement.status == 'pending').toList();
  }

  // Get movements statistics
  Map<String, int> get movementStats {
    final stats = <String, int>{
      'total': _movements.length,
      'pending': 0,
      'in_transit': 0,
      'completed': 0,
    };

    for (final movement in _movements) {
      stats[movement.status] = (stats[movement.status] ?? 0) + 1;
    }

    return stats;
  }

  // Initialize and load data
  Future<void> initialize() async {
    await loadMovements();
  }

  // Load movements
  Future<void> loadMovements({String? machineId}) async {
    _setLoading(true);
    _clearError();

    try {
      _movements = await _offlineService.getMovements(machineId: machineId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load movements: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create new movement
  Future<Movement?> createMovement({
    required String machineId,
    required String fromSiteId,
    required String toSiteId,
    required DateTime movementDate,
    required String transporterName,
    String? remarks,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    Machine? machine, // For offline denormalization
    Site? fromSite,   // For offline denormalization
    Site? toSite,     // For offline denormalization
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate input
      if (fromSiteId == toSiteId) {
        throw Exception('From site and to site cannot be the same');
      }

      final movement = Movement(
        movementId: _uuid.v4(),
        machineId: machineId,
        fromSiteId: fromSiteId,
        toSiteId: toSiteId,
        movementDate: movementDate,
        transporterName: transporterName,
        remarks: remarks,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
        status: 'pending',
      );

      // Set denormalized data for offline use
      if (machine != null) {
        movement.machineType = machine.type;
        movement.machineModel = machine.model;
      }
      
      if (fromSite != null) {
        movement.fromSiteName = fromSite.siteName;
      }
      
      if (toSite != null) {
        movement.toSiteName = toSite.siteName;
      }

      final createdMovement = await _offlineService.createMovement(movement);
      
      // Add to local list
      _movements.insert(0, createdMovement);
      notifyListeners();

      return createdMovement;
    } catch (e) {
      _setError('Failed to create movement: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update movement status
  Future<bool> updateMovementStatus(String movementId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final movement = _movements.firstWhere(
        (m) => m.movementId == movementId,
        orElse: () => throw Exception('Movement not found'),
      );

      final updatedMovement = movement.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      // Update in offline service
      await _offlineService.createMovement(updatedMovement); // Using create for upsert behavior
      
      // Update local list
      final index = _movements.indexWhere((m) => m.movementId == movementId);
      if (index != -1) {
        _movements[index] = updatedMovement;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update movement status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update movement
  Future<bool> updateMovement(Movement movement) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedMovement = movement.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in offline service
      await _offlineService.createMovement(updatedMovement);
      
      // Update local list
      final index = _movements.indexWhere((m) => m.movementId == movement.movementId);
      if (index != -1) {
        _movements[index] = updatedMovement;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update movement: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get movement by ID
  Movement? getMovementById(String movementId) {
    try {
      return _movements.firstWhere((movement) => movement.movementId == movementId);
    } catch (e) {
      return null;
    }
  }

  // Search movements
  List<Movement> searchMovements(String query) {
    if (query.isEmpty) return _movements;
    
    final lowercaseQuery = query.toLowerCase();
    return _movements.where((movement) {
      return movement.machineId.toLowerCase().contains(lowercaseQuery) ||
             movement.transporterName.toLowerCase().contains(lowercaseQuery) ||
             (movement.fromSiteName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (movement.toSiteName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (movement.machineType?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (movement.machineModel?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (movement.remarks?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Get movements by date range
  List<Movement> getMovementsByDateRange(DateTime startDate, DateTime endDate) {
    return _movements.where((movement) {
      return movement.movementDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             movement.movementDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get movements between specific sites
  List<Movement> getMovementsBetweenSites(String fromSiteId, String toSiteId) {
    return _movements.where((movement) {
      return movement.fromSiteId == fromSiteId && movement.toSiteId == toSiteId;
    }).toList();
  }

  // Get movement history for a machine
  List<Movement> getMachineMovementHistory(String machineId) {
    final machineMovements = getMovementsByMachine(machineId);
    machineMovements.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    return machineMovements;
  }

  // Get site activity (movements from/to a site)
  Map<String, List<Movement>> getSiteActivity(String siteId) {
    final incoming = _movements.where((m) => m.toSiteId == siteId).toList();
    final outgoing = _movements.where((m) => m.fromSiteId == siteId).toList();
    
    return {
      'incoming': incoming,
      'outgoing': outgoing,
    };
  }

  // Get transporter performance
  Map<String, Map<String, dynamic>> getTransporterPerformance() {
    final transporterStats = <String, Map<String, dynamic>>{};
    
    for (final movement in _movements) {
      if (!transporterStats.containsKey(movement.transporterName)) {
        transporterStats[movement.transporterName] = {
          'total_movements': 0,
          'completed_movements': 0,
          'pending_movements': 0,
          'in_transit_movements': 0,
        };
      }
      
      transporterStats[movement.transporterName]!['total_movements']++;
      transporterStats[movement.transporterName]!['${movement.status}_movements']++;
    }
    
    // Calculate completion rate
    transporterStats.forEach((transporter, stats) {
      final total = stats['total_movements'] as int;
      final completed = stats['completed_movements'] as int;
      stats['completion_rate'] = total > 0 ? (completed / total * 100).round() : 0;
    });

    return transporterStats;
  }

  // Get monthly movement trends
  Map<String, int> getMonthlyMovementTrends() {
    final monthlyTrends = <String, int>{};
    
    for (final movement in _movements) {
      final monthKey = '${movement.movementDate.year}-${movement.movementDate.month.toString().padLeft(2, '0')}';
      monthlyTrends[monthKey] = (monthlyTrends[monthKey] ?? 0) + 1;
    }
    
    return monthlyTrends;
  }

  // Refresh data
  Future<void> refresh() async {
    await loadMovements();
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