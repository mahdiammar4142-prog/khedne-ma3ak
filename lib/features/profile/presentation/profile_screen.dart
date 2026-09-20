import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/auth/data/user_profile_model.dart';
import 'package:lebanon_places/features/auth/data/user_profile_repository.dart';
import 'package:lebanon_places/features/friends/data/friends_providers.dart';

final _profileRepo = UserProfileRepository();
final _photoUpdatingProvider = StateProvider<bool>((ref) => false);

final _userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return _profileRepo.getProfile(user.uid);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(_userProfileProvider);
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Guest mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00A651),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).clearGuest();
                        if (context.mounted) context.go('/gate');
                      },
                      child: const Text('Create account or sign in'),
                    ),
                  ],
                ),
              ),
            );
          }
          return profileAsync.when(
            data: (profile) => _ProfileContent(
              displayName: profile?.displayName ?? user.displayName ?? 'User',
              handle: profile?.handle,
              email: profile?.email ?? user.email ?? '',
              photoUrl: profile?.photoUrl ?? user.photoURL,
              connectionCount: friendsAsync.valueOrNull?.length ?? profile?.connectionIds.length ?? 0,
              photoUpdating: ref.watch(_photoUpdatingProvider),
              onChangePhoto: () => _showPhotoDialog(
                context: context,
                ref: ref,
                userId: user.uid,
                currentPhotoUrl: profile?.photoUrl ?? user.photoURL,
              ),
              onSignOut: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/gate');
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ProfileContent(
              displayName: user.displayName ?? 'User',
              handle: null,
              email: user.email ?? '',
              photoUrl: user.photoURL,
              connectionCount: friendsAsync.valueOrNull?.length ?? 0,
              photoUpdating: ref.watch(_photoUpdatingProvider),
              onChangePhoto: () => _showPhotoDialog(
                context: context,
                ref: ref,
                userId: user.uid,
                currentPhotoUrl: user.photoURL,
              ),
              onSignOut: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/gate');
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Guest mode', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).clearGuest();
                    if (context.mounted) context.go('/gate');
                  },
                  child: const Text('Sign in or create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String displayName;
  final String? handle;
  final String email;
  final String? photoUrl;
  final int connectionCount;
  final bool photoUpdating;
  final Future<void> Function() onChangePhoto;
  final VoidCallback onSignOut;

  const _ProfileContent({
    required this.displayName,
    required this.handle,
    required this.email,
    this.photoUrl,
    required this.connectionCount,
    required this.photoUpdating,
    required this.onChangePhoto,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _avatarImage(photoUrl),
                        child: _avatarImage(photoUrl) == null
                            ? Icon(Icons.person_rounded, size: 48, color: colorScheme.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: photoUpdating ? null : onChangePhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: photoUpdating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if ((handle ?? '').isNotEmpty)
                  Text(
                    '@$handle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if ((handle ?? '').isNotEmpty) const SizedBox(height: 2),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Account',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.people_rounded,
                  title: 'Friends',
                  subtitle: connectionCount == 0
                      ? 'Friends and people you follow'
                      : '$connectionCount connections',
                  onTap: () => context.push('/friends'),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _ProfileTile(
                  icon: Icons.event_rounded,
                  title: 'My events',
                  onTap: () => context.push('/events'),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _ProfileTile(
                  icon: Icons.favorite_rounded,
                  title: 'Saved places',
                  onTap: () => context.push('/search'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Sign out',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: const Color(0xFF9B1C1C),
            side: const BorderSide(color: Color(0xFFE6B4B4)),
            backgroundColor: const Color(0xFFFFF5F5),
          ),
        ),
      ],
    );
  }
}

ImageProvider? _avatarImage(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final uri = Uri.tryParse(photoUrl.trim());
  if (uri == null || !uri.hasScheme) return null;
  return NetworkImage(photoUrl.trim());
}

Future<void> _showPhotoDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required String? currentPhotoUrl,
}) async {
  final controller = TextEditingController(text: currentPhotoUrl ?? '');
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile picture',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://.../photo.jpg',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _savePhotoUrl(
                        context: context,
                        ref: ref,
                        userId: userId,
                        photoUrl: null,
                      );
                    },
                    child: const Text('Remove photo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final url = controller.text.trim();
                      final uri = Uri.tryParse(url);
                      if (url.isEmpty ||
                          uri == null ||
                          (!uri.isScheme('http') && !uri.isScheme('https'))) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid image URL.'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await _savePhotoUrl(
                        context: context,
                        ref: ref,
                        userId: userId,
                        photoUrl: url,
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _savePhotoUrl({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required String? photoUrl,
}) async {
  ref.read(_photoUpdatingProvider.notifier).state = true;
  try {
    await _profileRepo.updatePhotoUrl(userId, photoUrl);
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == userId) {
      await authUser.updatePhotoURL(photoUrl);
    }
    ref.invalidate(_userProfileProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            photoUrl == null || photoUrl.isEmpty
                ? 'Profile picture removed.'
                : 'Profile picture updated.',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    }
  } finally {
    ref.read(_photoUpdatingProvider.notifier).state = false;
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            )
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black54),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
