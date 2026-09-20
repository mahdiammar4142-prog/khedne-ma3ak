import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/features/events/domain/event_model.dart';
import 'package:lebanon_places/features/events/data/events_repository.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

final _eventsRepo = DemoEventsRepository();
final _profileRepo = UserProfileRepository();

final _eventDetailProvider = FutureProvider.autoDispose.family<EventModel?, String>(
  (ref, id) => _eventsRepo.getById(id),
);
final _chatUserProfileProvider = FutureProvider.autoDispose.family<UserProfileModel?, String>(
  (ref, userId) => _profileRepo.getProfile(userId),
);

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  PlaceModel? _selectedPlace;
  final TextEditingController _chatController = TextEditingController();

  Future<void> _pickLocation() async {
    final picked = await showModalBottomSheet<PlaceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _PlacePickerSheet(
        onSearch: (query) => ref.read(placesRepositoryProvider).search(query),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedPlace = picked;
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(_eventDetailProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentUserId = currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(
              child: Text('Event not found', style: TextStyle(color: Colors.black87)),
            );
          }
          final isHost = currentUserId != null && event.createdBy == currentUserId;
          final canVote = currentUserId != null &&
              (isHost || event.memberIds.contains(currentUserId));
          final canChat = canVote;
          final pendingRequests = event.joinRequests
              .where((r) => r.status == EventJoinRequestStatus.pending)
              .toList();
          final votesByPlace = <String, int>{};
          for (final v in event.placeVotes) {
            votesByPlace[v.placeId] = (votesByPlace[v.placeId] ?? 0) + 1;
          }
          final sorted = votesByPlace.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFF101615),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${event.memberIds.length} members',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visibility: ${event.visibility.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (event.selectedPlaceId != null)
                        FutureBuilder<PlaceModel?>(
                          future: ref
                              .read(placesRepositoryProvider)
                              .getById(event.selectedPlaceId!),
                          builder: (context, snap) {
                            final selectedName =
                                snap.data?.name ?? event.selectedPlaceId!;
                            return Text(
                              'Selected place: $selectedName',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white70),
                            );
                          },
                        ),
                      if (isHost)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF00A651),
                            ),
                            onPressed: () async {
                              await _pickLocation();
                              if (!mounted || _selectedPlace == null) return;
                              await _eventsRepo.setSelectedPlace(
                                widget.eventId,
                                _selectedPlace!.id,
                              );
                              ref.invalidate(_eventDetailProvider(widget.eventId));
                              setState(() => _selectedPlace = null);
                            },
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Change event location'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...sorted.map((e) => FutureBuilder(
                    future: ref.read(placesRepositoryProvider).getById(e.key),
                    builder: (ctx, snap) {
                      final place = snap.data;
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(Icons.thumb_up, color: Colors.black87),
                          title: Text(
                            place?.name ?? e.key,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: Text(
                            '${e.value} vote(s)',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          onTap: !canVote
                              ? null
                              : () {
                            _eventsRepo.addVote(widget.eventId, e.key, currentUserId);
                            ref.invalidate(_eventDetailProvider(widget.eventId));
                          },
                        ),
                      );
                    },
                  )),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No votes yet. Add a place suggestion and vote.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              if (!canVote)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Only host and accepted members can vote.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add location to vote on:',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: canVote ? _pickLocation : null,
                        icon: const Icon(Icons.place_rounded),
                        label: const Text('Choose location'),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedPlace != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Selected: ${_selectedPlace!.name}${_selectedPlace!.region != null ? ' • ${_selectedPlace!.region}' : ''}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF00A651),
                          disabledForegroundColor: Colors.black54,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                        ),
                        onPressed: _selectedPlace == null
                            || !canVote
                            ? null
                            : () async {
                                await _eventsRepo.addVote(
                                  widget.eventId,
                                  _selectedPlace!.id,
                                  currentUserId,
                                );
                                ref.invalidate(_eventDetailProvider(widget.eventId));
                                setState(() => _selectedPlace = null);
                              },
                        child: const Text('Add & vote for this location'),
                      ),
                    ],
                  ),
                ),
              ),
              if (isHost) ...[
                const SizedBox(height: 24),
                Text(
                  'Join requests',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (pendingRequests.isEmpty)
                  const Text(
                    'No pending requests.',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  ...pendingRequests.map(
                    (r) => Card(
                      child: ListTile(
                        title: Text(
                          r.userId,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: const Text(
                          'Wants to join this event',
                          style: TextStyle(color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await _eventsRepo.respondToJoinRequest(
                                  eventId: event.id,
                                  hostUserId: currentUserId,
                                  requesterUserId: r.userId,
                                  approve: false,
                                );
                                ref.invalidate(_eventDetailProvider(widget.eventId));
                              },
                              child: const Text('Decline'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                await _eventsRepo.respondToJoinRequest(
                                  eventId: event.id,
                                  hostUserId: currentUserId,
                                  requesterUserId: r.userId,
                                  approve: true,
                                );
                                ref.invalidate(_eventDetailProvider(widget.eventId));
                              },
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                'Event chat',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: event.chatMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: event.chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = event.chatMessages[index];
                          final isMine = message.userId == currentUserId;
                          final senderProfile =
                              ref.watch(_chatUserProfileProvider(message.userId)).valueOrNull;
                          final senderLabel = _senderLabel(
                            messageUserId: message.userId,
                            currentUserId: currentUserId,
                            currentUserName: currentUser?.displayName,
                            currentUserEmail: currentUser?.email,
                            profile: senderProfile,
                          );
                          final bubbleColor =
                              isMine ? const Color(0xFF00A651) : Colors.white;
                          final textColor = isMine ? Colors.white : Colors.black87;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 280),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.text,
                                      style: TextStyle(color: textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$senderLabel • ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt), alwaysUse24HourFormat: false)}',
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      enabled: canChat,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: canChat
                            ? 'Type a message'
                            : 'Only host and accepted members can chat',
                        hintStyle: const TextStyle(color: Colors.black45),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: !canChat
                        ? null
                        : () async {
                            final text = _chatController.text.trim();
                            if (text.isEmpty) return;
                            await _eventsRepo.sendMessage(
                              eventId: event.id,
                              userId: currentUserId,
                              text: text,
                            );
                            _chatController.clear();
                            ref.invalidate(_eventDetailProvider(widget.eventId));
                          },
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.black87)),
        ),
      ),
    );
  }
}

String _senderLabel({
  required String messageUserId,
  required String? currentUserId,
  required String? currentUserName,
  required String? currentUserEmail,
  required UserProfileModel? profile,
}) {
  final handle = profile?.handle?.trim();
  if (handle != null && handle.isNotEmpty) return '@$handle';
  final displayName = profile?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  if (messageUserId == currentUserId) {
    if ((currentUserName ?? '').trim().isNotEmpty) return currentUserName!.trim();
    if ((currentUserEmail ?? '').trim().isNotEmpty) return currentUserEmail!.trim();
    return 'You';
  }
  return 'User';
}

class _PlacePickerSheet extends StatefulWidget {
  final Future<List<PlaceModel>> Function(String query) onSearch;

  const _PlacePickerSheet({required this.onSearch});

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insetBottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, insetBottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose location',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              labelText: 'Search places',
              hintText: 'e.g. beach, restaurant, pool',
            ),
            onChanged: (value) {
              setState(() {
                _query = value.trim();
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: FutureBuilder<List<PlaceModel>>(
              future: widget.onSearch(_query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading places',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  );
                }
                final places = snapshot.data ?? const [];
                if (places.isEmpty) {
                  return const Center(
                    child: Text(
                      'No places found',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: places.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_rounded, color: Colors.black87),
                      title: Text(
                        place.name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Text(
                        '${place.category.name[0].toUpperCase()}${place.category.name.substring(1)}${place.region != null ? ' • ${place.region}' : ''}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      onTap: () => Navigator.pop(context, place),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
