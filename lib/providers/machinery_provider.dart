import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../models/site.dart';
import '../services/offline_service.dart';
import '../services/qr_service.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class MachineryProvider extends ChangeNotifier {
  final OfflineService _offlineService = OfflineService.instance;
  final QrService _qrService = QrService();
  final Uuid _uuid = const Uuid();

  List<Machine> _machines = [];
  List<Site> _sites = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Machine> get machines => _machines;
  List<Site> get sites => _sites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered machines by site
  List<Machine> getMachinesBySite(String? siteId) {
    if (siteId == null) return _machines;
    return _machines.where((machine) => machine.assignedSiteId == siteId).toList();
  }

  // Get machines by type
  List<Machine> getMachinesByType(String type) {
    return _machines.where((machine) => machine.type == type).toList();
  }

  // Get machine statistics
  Map<String, int> get machineStatsByType {
    final stats = <String, int>{};
    for (final type in AppConstants.machineTypes) {
      stats[type] = _machines.where((m) => m.type == type && m.isActive).length;
    }
    return stats;
  }

  int get totalActiveMachines => _machines.where((m) => m.isActive).length;

  // Initialize and load data
  Future<void> initialize() async {
    await loadMachines();
    await loadSites();
  }

  // Load machines
  Future<void> loadMachines({String? siteId}) async {
    _setLoading(true);
    _clearError();

    try {
      _machines = await _offlineService.getMachines(siteId: siteId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load machines: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load sites
  Future<void> loadSites() async {
    try {
      _sites = await _offlineService.getSites();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sites: ${e.toString()}');
    }
  }

  // Create new machine
  Future<Machine?> createMachine({
    required String type,
    required String model,
    required String brand,
    required DateTime purchaseDate,
    required String assignedSiteId,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Generate machine ID and QR code
      final machineId = _qrService.generateSimpleMachineId(type);
      final qrCode = _qrService.generateMachineQrCode(machineId, type, model);
      
      final machine = Machine(
        machineId: machineId,
        type: type,
        model: model,
        brand: brand,
        purchaseDate: purchaseDate,
        assignedSiteId: assignedSiteId,
        photoUrl: photoUrl,
        qrCode: qrCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Set site name for offline use
      final site = _sites.firstWhere(
        (s) => s.siteId == assignedSiteId,
        orElse: () => throw Exception('Site not found'),
      );
      machine.siteName = site.siteName;

      final createdMachine = await _offlineService.createMachine(machine);
      
      // Add to local list
      _machines.insert(0, createdMachine);
      notifyListeners();

      return createdMachine;
    } catch (e) {
      _setError('Failed to create machine: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update machine
  Future<bool> updateMachine(Machine machine) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedMachine = machine.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update in offline service (will sync when online)
      await _offlineService.createMachine(updatedMachine); // Using create for upsert behavior
      
      // Update local list
      final index = _machines.indexWhere((m) => m.machineId == machine.machineId);
      if (index != -1) {
        _machines[index] = updatedMachine;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update machine: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get machine by ID
  Machine? getMachineById(String machineId) {
    try {
      return _machines.firstWhere((machine) => machine.machineId == machineId);
    } catch (e) {
      return null;
    }
  }

  // Get machine by QR code
  Future<Machine?> getMachineByQrCode(String qrCode) async {
    _setLoading(true);
    _clearError();

    try {
      final machine = await _offlineService.getMachineByQrCode(qrCode);
      return machine;
    } catch (e) {
      _setError('Machine not found: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get site by ID
  Site? getSiteById(String siteId) {
    try {
      return _sites.firstWhere((site) => site.siteId == siteId);
    } catch (e) {
      return null;
    }
  }

  // Search machines
  List<Machine> searchMachines(String query) {
    if (query.isEmpty) return _machines;
    
    final lowercaseQuery = query.toLowerCase();
    return _machines.where((machine) {
      return machine.machineId.toLowerCase().contains(lowercaseQuery) ||
             machine.type.toLowerCase().contains(lowercaseQuery) ||
             machine.model.toLowerCase().contains(lowercaseQuery) ||
             machine.brand.toLowerCase().contains(lowercaseQuery) ||
             (machine.siteName?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  // Filter machines by multiple criteria
  List<Machine> filterMachines({
    String? type,
    String? siteId,
    DateTime? purchasedAfter,
    DateTime? purchasedBefore,
  }) {
    var filtered = _machines.where((machine) => machine.isActive);

    if (type != null) {
      filtered = filtered.where((machine) => machine.type == type);
    }

    if (siteId != null) {
      filtered = filtered.where((machine) => machine.assignedSiteId == siteId);
    }

    if (purchasedAfter != null) {
      filtered = filtered.where((machine) => machine.purchaseDate.isAfter(purchasedAfter));
    }

    if (purchasedBefore != null) {
      filtered = filtered.where((machine) => machine.purchaseDate.isBefore(purchasedBefore));
    }

    return filtered.toList();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadMachines();
    await loadSites();
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