import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/parcel.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  /// Generate QR code data for a parcel
  String generateParcelQRData(Parcel parcel) {
    // Convert to a simple string format for QR code
    return 'ZIPBUS:${parcel.trackingNumber}:${parcel.receiverName}:${parcel.receiverPhone}:${parcel.status}';
  }

  /// Parse QR code data to extract parcel information
  Map<String, String>? parseParcelQRData(String qrData) {
    try {
      if (!qrData.startsWith('ZIPBUS:')) {
        return null; // Not a ZipBus QR code
      }

      final parts = qrData.split(':');
      if (parts.length < 5) {
        return null; // Invalid format
      }

      return {
        'type': 'zipbus_parcel',
        'tracking': parts[1],
        'receiver': parts[2],
        'phone': parts[3],
        'status': parts[4],
      };
    } catch (e) {
      debugPrint('❌ Error parsing QR data: $e');
      return null;
    }
  }

  /// Generate QR code widget for a parcel
  Widget generateParcelQRWidget(Parcel parcel, {double size = 200}) {
    final qrData = generateParcelQRData(parcel);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tracking #${parcel.trackingNumber}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Scan to view parcel details',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Save QR code as image file
  Future<String?> saveParcelQRCode(Parcel parcel, GlobalKey qrKey) async {
    try {
      final RenderRepaintBoundary boundary = qrKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to generate QR code image');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // Save to app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String qrCodesDir = path.join(appDocDir.path, 'qr_codes');
      
      // Create QR codes directory if it doesn't exist
      final Directory qrCodesDirObj = Directory(qrCodesDir);
      if (!await qrCodesDirObj.exists()) {
        await qrCodesDirObj.create(recursive: true);
      }

      final String fileName = 'qr_${parcel.trackingNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = path.join(qrCodesDir, fileName);
      
      final File qrFile = File(filePath);
      await qrFile.writeAsBytes(pngBytes);
      
      debugPrint('📱 QR code saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error saving QR code: $e');
      return null;
    }
  }

  /// Get QR code file from path
  File? getQRCodeFile(String? qrCodePath) {
    if (qrCodePath == null || qrCodePath.isEmpty) return null;
    
    final file = File(qrCodePath);
    return file.existsSync() ? file : null;
  }

  /// Delete QR code file
  Future<bool> deleteQRCode(String? qrCodePath) async {
    if (qrCodePath == null || qrCodePath.isEmpty) return false;
    
    try {
      final file = File(qrCodePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ QR code deleted: $qrCodePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting QR code: $e');
      return false;
    }
  }

  /// Clean up old QR codes (older than 30 days)
  Future<void> cleanupOldQRCodes() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String qrCodesDir = path.join(appDocDir.path, 'qr_codes');
      final Directory qrCodesDirObj = Directory(qrCodesDir);
      
      if (!await qrCodesDirObj.exists()) {
        return;
      }

      final List<FileSystemEntity> files = await qrCodesDirObj.list().toList();
      final DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('🧹 Cleaned up $deletedCount old QR codes');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old QR codes: $e');
    }
  }

  /// Validate if QR data is a valid ZipBus parcel QR code
  bool isValidParcelQRCode(String qrData) {
    final parsed = parseParcelQRData(qrData);
    return parsed != null && parsed['tracking']?.isNotEmpty == true;
  }

  /// Get tracking number from QR code data
  String? getTrackingNumberFromQR(String qrData) {
    final parsed = parseParcelQRData(qrData);
    return parsed?['tracking'];
  }

  /// Generate QR code for sharing parcel information
  String generateShareableQRData(Parcel parcel) {
    // Create a more detailed QR code for sharing
    return 'ZIPBUS_SHARE:${parcel.trackingNumber}:${parcel.fromLocation}:${parcel.toLocation}:${parcel.receiverName}:${parcel.amount}:${parcel.status}';
  }

  /// Create a printable QR code label
  Widget createPrintableQRLabel(Parcel parcel) {
    final qrData = generateParcelQRData(parcel);
    
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Text(
            'ZipBus Parcel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // QR Code
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 150,
            backgroundColor: Colors.white,
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Parcel details
          Text(
            'Tracking: ${parcel.trackingNumber}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'From: ${parcel.fromLocation}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'To: ${parcel.toLocation}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Receiver: ${parcel.receiverName}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Amount: TZS ${parcel.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12),
          ),
          
          const SizedBox(height: 8),
          
          // Footer
          const Text(
            'Scan with ZipBus app for details',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
