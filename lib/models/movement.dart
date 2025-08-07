import 'package:hive/hive.dart';

part 'movement.g.dart';

@HiveType(typeId: 2)
class Movement extends HiveObject {
  @HiveField(0)
  String movementId;
  
  @HiveField(1)
  String machineId;
  
  @HiveField(2)
  String fromSiteId;
  
  @HiveField(3)
  String toSiteId;
  
  @HiveField(4)
  DateTime movementDate;
  
  @HiveField(5)
  String transporterName;
  
  @HiveField(6)
  String? remarks;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime updatedAt;
  
  @HiveField(9)
  String? fromSiteName; // Denormalized for offline use
  
  @HiveField(10)
  String? toSiteName; // Denormalized for offline use
  
  @HiveField(11)
  String? machineType; // Denormalized for offline use
  
  @HiveField(12)
  String? machineModel; // Denormalized for offline use
  
  @HiveField(13)
  bool needsSync; // For offline synchronization
  
  @HiveField(14)
  double? fromLatitude; // GPS coordinates
  
  @HiveField(15)
  double? fromLongitude;
  
  @HiveField(16)
  double? toLatitude;
  
  @HiveField(17)
  double? toLongitude;
  
  @HiveField(18)
  String status; // pending, in_transit, completed

  Movement({
    required this.movementId,
    required this.machineId,
    required this.fromSiteId,
    required this.toSiteId,
    required this.movementDate,
    required this.transporterName,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.fromSiteName,
    this.toSiteName,
    this.machineType,
    this.machineModel,
    this.needsSync = false,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.status = 'pending',
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      movementId: json['movement_id'] ?? '',
      machineId: json['machine_id'] ?? '',
      fromSiteId: json['from_site_id'] ?? '',
      toSiteId: json['to_site_id'] ?? '',
      movementDate: DateTime.parse(json['movement_date']),
      transporterName: json['transporter_name'] ?? '',
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      fromSiteName: json['from_site_name'],
      toSiteName: json['to_site_name'],
      machineType: json['machine_type'],
      machineModel: json['machine_model'],
      needsSync: false,
      fromLatitude: json['from_latitude']?.toDouble(),
      fromLongitude: json['from_longitude']?.toDouble(),
      toLatitude: json['to_latitude']?.toDouble(),
      toLongitude: json['to_longitude']?.toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movement_id': movementId,
      'machine_id': machineId,
      'from_site_id': fromSiteId,
      'to_site_id': toSiteId,
      'movement_date': movementDate.toIso8601String().split('T')[0], // Date only
      'transporter_name': transporterName,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'from_latitude': fromLatitude,
      'from_longitude': fromLongitude,
      'to_latitude': toLatitude,
      'to_longitude': toLongitude,
      'status': status,
    };
  }

  Movement copyWith({
    String? movementId,
    String? machineId,
    String? fromSiteId,
    String? toSiteId,
    DateTime? movementDate,
    String? transporterName,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fromSiteName,
    String? toSiteName,
    String? machineType,
    String? machineModel,
    bool? needsSync,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    String? status,
  }) {
    return Movement(
      movementId: movementId ?? this.movementId,
      machineId: machineId ?? this.machineId,
      fromSiteId: fromSiteId ?? this.fromSiteId,
      toSiteId: toSiteId ?? this.toSiteId,
      movementDate: movementDate ?? this.movementDate,
      transporterName: transporterName ?? this.transporterName,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fromSiteName: fromSiteName ?? this.fromSiteName,
      toSiteName: toSiteName ?? this.toSiteName,
      machineType: machineType ?? this.machineType,
      machineModel: machineModel ?? this.machineModel,
      needsSync: needsSync ?? this.needsSync,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Movement(id: $movementId, machine: $machineId, from: $fromSiteName, to: $toSiteName)';
  }
}