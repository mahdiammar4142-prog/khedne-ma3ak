import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_repository.dart';
import 'package:lebanon_places/features/auth/presentation/gate_screen.dart';
import 'package:lebanon_places/features/auth/presentation/login_screen.dart';
import 'package:lebanon_places/features/auth/presentation/register_screen.dart';
import 'package:lebanon_places/features/chatbot/presentation/chatbot_screen.dart';
import 'package:lebanon_places/features/events/presentation/create_event_screen.dart';
import 'package:lebanon_places/features/events/presentation/event_detail_screen.dart';
import 'package:lebanon_places/features/friends/presentation/friends_screen.dart';
import 'package:lebanon_places/features/guide/presentation/guide_screen.dart';
import 'package:lebanon_places/features/home/presentation/home_screen.dart';
import 'package:lebanon_places/features/places/presentation/place_detail_screen.dart';
import 'package:lebanon_places/features/places/presentation/favorites_screen.dart';
import 'package:lebanon_places/features/places/presentation/bookings_screen.dart';
import 'package:lebanon_places/features/places/presentation/place_contribution_screen.dart';
import 'package:lebanon_places/features/places/domain/place_contribution_model.dart';
import 'package:lebanon_places/features/places/presentation/places_map_screen.dart';
import 'package:lebanon_places/features/places/presentation/places_search_screen.dart';
import 'package:lebanon_places/features/places/presentation/place_submissions_screen.dart';
import 'package:lebanon_places/features/profile/presentation/profile_screen.dart';
import 'package:lebanon_places/features/trips/presentation/trip_planning_screen.dart';

final _auth = AuthRepository();

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  try {
    final location = state.matchedLocation;
    final isGate = location == '/gate';
    final isAuthPage = location == '/login' || location == '/register';

    final user = _auth.currentUser;
    if (user != null) {
      if (isGate) return '/home';
      return null;
    }

    final isGuest = await _auth.isGuest();
    if (isGuest) {
      if (isGate) return '/home';
      return null;
    }

    if (isGate || isAuthPage) return null;
    return '/gate';
  } catch (_) {
    // Firebase not initialized or auth error – show gate
    return null;
  }
}

final appRouter = GoRouter(
  initialLocation: '/gate',
  redirect: _redirect,
  routes: [
    GoRoute(path: '/gate', builder: (_, __) => const GateScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/search',
      builder: (_, __) => const PlacesSearchScreen(),
      routes: [
        GoRoute(
          path: 'place/:id',
          builder: (_, state) => PlaceDetailScreen(placeId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
    GoRoute(
      path: '/add-location',
      builder: (_, __) => const PlaceSubmissionsScreen(),
    ),
    GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
    GoRoute(
      path: '/contribute/:id',
      builder: (_, state) {
        final rawType = state.uri.queryParameters['type'];
        final initialType = switch (rawType) {
          'booking' => PlaceContributionType.bookingRequest,
          'review' => PlaceContributionType.review,
          'edit' => PlaceContributionType.editSuggestion,
          'tags' => PlaceContributionType.tagSuggestion,
          'issue' => PlaceContributionType.issueReport,
          _ => null,
        };
        return PlaceContributionScreen(
          placeId: state.pathParameters['id']!,
          initialType: initialType,
        );
      },
    ),
    GoRoute(
      path: '/map',
      builder: (_, state) {
        final query = state.extra is String ? state.extra as String? : null;
        return PlacesMapScreen(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/events',
      builder: (_, __) => const CreateEventScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
    GoRoute(path: '/chatbot', builder: (_, __) => const ChatbotScreen()),
    GoRoute(path: '/guide', builder: (_, __) => const GuideScreen()),
    GoRoute(path: '/trips', builder: (_, __) => const TripPlanningScreen()),
  ],
);
