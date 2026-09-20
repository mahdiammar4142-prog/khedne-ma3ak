import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lebanon_places/features/places/domain/place_contribution_model.dart';

class PlaceContributionsRepository {
  PlaceContributionsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('placeContributions');

  Stream<List<PlaceContributionModel>> watchMine(
    String userId, {
    PlaceContributionType? type,
  }) {
    Query<Map<String, dynamic>> query =
        _col.where('userId', isEqualTo: userId);
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => PlaceContributionModel.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> submit({
    required String userId,
    required String? userEmail,
    required String placeId,
    required String placeName,
    required PlaceContributionType type,
    required String message,
    List<String> tags = const [],
    int? rating,
    DateTime? bookingDate,
    int? peopleCount,
  }) async {
    final now = DateTime.now();
    final ref = _col.doc();
    final model = PlaceContributionModel(
      id: ref.id,
      userId: userId,
      userEmail: userEmail,
      placeId: placeId,
      placeName: placeName,
      type: type,
      message: message.trim(),
      tags: tags,
      rating: rating,
      bookingDate: bookingDate,
      peopleCount: peopleCount,
      status: PlaceContributionStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(model.toMap());
  }
}
