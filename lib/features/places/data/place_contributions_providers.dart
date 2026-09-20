import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/features/places/data/place_contributions_repository.dart';
import 'package:lebanon_places/features/places/domain/place_contribution_model.dart';

final placeContributionsRepositoryProvider =
    Provider<PlaceContributionsRepository>((ref) {
  return PlaceContributionsRepository();
});

final myBookingRequestsProvider =
    StreamProvider.family<List<PlaceContributionModel>, String>((ref, userId) {
  return ref.watch(placeContributionsRepositoryProvider).watchMine(
        userId,
        type: PlaceContributionType.bookingRequest,
      );
});
