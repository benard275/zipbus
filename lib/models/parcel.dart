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
    );
  }
}