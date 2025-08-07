import 'package:hive/hive.dart';

part 'machine.g.dart';

@HiveType(typeId: 0)
class Machine extends HiveObject {
  @HiveField(0)
  String machineId;
  
  @HiveField(1)
  String type;
  
  @HiveField(2)
  String model;
  
  @HiveField(3)
  String brand;
  
  @HiveField(4)
  DateTime purchaseDate;
  
  @HiveField(5)
  String assignedSiteId;
  
  @HiveField(6)
  String? photoUrl;
  
  @HiveField(7)
  String qrCode;
  
  @HiveField(8)
  DateTime createdAt;
  
  @HiveField(9)
  DateTime updatedAt;
  
  @HiveField(10)
  bool isActive;
  
  @HiveField(11)
  String? siteName; // Denormalized for offline use
  
  @HiveField(12)
  bool needsSync; // For offline synchronization

  Machine({
    required this.machineId,
    required this.type,
    required this.model,
    required this.brand,
    required this.purchaseDate,
    required this.assignedSiteId,
    this.photoUrl,
    required this.qrCode,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.siteName,
    this.needsSync = false,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      machineId: json['machine_id'] ?? '',
      type: json['type'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      purchaseDate: DateTime.parse(json['purchase_date']),
      assignedSiteId: json['assigned_site_id'] ?? '',
      photoUrl: json['photo_url'],
      qrCode: json['qr_code'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      siteName: json['site_name'],
      needsSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'machine_id': machineId,
      'type': type,
      'model': model,
      'brand': brand,
      'purchase_date': purchaseDate.toIso8601String(),
      'assigned_site_id': assignedSiteId,
      'photo_url': photoUrl,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  Machine copyWith({
    String? machineId,
    String? type,
    String? model,
    String? brand,
    DateTime? purchaseDate,
    String? assignedSiteId,
    String? photoUrl,
    String? qrCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? siteName,
    bool? needsSync,
  }) {
    return Machine(
      machineId: machineId ?? this.machineId,
      type: type ?? this.type,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      assignedSiteId: assignedSiteId ?? this.assignedSiteId,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      siteName: siteName ?? this.siteName,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  @override
  String toString() {
    return 'Machine(id: $machineId, type: $type, model: $model, brand: $brand)';
  }
}