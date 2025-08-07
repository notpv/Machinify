import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/offline_service.dart';

class AppProvider extends ChangeNotifier {
  // Theme Management
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Localization
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  // Authentication State
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? _userRole;
  String? get userRole => _userRole;
  bool get isManager => _userRole == 'manager';
  bool get isFieldEngineer => _userRole == 'field_engineer';

  // App State
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Connectivity State
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;

  // Selected Site (for filtering)
  String? _selectedSiteId;
  String? get selectedSiteId => _selectedSiteId;

  void setSelectedSite(String? siteId) {
    _selectedSiteId = siteId;
    notifyListeners();
  }

  // Initialize app state
  Future<void> initialize() async {
    setLoading(true);
    
    try {
      // Initialize offline service
      await OfflineService.instance.initialize();
      
      // Check authentication state
      _currentUser = Supabase.instance.client.auth.currentUser;
      if (_currentUser != null) {
        _userRole = _currentUser!.userMetadata?['role'] ?? 'field_engineer';
      }
      
      // Listen to auth changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        _currentUser = data.session?.user;
        if (_currentUser != null) {
          _userRole = _currentUser!.userMetadata?['role'] ?? 'field_engineer';
        } else {
          _userRole = null;
        }
        notifyListeners();
      });
      
      // Listen to connectivity changes
      OfflineService.instance.connectivityStream.listen((isConnected) {
        _isOnline = isConnected;
        _updatePendingSyncCount();
        notifyListeners();
      });
      
      // Update initial connectivity state
      _isOnline = await OfflineService.instance.isOnline();
      _updatePendingSyncCount();
      
    } catch (e) {
      setError('Failed to initialize app: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _updatePendingSyncCount() {
    _pendingSyncCount = OfflineService.instance.pendingSyncCount;
  }

  // Manual sync trigger
  Future<void> syncData() async {
    if (!_isOnline) return;
    
    setLoading(true);
    try {
      await OfflineService.instance.syncPendingData();
      _updatePendingSyncCount();
    } catch (e) {
      setError('Sync failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  // Language switching
  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('hi'));
    } else {
      setLocale(const Locale('en'));
    }
  }

  // Theme switching
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  // User preferences
  Map<String, dynamic> get userPreferences => {
    'theme_mode': _themeMode.name,
    'locale': _locale.languageCode,
    'selected_site_id': _selectedSiteId,
  };

  void loadUserPreferences(Map<String, dynamic> preferences) {
    if (preferences['theme_mode'] != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == preferences['theme_mode'],
        orElse: () => ThemeMode.system,
      );
    }
    
    if (preferences['locale'] != null) {
      _locale = Locale(preferences['locale']);
    }
    
    if (preferences['selected_site_id'] != null) {
      _selectedSiteId = preferences['selected_site_id'];
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}