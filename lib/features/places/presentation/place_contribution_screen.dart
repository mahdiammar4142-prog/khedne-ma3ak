import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lebanon_places/features/auth/data/auth_providers.dart';
import 'package:lebanon_places/features/places/data/place_contributions_providers.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/domain/place_contribution_model.dart';

class PlaceContributionScreen extends ConsumerStatefulWidget {
  final String placeId;
  final PlaceContributionType? initialType;

  const PlaceContributionScreen({
    super.key,
    required this.placeId,
    this.initialType,
  });

  @override
  ConsumerState<PlaceContributionScreen> createState() =>
      _PlaceContributionScreenState();
}

class _PlaceContributionScreenState extends ConsumerState<PlaceContributionScreen> {
  static const _fieldGreen = Color(0xFF00A651);
  static const _fieldDark = Color(0xFF202827);
  late PlaceContributionType _type;
  final _messageController = TextEditingController();
  final _tagsController = TextEditingController();
  final _peopleController = TextEditingController(text: '2');
  int _rating = 4;
  DateTime? _bookingDate;
  bool _saving = false;
  String? _info;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? PlaceContributionType.review;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tagsController.dispose();
    _peopleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _bookingDate ?? now.add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _bookingDate = picked);
  }

  Future<void> _submit(String placeName) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      setState(() {
        _error = 'Sign in to submit.';
        _info = null;
      });
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _error = 'Please add a short message.';
        _info = null;
      });
      return;
    }
    int? peopleCount;
    if (_type == PlaceContributionType.bookingRequest) {
      peopleCount = int.tryParse(_peopleController.text.trim());
      if (_bookingDate == null || peopleCount == null || peopleCount <= 0) {
        setState(() {
          _error = 'Please choose booking date and valid people count.';
          _info = null;
        });
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
      _info = null;
    });
    try {
      final tags = _type == PlaceContributionType.tagSuggestion
          ? _tagsController.text
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList()
          : const <String>[];
      await ref.read(placeContributionsRepositoryProvider).submit(
            userId: user.uid,
            userEmail: user.email,
            placeId: widget.placeId,
            placeName: placeName,
            type: _type,
            message: message,
            tags: tags,
            rating: _type == PlaceContributionType.review ? _rating : null,
            bookingDate:
                _type == PlaceContributionType.bookingRequest ? _bookingDate : null,
            peopleCount: peopleCount,
          );
      if (!mounted) return;
      _messageController.clear();
      _tagsController.clear();
      setState(() {
        _bookingDate = null;
        _peopleController.text = '2';
        _info = 'Submitted successfully. Status: pending.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contribute'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
      ),
      body: placeAsync.when(
        data: (place) {
          if (place == null) {
            return const Center(
              child: Text('Place not found', style: TextStyle(color: Colors.black87)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                place.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlaceContributionType>(
                initialValue: _type,
                style: const TextStyle(color: Colors.white),
                dropdownColor: _fieldDark,
                iconEnabledColor: _fieldGreen,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: _fieldDark,
                  labelText: 'Contribution type',
                  labelStyle: TextStyle(color: _fieldGreen),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PlaceContributionType.review,
                    child: Text('Review', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: PlaceContributionType.editSuggestion,
                    child: Text('Edit suggestion', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: PlaceContributionType.tagSuggestion,
                    child: Text('Tag suggestion', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: PlaceContributionType.issueReport,
                    child: Text('Report issue', style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: PlaceContributionType.bookingRequest,
                    child: Text('Booking request', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
              ),
              if (_type == PlaceContributionType.review) ...[
                const SizedBox(height: 12),
                Text(
                  'Rating: $_rating / 5',
                  style: const TextStyle(color: Colors.black87),
                ),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: _rating.toDouble(),
                  label: '$_rating',
                  onChanged: (v) => setState(() => _rating = v.round()),
                ),
              ],
              if (_type == PlaceContributionType.tagSuggestion) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: _fieldDark,
                    labelText: 'Tags (comma separated)',
                    labelStyle: TextStyle(color: _fieldGreen),
                    hintText: 'family-friendly, budget, romantic',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
              if (_type == PlaceContributionType.bookingRequest) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.date_range_rounded),
                        label: Text(
                          _bookingDate == null
                              ? 'Pick date'
                              : '${_bookingDate!.day}/${_bookingDate!.month}/${_bookingDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _peopleController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: _fieldDark,
                          labelText: 'People',
                          labelStyle: TextStyle(color: _fieldGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _fieldDark,
                  labelText: switch (_type) {
                    PlaceContributionType.review => 'Your review',
                    PlaceContributionType.editSuggestion => 'What should be corrected?',
                    PlaceContributionType.tagSuggestion => 'Tag notes',
                    PlaceContributionType.issueReport => 'Issue details',
                    PlaceContributionType.bookingRequest => 'Booking notes',
                  },
                  labelStyle: const TextStyle(color: _fieldGreen),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : () => _submit(place.name),
                icon: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Submit'),
              ),
              if (_info != null) ...[
                const SizedBox(height: 10),
                Text(_info!, style: const TextStyle(color: Colors.green)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
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
