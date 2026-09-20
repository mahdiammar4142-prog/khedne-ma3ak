import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/features/friends/data/friend_request_model.dart';

enum FriendRelationType {
  none,
  outgoingPending,
  incomingPending,
  friends,
}

class FriendRelation {
  final FriendRelationType type;
  final String? requestId;

  const FriendRelation({
    required this.type,
    this.requestId,
  });
}

class FriendsRepository {
  FriendsRepository({
    FirebaseFirestore? firestore,
    UserProfileRepository? profileRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _profileRepository = profileRepository ?? UserProfileRepository();

  final FirebaseFirestore _firestore;
  final UserProfileRepository _profileRepository;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('friendRequests');

  Stream<List<FriendRequestModel>> watchIncomingRequests(String userId) {
    return _requestsCol
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<FriendRequestModel>> watchOutgoingRequests(String userId) {
    return _requestsCol
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<List<UserProfileModel>> watchFriends(String userId) async* {
    final incomingStream = _requestsCol
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots();
    final outgoingStream = _requestsCol
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .snapshots();

    await for (final event in CombineLatest2(incomingStream, outgoingStream).stream) {
      final incoming = event.item1.docs
          .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
          .toList();
      final outgoing = event.item2.docs
          .map((d) => FriendRequestModel.fromMap(d.id, d.data()))
          .toList();

      final ids = <String>{
        ...incoming.map((r) => r.fromUserId),
        ...outgoing.map((r) => r.toUserId),
      };

      final friends = <UserProfileModel>[];
      for (final id in ids) {
        final profile = await _profileRepository.getProfile(id);
        if (profile != null) friends.add(profile);
      }
      friends.sort((a, b) => a.displayName.compareTo(b.displayName));
      yield friends;
    }
  }

  Future<List<UserProfileModel>> searchUsers({
    required String query,
    required String currentUserId,
  }) async {
    final raw = query.trim();
    final lower = raw.toLowerCase();
    if (raw.isEmpty) return const [];

    final docsById = <String, Map<String, dynamic>>{};

    Future<void> collect(Query<Map<String, dynamic>> q) async {
      final snap = await q.limit(20).get();
      for (final d in snap.docs) {
        docsById[d.id] = d.data();
      }
    }

    // Exact email match (works for old docs via email and new docs via emailLower).
    await collect(_usersCol.where('emailLower', isEqualTo: lower));
    await collect(_usersCol.where('email', isEqualTo: lower));

    // Prefix username match (new docs).
    await collect(
      _usersCol
          .where('displayNameLower', isGreaterThanOrEqualTo: lower)
          .where('displayNameLower', isLessThan: '$lower\uf8ff'),
    );

    // Handle exact/prefix match.
    await collect(_usersCol.where('handleLower', isEqualTo: lower.replaceFirst('@', '')));
    final handlePrefix = lower.replaceFirst('@', '');
    if (handlePrefix.isNotEmpty) {
      await collect(
        _usersCol
            .where('handleLower', isGreaterThanOrEqualTo: handlePrefix)
            .where('handleLower', isLessThan: '$handlePrefix\uf8ff'),
      );
    }

    // Exact username fallback (for existing docs without displayNameLower).
    await collect(_usersCol.where('displayName', isEqualTo: raw));

    final results = docsById.entries
        .where((e) => e.key != currentUserId)
        .map((e) => UserProfileModel.fromMap(e.key, e.value))
        .toList();

    // Final local filter to support both username/email query in one field.
    final filtered = results.where((u) {
      final name = u.displayName.toLowerCase();
      final handle = (u.handle ?? '').toLowerCase();
      final email = (u.email ?? '').toLowerCase();
      return name.contains(lower) ||
          handle.contains(lower.replaceFirst('@', '')) ||
          email.contains(lower);
    }).toList();

    final deduped = _dedupeByIdentity(filtered);
    deduped.sort((a, b) => a.displayName.compareTo(b.displayName));
    return deduped;
  }

  Future<FriendRelation> getRelation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final outgoingSnap = await _requestsCol
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: otherUserId)
        .limit(1)
        .get();
    if (outgoingSnap.docs.isNotEmpty) {
      final r = FriendRequestModel.fromMap(
        outgoingSnap.docs.first.id,
        outgoingSnap.docs.first.data(),
      );
      if (r.status == FriendRequestStatus.accepted) {
        return const FriendRelation(type: FriendRelationType.friends);
      }
      if (r.status == FriendRequestStatus.pending) {
        return const FriendRelation(type: FriendRelationType.outgoingPending);
      }
    }

    final incomingSnap = await _requestsCol
        .where('fromUserId', isEqualTo: otherUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .limit(1)
        .get();
    if (incomingSnap.docs.isNotEmpty) {
      final doc = incomingSnap.docs.first;
      final r = FriendRequestModel.fromMap(doc.id, doc.data());
      if (r.status == FriendRequestStatus.accepted) {
        return const FriendRelation(type: FriendRelationType.friends);
      }
      if (r.status == FriendRequestStatus.pending) {
        return FriendRelation(
          type: FriendRelationType.incomingPending,
          requestId: doc.id,
        );
      }
    }

    return const FriendRelation(type: FriendRelationType.none);
  }

  Future<void> sendRequest({
    required UserProfileModel fromUser,
    required UserProfileModel toUser,
  }) async {
    if (fromUser.id == toUser.id) {
      throw Exception('You cannot add yourself.');
    }

    final forwardId = _requestDocId(fromUser.id, toUser.id);

    final forwardSnap = await _requestsCol
        .where('fromUserId', isEqualTo: fromUser.id)
        .where('toUserId', isEqualTo: toUser.id)
        .limit(1)
        .get();
    final reverseSnap = await _requestsCol
        .where('fromUserId', isEqualTo: toUser.id)
        .where('toUserId', isEqualTo: fromUser.id)
        .limit(1)
        .get();

    if (forwardSnap.docs.isNotEmpty) {
      final doc = forwardSnap.docs.first;
      final existing = FriendRequestModel.fromMap(doc.id, doc.data());
      if (existing.status == FriendRequestStatus.pending) {
        throw Exception('Friend request already sent.');
      }
      if (existing.status == FriendRequestStatus.accepted) {
        throw Exception('You are already friends.');
      }
    }

    if (reverseSnap.docs.isNotEmpty) {
      final doc = reverseSnap.docs.first;
      final existing = FriendRequestModel.fromMap(doc.id, doc.data());
      if (existing.status == FriendRequestStatus.pending) {
        throw Exception('This user already sent you a request. Accept it in Incoming requests.');
      }
      if (existing.status == FriendRequestStatus.accepted) {
        throw Exception('You are already friends.');
      }
    }

    final now = DateTime.now();
    final request = FriendRequestModel(
      id: forwardId,
      fromUserId: fromUser.id,
      toUserId: toUser.id,
      fromDisplayName: fromUser.displayName,
      fromEmail: fromUser.email,
      toDisplayName: toUser.displayName,
      toEmail: toUser.email,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _requestsCol.doc(forwardId).set(request.toMap());
  }

  Future<void> acceptRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    final ref = _requestsCol.doc(requestId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Request not found.');
    }
    final request = FriendRequestModel.fromMap(snap.id, snap.data()!);
    if (request.toUserId != currentUserId) {
      throw Exception('Only the recipient can accept this request.');
    }
    if (request.status != FriendRequestStatus.pending) {
      throw Exception('Request is no longer pending.');
    }

    await ref.update({
      'status': FriendRequestStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineRequest({
    required String requestId,
    required String currentUserId,
  }) async {
    final ref = _requestsCol.doc(requestId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Request not found.');
    }
    final request = FriendRequestModel.fromMap(snap.id, snap.data()!);
    if (request.toUserId != currentUserId) {
      throw Exception('Only the recipient can decline this request.');
    }

    await ref.update({
      'status': FriendRequestStatus.declined.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOutgoing({
    required String requestId,
    required String currentUserId,
  }) async {
    final ref = _requestsCol.doc(requestId);
    final snap = await ref.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Request not found.');
    }
    final request = FriendRequestModel.fromMap(snap.id, snap.data()!);
    if (request.fromUserId != currentUserId) {
      throw Exception('Only sender can cancel this request.');
    }
    await ref.delete();
  }

  Future<void> removeFriend({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final outgoingAccepted = await _requestsCol
        .where('fromUserId', isEqualTo: currentUserId)
        .where('toUserId', isEqualTo: otherUserId)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .get();
    final incomingAccepted = await _requestsCol
        .where('fromUserId', isEqualTo: otherUserId)
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: FriendRequestStatus.accepted.name)
        .get();

    final batch = _firestore.batch();
    for (final d in outgoingAccepted.docs) {
      batch.delete(d.reference);
    }
    for (final d in incomingAccepted.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  String _requestDocId(String fromUserId, String toUserId) => '${fromUserId}_$toUserId';

  List<UserProfileModel> _dedupeByIdentity(List<UserProfileModel> users) {
    final byEmail = <String, UserProfileModel>{};
    final noEmail = <UserProfileModel>[];

    for (final user in users) {
      final email = (user.email ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        noEmail.add(user);
        continue;
      }
      final existing = byEmail[email];
      if (existing == null) {
        byEmail[email] = user;
        continue;
      }
      byEmail[email] = _preferProfile(existing, user);
    }

    return [...byEmail.values, ...noEmail];
  }

  UserProfileModel _preferProfile(UserProfileModel a, UserProfileModel b) {
    final aHasHandle = (a.handle ?? '').trim().isNotEmpty;
    final bHasHandle = (b.handle ?? '').trim().isNotEmpty;
    if (aHasHandle != bHasHandle) return bHasHandle ? b : a;
    return a.updatedAt.isAfter(b.updatedAt) ? a : b;
  }
}

class CombineLatest2<A, B> {
  final Stream<A> a;
  final Stream<B> b;
  const CombineLatest2(this.a, this.b);

  Stream<_Pair<A, B>> get stream async* {
    A? latestA;
    B? latestB;
    var hasA = false;
    var hasB = false;

    final controller = Stream<_Pair<A, B>>.multi((multi) {
      final subA = a.listen((value) {
        latestA = value;
        hasA = true;
        if (hasA && hasB) multi.add(_Pair(latestA as A, latestB as B));
      }, onError: multi.addError);
      final subB = b.listen((value) {
        latestB = value;
        hasB = true;
        if (hasA && hasB) multi.add(_Pair(latestA as A, latestB as B));
      }, onError: multi.addError);
      multi.onCancel = () async {
        await subA.cancel();
        await subB.cancel();
      };
    });
    yield* controller;
  }
}

class _Pair<A, B> {
  final A item1;
  final B item2;
  const _Pair(this.item1, this.item2);
}

