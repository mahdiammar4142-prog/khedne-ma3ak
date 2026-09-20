import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';

const String _usersCollection = 'users';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_usersCollection);

  Future<bool> isHandleTaken(String handle) async {
    final normalized = handle.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final snap = await _col.where('handleLower', isEqualTo: normalized).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<String> generateUniqueHandle(String displayName) async {
    final base = _normalizeHandle(displayName);
    final rng = Random();

    for (var i = 0; i < 20; i++) {
      final suffix = (1000 + rng.nextInt(9000)).toString();
      final candidate = '${base}_$suffix';
      if (!await isHandleTaken(candidate)) {
        return candidate;
      }
    }

    // Final fallback.
    final fallback = 'user_${DateTime.now().millisecondsSinceEpoch % 10000000}';
    return fallback;
  }

  Future<UserProfileModel?> getProfile(String userId) async {
    final doc = await _col.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfileModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Stream<UserProfileModel?> watchProfile(String userId) {
    return _col.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfileModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    });
  }

  Future<void> createProfile(UserProfileModel profile) async {
    final map = profile.toMap();
    await _col.doc(profile.id).set({
      ...map,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    });
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    await _col.doc(profile.id).update({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setProfile(UserProfileModel profile) async {
    await _col.doc(profile.id).set(
          {
            ...profile.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  /// Add or remove a connection (follow/friend).
  Future<void> updateConnections(
    String userId,
    List<String> connectionIds,
  ) async {
    await _col.doc(userId).update({
      'connectionIds': connectionIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add or remove a saved place.
  Future<void> updateSavedPlaces(
    String userId,
    List<String> savedPlaceIds,
  ) async {
    await _col.doc(userId).set({
      'savedPlaceIds': savedPlaceIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePhotoUrl(
    String userId,
    String? photoUrl,
  ) async {
    await _col.doc(userId).set({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ensures the user has a profile document in Firestore.
  /// Useful for accounts created before profile writes were configured correctly.
  Future<void> ensureProfileExists({
    required String userId,
    required String displayName,
    String? email,
    String? photoUrl,
  }) async {
    final safeName = displayName.trim().isEmpty ? 'User' : displayName.trim();
    final base = _normalizeHandle(safeName);
    final suffix = userId.length >= 6 ? userId.substring(0, 6).toLowerCase() : userId.toLowerCase();
    final handle = '${base}_$suffix';

    await _col.doc(userId).set({
      'displayName': safeName,
      'displayNameLower': safeName.toLowerCase(),
      'handle': handle,
      'handleLower': handle.toLowerCase(),
      'email': email?.trim().toLowerCase(),
      'emailLower': email?.trim().toLowerCase(),
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _normalizeHandle(String input) {
    final lower = input.trim().toLowerCase();
    final safe = lower.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (collapsed.length >= 3) return collapsed;
    if (collapsed.isEmpty) return 'user';
    return '${collapsed}user';
  }
}
