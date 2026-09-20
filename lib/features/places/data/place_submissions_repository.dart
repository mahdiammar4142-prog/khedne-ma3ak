import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/domain/place_submission_model.dart';

class PlaceSubmissionsRepository {
  PlaceSubmissionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('placeSubmissions');

  Stream<List<PlaceSubmissionModel>> watchMine(String userId) {
    return _col
        .where('submittedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => PlaceSubmissionModel.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> submitNewPlace({
    required String userId,
    required String? userEmail,
    required String name,
    required String description,
    required PlaceCategory category,
    required String mapsLink,
  }) async {
    final parsed = parseGoogleMapsLink(mapsLink);
    final now = DateTime.now();
    final ref = _col.doc();
    final submission = PlaceSubmissionModel(
      id: ref.id,
      submittedBy: userId,
      submittedByEmail: userEmail,
      name: name.trim(),
      description: description.trim(),
      category: category,
      mapsLink: mapsLink.trim(),
      latitude: parsed.latitude,
      longitude: parsed.longitude,
      googlePlaceId: parsed.googlePlaceId,
      status: PlaceSubmissionStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(submission.toMap());
  }

  static bool isLikelyGoogleMapsLink(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host.toLowerCase();
    return host.contains('google.') ||
        host.contains('goo.gl') ||
        host.contains('maps.app.goo.gl');
  }

  static ParsedMapsLink parseGoogleMapsLink(String rawLink) {
    final link = rawLink.trim();
    final uri = Uri.tryParse(link);
    if (uri == null) return ParsedMapsLink(rawLink: rawLink);

    double? lat;
    double? lng;
    String? placeId;

    final atMatch = RegExp(r'@(-?\d+(\.\d+)?),(-?\d+(\.\d+)?)')
        .firstMatch(uri.toString());
    if (atMatch != null) {
      lat = double.tryParse(atMatch.group(1) ?? '');
      lng = double.tryParse(atMatch.group(3) ?? '');
    }

    if (lat == null || lng == null) {
      final q = uri.queryParameters['q'] ?? uri.queryParameters['query'];
      if (q != null) {
        final parts = q.split(',');
        if (parts.length >= 2) {
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      }
    }

    if (lat == null || lng == null) {
      final ll = uri.queryParameters['ll'];
      if (ll != null) {
        final parts = ll.split(',');
        if (parts.length >= 2) {
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      }
    }

    placeId = uri.queryParameters['query_place_id'] ??
        uri.queryParameters['placeid'] ??
        uri.queryParameters['place_id'];

    return ParsedMapsLink(
      rawLink: rawLink,
      latitude: lat,
      longitude: lng,
      googlePlaceId: placeId,
    );
  }
}
