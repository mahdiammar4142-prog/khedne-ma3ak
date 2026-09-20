/// Smart taxonomy: maps search terms to place categories and related concepts.
/// e.g. "burgers" -> [PlaceCategory.restaurant, PlaceCategory.snacks]
enum PlaceCategory {
  restaurant,
  cafe,
  snacks,
  hotel,
  pool,
  beach,
  nightlife,
  nature,
  shopping,
  activity,
  other,
}

/// Maps user search keywords to relevant categories and synonyms.
class TaxonomyNode {
  final String keyword;
  final List<PlaceCategory> categories;
  final List<String> synonyms;

  const TaxonomyNode({
    required this.keyword,
    required this.categories,
    this.synonyms = const [],
  });
}

/// Central taxonomy for Lebanon places (expandable).
class Taxonomy {
  static const List<TaxonomyNode> nodes = [
    // Food – meals & dishes
    TaxonomyNode(keyword: 'burger', categories: [PlaceCategory.restaurant, PlaceCategory.snacks],
        synonyms: ['burgers', 'burger joint', 'fast food']),
    TaxonomyNode(keyword: 'pizza', categories: [PlaceCategory.restaurant, PlaceCategory.snacks]),
    TaxonomyNode(keyword: 'sandwich', categories: [PlaceCategory.restaurant, PlaceCategory.snacks],
        synonyms: ['sandwiches', 'wrap', 'panini', 'sub']),
    TaxonomyNode(keyword: 'shawarma', categories: [PlaceCategory.restaurant, PlaceCategory.snacks]),
    TaxonomyNode(keyword: 'falafel', categories: [PlaceCategory.restaurant, PlaceCategory.snacks]),
    TaxonomyNode(keyword: 'sushi', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'pasta', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'grill', categories: [PlaceCategory.restaurant],
        synonyms: ['grilled', 'bbq', 'barbecue']),
    TaxonomyNode(keyword: 'mezze', categories: [PlaceCategory.restaurant],
        synonyms: ['mezza', 'meze']),
    TaxonomyNode(keyword: 'seafood', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'lebanese', categories: [PlaceCategory.restaurant],
        synonyms: ['lebanon', 'traditional']),
    TaxonomyNode(keyword: 'salad', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'vegan', categories: [PlaceCategory.restaurant, PlaceCategory.cafe]),
    TaxonomyNode(keyword: 'vegetarian', categories: [PlaceCategory.restaurant, PlaceCategory.cafe]),
    TaxonomyNode(keyword: 'breakfast', categories: [PlaceCategory.restaurant, PlaceCategory.cafe]),
    TaxonomyNode(keyword: 'brunch', categories: [PlaceCategory.restaurant, PlaceCategory.cafe]),
    TaxonomyNode(keyword: 'lunch', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'dinner', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'snack', categories: [PlaceCategory.snacks, PlaceCategory.cafe],
        synonyms: ['snacks', 'light bite']),
    TaxonomyNode(keyword: 'fine dining', categories: [PlaceCategory.restaurant]),
    TaxonomyNode(keyword: 'restaurant', categories: [PlaceCategory.restaurant],
        synonyms: ['eat', 'food', 'dining']),
    // Drinks & cafe
    TaxonomyNode(keyword: 'coffee', categories: [PlaceCategory.cafe],
        synonyms: ['espresso', 'latte', 'cappuccino']),
    TaxonomyNode(keyword: 'drink', categories: [PlaceCategory.cafe, PlaceCategory.restaurant, PlaceCategory.nightlife],
        synonyms: ['drinks', 'beverage', 'beverages']),
    TaxonomyNode(keyword: 'juice', categories: [PlaceCategory.cafe, PlaceCategory.snacks],
        synonyms: ['fresh juice', 'smoothie', 'smoothies']),
    TaxonomyNode(keyword: 'tea', categories: [PlaceCategory.cafe],
        synonyms: ['chai', 'herbal']),
    TaxonomyNode(keyword: 'wine', categories: [PlaceCategory.restaurant, PlaceCategory.nightlife]),
    TaxonomyNode(keyword: 'cocktail', categories: [PlaceCategory.nightlife, PlaceCategory.restaurant],
        synonyms: ['cocktails', 'mixology']),
    TaxonomyNode(keyword: 'cafe', categories: [PlaceCategory.cafe],
        synonyms: ['coffee shop', 'coffeehouse']),
    TaxonomyNode(keyword: 'bakery', categories: [PlaceCategory.snacks, PlaceCategory.cafe],
        synonyms: ['pastry', 'pastries', 'bread']),
    // Sweets & desserts
    TaxonomyNode(keyword: 'dessert', categories: [PlaceCategory.snacks, PlaceCategory.restaurant, PlaceCategory.cafe],
        synonyms: ['desserts', 'sweet']),
    TaxonomyNode(keyword: 'ice cream', categories: [PlaceCategory.snacks],
        synonyms: ['gelato', 'frozen']),
    TaxonomyNode(keyword: 'sweets', categories: [PlaceCategory.snacks],
        synonyms: ['knafeh', 'baklava', 'oriental sweets']),
    // Nightlife & bars
    TaxonomyNode(keyword: 'bar', categories: [PlaceCategory.nightlife, PlaceCategory.restaurant],
        synonyms: ['pub', 'lounge bar']),
    TaxonomyNode(keyword: 'club', categories: [PlaceCategory.nightlife],
        synonyms: ['nightclub', 'dancing']),
    TaxonomyNode(keyword: 'rooftop', categories: [PlaceCategory.nightlife, PlaceCategory.restaurant],
        synonyms: ['roof', 'terrace']),
    TaxonomyNode(keyword: 'lounge', categories: [PlaceCategory.nightlife, PlaceCategory.pool]),
    TaxonomyNode(keyword: 'hookah', categories: [PlaceCategory.nightlife, PlaceCategory.cafe],
        synonyms: ['shisha', 'argileh']),
    TaxonomyNode(keyword: 'live music', categories: [PlaceCategory.nightlife, PlaceCategory.restaurant]),
    // Stay
    TaxonomyNode(keyword: 'hotel', categories: [PlaceCategory.hotel],
        synonyms: ['stay', 'accommodation', 'resort', 'lodging']),
    TaxonomyNode(keyword: 'resort', categories: [PlaceCategory.hotel, PlaceCategory.pool]),
    TaxonomyNode(keyword: 'pool', categories: [PlaceCategory.pool],
        synonyms: ['swimming', 'pool day', 'poolside']),
    TaxonomyNode(keyword: 'beach', categories: [PlaceCategory.beach],
        synonyms: ['sea', 'beach club', 'seaside']),
    TaxonomyNode(keyword: 'spa', categories: [PlaceCategory.hotel, PlaceCategory.activity]),
    // Activities & nature
    TaxonomyNode(keyword: 'hiking', categories: [PlaceCategory.nature, PlaceCategory.activity]),
    TaxonomyNode(keyword: 'ski', categories: [PlaceCategory.nature, PlaceCategory.activity]),
    TaxonomyNode(keyword: 'nature', categories: [PlaceCategory.nature],
        synonyms: ['outdoor', 'outdoors', 'green']),
    TaxonomyNode(keyword: 'gym', categories: [PlaceCategory.activity],
        synonyms: ['fitness', 'workout']),
    TaxonomyNode(keyword: 'yoga', categories: [PlaceCategory.activity]),
    TaxonomyNode(
      keyword: 'activity',
      categories: [
        PlaceCategory.activity,
        PlaceCategory.nature,
        PlaceCategory.nightlife,
      ],
      synonyms: [
        'activities',
        'thing to do',
        'things to do',
        'fun',
        'entertainment',
      ],
    ),
    // Shopping
    TaxonomyNode(keyword: 'shopping', categories: [PlaceCategory.shopping],
        synonyms: ['shop', 'stores']),
    TaxonomyNode(keyword: 'mall', categories: [PlaceCategory.shopping],
        synonyms: ['shopping mall', 'centre']),
    TaxonomyNode(keyword: 'market', categories: [PlaceCategory.shopping]),
  ];

  /// Resolve search query to categories (smart taxonomy).
  static List<PlaceCategory> categoriesForQuery(String query) {
    if (query.trim().isEmpty) return PlaceCategory.values;
    final lower = query.toLowerCase().trim();
    final categories = <PlaceCategory>{};
    for (final node in nodes) {
      final matchKeyword = node.keyword.contains(lower) || lower.contains(node.keyword);
      final matchSynonym = node.synonyms.any((s) => s.contains(lower) || lower.contains(s));
      if (matchKeyword || matchSynonym) {
        categories.addAll(node.categories);
      }
    }
    return categories.isEmpty ? PlaceCategory.values : categories.toList();
  }

  static String categoryLabel(PlaceCategory c) {
    return c.name[0].toUpperCase() + c.name.substring(1);
  }
}
