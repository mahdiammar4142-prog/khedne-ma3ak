import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/features/friends/data/friend_request_model.dart';
import 'package:lebanon_places/features/friends/data/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository();
});

final currentUserProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return UserProfileRepository().getProfile(user.uid);
});

final incomingRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(friendsRepositoryProvider).watchIncomingRequests(user.uid);
});

final outgoingRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(friendsRepositoryProvider).watchOutgoingRequests(user.uid);
});

final friendsListProvider = StreamProvider<List<UserProfileModel>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(friendsRepositoryProvider).watchFriends(user.uid);
});

