class Conversation {
  final String id;
  final String participant1Id;
  final String participant1Name;
  final String participant2Id;
  final String participant2Name;
  final String? lastMessageId;
  final String? lastMessageText;
  final String? lastMessageTime;
  final String createdAt;
  final String updatedAt;

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant1Name,
    required this.participant2Id,
    required this.participant2Name,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      participant1Id: map['participant1Id'] as String,
      participant1Name: map['participant1Name'] as String,
      participant2Id: map['participant2Id'] as String,
      participant2Name: map['participant2Name'] as String,
      lastMessageId: map['lastMessageId'] as String?,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageTime: map['lastMessageTime'] as String?,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participant1Id': participant1Id,
      'participant1Name': participant1Name,
      'participant2Id': participant2Id,
      'participant2Name': participant2Name,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Conversation copyWith({
    String? id,
    String? participant1Id,
    String? participant1Name,
    String? participant2Id,
    String? participant2Name,
    String? lastMessageId,
    String? lastMessageText,
    String? lastMessageTime,
    String? createdAt,
    String? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participant1Id: participant1Id ?? this.participant1Id,
      participant1Name: participant1Name ?? this.participant1Name,
      participant2Id: participant2Id ?? this.participant2Id,
      participant2Name: participant2Name ?? this.participant2Name,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the other participant's name for the current user
  String getOtherParticipantName(String currentUserId) {
    return participant1Id == currentUserId ? participant2Name : participant1Name;
  }

  /// Get the other participant's ID for the current user
  String getOtherParticipantId(String currentUserId) {
    return participant1Id == currentUserId ? participant2Id : participant1Id;
  }

  /// Check if the conversation involves a specific user
  bool hasParticipant(String userId) {
    return participant1Id == userId || participant2Id == userId;
  }

  @override
  String toString() {
    return 'Conversation{id: $id, participant1Id: $participant1Id, participant1Name: $participant1Name, participant2Id: $participant2Id, participant2Name: $participant2Name, lastMessageId: $lastMessageId, lastMessageText: $lastMessageText, lastMessageTime: $lastMessageTime, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          participant1Id == other.participant1Id &&
          participant1Name == other.participant1Name &&
          participant2Id == other.participant2Id &&
          participant2Name == other.participant2Name &&
          lastMessageId == other.lastMessageId &&
          lastMessageText == other.lastMessageText &&
          lastMessageTime == other.lastMessageTime &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      participant1Id.hashCode ^
      participant1Name.hashCode ^
      participant2Id.hashCode ^
      participant2Name.hashCode ^
      lastMessageId.hashCode ^
      lastMessageText.hashCode ^
      lastMessageTime.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
