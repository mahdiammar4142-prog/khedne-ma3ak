
class EventModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime date;
  final List<String> memberIds;
  final List<PlaceVote> placeVotes;
  final EventVisibility visibility;
  final List<EventJoinRequest> joinRequests;
  final List<EventChatMessage> chatMessages;
  final String? selectedPlaceId;
  final String? description;

  const EventModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.date,
    this.memberIds = const [],
    this.placeVotes = const [],
    this.visibility = EventVisibility.public,
    this.joinRequests = const [],
    this.chatMessages = const [],
    this.selectedPlaceId,
    this.description,
  });

  int voteCount(String placeId) {
    return placeVotes.where((v) => v.placeId == placeId).length;
  }

  bool get isPublic => visibility == EventVisibility.public;

  EventModel copyWith({
    String? name,
    DateTime? date,
    List<String>? memberIds,
    List<PlaceVote>? placeVotes,
    EventVisibility? visibility,
    List<EventJoinRequest>? joinRequests,
    List<EventChatMessage>? chatMessages,
    String? selectedPlaceId,
    String? description,
  }) {
    return EventModel(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      date: date ?? this.date,
      memberIds: memberIds ?? this.memberIds,
      placeVotes: placeVotes ?? this.placeVotes,
      visibility: visibility ?? this.visibility,
      joinRequests: joinRequests ?? this.joinRequests,
      chatMessages: chatMessages ?? this.chatMessages,
      selectedPlaceId: selectedPlaceId ?? this.selectedPlaceId,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'date': date.toIso8601String(),
      'memberIds': memberIds,
      'placeVotes': placeVotes.map((v) => v.toMap()).toList(),
      'visibility': visibility.name,
      'joinRequests': joinRequests.map((r) => r.toMap()).toList(),
      'chatMessages': chatMessages.map((m) => m.toMap()).toList(),
      'selectedPlaceId': selectedPlaceId,
      'description': description,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      createdBy: (map['createdBy'] ?? '').toString(),
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      memberIds: (map['memberIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      placeVotes: (map['placeVotes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((v) => PlaceVote.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
      visibility: EventVisibility.values.firstWhere(
        (v) => v.name == (map['visibility'] ?? '').toString(),
        orElse: () => EventVisibility.public,
      ),
      joinRequests: (map['joinRequests'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((r) => EventJoinRequest.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
      chatMessages: (map['chatMessages'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => EventChatMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      selectedPlaceId: map['selectedPlaceId']?.toString(),
      description: map['description']?.toString(),
    );
  }
}

class PlaceVote {
  final String placeId;
  final String userId;

  const PlaceVote({required this.placeId, required this.userId});

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
    };
  }

  factory PlaceVote.fromMap(Map<String, dynamic> map) {
    return PlaceVote(
      placeId: (map['placeId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
    );
  }
}

enum EventVisibility {
  public,
  private,
}

enum EventJoinRequestStatus {
  pending,
  approved,
  rejected,
}

class EventJoinRequest {
  final String userId;
  final EventJoinRequestStatus status;
  final DateTime createdAt;

  const EventJoinRequest({
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventJoinRequest.fromMap(Map<String, dynamic> map) {
    return EventJoinRequest(
      userId: (map['userId'] ?? '').toString(),
      status: EventJoinRequestStatus.values.firstWhere(
        (v) => v.name == (map['status'] ?? '').toString(),
        orElse: () => EventJoinRequestStatus.pending,
      ),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class EventChatMessage {
  final String userId;
  final String text;
  final DateTime createdAt;

  const EventChatMessage({
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventChatMessage.fromMap(Map<String, dynamic> map) {
    return EventChatMessage(
      userId: (map['userId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
