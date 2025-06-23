import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Business mobile money details
  static const String businessPhoneNumber = '0629661245';
  static const String businessName = 'BENARD PAUL';

  /// Process mobile money payment
  /// Returns payment reference if successful, null if failed
  Future<String?> processMobileMoneyPayment({
    required String customerPhone,
    required double amount,
    required String trackingNumber,
  }) async {
    try {
      debugPrint('🏦 Processing mobile money payment:');
      debugPrint('   Customer: $customerPhone');
      debugPrint('   Amount: TZS ${amount.toStringAsFixed(2)}');
      debugPrint('   Tracking: $trackingNumber');
      debugPrint('   Business: $businessName ($businessPhoneNumber)');

      // Generate payment reference
      final paymentRef = _generatePaymentReference(trackingNumber);
      
      // Create payment message
      final message = _createPaymentMessage(
        amount: amount,
        trackingNumber: trackingNumber,
        paymentReference: paymentRef,
      );

      // Launch mobile money app or SMS
      final success = await _launchMobileMoneyPayment(
        customerPhone: customerPhone,
        message: message,
      );

      if (success) {
        debugPrint('✅ Mobile money payment initiated successfully');
        debugPrint('   Payment Reference: $paymentRef');
        return paymentRef;
      } else {
        debugPrint('❌ Failed to initiate mobile money payment');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Mobile money payment error: $e');
      return null;
    }
  }

  /// Generate unique payment reference
  String _generatePaymentReference(String trackingNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'ZB$trackingNumber${timestamp.substring(timestamp.length - 4)}';
  }

  /// Create payment instruction message
  String _createPaymentMessage({
    required double amount,
    required String trackingNumber,
    required String paymentReference,
  }) {
    return '''
🚚 ZipBus Payment Required

Parcel: #$trackingNumber
Amount: TZS ${amount.toStringAsFixed(2)}
Reference: $paymentReference

📱 MOBILE MONEY PAYMENT:
Send TZS ${amount.toStringAsFixed(2)} to:
📞 $businessPhoneNumber
👤 $businessName

💡 Use reference: $paymentReference
⚡ Payment confirms your parcel booking

Thank you for using ZipBus! 🚛
''';
  }

  /// Launch mobile money payment interface
  Future<bool> _launchMobileMoneyPayment({
    required String customerPhone,
    required String message,
  }) async {
    try {
      // Try to launch SMS with payment instructions
      final smsUri = Uri(
        scheme: 'sms',
        path: customerPhone,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }

      // Fallback: Try to launch default messaging app
      final fallbackUri = Uri(
        scheme: 'sms',
        path: '',
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error launching mobile money payment: $e');
      return false;
    }
  }

  /// Verify payment status (placeholder for future integration)
  Future<String> verifyPaymentStatus(String paymentReference) async {
    // In a real implementation, this would check with mobile money API
    // For now, return pending status
    debugPrint('🔍 Verifying payment status for: $paymentReference');
    
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In real implementation, you would integrate with:
    // - M-Pesa API
    // - Tigo Pesa API  
    // - Airtel Money API
    // - Halopesa API
    
    return 'pending'; // 'paid', 'failed', 'pending'
  }

  /// Get payment method display name
  String getPaymentMethodDisplayName(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash on Delivery';
      default:
        return 'Unknown';
    }
  }

  /// Get payment status display name
  String getPaymentStatusDisplayName(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return '✅ Paid';
      case 'pending':
        return '⏳ Pending';
      case 'failed':
        return '❌ Failed';
      default:
        return '❓ Unknown';
    }
  }

  /// Get payment status color
  int getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 0xFF4CAF50; // Green
      case 'pending':
        return 0xFFFF9800; // Orange
      case 'failed':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
