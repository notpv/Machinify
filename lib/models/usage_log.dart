import 'package:hive/hive.dart';

part 'usage_log.g.dart';

@HiveType(typeId: 1)
class UsageLog extends HiveObject {
  @HiveField(0)
  String logId;
  
  @HiveField(1)
  String machineId;
  
  @HiveField(2)
  DateTime date;
  
  @HiveField(3)
  double hoursRun;
  
  @HiveField(4)
  double dieselConsumed;
  
  @HiveField(5)
  String operatorName;
  
  @HiveField(6)
  String? fuelBillUrl;
  
  @HiveField(7)
  double? fuelEfficiency; // Calculated: dieselConsumed / hoursRun
  
  @HiveField(8)
  DateTime createdAt;
  
  @HiveField(9)
  DateTime updatedAt;
  
  @HiveField(10)
  String? remarks;
  
  @HiveField(11)
  String? machineType; // Denormalized for offline use
  
  @HiveField(12)
  String? machineModel; // Denormalized for offline use
  
  @HiveField(13)
  bool needsSync; // For offline synchronization
  
  @HiveField(14)
  bool isValidated; // Fuel efficiency validation status

  UsageLog({
    required this.logId,
    required this.machineId,
    required this.date,
    required this.hoursRun,
    required this.dieselConsumed,
    required this.operatorName,
    this.fuelBillUrl,
    this.fuelEfficiency,
    required this.createdAt,
    required this.updatedAt,
    this.remarks,
    this.machineType,
    this.machineModel,
    this.needsSync = false,
    this.isValidated = true,
  });

  factory UsageLog.fromJson(Map<String, dynamic> json) {
    return UsageLog(
      logId: json['log_id'] ?? '',
      machineId: json['machine_id'] ?? '',
      date: DateTime.parse(json['date']),
      hoursRun: (json['hours_run'] ?? 0.0).toDouble(),
      dieselConsumed: (json['diesel_consumed'] ?? 0.0).toDouble(),
      operatorName: json['operator_name'] ?? '',
      fuelBillUrl: json['fuel_bill_url'],
      fuelEfficiency: json['fuel_efficiency']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      remarks: json['remarks'],
      machineType: json['machine_type'],
      machineModel: json['machine_model'],
      needsSync: false,
      isValidated: json['is_validated'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'machine_id': machineId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'hours_run': hoursRun,
      'diesel_consumed': dieselConsumed,
      'operator_name': operatorName,
      'fuel_bill_url': fuelBillUrl,
      'fuel_efficiency': fuelEfficiency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'remarks': remarks,
      'is_validated': isValidated,
    };
  }

  UsageLog copyWith({
    String? logId,
    String? machineId,
    DateTime? date,
    double? hoursRun,
    double? dieselConsumed,
    String? operatorName,
    String? fuelBillUrl,
    double? fuelEfficiency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remarks,
    String? machineType,
    String? machineModel,
    bool? needsSync,
    bool? isValidated,
  }) {
    return UsageLog(
      logId: logId ?? this.logId,
      machineId: machineId ?? this.machineId,
      date: date ?? this.date,
      hoursRun: hoursRun ?? this.hoursRun,
      dieselConsumed: dieselConsumed ?? this.dieselConsumed,
      operatorName: operatorName ?? this.operatorName,
      fuelBillUrl: fuelBillUrl ?? this.fuelBillUrl,
      fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remarks: remarks ?? this.remarks,
      machineType: machineType ?? this.machineType,
      machineModel: machineModel ?? this.machineModel,
      needsSync: needsSync ?? this.needsSync,
      isValidated: isValidated ?? this.isValidated,
    );
  }

  /// Calculate fuel efficiency (liters per hour)
  double calculateFuelEfficiency() {
    if (hoursRun <= 0) return 0.0;
    return dieselConsumed / hoursRun;
  }

  /// Check if fuel efficiency is within acceptable range
  bool isFuelEfficiencyValid() {
    final efficiency = calculateFuelEfficiency();
    return efficiency >= 0.5 && efficiency <= 10.0;
  }

  @override
  String toString() {
    return 'UsageLog(id: $logId, machine: $machineId, hours: $hoursRun, fuel: $dieselConsumed)';
  }
}