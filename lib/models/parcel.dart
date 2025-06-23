class Parcel {
  final String id;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String fromLocation;
  final String toLocation;
  final double amount;
  final String status;
  final String trackingNumber;
  final String createdBy;
  final String createdAt;
  String? receivedBy; // Removed final to allow updates
  String? deliveredBy; // Removed final to allow updates

  // New payment fields
  final String paymentMethod; // 'mobile_money' or 'cash'
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? paymentReference; // For mobile money transactions

  // New delivery scheduling fields
  final String? preferredDeliveryDate;
  final String? preferredDeliveryTime;
  final String? deliveryInstructions;

  // New photo proof fields
  final String? pickupPhotoPath;
  final String? deliveryPhotoPath;
  final String? signaturePath;

  // Smart parcel features
  final bool hasInsurance;
  final double? insuranceValue;
  final double? insurancePremium;
  final String? specialHandling; // 'fragile', 'urgent', 'cold_chain', 'standard'
  final double? declaredValue;

  Parcel({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.fromLocation,
    required this.toLocation,
    required this.amount,
    required this.status,
    required this.trackingNumber,
    required this.createdBy,
    required this.createdAt,
    this.receivedBy,
    this.deliveredBy,
    // New payment parameters
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentReference,
    // New delivery scheduling parameters
    this.preferredDeliveryDate,
    this.preferredDeliveryTime,
    this.deliveryInstructions,
    // New photo proof parameters
    this.pickupPhotoPath,
    this.deliveryPhotoPath,
    this.signaturePath,
    // Smart parcel features parameters
    this.hasInsurance = false,
    this.insuranceValue,
    this.insurancePremium,
    this.specialHandling,
    this.declaredValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'amount': amount,
      'status': status,
      'trackingNumber': trackingNumber,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'receivedBy': receivedBy,
      'deliveredBy': deliveredBy,
      // New payment fields
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      // New delivery scheduling fields
      'preferredDeliveryDate': preferredDeliveryDate,
      'preferredDeliveryTime': preferredDeliveryTime,
      'deliveryInstructions': deliveryInstructions,
      // New photo proof fields
      'pickupPhotoPath': pickupPhotoPath,
      'deliveryPhotoPath': deliveryPhotoPath,
      'signaturePath': signaturePath,
      // Smart parcel features fields
      'hasInsurance': hasInsurance ? 1 : 0,
      'insuranceValue': insuranceValue,
      'insurancePremium': insurancePremium,
      'specialHandling': specialHandling,
      'declaredValue': declaredValue,
    };
  }

  factory Parcel.fromMap(Map<String, dynamic> map) {
    return Parcel(
      id: map['id'],
      senderName: map['senderName'],
      senderPhone: map['senderPhone'],
      receiverName: map['receiverName'],
      receiverPhone: map['receiverPhone'],
      fromLocation: map['fromLocation'],
      toLocation: map['toLocation'],
      amount: map['amount'],
      status: map['status'],
      trackingNumber: map['trackingNumber'],
      createdBy: map['createdBy'],
      createdAt: map['createdAt'],
      receivedBy: map['receivedBy'],
      deliveredBy: map['deliveredBy'],
      // New payment fields
      paymentMethod: map['paymentMethod'] ?? 'cash',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentReference: map['paymentReference'],
      // New delivery scheduling fields
      preferredDeliveryDate: map['preferredDeliveryDate'],
      preferredDeliveryTime: map['preferredDeliveryTime'],
      deliveryInstructions: map['deliveryInstructions'],
      // New photo proof fields
      pickupPhotoPath: map['pickupPhotoPath'],
      deliveryPhotoPath: map['deliveryPhotoPath'],
      signaturePath: map['signaturePath'],
      // Smart parcel features fields
      hasInsurance: (map['hasInsurance'] as int?) == 1,
      insuranceValue: map['insuranceValue']?.toDouble(),
      insurancePremium: map['insurancePremium']?.toDouble(),
      specialHandling: map['specialHandling'],
      declaredValue: map['declaredValue']?.toDouble(),
    );
  }
}