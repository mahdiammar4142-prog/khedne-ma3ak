import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/features/places/data/place_submissions_repository.dart';
import 'package:lebanon_places/features/places/domain/place_submission_model.dart';

final placeSubmissionsRepositoryProvider =
    Provider<PlaceSubmissionsRepository>((ref) {
  return PlaceSubmissionsRepository();
});

final myPlaceSubmissionsProvider =
    StreamProvider.family<List<PlaceSubmissionModel>, String>((ref, userId) {
  return ref.watch(placeSubmissionsRepositoryProvider).watchMine(userId);
});
