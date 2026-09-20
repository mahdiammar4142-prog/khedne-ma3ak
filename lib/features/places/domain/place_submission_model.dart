import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';

enum PlaceSubmissionStatus { pending, approved, rejected }

class PlaceSubmissionModel {
  final String id;
  final String submittedBy;
  final String? submittedByEmail;
  final String name;
  final String description;
  final PlaceCategory category;
  final String mapsLink;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;
  final PlaceSubmissionStatus status;
  final String? reviewNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlaceSubmissionModel({
    required this.id,
    required this.submittedBy,
    required this.submittedByEmail,
    required this.name,
    required this.description,
    required this.category,
    required this.mapsLink,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
    this.reviewNote,
  });

  factory PlaceSubmissionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value != null && value.toString().contains('Timestamp')) {
        final millis = (map['createdAtMillis'] as num?)?.toInt();
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }
      return DateTime.now();
    }

    return PlaceSubmissionModel(
      id: id,
      submittedBy: map['submittedBy'] as String? ?? '',
      submittedByEmail: map['submittedByEmail'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: PlaceCategory.values.byName((map['category'] as String?) ?? 'other'),
      mapsLink: map['mapsLink'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      googlePlaceId: map['googlePlaceId'] as String?,
      status: PlaceSubmissionStatus.values.byName(
        (map['status'] as String?) ?? PlaceSubmissionStatus.pending.name,
      ),
      reviewNote: map['reviewNote'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submittedBy': submittedBy,
      'submittedByEmail': submittedByEmail,
      'name': name,
      'description': description,
      'category': category.name,
      'mapsLink': mapsLink,
      'latitude': latitude,
      'longitude': longitude,
      'googlePlaceId': googlePlaceId,
      'status': status.name,
      'reviewNote': reviewNote,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAtMillis': createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class ParsedMapsLink {
  final String rawLink;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;

  const ParsedMapsLink({
    required this.rawLink,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
  });
}
