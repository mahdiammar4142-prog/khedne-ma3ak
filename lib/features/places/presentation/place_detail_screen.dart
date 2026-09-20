import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/domain/place_image_helper.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';
import 'package:lebanon_places/features/places/presentation/place_map_widget.dart';
import 'package:url_launcher/url_launcher.dart';

final _profileRepo = UserProfileRepository();
final _profileStreamProvider =
    StreamProvider.family<UserProfileModel?, String>((ref, userId) {
  return _profileRepo.watchProfile(userId);
});

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailProvider(placeId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Place details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
        actions: [
          placeAsync.maybeWhen(
            data: (place) {
              if (place == null) return const SizedBox.shrink();
              return _FavoriteButton(place: place);
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: placeAsync.when(
        data: (place) {
          if (place == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_rounded, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Place not found', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSection(place: place),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ChipLabel(label: Taxonomy.categoryLabel(place.category)),
                          if (place.region != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              place.region!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (place.rating != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade800),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.rating!.toStringAsFixed(1),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (place.description != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          place.description!,
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                        ),
                      ],
                      if (place.address != null) ...[
                        const SizedBox(height: 20),
                        _InfoTile(
                          icon: Icons.location_on_rounded,
                          title: 'Address',
                          subtitle: place.address!,
                        ),
                      ],
                      if (place.hasLocation) ...[
                        const SizedBox(height: 20),
                        PlaceMapWidget(place: place),
                      ],
                      if (place.phone != null)
                        _InfoTile(
                          icon: Icons.phone_rounded,
                          title: place.phone!,
                          isAction: true,
                          onTap: () => launchUrl(Uri(scheme: 'tel', path: place.phone)),
                        ),
                      if (place.website != null)
                        _InfoTile(
                          icon: Icons.language_rounded,
                          title: 'Website',
                          subtitle: place.website!,
                          isAction: true,
                          onTap: () => launchUrl(Uri.parse(place.website!)),
                        ),
                      if (place.bookable) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.push('/contribute/${place.id}?type=booking'),
                          icon: const Icon(Icons.book_online_rounded),
                          label: const Text('Request booking'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.push('/contribute/${place.id}?type=booking'),
                          icon: const Icon(Icons.book_online_rounded),
                          label: const Text('Request booking'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/contribute/${place.id}'),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Review / suggest edits / report issue'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final PlaceModel place;

  const _FavoriteButton({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    if (user == null) {
      return IconButton(
        tooltip: 'Sign in to save',
        icon: Icon(Icons.star_border_rounded, color: Colors.grey.shade700),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to save favorites.')),
          );
        },
      );
    }

    final profileAsync = ref.watch(_profileStreamProvider(user.uid));
    final profile = profileAsync.valueOrNull;
    final isFavorite = profile?.savedPlaceIds.contains(place.id) ?? false;

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        color: isFavorite ? Colors.amber.shade700 : Colors.grey.shade700,
      ),
      onPressed: () async {
        final current = profile ??
            UserProfileModel(
              id: user.uid,
              displayName: user.displayName ?? 'User',
              handle: null,
              email: user.email,
              photoUrl: user.photoURL,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              savedPlaceIds: const [],
            );
        final updated = [...current.savedPlaceIds];
        if (isFavorite) {
          updated.remove(place.id);
        } else {
          updated.add(place.id);
        }
        await _profileRepo.updateSavedPlaces(user.uid, updated.toSet().toList());
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  final PlaceModel place;

  const _HeroSection({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = placeBackgroundImageUrl(place);

    return Stack(
      children: [
        if (imageUrl != null)
          ClipRRect(
            child: Image.network(
              imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientFallback(theme),
            ),
          )
        else
          _gradientFallback(theme),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Text(
            place.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientFallback(ThemeData theme) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.place_rounded, size: 72, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;

  const _ChipLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isAction;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isAction = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAction ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subtitle != null)
                        Text(
                          title,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        subtitle ?? title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: subtitle != null ? FontWeight.w500 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAction) Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
