enum PlaceContributionType {
  review,
  editSuggestion,
  tagSuggestion,
  issueReport,
  bookingRequest,
}

enum PlaceContributionStatus { pending, approved, rejected }

class PlaceContributionModel {
  final String id;
  final String userId;
  final String? userEmail;
  final String placeId;
  final String placeName;
  final PlaceContributionType type;
  final String message;
  final List<String> tags;
  final int? rating;
  final DateTime? bookingDate;
  final int? peopleCount;
  final PlaceContributionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaceContributionModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.placeId,
    required this.placeName,
    required this.type,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.rating,
    this.bookingDate,
    this.peopleCount,
  });

  factory PlaceContributionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value, {bool allowNull = false}) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (allowNull) return null;
      return DateTime.now();
    }

    return PlaceContributionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String?,
      placeId: map['placeId'] as String? ?? '',
      placeName: map['placeName'] as String? ?? '',
      type: PlaceContributionType.values.byName(
        (map['type'] as String?) ?? PlaceContributionType.review.name,
      ),
      message: map['message'] as String? ?? '',
      tags: List<String>.from(map['tags'] ?? const []),
      rating: (map['rating'] as num?)?.toInt(),
      bookingDate: parseDate(map['bookingDate'], allowNull: true),
      peopleCount: (map['peopleCount'] as num?)?.toInt(),
      status: PlaceContributionStatus.values.byName(
        (map['status'] as String?) ?? PlaceContributionStatus.pending.name,
      ),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'placeId': placeId,
      'placeName': placeName,
      'type': type.name,
      'message': message,
      'tags': tags,
      'rating': rating,
      'bookingDate': bookingDate?.toIso8601String(),
      'peopleCount': peopleCount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAtMillis': createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': updatedAt.millisecondsSinceEpoch,
    };
  }
}
