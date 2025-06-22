import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SignatureService {
  static final SignatureService _instance = SignatureService._internal();
  factory SignatureService() => _instance;
  SignatureService._internal();

  /// Save signature to file
  Future<String?> saveSignature(
    Uint8List signatureBytes,
    String trackingNumber,
  ) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String signaturesDir = path.join(appDocDir.path, 'signatures');
      
      // Create signatures directory if it doesn't exist
      final Directory signaturesDirObj = Directory(signaturesDir);
      if (!await signaturesDirObj.exists()) {
        await signaturesDirObj.create(recursive: true);
      }

      final String fileName = 'signature_${trackingNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = path.join(signaturesDir, fileName);
      
      final File signatureFile = File(filePath);
      await signatureFile.writeAsBytes(signatureBytes);
      
      debugPrint('✍️ Signature saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error saving signature: $e');
      return null;
    }
  }

  /// Get signature file from path
  File? getSignatureFile(String? signaturePath) {
    if (signaturePath == null || signaturePath.isEmpty) return null;
    
    final file = File(signaturePath);
    return file.existsSync() ? file : null;
  }

  /// Delete signature file
  Future<bool> deleteSignature(String? signaturePath) async {
    if (signaturePath == null || signaturePath.isEmpty) return false;
    
    try {
      final file = File(signaturePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Signature deleted: $signaturePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting signature: $e');
      return false;
    }
  }

  /// Clean up old signatures (older than 30 days)
  Future<void> cleanupOldSignatures() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String signaturesDir = path.join(appDocDir.path, 'signatures');
      final Directory signaturesDirObj = Directory(signaturesDir);
      
      if (!await signaturesDirObj.exists()) {
        return;
      }

      final List<FileSystemEntity> files = await signaturesDirObj.list().toList();
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
        debugPrint('🧹 Cleaned up $deletedCount old signatures');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old signatures: $e');
    }
  }

  /// Convert signature widget to bytes
  static Future<Uint8List?> convertSignatureToBytes(
    GlobalKey signatureKey,
  ) async {
    try {
      final RenderRepaintBoundary boundary = signatureKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error converting signature to bytes: $e');
      return null;
    }
  }

  /// Validate signature (check if it's not empty)
  static bool isSignatureValid(Uint8List? signatureBytes) {
    if (signatureBytes == null || signatureBytes.isEmpty) {
      return false;
    }
    
    // Basic validation - check if signature has meaningful content
    // This is a simple check - in a real app you might want more sophisticated validation
    return signatureBytes.length > 1000; // Minimum size for a meaningful signature
  }

  /// Get all signatures for a tracking number
  Future<List<File>> getParcelSignatures(String trackingNumber) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String signaturesDir = path.join(appDocDir.path, 'signatures');
      final Directory signaturesDirObj = Directory(signaturesDir);
      
      if (!await signaturesDirObj.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await signaturesDirObj.list().toList();
      final List<File> parcelSignatures = [];

      for (final file in files) {
        if (file is File && file.path.contains(trackingNumber)) {
          parcelSignatures.add(file);
        }
      }

      return parcelSignatures;
    } catch (e) {
      debugPrint('❌ Error getting parcel signatures: $e');
      return [];
    }
  }

  /// Get signature display name
  String getSignatureDisplayName(String signaturePath) {
    return 'Digital Signature';
  }
}
