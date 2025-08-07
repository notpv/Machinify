import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get filter => _localizedValues[locale.languageCode]!['filter']!;
  String get refresh => _localizedValues[locale.languageCode]!['refresh']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get done => _localizedValues[locale.languageCode]!['done']!;
  String get next => _localizedValues[locale.languageCode]!['next']!;
  String get previous => _localizedValues[locale.languageCode]!['previous']!;

  // Authentication
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get signIn => _localizedValues[locale.languageCode]!['sign_in']!;
  String get signUp => _localizedValues[locale.languageCode]!['sign_up']!;
  String get createAccount => _localizedValues[locale.languageCode]!['create_account']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgot_password']!;

  // Navigation
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get machines => _localizedValues[locale.languageCode]!['machines']!;
  String get dashboard => _localizedValues[locale.languageCode]!['dashboard']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;

  // Machinery
  String get addMachine => _localizedValues[locale.languageCode]!['add_machine']!;
  String get machineId => _localizedValues[locale.languageCode]!['machine_id']!;
  String get machineType => _localizedValues[locale.languageCode]!['machine_type']!;
  String get model => _localizedValues[locale.languageCode]!['model']!;
  String get brand => _localizedValues[locale.languageCode]!['brand']!;
  String get purchaseDate => _localizedValues[locale.languageCode]!['purchase_date']!;
  String get assignedSite => _localizedValues[locale.languageCode]!['assigned_site']!;
  String get qrCode => _localizedValues[locale.languageCode]!['qr_code']!;
  String get photo => _localizedValues[locale.languageCode]!['photo']!;

  // Machine Types
  String get excavator => _localizedValues[locale.languageCode]!['excavator']!;
  String get roller => _localizedValues[locale.languageCode]!['roller']!;
  String get bulldozer => _localizedValues[locale.languageCode]!['bulldozer']!;
  String get crane => _localizedValues[locale.languageCode]!['crane']!;
  String get grader => _localizedValues[locale.languageCode]!['grader']!;

  // Usage Logging
  String get logUsage => _localizedValues[locale.languageCode]!['log_usage']!;
  String get usageDate => _localizedValues[locale.languageCode]!['usage_date']!;
  String get hoursRun => _localizedValues[locale.languageCode]!['hours_run']!;
  String get dieselConsumed => _localizedValues[locale.languageCode]!['diesel_consumed']!;
  String get operatorName => _localizedValues[locale.languageCode]!['operator_name']!;
  String get fuelBill => _localizedValues[locale.languageCode]!['fuel_bill']!;
  String get fuelEfficiency => _localizedValues[locale.languageCode]!['fuel_efficiency']!;
  String get remarks => _localizedValues[locale.languageCode]!['remarks']!;

  // Movement
  String get recordMovement => _localizedValues[locale.languageCode]!['record_movement']!;
  String get fromSite => _localizedValues[locale.languageCode]!['from_site']!;
  String get toSite => _localizedValues[locale.languageCode]!['to_site']!;
  String get movementDate => _localizedValues[locale.languageCode]!['movement_date']!;
  String get transporterName => _localizedValues[locale.languageCode]!['transporter_name']!;
  String get movementStatus => _localizedValues[locale.languageCode]!['movement_status']!;

  // Status
  String get pending => _localizedValues[locale.languageCode]!['pending']!;
  String get inTransit => _localizedValues[locale.languageCode]!['in_transit']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get active => _localizedValues[locale.languageCode]!['active']!;
  String get inactive => _localizedValues[locale.languageCode]!['inactive']!;

  // Dashboard
  String get totalMachines => _localizedValues[locale.languageCode]!['total_machines']!;
  String get recentLogs => _localizedValues[locale.languageCode]!['recent_logs']!;
  String get pendingMovements => _localizedValues[locale.languageCode]!['pending_movements']!;
  String get fuelConsumption => _localizedValues[locale.languageCode]!['fuel_consumption']!;
  String get analytics => _localizedValues[locale.languageCode]!['analytics']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;

  // Connectivity
  String get online => _localizedValues[locale.languageCode]!['online']!;
  String get offline => _localizedValues[locale.languageCode]!['offline']!;
  String get syncing => _localizedValues[locale.languageCode]!['syncing']!;
  String get syncComplete => _localizedValues[locale.languageCode]!['sync_complete']!;
  String get syncFailed => _localizedValues[locale.languageCode]!['sync_failed']!;

  // Validation Messages
  String get fieldRequired => _localizedValues[locale.languageCode]!['field_required']!;
  String get invalidEmail => _localizedValues[locale.languageCode]!['invalid_email']!;
  String get passwordTooShort => _localizedValues[locale.languageCode]!['password_too_short']!;
  String get invalidNumber => _localizedValues[locale.languageCode]!['invalid_number']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Machinify',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      'refresh': 'Refresh',
      'retry': 'Retry',
      'close': 'Close',
      'done': 'Done',
      'next': 'Next',
      'previous': 'Previous',

      // Authentication
      'login': 'Login',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'create_account': 'Create Account',
      'forgot_password': 'Forgot Password',

      // Navigation
      'home': 'Home',
      'machines': 'Machines',
      'dashboard': 'Dashboard',
      'profile': 'Profile',
      'settings': 'Settings',

      // Machinery
      'add_machine': 'Add Machine',
      'machine_id': 'Machine ID',
      'machine_type': 'Machine Type',
      'model': 'Model',
      'brand': 'Brand',
      'purchase_date': 'Purchase Date',
      'assigned_site': 'Assigned Site',
      'qr_code': 'QR Code',
      'photo': 'Photo',

      // Machine Types
      'excavator': 'Excavator',
      'roller': 'Roller',
      'bulldozer': 'Bulldozer',
      'crane': 'Crane',
      'grader': 'Grader',

      // Usage Logging
      'log_usage': 'Log Usage',
      'usage_date': 'Usage Date',
      'hours_run': 'Hours Run',
      'diesel_consumed': 'Diesel Consumed',
      'operator_name': 'Operator Name',
      'fuel_bill': 'Fuel Bill',
      'fuel_efficiency': 'Fuel Efficiency',
      'remarks': 'Remarks',

      // Movement
      'record_movement': 'Record Movement',
      'from_site': 'From Site',
      'to_site': 'To Site',
      'movement_date': 'Movement Date',
      'transporter_name': 'Transporter Name',
      'movement_status': 'Movement Status',

      // Status
      'pending': 'Pending',
      'in_transit': 'In Transit',
      'completed': 'Completed',
      'active': 'Active',
      'inactive': 'Inactive',

      // Dashboard
      'total_machines': 'Total Machines',
      'recent_logs': 'Recent Logs',
      'pending_movements': 'Pending Movements',
      'fuel_consumption': 'Fuel Consumption',
      'analytics': 'Analytics',
      'reports': 'Reports',

      // Connectivity
      'online': 'Online',
      'offline': 'Offline',
      'syncing': 'Syncing',
      'sync_complete': 'Sync Complete',
      'sync_failed': 'Sync Failed',

      // Validation Messages
      'field_required': 'This field is required',
      'invalid_email': 'Please enter a valid email',
      'password_too_short': 'Password must be at least 6 characters',
      'invalid_number': 'Please enter a valid number',
    },
    'hi': {
      // Common
      'app_name': 'मशीनिफाई',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'search': 'खोजें',
      'filter': 'फिल्टर',
      'refresh': 'रिफ्रेश',
      'retry': 'पुनः प्रयास',
      'close': 'बंद करें',
      'done': 'पूर्ण',
      'next': 'अगला',
      'previous': 'पिछला',

      // Authentication
      'login': 'लॉगिन',
      'logout': 'लॉगआउट',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'sign_in': 'साइन इन',
      'sign_up': 'साइन अप',
      'create_account': 'खाता बनाएं',
      'forgot_password': 'पासवर्ड भूल गए',

      // Navigation
      'home': 'होम',
      'machines': 'मशीनें',
      'dashboard': 'डैशबोर्ड',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्स',

      // Machinery
      'add_machine': 'मशीन जोड़ें',
      'machine_id': 'मशीन आईडी',
      'machine_type': 'मशीन का प्रकार',
      'model': 'मॉडल',
      'brand': 'ब्रांड',
      'purchase_date': 'खरीद की तारीख',
      'assigned_site': 'निर्दिष्ट साइट',
      'qr_code': 'क्यूआर कोड',
      'photo': 'फोटो',

      // Machine Types
      'excavator': 'एक्सकेवेटर',
      'roller': 'रोलर',
      'bulldozer': 'बुलडोजर',
      'crane': 'क्रेन',
      'grader': 'ग्रेडर',

      // Usage Logging
      'log_usage': 'उपयोग लॉग करें',
      'usage_date': 'उपयोग की तारीख',
      'hours_run': 'चलने के घंटे',
      'diesel_consumed': 'डीजल की खपत',
      'operator_name': 'ऑपरेटर का नाम',
      'fuel_bill': 'ईंधन बिल',
      'fuel_efficiency': 'ईंधन दक्षता',
      'remarks': 'टिप्पणी',

      // Movement
      'record_movement': 'आवाजाही रिकॉर्ड करें',
      'from_site': 'से साइट',
      'to_site': 'तक साइट',
      'movement_date': 'आवाजाही की तारीख',
      'transporter_name': 'ट्रांसपोर्टर का नाम',
      'movement_status': 'आवाजाही की स्थिति',

      // Status
      'pending': 'लंबित',
      'in_transit': 'ट्रांजिट में',
      'completed': 'पूर्ण',
      'active': 'सक्रिय',
      'inactive': 'निष्क्रिय',

      // Dashboard
      'total_machines': 'कुल मशीनें',
      'recent_logs': 'हाल के लॉग',
      'pending_movements': 'लंबित आवाजाही',
      'fuel_consumption': 'ईंधन की खपत',
      'analytics': 'विश्लेषण',
      'reports': 'रिपोर्ट',

      // Connectivity
      'online': 'ऑनलाइन',
      'offline': 'ऑफलाइन',
      'syncing': 'सिंक हो रहा है',
      'sync_complete': 'सिंक पूर्ण',
      'sync_failed': 'सिंक असफल',

      // Validation Messages
      'field_required': 'यह फील्ड आवश्यक है',
      'invalid_email': 'कृपया एक वैध ईमेल दर्ज करें',
      'password_too_short': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
      'invalid_number': 'कृपया एक वैध संख्या दर्ज करें',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}