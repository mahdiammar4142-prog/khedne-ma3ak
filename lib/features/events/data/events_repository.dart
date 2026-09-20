import 'dart:convert';

import 'package:lebanon_places/features/events/domain/event_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class EventsRepository {
  Future<List<EventModel>> listForUser(String userId);
  Future<List<EventModel>> listDiscoverable({
    required String userId,
    required Set<String> friendIds,
  });
  Future<EventModel?> getById(String id);
  Future<void> create(EventModel event);
  Future<void> addVote(String eventId, String placeId, String userId);
  Future<void> setSelectedPlace(String eventId, String placeId);
  Future<void> requestJoin({
    required String eventId,
    required String userId,
    required bool canRequestPrivate,
  });
  Future<void> respondToJoinRequest({
    required String eventId,
    required String hostUserId,
    required String requesterUserId,
    required bool approve,
  });
  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String text,
  });
}

/// Demo implementation. Replace with Firestore.
class DemoEventsRepository implements EventsRepository {
  static const _storageKey = 'demo_events_v1';
  static final List<EventModel> _events = [];
  static bool _isLoaded = false;
  static Future<void>? _loadFuture;

  Future<void> _ensureLoaded() {
    _loadFuture ??= _loadFromStorage();
    return _loadFuture!;
  }

  Future<void> _loadFromStorage() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _events
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e))),
            );
        }
      } catch (_) {
        _events.clear();
      }
    }
    _isLoaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_events.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<List<EventModel>> listForUser(String userId) async {
    await _ensureLoaded();
    return _events.where((e) => e.memberIds.contains(userId) || e.createdBy == userId).toList();
  }

  @override
  Future<List<EventModel>> listDiscoverable({
    required String userId,
    required Set<String> friendIds,
  }) async {
    await _ensureLoaded();
    return _events.where((e) {
      if (e.createdBy == userId || e.memberIds.contains(userId)) return false;
      if (e.isPublic) return true;
      return friendIds.contains(e.createdBy);
    }).toList();
  }

  @override
  Future<EventModel?> getById(String id) async {
    await _ensureLoaded();
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> create(EventModel event) async {
    await _ensureLoaded();
    _events.add(event);
    await _persist();
  }

  @override
  Future<void> addVote(String eventId, String placeId, String userId) async {
    await _ensureLoaded();
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) return;
    final e = _events[i];
    final votes = e.placeVotes.where((v) => v.userId != userId).toList();
    votes.add(PlaceVote(placeId: placeId, userId: userId));
    _events[i] = e.copyWith(placeVotes: votes);
    await _persist();
  }

  @override
  Future<void> setSelectedPlace(String eventId, String placeId) async {
    await _ensureLoaded();
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) return;
    final e = _events[i];
    _events[i] = e.copyWith(selectedPlaceId: placeId);
    await _persist();
  }

  @override
  Future<void> requestJoin({
    required String eventId,
    required String userId,
    required bool canRequestPrivate,
  }) async {
    await _ensureLoaded();
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) {
      throw Exception('Event not found.');
    }
    final event = _events[i];
    if (event.createdBy == userId || event.memberIds.contains(userId)) {
      throw Exception('You are already in this event.');
    }
    if (!event.isPublic && !canRequestPrivate) {
      throw Exception('Private events are requestable only by host friends.');
    }
    final existing = event.joinRequests.where((r) => r.userId == userId);
    if (existing.any((r) => r.status == EventJoinRequestStatus.pending)) {
      throw Exception('Join request already pending.');
    }
    if (existing.any((r) => r.status == EventJoinRequestStatus.approved)) {
      throw Exception('You were already approved for this event.');
    }
    final updated = [
      ...event.joinRequests.where((r) => r.userId != userId),
      EventJoinRequest(
        userId: userId,
        status: EventJoinRequestStatus.pending,
        createdAt: DateTime.now(),
      ),
    ];
    _events[i] = event.copyWith(joinRequests: updated);
    await _persist();
  }

  @override
  Future<void> respondToJoinRequest({
    required String eventId,
    required String hostUserId,
    required String requesterUserId,
    required bool approve,
  }) async {
    await _ensureLoaded();
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) throw Exception('Event not found.');
    final event = _events[i];
    if (event.createdBy != hostUserId) {
      throw Exception('Only host can manage join requests.');
    }
    final hasRequest = event.joinRequests.any((r) => r.userId == requesterUserId);
    if (!hasRequest) {
      throw Exception('Request not found.');
    }

    final updatedRequests = event.joinRequests
        .map((r) => r.userId == requesterUserId
            ? EventJoinRequest(
                userId: r.userId,
                status: approve
                    ? EventJoinRequestStatus.approved
                    : EventJoinRequestStatus.rejected,
                createdAt: r.createdAt,
              )
            : r)
        .toList();

    final updatedMembers = [...event.memberIds];
    if (approve && !updatedMembers.contains(requesterUserId)) {
      updatedMembers.add(requesterUserId);
    }

    _events[i] = event.copyWith(
      joinRequests: updatedRequests,
      memberIds: updatedMembers,
    );
    await _persist();
  }

  @override
  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String text,
  }) async {
    await _ensureLoaded();
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) throw Exception('Event not found.');
    final event = _events[i];
    final isParticipant = event.createdBy == userId || event.memberIds.contains(userId);
    if (!isParticipant) {
      throw Exception('Only host and accepted members can chat in this event.');
    }
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    final updatedMessages = [
      ...event.chatMessages,
      EventChatMessage(
        userId: userId,
        text: cleaned,
        createdAt: DateTime.now(),
      ),
    ];
    _events[i] = event.copyWith(chatMessages: updatedMessages);
    await _persist();
  }
}
