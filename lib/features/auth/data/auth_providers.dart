import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Current Firebase user or null.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Whether we should show the app (user signed in or guest). If false, redirect to gate.
final authGateProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user != null) return true;
  final isGuest = await auth.isGuest();
  return isGuest;
});
