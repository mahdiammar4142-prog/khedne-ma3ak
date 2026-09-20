import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/data/places_repository.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

/// Single source for the places repository. Switch to [FirestorePlacesRepository]
/// when Firebase is initialized and you want to use the database.
final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return DemoPlacesRepository();
});

/// Place by ID.
final placeDetailProvider =
    FutureProvider.family<PlaceModel?, String>((ref, id) async {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.getById(id);
});

/// Search results for a query.
final searchResultsProvider =
    FutureProvider.family<List<PlaceModel>, String>((ref, query) async {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.search(query);
});

/// Places for the map (optional query filter).
final mapPlacesProvider =
    FutureProvider.family<List<PlaceModel>, String?>((ref, query) async {
  final repo = ref.watch(placesRepositoryProvider);
  return repo.search(query ?? '');
});

/// Places for the guide (by category).
final guidePlacesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final repo = ref.watch(placesRepositoryProvider);
  final cat = ref.watch(guideCategoryProvider);
  if (cat == null) return repo.search('');
  return repo.search('', categories: [cat]);
});

final guideCategoryProvider = StateProvider<PlaceCategory?>((ref) => null);
