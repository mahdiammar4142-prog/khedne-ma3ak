import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/core/theme/app_theme.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/domain/place_image_helper.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final VoidCallback? onTap;

  const PlaceCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = place.name.trim().isEmpty ? 'Unknown place' : place.name.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap ?? () => context.push('/search/place/${place.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlaceThumbnail(place: place),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Taxonomy.categoryLabel(place.category)} • ${place.region ?? "Lebanon"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (place.rating != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 4),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 14),
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceThumbnail extends StatelessWidget {
  final PlaceModel place;

  const _PlaceThumbnail({required this.place});

  static Color _colorFor(PlaceCategory c) {
    switch (c) {
      case PlaceCategory.restaurant:
      case PlaceCategory.snacks:
        return const Color(0xFF81D4FA); // Light blue
      case PlaceCategory.cafe:
        return const Color(0xFF6D4C41);
      case PlaceCategory.hotel:
        return AppTheme.accent; // Blue
      case PlaceCategory.pool:
      case PlaceCategory.beach:
        return AppTheme.accentCyan; // Cyan
      case PlaceCategory.nightlife:
        return AppTheme.accentOrange; // Orange
      case PlaceCategory.nature:
      case PlaceCategory.activity:
        return AppTheme.primary; // Teal
      case PlaceCategory.shopping:
        return const Color(0xFF00796B);
      default:
        return AppTheme.accent;
    }
  }

  static IconData _iconFor(PlaceCategory c) {
    switch (c) {
      case PlaceCategory.restaurant:
      case PlaceCategory.snacks:
        return Icons.restaurant_rounded;
      case PlaceCategory.cafe:
        return Icons.coffee_rounded;
      case PlaceCategory.hotel:
        return Icons.hotel_rounded;
      case PlaceCategory.pool:
        return Icons.pool_rounded;
      case PlaceCategory.beach:
        return Icons.beach_access_rounded;
      case PlaceCategory.nightlife:
        return Icons.nightlife_rounded;
      case PlaceCategory.nature:
        return Icons.nature_rounded;
      case PlaceCategory.shopping:
        return Icons.shopping_bag_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = place.category;
    final color = _colorFor(category);
    final imageUrl = placeBackgroundImageUrl(place);

    return Container(
      width: 88,
      height: 88,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: 88,
              height: 88,
              errorBuilder: (_, __, ___) => Icon(_iconFor(category), size: 36, color: color),
            )
          : Icon(_iconFor(category), size: 36, color: color),
    );
  }
}
