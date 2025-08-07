import 'package:hive/hive.dart';

part 'site.g.dart';

@HiveType(typeId: 3)
class Site extends HiveObject {
  @HiveField(0)
  String siteId;
  
  @HiveField(1)
  String siteName;
  
  @HiveField(2)
  double? latitude;
  
  @HiveField(3)
  double? longitude;
  
  @HiveField(4)
  String? address;
  
  @HiveField(5)
  String? contactPerson;
  
  @HiveField(6)
  String? contactPhone;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime updatedAt;
  
  @HiveField(9)
  bool isActive;
  
  @HiveField(10)
  int machineCount; // Number of machines currently at this site
  
  @HiveField(11)
  String? region; // For grouping sites
  
  @HiveField(12)
  bool needsSync; // For offline synchronization

  Site({
    required this.siteId,
    required this.siteName,
    this.latitude,
    this.longitude,
    this.address,
    this.contactPerson,
    this.contactPhone,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.machineCount = 0,
    this.region,
    this.needsSync = false,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      siteId: json['site_id'] ?? '',
      siteName: json['site_name'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      address: json['address'],
      contactPerson: json['contact_person'],
      contactPhone: json['contact_phone'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      machineCount: json['machine_count'] ?? 0,
      region: json['region'],
      needsSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_id': siteId,
      'site_name': siteName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'contact_person': contactPerson,
      'contact_phone': contactPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'machine_count': machineCount,
      'region': region,
    };
  }

  Site copyWith({
    String? siteId,
    String? siteName,
    double? latitude,
    double? longitude,
    String? address,
    String? contactPerson,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? machineCount,
    String? region,
    bool? needsSync,
  }) {
    return Site(
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      machineCount: machineCount ?? this.machineCount,
      region: region ?? this.region,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  /// Calculate distance to another site in kilometers
  double? distanceTo(Site other) {
    if (latitude == null || longitude == null || 
        other.latitude == null || other.longitude == null) {
      return null;
    }
    
    // Haversine formula for calculating distance between two points
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = latitude! * (3.14159265359 / 180);
    final double lat2Rad = other.latitude! * (3.14159265359 / 180);
    final double deltaLatRad = (other.latitude! - latitude!) * (3.14159265359 / 180);
    final double deltaLonRad = (other.longitude! - longitude!) * (3.14159265359 / 180);
    
    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLonRad / 2).sin() * (deltaLonRad / 2).sin();
    
    final double c = 2 * (a.sqrt()).atan2((1 - a).sqrt());
    
    return earthRadius * c;
  }

  @override
  String toString() {
    return 'Site(id: $siteId, name: $siteName, machines: $machineCount)';
  }
}