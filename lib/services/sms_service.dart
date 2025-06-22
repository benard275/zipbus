import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Helper method to clean phone numbers
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure proper formatting
    if (cleaned.startsWith('0') && cleaned.length > 1) {
      // Convert local format to international (assuming Tanzania +255)
      cleaned = '+255${cleaned.substring(1)}';
    }

    return cleaned;
  }

  Future<void> initialize() async {
    // Simple initialization - no complex setup needed
    debugPrint('NotificationService initialized');
  }

  // Send notification via phone's messaging app (ACTUALLY OPEN THE APP)
  Future<bool> sendMessageViaApp({
    required String phoneNumber,
    required String message,
  }) async {
    if (phoneNumber.isEmpty) return false;

    try {
      // Clean and format phone number
      String cleanPhoneNumber = _cleanPhoneNumber(phoneNumber);
      debugPrint('🔄 Attempting to open messaging app for: $cleanPhoneNumber');
      debugPrint('📝 Message: $message');

      // Try multiple SMS URI approaches
      List<Map<String, String>> uriAttempts = [
        {
          'name': 'Standard SMS URI',
          'uri': 'sms:$cleanPhoneNumber?body=${Uri.encodeComponent(message)}'
        },
        {
          'name': 'SMS with SENDTO action',
          'uri': 'smsto:$cleanPhoneNumber?body=${Uri.encodeComponent(message)}'
        },
        {
          'name': 'Simple SMS URI',
          'uri': 'sms:$cleanPhoneNumber'
        },
      ];

      for (var attempt in uriAttempts) {
        try {
          debugPrint('🔗 Trying ${attempt['name']}: ${attempt['uri']}');
          final Uri uri = Uri.parse(attempt['uri']!);

          // Check if we can launch this URI
          bool canLaunch = await canLaunchUrl(uri);
          debugPrint('   Can launch: $canLaunch');

          if (canLaunch) {
            bool launched = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (launched) {
              debugPrint('✅ Successfully opened messaging app using ${attempt['name']}');
              if (attempt['name'] == 'Simple SMS URI') {
                debugPrint('📱 Please manually type: $message');
              }
              return true;
            }
          }
        } catch (e) {
          debugPrint('❌ ${attempt['name']} failed: $e');
          continue;
        }
      }

      // Try alternative approach - just open messaging app
      try {
        debugPrint('🔄 Trying fallback approach...');
        final Uri fallbackUri = Uri.parse('sms:$cleanPhoneNumber');
        bool launched = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          debugPrint('✅ Opened messaging app (without pre-filled message) for $cleanPhoneNumber');
          debugPrint('📱 Please manually type: $message');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Fallback also failed: $e');
      }

      // Final fallback
      debugPrint('📱 MANUAL MESSAGE REQUIRED:');
      debugPrint('   Send to: $cleanPhoneNumber');
      debugPrint('   Message: $message');
      return false;

    } catch (e) {
      debugPrint('❌ Critical error in sendMessageViaApp: $e');
      return false;
    }
  }

  // ACTUALLY OPEN MESSAGING APP for parcel status updates
  Future<bool> sendStatusUpdateNotification({
    required String phoneNumber,
    required String trackingNumber,
    required String status,
  }) async {
    if (phoneNumber.isEmpty) return false;

    // Create simple, friendly message
    String message;
    switch (status.toLowerCase()) {
      case 'pending':
        message = '📦 Your ZipBus parcel #$trackingNumber is ready for pickup!';
        break;
      case 'in transit':
        message = '🚚 Your ZipBus parcel #$trackingNumber is on the way!';
        break;
      case 'delivered':
        message = '✅ Your ZipBus parcel #$trackingNumber has been delivered!';
        break;
      default:
        message = '📱 ZipBus update: Your parcel #$trackingNumber status: $status';
    }

    debugPrint('🚀 SENDING NOTIFICATION: $status for parcel #$trackingNumber to $phoneNumber');

    try {
      bool success = await sendMessageViaApp(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (success) {
        debugPrint('✅ Messaging app opened successfully for $phoneNumber');
      } else {
        debugPrint('❌ Failed to open messaging app for $phoneNumber');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Notification error: $e');
      return false;
    }
  }

  // Show simple debug message (no complex notifications needed)
  Future<void> showSimpleNotification({
    required String title,
    required String message,
  }) async {
    debugPrint('📱 $title: $message');
  }

  // Alternative method: Show notification details in a simple format
  Future<void> showNotificationDetails({
    required String phoneNumber,
    required String message,
  }) async {
    String cleanPhone = _cleanPhoneNumber(phoneNumber);
    debugPrint('=== ZipBus Notification ===');
    debugPrint('To: $cleanPhone');
    debugPrint('Message: $message');
    debugPrint('========================');
  }
}
