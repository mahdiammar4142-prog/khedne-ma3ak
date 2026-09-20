import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/friends/data/friend_request_model.dart';
import 'package:lebanon_places/features/friends/data/friends_providers.dart';
import 'package:lebanon_places/features/friends/data/friends_repository.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _loadingSearch = false;
  List<UserProfileModel> _searchResults = const [];
  String? _info;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loadingSearch = true;
      _info = null;
      _error = null;
      _searchResults = const [];
    });
    try {
      final current = await ref.read(currentUserProfileProvider.future);
      if (current == null) return;
      final users = await ref.read(friendsRepositoryProvider).searchUsers(
            query: query,
            currentUserId: current.id,
          );
      if (!mounted) return;
      setState(() {
        _searchResults = users;
        _info = users.isEmpty ? 'No user found for that username/email.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSearch = false;
      });
    }
  }

  Future<void> _sendRequest(UserProfileModel toUser) async {
    final current = await ref.read(currentUserProfileProvider.future);
    if (current == null) return;
    setState(() {
      _error = null;
      _info = null;
    });
    try {
      await ref.read(friendsRepositoryProvider).sendRequest(
            fromUser: current,
            toUser: toUser,
          );
      if (!mounted) return;
      setState(() {
        _info = 'Friend request sent.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _accept(FriendRequestModel request) async {
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null) return;
    await ref.read(friendsRepositoryProvider).acceptRequest(
          requestId: request.id,
          currentUserId: user.id,
        );
  }

  Future<void> _acceptById(String requestId) async {
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null) return;
    await ref.read(friendsRepositoryProvider).acceptRequest(
          requestId: requestId,
          currentUserId: user.id,
        );
    if (!mounted) return;
    setState(() {
      _info = 'Friend request accepted.';
      _error = null;
    });
  }

  Future<void> _decline(FriendRequestModel request) async {
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null) return;
    await ref.read(friendsRepositoryProvider).declineRequest(
          requestId: request.id,
          currentUserId: user.id,
        );
  }

  Future<void> _cancel(FriendRequestModel request) async {
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null) return;
    await ref.read(friendsRepositoryProvider).cancelOutgoing(
          requestId: request.id,
          currentUserId: user.id,
        );
  }

  Future<void> _removeFriend(UserProfileModel friend) async {
    final user = await ref.read(currentUserProfileProvider.future);
    if (user == null) return;
    try {
      await ref.read(friendsRepositoryProvider).removeFriend(
            currentUserId: user.id,
            otherUserId: friend.id,
          );
      if (!mounted) return;
      setState(() {
        _info = 'Friend removed.';
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('Friends'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Add friend',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            onPressed: () {
              _searchFocusNode.requestFocus();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.black87),
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Find by username or email',
                hintText: 'e.g. sara, @sara_4821, sara@gmail.com',
                labelStyle: const TextStyle(color: Colors.black87),
                hintStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
                suffixIcon: IconButton(
                  onPressed: _loadingSearch ? null : _searchUsers,
                  icon: _loadingSearch
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._searchResults.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _UserResultTile(
                  user: user,
                  currentUserProfileAsync: ref.watch(currentUserProfileProvider),
                  onAddFriend: () => _sendRequest(user),
                  onAcceptById: _acceptById,
                ),
              ),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 8),
            Text(_info!, style: const TextStyle(color: Color(0xFF1E7E34))),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
          ],
          const SizedBox(height: 20),
          const _SectionTitle('Incoming requests'),
          const SizedBox(height: 8),
          incomingAsync.when(
            data: (items) => items.isEmpty
                ? const _EmptyText('No incoming requests')
                : Column(
                    children: items
                        .map((r) => _RequestTile(
                              title: r.fromDisplayName ?? r.fromEmail ?? 'User',
                              subtitle: r.fromEmail,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _decline(r),
                                    child: const Text('Decline'),
                                  ),
                                  FilledButton(
                                    onPressed: () => _accept(r),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Pending requests'),
          const SizedBox(height: 8),
          outgoingAsync.when(
            data: (items) => items.isEmpty
                ? const _EmptyText('No pending requests')
                : Column(
                    children: items
                        .map((r) => _RequestTile(
                              title: r.toDisplayName ?? r.toEmail ?? 'User',
                              subtitle: r.toEmail,
                              trailing: TextButton(
                                onPressed: () => _cancel(r),
                                child: const Text('Cancel'),
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('My friends'),
          const SizedBox(height: 8),
          friendsAsync.when(
            data: (items) => items.isEmpty
                ? const _EmptyText('No friends yet')
                : Column(
                    children: items
                        .map((u) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                child: Text(
                                  (u.displayName.isEmpty
                                          ? '?'
                                          : u.displayName[0])
                                      .toUpperCase(),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              title: Text(
                                u.displayName,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              subtitle: Text(
                                '@${u.handle ?? u.displayName} • ${_maskEmail(u.email)}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: TextButton(
                                onPressed: () => _removeFriend(u),
                                child: const Text('Remove'),
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F1A18),
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;

  const _RequestTile({
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(color: Colors.black54)),
        trailing: trailing,
      ),
    );
  }
}

class _UserResultTile extends ConsumerWidget {
  final UserProfileModel user;
  final AsyncValue<UserProfileModel?> currentUserProfileAsync;
  final VoidCallback onAddFriend;
  final Future<void> Function(String requestId) onAcceptById;

  const _UserResultTile({
    required this.user,
    required this.currentUserProfileAsync,
    required this.onAddFriend,
    required this.onAcceptById,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return currentUserProfileAsync.when(
      data: (current) {
        if (current == null) {
          return const SizedBox.shrink();
        }
        return FutureBuilder<FriendRelation>(
          future: ref.read(friendsRepositoryProvider).getRelation(
            currentUserId: current.id,
            otherUserId: user.id,
          ),
          builder: (context, snap) {
            final relation = snap.data;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (user.displayName.isEmpty ? '?' : user.displayName[0]).toUpperCase(),
                  ),
                ),
                title: Text(user.displayName, style: const TextStyle(color: Colors.black87)),
                subtitle: Text(
                  '@${user.handle ?? user.displayName} • ${_maskEmail(user.email)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: _buildActionButton(relation),
              ),
            );
          },
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const ListTile(
          title: Text('Loading...', style: TextStyle(color: Colors.black54)),
        ),
      ),
      error: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const ListTile(
          title: Text('Unavailable', style: TextStyle(color: Colors.black54)),
        ),
      ),
    );
  }

  Widget _buildActionButton(FriendRelation? relation) {
    final type = relation?.type ?? FriendRelationType.none;
    switch (type) {
      case FriendRelationType.friends:
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
          ),
          onPressed: null,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Friends'),
        );
      case FriendRelationType.outgoingPending:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black54,
          ),
          onPressed: null,
          child: const Text('Pending'),
        );
      case FriendRelationType.incomingPending:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            foregroundColor: Colors.white,
          ),
          onPressed: relation?.requestId == null
              ? null
              : () => onAcceptById(relation!.requestId!),
          child: const Text('Accept'),
        );
      case FriendRelationType.none:
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00A651),
            foregroundColor: Colors.white,
          ),
          onPressed: onAddFriend,
          child: const Text('Add'),
        );
    }
  }
}

String _maskEmail(String? email) {
  if (email == null || email.isEmpty) return 'No email';
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final name = parts[0];
  final domain = parts[1];
  if (name.length <= 2) {
    return '${name[0]}***@$domain';
  }
  return '${name.substring(0, 2)}***@$domain';
}

