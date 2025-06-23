class PaymentRecord {
  final String id;
  final String trackingNumber;
  final String fromLocation;
  final String toLocation;
  final double amount;
  final String paymentDate;
  final String agentId;
  final String agentName;
  final String paymentMethod;
  final String? paymentReference;
  final String createdAt;

  PaymentRecord({
    required this.id,
    required this.trackingNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.amount,
    required this.paymentDate,
    required this.agentId,
    required this.agentName,
    required this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'amount': amount,
      'paymentDate': paymentDate,
      'agentId': agentId,
      'agentName': agentName,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'createdAt': createdAt,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'],
      trackingNumber: map['trackingNumber'],
      fromLocation: map['fromLocation'],
      toLocation: map['toLocation'],
      amount: map['amount'],
      paymentDate: map['paymentDate'],
      agentId: map['agentId'],
      agentName: map['agentName'],
      paymentMethod: map['paymentMethod'],
      paymentReference: map['paymentReference'],
      createdAt: map['createdAt'],
    );
  }

  /// Get formatted payment method display name
  String get paymentMethodDisplay {
    switch (paymentMethod.toLowerCase()) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod;
    }
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return 'TZS ${amount.toStringAsFixed(2)}';
  }

  /// Get formatted date for display
  String get formattedDate {
    try {
      final date = DateTime.parse(paymentDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return paymentDate;
    }
  }

  /// Get route display (from → to)
  String get routeDisplay {
    return '$fromLocation → $toLocation';
  }
}
