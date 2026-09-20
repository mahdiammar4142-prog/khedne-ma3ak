import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/core/map/lebanon_map_config.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/data/google_places_service.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacesMapScreen extends ConsumerStatefulWidget {
  /// Optional search query (e.g. from search). If null, shows all places in Lebanon.
  final String? initialQuery;

  const PlacesMapScreen({super.key, this.initialQuery});

  @override
  ConsumerState<PlacesMapScreen> createState() => _PlacesMapScreenState();
}

class _PlacesMapScreenState extends ConsumerState<PlacesMapScreen> {
  GoogleMapController? _mapController;
  PlaceModel? _selectedPlace;
  bool _cameraFitted = false;
  static final GooglePlacesService _placesService = GooglePlacesService();
  Future<List<PlaceModel>>? _resolvedPlacesFuture;
  String? _resolvedSourceKey;

  @override
  void dispose() {
    // google_maps_flutter_web manages map lifecycle internally; explicit dispose
    // here can trigger assertion errors during fast rebuild/dispose scenarios.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(mapPlacesProvider(widget.initialQuery));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Map – Lebanon'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location_rounded, color: Colors.grey.shade800),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(LebanonMapConfig.defaultCamera),
              );
            },
          ),
        ],
      ),
      body: placesAsync.when(
        data: (places) {
          final sourceKey = places.map((p) => p.id).join('|');
          if (_resolvedPlacesFuture == null || _resolvedSourceKey != sourceKey) {
            _resolvedSourceKey = sourceKey;
            _resolvedPlacesFuture = _resolvePlacesForMap(places);
          }
          return FutureBuilder<List<PlaceModel>>(
            future: _resolvedPlacesFuture,
            builder: (context, resolvedSnap) {
              if (resolvedSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final resolved = resolvedSnap.data ?? places;
              final placesWithLocation = resolved
                  .where((p) => LebanonMapConfig.isLikelyInLebanon(p.latitude, p.longitude))
                  .toList();
              if (placesWithLocation.isEmpty) {
                return const Center(
                  child: Text('No places with location data to show on map.'),
                );
              }
              final markers = <Marker>{};
              for (final p in placesWithLocation) {
                markers.add(
                  Marker(
                    markerId: MarkerId(p.id),
                    position: LatLng(p.latitude!, p.longitude!),
                    infoWindow: InfoWindow(
                      title: '${p.name} • ${p.region ?? "Lebanon"}',
                      snippet: Taxonomy.categoryLabel(p.category),
                    ),
                    onTap: () => setState(() => _selectedPlace = p),
                  ),
                );
              }
              if (_isDesktopUnsupportedForEmbeddedMap) {
                return _DesktopMapFallback(places: placesWithLocation);
              }

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: LebanonMapConfig.defaultCamera,
                    markers: markers,
                    mapType: MapType.normal,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    onMapCreated: (c) {
                      _mapController = c;
                      if (!_cameraFitted) {
                        _cameraFitted = true;
                        _fitToPlaces(placesWithLocation);
                      }
                    },
                  ),
                  if (_selectedPlace != null) _buildBottomSheet(context, _selectedPlace!),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, PlaceModel place) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade800),
                      onPressed: () => setState(() => _selectedPlace = null),
                    ),
                  ],
                ),
                Text(
                  '${place.name} • ${place.region ?? "Lebanon"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (place.rating != null)
                  Text('★ ${place.rating!.toStringAsFixed(1)}'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    context.push('/search/place/${place.id}');
                  },
                  child: const Text('View details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isDesktopUnsupportedForEmbeddedMap {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _fitToPlaces(List<PlaceModel> places) async {
    if (_mapController == null || places.isEmpty) return;
    final lats = places.map((p) => p.latitude!).toList();
    final lngs = places.map((p) => p.longitude!).toList();
    final southWest = LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b));
    final northEast = LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b));
    final bounds = LatLngBounds(southwest: southWest, northeast: northEast);
    await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  Future<List<PlaceModel>> _resolvePlacesForMap(List<PlaceModel> places) async {
    final resolved = await Future.wait(
      places.map((p) async {
        // If we have a verified Google Place ID, prefer official coordinates.
        // Otherwise keep stored coordinates to avoid noisy text rematches.
        final hasExplicitPlaceId = (p.googlePlaceId ?? '').trim().isNotEmpty;
        if (!hasExplicitPlaceId && p.latitude != null && p.longitude != null) {
          return p;
        }
        final official = await _placesService.resolvePlace(p);
        final lat = official?.latitude;
        final lng = official?.longitude;
        if (lat == null || lng == null) return p;
        if (!LebanonMapConfig.isLikelyInLebanon(lat, lng)) return p;
        return PlaceModel(
          id: p.id,
          name: p.name,
          description: p.description,
          category: p.category,
          region: p.region,
          address: p.address,
          latitude: lat,
          longitude: lng,
          rating: p.rating,
          imageUrls: p.imageUrls,
          tags: p.tags,
          phone: p.phone,
          website: p.website,
          googlePlaceId: p.googlePlaceId ?? official?.placeId,
          bookable: p.bookable,
        );
      }),
    );
    return resolved;
  }
}

class _DesktopMapFallback extends StatelessWidget {
  final List<PlaceModel> places;
  static final GooglePlacesService _placesService = GooglePlacesService();

  const _DesktopMapFallback({required this.places});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Text(
            'Embedded Google Map is not available on this desktop target. Use Open in Google Maps for accurate location view.',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FilledButton.icon(
            onPressed: () => _openLebanonMap(),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Lebanon map in browser'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: places.length,
            itemBuilder: (_, i) {
              final p = places[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('${p.latitude}, ${p.longitude}'),
                trailing: IconButton(
                  icon: const Icon(Icons.map_rounded),
                  onPressed: () => _openPlaceMap(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openLebanonMap() async {
    final url = Uri.parse('https://www.google.com/maps/@33.8938,35.5018,9z');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openPlaceMap(PlaceModel p) async {
    final url = await _placesService.mapsUriForPlace(p);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
