import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class TripPlanningScreen extends StatelessWidget {
  const TripPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trip planning & booking'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan your trip',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search for places, add them to your trip, and get advice. '
                    'Booking can be done via partner links or direct contact (phone/website) from place details.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search places'),
            subtitle: const Text('Find restaurants, hotels, pools'),
            onTap: () => context.push('/search'),
          ),
          const ListTile(
            leading: Icon(Icons.map),
            title: Text('Regions to explore'),
            subtitle: Text('Beirut, Byblos, Jounieh, Batroun, Tripoli...'),
          ),
          ListTile(
            leading: const Icon(Icons.book_online),
            title: const Text('Booking'),
            subtitle: const Text('Tap "Book / Plan trip" on a place to open booking options'),
            onTap: () async {
              final uri = Uri.parse('https://www.google.com/search?q=hotels+lebanon+booking');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}
