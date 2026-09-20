import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/places/data/place_submissions_providers.dart';
import 'package:lebanon_places/features/places/data/place_submissions_repository.dart';
import 'package:lebanon_places/features/places/domain/place_submission_model.dart';

class PlaceSubmissionsScreen extends ConsumerStatefulWidget {
  const PlaceSubmissionsScreen({super.key});

  @override
  ConsumerState<PlaceSubmissionsScreen> createState() =>
      _PlaceSubmissionsScreenState();
}

class _PlaceSubmissionsScreenState extends ConsumerState<PlaceSubmissionsScreen> {
  static const _fieldGreen = Color(0xFF00A651);
  static const _fieldDark = Color(0xFF202827);
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  PlaceCategory _category = PlaceCategory.restaurant;
  bool _submitting = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _mapsLinkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      setState(() {
        _error = 'Sign in to submit a new place.';
        _message = null;
      });
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final mapsLink = _mapsLinkController.text.trim();

    if (name.isEmpty || description.isEmpty || mapsLink.isEmpty) {
      setState(() {
        _error = 'Please fill all required fields.';
        _message = null;
      });
      return;
    }
    if (!PlaceSubmissionsRepository.isLikelyGoogleMapsLink(mapsLink)) {
      setState(() {
        _error = 'Please provide a valid Google Maps shared link.';
        _message = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(placeSubmissionsRepositoryProvider).submitNewPlace(
            userId: user.uid,
            userEmail: user.email,
            name: name,
            description: description,
            category: _category,
            mapsLink: mapsLink,
          );
      if (!mounted) return;
      _nameController.clear();
      _descriptionController.clear();
      _mapsLinkController.clear();
      setState(() {
        _category = PlaceCategory.restaurant;
        _message = 'Submission sent. Status: pending review.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyFirestoreError(
          e,
          fallback: e.toString().replaceFirst('Exception: ', ''),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final submissionsAsync = user == null
        ? const AsyncValue<List<PlaceSubmissionModel>>.data([])
        : ref.watch(myPlaceSubmissionsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101615),
        title: const Text('Add location'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit a new place',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill name, description and Google Maps shared link.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: _fieldDark,
                    labelText: 'Place name',
                    labelStyle: TextStyle(color: _fieldGreen),
                    hintText: 'e.g. Sunset Rooftop Beirut',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: _fieldDark,
                    labelText: 'Description',
                    labelStyle: TextStyle(color: _fieldGreen),
                    hintText: 'Short summary of what makes this place useful.',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PlaceCategory>(
                  initialValue: _category,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: _fieldDark,
                  iconEnabledColor: _fieldGreen,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: _fieldDark,
                    labelText: 'Category',
                    labelStyle: TextStyle(color: _fieldGreen),
                  ),
                  items: PlaceCategory.values
                      .where((c) => c != PlaceCategory.other)
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            Taxonomy.categoryLabel(c),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mapsLinkController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: _fieldDark,
                    labelText: 'Google Maps shared link',
                    labelStyle: TextStyle(color: _fieldGreen),
                    hintText: 'https://maps.google.com/...',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Submit new place'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EDDA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_message!, style: const TextStyle(color: Color(0xFF1E7E34))),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8D7DA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: const TextStyle(color: Color(0xFF842029))),
            ),
          ],
          if (user == null) ...[
            const SizedBox(height: 10),
            const Text(
              'Guest mode: sign in to submit and track your requests.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 24),
          Text('My submissions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black87, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          submissionsAsync.when(
            data: (items) {
              if (user == null) {
                return const Text(
                  'Sign in to view submissions.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              if (items.isEmpty) {
                return const Text(
                  'No submissions yet.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: items
                    .map(
                      (s) => Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(
                            s.name,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          subtitle: Text(
                            '${Taxonomy.categoryLabel(s.category)} • ${_formatDate(s.createdAt)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: _StatusBadge(status: s.status),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              _friendlyFirestoreError(
                e,
                fallback: 'Could not load submissions: $e',
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
    return 'Could not access submissions yet. Please deploy latest Firestore rules, then restart the app.';
  }
  return fallback;
}

class _StatusBadge extends StatelessWidget {
  final PlaceSubmissionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      PlaceSubmissionStatus.pending => (
          const Color(0xFFFFF3CD),
          const Color(0xFF8A6D00),
          'Pending'
        ),
      PlaceSubmissionStatus.approved => (
          const Color(0xFFD4EDDA),
          const Color(0xFF1E7E34),
          'Approved'
        ),
      PlaceSubmissionStatus.rejected => (
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

String _formatDate(DateTime value) {
  final d = value.day.toString().padLeft(2, '0');
  final m = value.month.toString().padLeft(2, '0');
  final y = value.year;
  return '$d/$m/$y';
}
