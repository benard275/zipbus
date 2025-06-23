class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String messageText;
  final String messageType; // 'text', 'image', 'file', etc.
  final bool isRead;
  final String sentAt;
  final String? deliveredAt;
  final String? readAt;
  final String deliveryStatus; // 'sent', 'delivered', 'read'

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.messageText,
    this.messageType = 'text',
    this.isRead = false,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.deliveryStatus = 'sent',
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversationId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      receiverId: map['receiverId'] as String,
      receiverName: map['receiverName'] as String,
      messageText: map['messageText'] as String,
      messageType: map['messageType'] as String? ?? 'text',
      isRead: (map['isRead'] as int) == 1,
      sentAt: map['sentAt'] as String,
      deliveredAt: map['deliveredAt'] as String?,
      readAt: map['readAt'] as String?,
      deliveryStatus: map['deliveryStatus'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'messageText': messageText,
      'messageType': messageType,
      'isRead': isRead ? 1 : 0,
      'sentAt': sentAt,
      'deliveredAt': deliveredAt,
      'readAt': readAt,
      'deliveryStatus': deliveryStatus,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? messageText,
    String? messageType,
    bool? isRead,
    String? sentAt,
    String? deliveredAt,
    String? readAt,
    String? deliveryStatus,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  @override
  String toString() {
    return 'Message{id: $id, conversationId: $conversationId, senderId: $senderId, senderName: $senderName, receiverId: $receiverId, receiverName: $receiverName, messageText: $messageText, messageType: $messageType, isRead: $isRead, sentAt: $sentAt, deliveredAt: $deliveredAt, readAt: $readAt, deliveryStatus: $deliveryStatus}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          receiverId == other.receiverId &&
          receiverName == other.receiverName &&
          messageText == other.messageText &&
          messageType == other.messageType &&
          isRead == other.isRead &&
          sentAt == other.sentAt &&
          deliveredAt == other.deliveredAt &&
          readAt == other.readAt &&
          deliveryStatus == other.deliveryStatus;

  @override
  int get hashCode =>
      id.hashCode ^
      conversationId.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      receiverId.hashCode ^
      receiverName.hashCode ^
      messageText.hashCode ^
      messageType.hashCode ^
      isRead.hashCode ^
      sentAt.hashCode ^
      deliveredAt.hashCode ^
      readAt.hashCode ^
      deliveryStatus.hashCode;
}
