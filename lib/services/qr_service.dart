import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QrService {
  static final QrService _instance = QrService._internal();
  factory QrService() => _instance;
  QrService._internal();

  /// Generate a unique QR code string for a machine
  String generateMachineQrCode(String machineId, String type, String model) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    
    // Format: MACH-{TYPE}-{MACHINE_ID}-{RANDOM}-{TIMESTAMP}
    return 'MACH-${type.toUpperCase()}-$machineId-$random-$timestamp';
  }

  /// Validate if a QR code is a valid machine QR code
  bool isValidMachineQrCode(String qrCode) {
    if (qrCode.isEmpty) return false;
    
    // Check if it starts with MACH- and has the correct format
    final parts = qrCode.split('-');
    return parts.length >= 5 && parts[0] == 'MACH';
  }

  /// Extract machine ID from QR code
  String? extractMachineIdFromQrCode(String qrCode) {
    if (!isValidMachineQrCode(qrCode)) return null;
    
    final parts = qrCode.split('-');
    if (parts.length >= 3) {
      return parts[2]; // Machine ID is the third part
    }
    
    return null;
  }

  /// Generate QR code widget
  Widget generateQrCodeWidget(
    String data, {
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(8.0),
    );
  }

  /// Generate QR code widget with machine info overlay
  Widget generateMachineQrCodeWidget(
    String qrCode,
    String machineId,
    String type,
    String model, {
    double size = 250.0,
  }) {
    return Container(
      width: size,
      height: size + 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: qrCode,
            version: QrVersions.auto,
            size: size - 40,
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            padding: const EdgeInsets.all(8.0),
          ),
          const SizedBox(height: 8),
          Text(
            machineId,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            '$type - $model',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Generate a simple alphanumeric ID for machines
  String generateSimpleMachineId(String type) {
    final typeCode = _getTypeCode(type);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(999).toString().padLeft(3, '0');
    
    // Take last 6 digits of timestamp for brevity
    final shortTimestamp = timestamp.substring(timestamp.length - 6);
    
    return '$typeCode$shortTimestamp$random';
  }

  String _getTypeCode(String type) {
    switch (type.toLowerCase()) {
      case 'excavator':
        return 'EX';
      case 'roller':
        return 'RL';
      case 'bulldozer':
        return 'BD';
      case 'crane':
        return 'CR';
      case 'grader':
        return 'GR';
      default:
        return 'MC'; // Generic machine code
    }
  }

  /// Parse QR code to extract machine information
  Map<String, String>? parseQrCode(String qrCode) {
    if (!isValidMachineQrCode(qrCode)) return null;
    
    final parts = qrCode.split('-');
    if (parts.length < 5) return null;
    
    return {
      'prefix': parts[0], // MACH
      'type': parts[1],
      'machine_id': parts[2],
      'random': parts[3],
      'timestamp': parts[4],
    };
  }

  /// Generate a printable QR code label with machine details
  Widget generatePrintableQrLabel(
    String qrCode,
    String machineId,
    String type,
    String model,
    String brand,
    DateTime purchaseDate,
  ) {
    return Container(
      width: 300,
      height: 400,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: const Text(
              'MACHINIFY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // QR Code
          QrImageView(
            data: qrCode,
            version: QrVersions.auto,
            size: 180,
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
          
          const SizedBox(height: 16),
          
          // Machine Details
          Text(
            machineId,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            type.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '$brand $model',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Purchased: ${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          
          const Spacer(),
          
          // Footer
          const Text(
            'Scan to access machine details',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}