import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';

class PlaceModel {
  final String id;
  final String name;
  final String? description;
  final PlaceCategory category;
  final String? region;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final List<String> imageUrls;
  final List<String> tags;
  final String? phone;
  final String? website;
  final String? googlePlaceId;
  final bool bookable;

  const PlaceModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.region,
    this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.imageUrls = const [],
    this.tags = const [],
    this.phone,
    this.website,
    this.googlePlaceId,
    this.bookable = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory PlaceModel.fromMap(String id, Map<String, dynamic> map) {
    return PlaceModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      category: PlaceCategory.values.byName((map['category'] as String?) ?? 'other'),
      region: map['region'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      googlePlaceId: map['googlePlaceId'] as String?,
      bookable: map['bookable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category.name,
        'region': region,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'imageUrls': imageUrls,
        'tags': tags,
        'phone': phone,
        'website': website,
        'googlePlaceId': googlePlaceId,
        'bookable': bookable,
      };
}
