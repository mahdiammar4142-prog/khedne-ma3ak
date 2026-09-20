import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _teal = Color(0xFF00A651);
  static const _orange = Color(0xFFFF9800);
  static const _cyan = Color(0xFF00BCD4);
  static const _lightBlue = Color(0xFF81D4FA);
  static const _blue = Color(0xFF2196F3);
  static const _yellow = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = MediaQuery.of(context).size.width <= 380;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header: logo + search + chatbot + friends + star
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isSmallMobile ? 'Khedne\nMa3ak' : 'Khedne Ma3ak',
                        maxLines: isSmallMobile ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.search_rounded, color: Colors.grey.shade800, size: 24),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.auto_awesome, color: Colors.grey.shade800, size: 24),
                      tooltip: 'Chatbot',
                      onPressed: () => context.push('/chatbot'),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.person_add_alt_1_rounded, color: Colors.grey.shade800, size: 24),
                      tooltip: 'Add friends',
                      onPressed: () => context.push('/friends'),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.event_note_rounded, color: Colors.grey.shade800, size: 24),
                      tooltip: 'Events menu',
                      onPressed: () => context.push('/events'),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.star_border_rounded, color: Colors.grey.shade800, size: 24),
                      tooltip: 'Favorites',
                      onPressed: () => context.push('/favorites'),
                    ),
                  ],
                ),
              ),
            ),
            // Top nav: Activity, Bookings, Profile
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavButton(
                        icon: Icons.show_chart_rounded,
                        label: 'Activity',
                        color: _teal,
                        onTap: () => context.push('/search', extra: 'activity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavButton(
                        icon: Icons.calendar_today_rounded,
                        label: 'Bookings',
                        color: _teal,
                        onTap: () => context.push('/bookings'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavButton(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        color: _orange,
                        onTap: () => context.push('/profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            // 2x2 category grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _CategoryCard(
                    imagePath: 'assets/images/pools_beaches.png',
                    label: 'Pools And Beaches',
                    borderColor: _cyan,
                    onTap: () => context.push('/search', extra: 'pool'),
                  ),
                  _CategoryCard(
                    imagePath: 'assets/images/restaurants.png',
                    label: 'Restaurants',
                    borderColor: _lightBlue,
                    onTap: () => context.push('/search', extra: 'restaurant'),
                  ),
                  _CategoryCard(
                    imagePath: 'assets/images/sports_activities.png',
                    label: 'Sports & Activities',
                    borderColor: _orange,
                    onTap: () => context.push('/search', extra: 'activity'),
                  ),
                  _CategoryCard(
                    imagePath: 'assets/images/hotels_guesthouses.png',
                    label: 'Hotels and Guesthouses',
                    borderColor: _blue,
                    onTap: () => context.push('/search', extra: 'hotel'),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Bottom nav: Taxi, Explore, Add Location
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavButton(
                        icon: Icons.local_taxi_rounded,
                        label: 'Taxi',
                        color: _yellow,
                        onTap: () => _showTaxiOptions(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavButton(
                        icon: Icons.explore_rounded,
                        label: 'Explore',
                        color: _teal,
                        onTap: () => context.push('/map'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NavButton(
                        icon: Icons.add_location_alt_rounded,
                        label: 'Add Location',
                        color: _blue,
                        onTap: () => context.push('/add-location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

Future<void> _showTaxiOptions(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  Future<void> open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open this option on your device.')),
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_taxi_rounded, color: Colors.black87),
              title: const Text(
                'Open Careem',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await open(Uri.parse('https://www.careem.com/'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_rounded, color: Colors.black87),
              title: const Text(
                'Open Uber',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await open(Uri.parse('https://m.uber.com/'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_rounded, color: Colors.black87),
              title: const Text(
                'Open taxi search on Google Maps',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await open(Uri.parse(
                    'https://www.google.com/maps/search/taxi+near+me'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: Colors.black87),
              title: const Text(
                'Call local taxi',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Edit this number for your area',
                style: TextStyle(color: Colors.black54),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await open(Uri(scheme: 'tel', path: '1213'));
              },
            ),
          ],
        ),
      );
    },
  );
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final Color borderColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.imagePath,
    required this.label,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        borderColor.withOpacity(0.4),
                        borderColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Icon(Icons.image_not_supported_rounded, size: 48, color: borderColor.withOpacity(0.6)),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
