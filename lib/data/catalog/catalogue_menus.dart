/// Sheetal catalogue menus → product categories (DB `products.category` names).
/// Order matches the client catalogue index.
class CatalogueMenus {
  const CatalogueMenus._();

  /// Display order of menu sections on Home / Categories.
  static const menuOrder = <String>[
    'Ice Cream Menu',
    'Milk Menu',
    'Namkeen Menu',
    'Frozen Products',
  ];

  /// Each category appears once under its primary menu.
  static const Map<String, List<String>> categoriesByMenu = {
    'Ice Cream Menu': [
      'Natural Cup',
      'Jumbo Cup',
      'Big Cup',
      'Ripple Special',
      'Jamel Lassi',
      'Kulfi',
      'Candy',
      'Cone',
      'Freezo Cone',
      'Gully Gola',
      'Novelties',
      'Cake & Pastry',
      'Home Pack Tub',
      '750ml Tub',
      'Family Pack',
    ],
    'Milk Menu': [
      'Milk',
      'Buttermilk',
      'Dahi',
      'Ghee',
      'Paneer & Butter',
      'Flavoured Milk',
      'Sweets',
      'Shrikhand',
      'Chocolate',
    ],
    'Namkeen Menu': [
      'Cookies',
      'Khari',
      'Rusk',
      'Cream Roll',
      'Bread',
      'Namkeen',
      'Wafers',
      'Banana Wafers',
      'Fryums',
      'Tea Time Snacks',
      'Popcorn',
      'Premium Cream Stix',
      'Premium Snacks',
      'Ready to Eat Kits',
    ],
    'Frozen Products': [
      'Paratha',
      'Naan',
      'French Fries',
      'Samosa',
      'Pizza',
      'Sandwich',
      'Ready to Eat Snacks',
      'Tikki',
      'Frozen Sweets',
      'Vegetables',
    ],
  };

  /// Short labels for tile UI (optional). Falls back to category name.
  static String tileLabel(String category) {
    const aliases = {
      'Home Pack Tub': 'Home Pack\nTub',
      '750ml Tub': '750ml Tub',
      'Family Pack': 'Family Pack',
      'Paneer & Butter': 'Paneer &\nButter',
      'Flavoured Milk': 'Flavoured\nMilk',
      'Premium Cream Stix': 'Cream Stix',
      'Premium Snacks': 'Premium\nSnacks',
      'Ready to Eat Kits': 'RTE Kits',
      'Ready to Eat Snacks': 'RTE Snacks',
      'French Fries': 'French Fries',
      'Frozen Sweets': 'Frozen\nSweets',
      'Banana Wafers': 'Banana\nWafers',
      'Tea Time Snacks': 'Tea Time\nSnacks',
      'Ripple Special': 'Ripple\nSpecial',
      'Cake & Pastry': 'Cake &\nPastry',
      'Freezo Cone': 'Freezo\nCone',
      'Gully Gola': 'Gully Gola',
      'Jamel Lassi': 'Jamel\nLassi',
    };
    return aliases[category] ?? category;
  }

  /// Build menu segments using only categories that exist in [available].
  static List<({String menu, List<String> categories})> menusWithProducts(
    Iterable<String> available,
  ) {
    final set = available.toSet();
    final result = <({String menu, List<String> categories})>[];
    for (final menu in menuOrder) {
      final cats = [
        for (final c in categoriesByMenu[menu] ?? const <String>[])
          if (set.contains(c)) c,
      ];
      // Also include any leftover DB categories that match loosely.
      if (cats.isEmpty) continue;
      result.add((menu: menu, categories: cats));
    }

    // Append unknown categories under "More" if any.
    final known = {
      for (final list in categoriesByMenu.values) ...list,
    };
    final extras = [
      for (final c in available)
        if (c != 'All' && !known.contains(c)) c,
    ]..sort();
    if (extras.isNotEmpty) {
      result.add((menu: 'More', categories: extras));
    }
    return result;
  }
}
