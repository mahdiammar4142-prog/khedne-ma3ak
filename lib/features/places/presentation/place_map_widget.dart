import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lebanon_places/core/map/lebanon_map_config.dart';
import 'package:lebanon_places/features/places/data/google_places_service.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

/// Embedded map for a single place in Lebanon (place detail screen).
class PlaceMapWidget extends StatelessWidget {
  final PlaceModel place;
  static final GooglePlacesService _placesService = GooglePlacesService();

  const PlaceMapWidget({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResolvedPlaceData?>(
      future: _placesService.resolvePlace(place),
      builder: (context, snapshot) {
        final resolved = snapshot.data;
        final hasExplicitPlaceId = (place.googlePlaceId ?? '').trim().isNotEmpty;
        final lat = hasExplicitPlaceId
            ? (resolved?.latitude ?? place.latitude)
            : (place.latitude ?? resolved?.latitude);
        final lng = hasExplicitPlaceId
            ? (resolved?.longitude ?? place.longitude)
            : (place.longitude ?? resolved?.longitude);
        if (!LebanonMapConfig.isLikelyInLebanon(lat, lng)) {
          return const SizedBox.shrink();
        }

        final isDesktop = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: isDesktop
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text(
                          'Map preview is unavailable on this desktop target.',
                          style: TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: LebanonMapConfig.cameraForPlace(
                          lat!,
                          lng!,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(place.id),
                            position: LatLng(lat, lng),
                            infoWindow: InfoWindow(title: place.name),
                          ),
                        },
                        mapType: MapType.normal,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        liteModeEnabled: false,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in Google Maps'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final url = await _placesService.mapsUriForPlace(place);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
