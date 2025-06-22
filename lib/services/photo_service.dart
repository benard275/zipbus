import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Take a photo for parcel pickup proof
  Future<String?> takePickupPhoto(String trackingNumber) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final savedPath = await _savePhoto(
          photo,
          'pickup_${trackingNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        debugPrint('📸 Pickup photo saved: $savedPath');
        return savedPath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error taking pickup photo: $e');
      return null;
    }
  }

  /// Take a photo for parcel delivery proof
  Future<String?> takeDeliveryPhoto(String trackingNumber) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final savedPath = await _savePhoto(
          photo,
          'delivery_${trackingNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        debugPrint('📸 Delivery photo saved: $savedPath');
        return savedPath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error taking delivery photo: $e');
      return null;
    }
  }

  /// Save photo to app documents directory
  Future<String> _savePhoto(XFile photo, String fileName) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String photosDir = path.join(appDocDir.path, 'photos');
    
    // Create photos directory if it doesn't exist
    final Directory photosDirObj = Directory(photosDir);
    if (!await photosDirObj.exists()) {
      await photosDirObj.create(recursive: true);
    }

    final String filePath = path.join(photosDir, fileName);
    final File savedFile = await File(photo.path).copy(filePath);
    
    return savedFile.path;
  }

  /// Get photo file from path
  File? getPhotoFile(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;
    
    final file = File(photoPath);
    return file.existsSync() ? file : null;
  }

  /// Delete photo file
  Future<bool> deletePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return false;
    
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Photo deleted: $photoPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting photo: $e');
      return false;
    }
  }

  /// Get all photos for a tracking number
  Future<List<File>> getParcelPhotos(String trackingNumber) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos');
      final Directory photosDirObj = Directory(photosDir);
      
      if (!await photosDirObj.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await photosDirObj.list().toList();
      final List<File> parcelPhotos = [];

      for (final file in files) {
        if (file is File && file.path.contains(trackingNumber)) {
          parcelPhotos.add(file);
        }
      }

      return parcelPhotos;
    } catch (e) {
      debugPrint('❌ Error getting parcel photos: $e');
      return [];
    }
  }

  /// Clean up old photos (older than 30 days)
  Future<void> cleanupOldPhotos() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String photosDir = path.join(appDocDir.path, 'photos');
      final Directory photosDirObj = Directory(photosDir);
      
      if (!await photosDirObj.exists()) {
        return;
      }

      final List<FileSystemEntity> files = await photosDirObj.list().toList();
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
        debugPrint('🧹 Cleaned up $deletedCount old photos');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up old photos: $e');
    }
  }

  /// Get photo display name
  String getPhotoDisplayName(String photoPath) {
    final fileName = path.basename(photoPath);
    if (fileName.startsWith('pickup_')) {
      return 'Pickup Photo';
    } else if (fileName.startsWith('delivery_')) {
      return 'Delivery Photo';
    } else {
      return 'Photo';
    }
  }

  /// Check if photo is pickup photo
  bool isPickupPhoto(String photoPath) {
    return path.basename(photoPath).startsWith('pickup_');
  }

  /// Check if photo is delivery photo
  bool isDeliveryPhoto(String photoPath) {
    return path.basename(photoPath).startsWith('delivery_');
  }
}
