import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/category_image.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/presentation/widgets/product_card.dart';
import 'package:sheetal_icecream/features/profile/presentation/profile_bottom_sheet.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _openCategoryPage(String category) {
    context.read<CatalogCubit>().openCategory(category);
    context.read<ShellCubit>().select(AppTab.categories);
  }

  void _selectCategory(String category) {
    context.read<CatalogCubit>().selectCategory(category);
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToGrid() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      600,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogCubit>().state;
    final cart = context.watch<CartCubit>().state;
    final isSearching = catalog.query.trim().isNotEmpty;
    final isCategoryFiltered = catalog.category != 'All';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // 1. Sheetal Magenta Delivery Header (with pure white logo)
          const SliverToBoxAdapter(child: _DeliveryHeader()),

          // 2. Search Bar with category selection option when a category is selected
          SliverToBoxAdapter(
            child: _SearchBar(
              controller: _search,
              onQuery: context.read<CatalogCubit>().search,
              showCategorySelection: isCategoryFiltered || isSearching,
              categories: catalog.categories,
              selectedCategory: catalog.category,
              onCategory: _selectCategory,
            ),
          ),

          // When searching or filtering by a category, show only results grid
          if (!isSearching && !isCategoryFiltered) ...[
            // 3. Hero Promo Banner
            SliverToBoxAdapter(
              child: _HeroBanner(onShopNow: _scrollToGrid),
            ),

            // 4. Shop by Category Circular Rings (Only category view on home screen)
            SliverToBoxAdapter(
              child: _ShopByCategory(
                onCategory: _openCategoryPage,
                selectedCategory: catalog.category,
                categories: catalog.categories,
                categoryImages: catalog.categoryImages,
                products: catalog.products,
              ),
            ),

            // 5. Best Sellers Section
            SliverToBoxAdapter(
              child: _BestSellersBar(
                products: catalog.bestSellers,
                cart: cart,
              ),
            ),

            // 6. New Arrivals Section
            SliverToBoxAdapter(
              child: _NewArrivalsBar(
                products: catalog.newArrivals,
                cart: cart,
              ),
            ),

            // 7. Special Offers Banners
            SliverToBoxAdapter(
              child: _SpecialOffers(onExplore: _scrollToGrid),
            ),
          ],

          // 8. Section Header (All ice creams or Selected Category)
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: isSearching
                  ? 'Search results'
                  : catalog.category == 'All'
                      ? 'All ice creams'
                      : catalog.category,
              countLabel: '${catalog.visible.length} items',
            ),
          ),

          // 9. Main Products Grid
          if (catalog.loading && catalog.products.isEmpty)
            const SliverToBoxAdapter(child: _CatalogStatus(loading: true))
          else if (catalog.error != null && catalog.products.isEmpty)
            SliverToBoxAdapter(
              child: _CatalogStatus(
                message: catalog.error!,
                onRetry: () => context.read<CatalogCubit>().loadFromSupabase(),
              ),
            )
          else if (catalog.visible.isEmpty)
            const SliverToBoxAdapter(child: _EmptySearch())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 248,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = catalog.visible[index];
                    return ProductCard(
                      key: ValueKey('product-${product.id}'),
                      product: product,
                      quantity: cart.quantityOf(product.id),
                      onIncrement: () =>
                          context.read<CartCubit>().increment(product.id),
                      onDecrement: () =>
                          context.read<CartCubit>().decrement(product.id),
                    );
                  },
                  childCount: catalog.visible.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Delivery Header (Sheetal Magenta Header with WHITE Logo)
// ---------------------------------------------------------------------------
class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sheetal Logo (white logo so it clearly pops on magenta background)
              Image.asset(
                'assets/images/logo_white.webp',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/logo.png',
                  color: Colors.white,
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sheetal',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'ICE CREAM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white70,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Icon Button
              const _ProfileButton(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Delivering to HSR Layout',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 10 minutes badge (required by test and prototype)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚡ ', style: TextStyle(fontSize: 10)),
                    Text(
                      '10 minutes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile and Account',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('profile-button'),
          onTap: () => ProfileBottomSheet.show(context),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Search Bar (matching prototype line 43)
// ---------------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onQuery,
    required this.showCategorySelection,
    required this.categories,
    required this.selectedCategory,
    required this.onCategory,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQuery;
  final bool showCategorySelection;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            height: 48,
            child: TextField(
              key: const Key('search-field'),
              controller: controller,
              onChanged: onQuery,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.deepInk,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search your favourite ice cream',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.softMuted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.softMuted,
                  size: 20,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: AppColors.softMuted,
                        onPressed: () {
                          controller.clear();
                          onQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFFFF8FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.linePink, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.linePink, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (showCategorySelection)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => onCategory(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.brandGradient : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.linePink,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && cat != 'All') ...[
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.deepInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Hero Promo Banner (from prototype line 44)
// ---------------------------------------------------------------------------
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShopNow});

  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1FA), Color(0xFFF1EAFB)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.linePink, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.royalPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SHEETAL ICE CREAMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Passion for\nPerfect Taste',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepInk,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onShopNow,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text(
                          'Shop now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/slider-novelties.png',
            width: 115,
            height: 115,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/purity_milk.png',
              width: 115,
              height: 115,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Shop by Category Circular Rings (from prototype line 45)
// ---------------------------------------------------------------------------
class _ShopByCategory extends StatelessWidget {
  const _ShopByCategory({
    required this.onCategory,
    required this.selectedCategory,
    required this.categories,
    required this.categoryImages,
    required this.products,
  });

  final ValueChanged<String> onCategory;
  final String selectedCategory;
  final List<String> categories;
  final Map<String, String> categoryImages;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final cats = categories.where((cat) => cat != 'All').toList();
    if (cats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Shop by category',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = cats[index];
              final img = categoryImages[cat];
              final fallback = categoryImageFallback(products, cat, img);
              final isSelected = cat == selectedCategory;

              return GestureDetector(
                onTap: () => onCategory(cat),
                child: SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected
                              ? AppColors.brandGradient
                              : AppColors.ringGradient,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: CategoryImage(
                            imageUrl: img,
                            fallbackUrl: fallback,
                            label: cat,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.deepInk,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Best Sellers Section (from prototype line 46)
// ---------------------------------------------------------------------------
class _BestSellersBar extends StatelessWidget {
  const _BestSellersBar({
    required this.products,
    required this.cart,
  });

  final List<Product> products;
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Best sellers',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
                  key: ValueKey('best-seller-${product.id}'),
                  product: product,
                  quantity: cart.quantityOf(product.id),
                  onIncrement: () =>
                      context.read<CartCubit>().increment(product.id),
                  onDecrement: () =>
                      context.read<CartCubit>().decrement(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6. New Arrivals Section (from prototype line 47)
// ---------------------------------------------------------------------------
class _NewArrivalsBar extends StatelessWidget {
  const _NewArrivalsBar({
    required this.products,
    required this.cart,
  });

  final List<Product> products;
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'New arrivals',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
                  key: ValueKey('new-arrival-${product.id}'),
                  product: product,
                  quantity: cart.quantityOf(product.id),
                  onIncrement: () =>
                      context.read<CartCubit>().increment(product.id),
                  onDecrement: () =>
                      context.read<CartCubit>().decrement(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Special Offers Banners (from prototype line 48)
// ---------------------------------------------------------------------------
class _SpecialOffers extends StatelessWidget {
  const _SpecialOffers({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Special offers',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Promo 1: Free Delivery above ₹199
              GestureDetector(
                onTap: onExplore,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD43375), Color(0xFFE86A9C)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Free delivery above ₹199',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'On your favorite treats',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/slider-cake.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Promo 2: New Cookies Sandwich
              GestureDetector(
                onTap: onExplore,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF583090), Color(0xFF7A4FC0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'New: Cookies Sandwich',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try it today',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/slider-novelties.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Section Title & Empty Search
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.countLabel});

  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
          Text(
            countLabel,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.softMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({this.loading = false, this.message, this.onRetry});

  final bool loading;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
      child: Column(
        children: [
          if (loading)
            const CircularProgressIndicator(color: AppColors.primary)
          else ...[
            Text(
              message ?? 'No ice creams yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.softMuted,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 110),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.softMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No ice creams match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.softMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<CatalogCubit>().search('');
                context.read<CatalogCubit>().selectCategory('All');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Show all ice creams'),
            ),
          ],
        ),
      ),
    );
  }
}
