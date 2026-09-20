import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lebanon_places/core/config/google_api_config.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

class GooglePlacesService {
  GooglePlacesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, ResolvedPlaceData?> _resolvedCache = {};

  Future<Uri> mapsUriForPlace(PlaceModel place) async {
    final resolved = await resolvePlace(place);
    final placeId = place.googlePlaceId ?? resolved?.placeId;
    if (placeId != null && placeId.isNotEmpty) {
      final query = _queryText(place);
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}&query_place_id=${Uri.encodeComponent(placeId)}',
      );
    }
    final query = _queryText(place);
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }

  Future<ResolvedPlaceData?> resolvePlace(PlaceModel place) async {
    final apiKey = googleMapsApiKey;
    if (apiKey == null || apiKey.isEmpty) return _fallbackResolved(place);

    final cacheKey = place.id;
    if (_resolvedCache.containsKey(cacheKey)) return _resolvedCache[cacheKey];

    final explicitPlaceId = place.googlePlaceId?.trim();
    if (explicitPlaceId != null && explicitPlaceId.isNotEmpty) {
      final byId = await _resolveByPlaceId(
        apiKey: apiKey,
        placeId: explicitPlaceId,
        place: place,
      );
      _resolvedCache[cacheKey] = byId;
      return byId;
    }

    final query = _queryText(place);
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/findplacefromtext/json', {
      'input': query,
      'inputtype': 'textquery',
      'fields': 'place_id,name,formatted_address,geometry/location',
      'locationbias': 'rectangle:33.05,35.05|34.70,36.65',
      'key': apiKey,
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        final fallback = _fallbackResolved(place);
        _resolvedCache[cacheKey] = fallback;
        return fallback;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String?;
      if (status != 'OK') {
        final fallback = _fallbackResolved(place);
        _resolvedCache[cacheKey] = fallback;
        return fallback;
      }
      final candidates = body['candidates'] as List<dynamic>? ?? const [];
      if (candidates.isEmpty) {
        final fallback = _fallbackResolved(place);
        _resolvedCache[cacheKey] = fallback;
        return fallback;
      }
      final first = candidates.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final resolved = ResolvedPlaceData(
        placeId: first['place_id'] as String?,
        name: first['name'] as String?,
        formattedAddress: first['formatted_address'] as String?,
        latitude: (location?['lat'] as num?)?.toDouble() ?? place.latitude,
        longitude: (location?['lng'] as num?)?.toDouble() ?? place.longitude,
      );
      _resolvedCache[cacheKey] = resolved;
      return resolved;
    } catch (_) {
      final fallback = _fallbackResolved(place);
      _resolvedCache[cacheKey] = fallback;
      return fallback;
    }
  }

  Future<ResolvedPlaceData> _resolveByPlaceId({
    required String apiKey,
    required String placeId,
    required PlaceModel place,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'place_id,name,formatted_address,geometry/location',
      'key': apiKey,
    });
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        final viaNew = await _resolveByPlaceIdPlacesApiNew(
          apiKey: apiKey,
          placeId: placeId,
          place: place,
        );
        if (viaNew != null) return viaNew;
        return await _resolveByGeocodePlaceId(
          apiKey: apiKey,
          placeId: placeId,
          place: place,
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((body['status'] as String?) != 'OK') {
        final viaNew = await _resolveByPlaceIdPlacesApiNew(
          apiKey: apiKey,
          placeId: placeId,
          place: place,
        );
        if (viaNew != null) return viaNew;
        return await _resolveByGeocodePlaceId(
          apiKey: apiKey,
          placeId: placeId,
          place: place,
        );
      }
      final result = body['result'] as Map<String, dynamic>? ?? const {};
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      return ResolvedPlaceData(
        placeId: result['place_id'] as String? ?? placeId,
        name: result['name'] as String? ?? place.name,
        formattedAddress: result['formatted_address'] as String? ?? place.address,
        latitude: (location?['lat'] as num?)?.toDouble() ?? place.latitude,
        longitude: (location?['lng'] as num?)?.toDouble() ?? place.longitude,
      );
    } catch (_) {
      final viaNew = await _resolveByPlaceIdPlacesApiNew(
        apiKey: apiKey,
        placeId: placeId,
        place: place,
      );
      if (viaNew != null) return viaNew;
      return await _resolveByGeocodePlaceId(
        apiKey: apiKey,
        placeId: placeId,
        place: place,
      );
    }
  }

  Future<ResolvedPlaceData?> _resolveByPlaceIdPlacesApiNew({
    required String apiKey,
    required String placeId,
    required PlaceModel place,
  }) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
    try {
      final response = await _client.get(
        uri,
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
        },
      );
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final location = body['location'] as Map<String, dynamic>?;
      final displayName = body['displayName'] as Map<String, dynamic>?;
      return ResolvedPlaceData(
        placeId: (body['id'] as String?) ?? placeId,
        name: displayName?['text'] as String? ?? place.name,
        formattedAddress: body['formattedAddress'] as String? ?? place.address,
        latitude: (location?['latitude'] as num?)?.toDouble() ?? place.latitude,
        longitude: (location?['longitude'] as num?)?.toDouble() ?? place.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ResolvedPlaceData> _resolveByGeocodePlaceId({
    required String apiKey,
    required String placeId,
    required PlaceModel place,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'place_id': placeId,
      'key': apiKey,
    });
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) return _fallbackResolved(place);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if ((body['status'] as String?) != 'OK') return _fallbackResolved(place);
      final results = body['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return _fallbackResolved(place);
      final first = results.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      return ResolvedPlaceData(
        placeId: placeId,
        name: first['formatted_address'] as String? ?? place.name,
        formattedAddress: first['formatted_address'] as String? ?? place.address,
        latitude: (location?['lat'] as num?)?.toDouble() ?? place.latitude,
        longitude: (location?['lng'] as num?)?.toDouble() ?? place.longitude,
      );
    } catch (_) {
      return _fallbackResolved(place);
    }
  }

  String _queryText(PlaceModel place) {
    final parts = <String>[
      place.name,
      if ((place.address ?? '').trim().isNotEmpty) place.address!,
      if ((place.region ?? '').trim().isNotEmpty) place.region!,
      'Lebanon',
    ];
    return parts.join(', ');
  }

  ResolvedPlaceData _fallbackResolved(PlaceModel place) {
    return ResolvedPlaceData(
      placeId: null,
      name: place.name,
      formattedAddress: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
    );
  }
}

class ResolvedPlaceData {
  final String? placeId;
  final String? name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  const ResolvedPlaceData({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

