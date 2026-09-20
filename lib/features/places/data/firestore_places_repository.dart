import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';
import 'package:lebanon_places/features/places/data/places_repository.dart';

/// Firestore collection name for places (Lebanon).
const String placesCollection = 'places';

/// Reads and writes places from Firestore. Use when Firebase is initialized.
class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(placesCollection);

  @override
  Future<List<PlaceModel>> search(String query,
      {List<PlaceCategory>? categories}) async {
    Query<Map<String, dynamic>> q = _col.orderBy('name');
    final snapshot = await q.get();
    final all = snapshot.docs
        .map((d) => PlaceModel.fromMap(d.id, d.data()))
        .toList();

    final taxonomyCategories = Taxonomy.categoriesForQuery(query);
    final useCategories = categories ?? taxonomyCategories;
    final lower = query.toLowerCase();
    final shouldRequireText = query.isNotEmpty &&
        (categories != null || taxonomyCategories.length == PlaceCategory.values.length);
    return all.where((p) {
      final matchCategory = useCategories.contains(p.category);
      final matchText = !shouldRequireText ||
          p.name.toLowerCase().contains(lower) ||
          (p.description?.toLowerCase().contains(lower) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(lower));
      return matchCategory && matchText;
    }).toList();
  }

  @override
  Future<PlaceModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return PlaceModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Add or update a place (for admin/seed).
  Future<void> setPlace(PlaceModel place) async {
    await _col.doc(place.id).set(place.toMap());
  }

  /// Seed multiple places (for initial import).
  Future<void> seedPlaces(List<PlaceModel> places) async {
    final batch = _firestore.batch();
    for (final p in places) {
      batch.set(_col.doc(p.id), p.toMap());
    }
    await batch.commit();
  }
}
