import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/events/domain/event_model.dart';
import 'package:lebanon_places/features/events/data/events_repository.dart';
import 'package:lebanon_places/features/friends/data/friends_providers.dart';

final _eventsRepo = DemoEventsRepository();
const _uuid = Uuid();

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  static const _fieldGreen = Color(0xFF00A651);
  static const _fieldDark = Color(0xFF202827);
  int _reloadToken = 0;

  void _refresh() {
    if (!mounted) return;
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101615),
          title: const Text('Events menu'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF00A651),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFF00A651),
            tabs: [
              Tab(text: 'My events'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: currentUser == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Sign in to create events and request to join events.',
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ref.watch(friendsListProvider).when(
                  data: (friends) {
                    final friendIds = friends.map((f) => f.id).toSet();
                    return TabBarView(
                      children: [
                        _MyEventsTab(
                          userId: currentUser.uid,
                          reloadToken: _reloadToken,
                          onCreateEvent: () => _showCreateDialog(
                            context,
                            currentUser.uid,
                            onCreated: _refresh,
                          ),
                          onRefresh: _refresh,
                        ),
                        _DiscoverEventsTab(
                          userId: currentUser.uid,
                          friendIds: friendIds,
                          reloadToken: _reloadToken,
                          onRefresh: _refresh,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: const TextStyle(color: Colors.black87)),
                  ),
                ),
      ),
    );
  }

  void _showCreateDialog(
    BuildContext context,
    String uid, {
    required VoidCallback onCreated,
  }) {
    final nameController = TextEditingController();
    var visibility = EventVisibility.public;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('New event', style: TextStyle(color: Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: _fieldDark,
                  labelText: 'Event name',
                  labelStyle: TextStyle(color: _fieldGreen),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<EventVisibility>(
                segments: const [
                  ButtonSegment(
                    value: EventVisibility.public,
                    label: Text('Public'),
                    icon: Icon(Icons.public_rounded),
                  ),
                  ButtonSegment(
                    value: EventVisibility.private,
                    label: Text('Private'),
                    icon: Icon(Icons.lock_rounded),
                  ),
                ],
                selected: {visibility},
                onSelectionChanged: (selection) {
                  setDialogState(() => visibility = selection.first);
                },
              ),
              const SizedBox(height: 8),
              Text(
                visibility == EventVisibility.public
                    ? 'Public: visible to all users, join by request.'
                    : 'Private: visible to your friends, join by request.',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final event = EventModel(
                  id: _uuid.v4(),
                  name: name,
                  createdBy: uid,
                  date: DateTime.now().add(const Duration(days: 7)),
                  memberIds: [uid],
                  visibility: visibility,
                );
                await _eventsRepo.create(event);
                if (ctx.mounted) Navigator.pop(ctx);
                onCreated();
                if (context.mounted) context.push('/events/${event.id}');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  final String userId;
  final int reloadToken;
  final VoidCallback onCreateEvent;
  final VoidCallback onRefresh;

  const _MyEventsTab({
    required this.userId,
    required this.reloadToken,
    required this.onCreateEvent,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventModel>>(
      key: ValueKey('my-events-$reloadToken-$userId'),
      future: _eventsRepo.listForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.black87)),
          );
        }
        final events = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: onCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('Create new event'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (events.isEmpty)
              const Card(
                color: Color(0xFFFFFFFF),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No events yet. Create one and share it.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              )
            else
              ...events.map((e) => Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(
                        e.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${e.memberIds.length} members • ${e.visibility.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                      onTap: () => context.push('/events/${e.id}').then((_) => onRefresh()),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _DiscoverEventsTab extends StatelessWidget {
  final String userId;
  final Set<String> friendIds;
  final int reloadToken;
  final VoidCallback onRefresh;

  const _DiscoverEventsTab({
    required this.userId,
    required this.friendIds,
    required this.reloadToken,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EventModel>>(
      key: ValueKey('discover-events-$reloadToken-$userId-${friendIds.length}'),
      future: _eventsRepo.listDiscoverable(userId: userId, friendIds: friendIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.black87)),
          );
        }
        final events = snapshot.data ?? const [];
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'No discoverable events right now.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: events.map((e) {
            final myRequest = e.joinRequests.where((r) => r.userId == userId).toList();
            final status = myRequest.isEmpty ? null : myRequest.first.status;
            final canRequestPrivate = e.isPublic || friendIds.contains(e.createdBy);
            final disabled = status == EventJoinRequestStatus.pending ||
                status == EventJoinRequestStatus.approved;
            return Card(
              color: Colors.white,
              child: ListTile(
                title: Text(
                  e.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${e.visibility.name.toUpperCase()} • Host: ${e.createdBy}',
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (!canRequestPrivate || disabled)
                      ? null
                      : () async {
                          try {
                            await _eventsRepo.requestJoin(
                              eventId: e.id,
                              userId: userId,
                              canRequestPrivate: canRequestPrivate,
                            );
                            onRefresh();
                          } catch (err) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$err')),
                            );
                          }
                        },
                  child: Text(_buttonLabel(status, canRequestPrivate)),
                ),
                onTap: () => context.push('/events/${e.id}').then((_) => onRefresh()),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _buttonLabel(EventJoinRequestStatus? status, bool canRequestPrivate) {
    if (!canRequestPrivate) return 'Friends only';
    return switch (status) {
      EventJoinRequestStatus.pending => 'Requested',
      EventJoinRequestStatus.approved => 'Approved',
      EventJoinRequestStatus.rejected => 'Request again',
      null => 'Request join',
    };
  }
}
