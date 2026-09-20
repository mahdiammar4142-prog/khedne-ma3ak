import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lebanon_places/core/taxonomy/taxonomy_model.dart';
import 'package:lebanon_places/features/places/data/places_repository_provider.dart';
import 'package:lebanon_places/features/places/presentation/widgets/place_card.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

class PlacesSearchScreen extends ConsumerStatefulWidget {
  const PlacesSearchScreen({super.key});

  @override
  ConsumerState<PlacesSearchScreen> createState() => _PlacesSearchScreenState();
}

class _PlacesSearchScreenState extends ConsumerState<PlacesSearchScreen> {
  final _controller = TextEditingController();
  final String _hint = 'e.g. burgers, pool, hotel';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is String && extra.isNotEmpty) {
      final initialQuery = extra;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.text = initialQuery;
        ref.read(_searchQueryProvider.notifier).state = initialQuery;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search places'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey.shade800),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.map_rounded, color: Colors.grey.shade800),
            tooltip: 'Show on map',
            onPressed: () => context.push('/map', extra: query),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: _hint,
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                        onPressed: () {
                          _controller.clear();
                          ref.read(_searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => ref.read(_searchQueryProvider.notifier).state = v,
              onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
            ),
          ),
          if (query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                  child: Row(
                  children: Taxonomy.categoriesForQuery(query)
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(Taxonomy.categoryLabel(c)),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: resultsAsync.when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No places found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try another search (e.g. burgers, pool, hotel)',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => PlaceCard(place: list[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

}
