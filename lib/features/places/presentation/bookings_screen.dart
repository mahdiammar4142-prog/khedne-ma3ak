import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/places/data/place_contributions_providers.dart';
import 'package:lebanon_places/features/places/domain/place_contribution_model.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final bookingsAsync = user == null
        ? const AsyncValue<List<PlaceContributionModel>>.data([])
        : ref.watch(myBookingRequestsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('My bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking requests',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Submit booking requests from a place detail page.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          bookingsAsync.when(
            data: (items) {
              if (user == null) {
                return const Text(
                  'Sign in to view your booking requests.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              if (items.isEmpty) {
                return const Text(
                  'No booking requests yet.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: items.map((item) {
                  final date = item.bookingDate;
                  final dateText = date == null
                      ? 'No date'
                      : '${date.day}/${date.month}/${date.year}';
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(
                        item.placeName,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Text(
                        '$dateText • ${item.peopleCount ?? '-'} people',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: _BookingStatus(status: item.status),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              _friendlyFirestoreError(
                e,
                fallback: 'Error loading bookings: $e',
              ),
              style: TextStyle(
                color: _isPermissionDenied(e) ? Colors.black54 : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isPermissionDenied(Object error) {
  final lower = error.toString().toLowerCase();
  return lower.contains('permission-denied') ||
      lower.contains('missing or insufficient permissions');
}

String _friendlyFirestoreError(
  Object error, {
  required String fallback,
}) {
  if (_isPermissionDenied(error)) {
    return 'Could not load bookings yet. Please deploy latest Firestore rules, then restart the app.';
  }
  return fallback;
}

class _BookingStatus extends StatelessWidget {
  final PlaceContributionStatus status;

  const _BookingStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      PlaceContributionStatus.pending => (
          const Color(0xFFFFF3CD),
          const Color(0xFF8A6D00),
          'Pending'
        ),
      PlaceContributionStatus.approved => (
          const Color(0xFFD4EDDA),
          const Color(0xFF1E7E34),
          'Approved'
        ),
      PlaceContributionStatus.rejected => (
          const Color(0xFFF8D7DA),
          const Color(0xFF842029),
          'Rejected'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
