import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/data/places_repository.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';
import 'package:lebanon_places/features/places/presentation/widgets/place_card.dart';

final _profileRepo = UserProfileRepository();
final _favoritesProfileProvider =
    StreamProvider.family((ref, String userId) => _profileRepo.watchProfile(userId));

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favorite places'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Sign in to save and view favorites.',
                  style: TextStyle(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final profileAsync = ref.watch(_favoritesProfileProvider(user.uid));
          return profileAsync.when(
            data: (profile) {
              final ids = profile?.savedPlaceIds ?? const <String>[];
              if (ids.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No favorites yet. Open a place and tap the star to save it.',
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return _FavoritesList(placeIds: ids);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  final List<String> placeIds;

  const _FavoritesList({required this.placeIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(placesRepositoryProvider);
    return FutureBuilder<List<PlaceModel>>(
      future: _loadPlaces(repo, placeIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          return const Center(child: CircularProgressIndicator());
        }
        final places = snapshot.data!;
        if (places.isEmpty) {
          return Center(
            child: Text(
              'Your favorite places are unavailable right now.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: places.length,
          itemBuilder: (_, i) => PlaceCard(place: places[i]),
        );
      },
    );
  }

  Future<List<PlaceModel>> _loadPlaces(PlacesRepository repo, List<String> ids) async {
    final items = <PlaceModel>[];
    for (final id in ids) {
      final p = await repo.getById(id);
      if (p != null) items.add(p);
    }
    return items;
  }
}

