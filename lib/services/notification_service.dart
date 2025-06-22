import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> sendNotification(String mobile, String message) async {
    // Simulate sending a notification (e.g., SMS or push notification)
    // In a real app, integrate with Firebase, Twilio, or another service
    if (kDebugMode) {
      print('Sending notification to $mobile: $message');
    }
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}