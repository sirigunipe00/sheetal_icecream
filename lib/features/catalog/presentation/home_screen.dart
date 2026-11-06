import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/category_image.dart';
import 'package:sheetal_icecream/core/widgets/product_image.dart';
import 'package:sheetal_icecream/data/catalog/catalogue_menus.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/presentation/widgets/product_card.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';
import 'package:sheetal_icecream/services/device_location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String _deliveryLabel = 'Finding your location…';

  @override
  void initState() {
    super.initState();
    _loadDeliveryLocation();
  }

  Future<void> _loadDeliveryLocation() async {
    try {
      final label = await DeviceLocation.currentLabel();
      if (!mounted) return;
      setState(() => _deliveryLabel = label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deliveryLabel = 'Location unavailable');
    }
  }

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
          SliverToBoxAdapter(
            child: _DeliveryHeader(
              label: _deliveryLabel,
              onRetry: _loadDeliveryLocation,
            ),
          ),

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
            // 3. Hero Promo Banner Slider
            SliverToBoxAdapter(
              child: _HeroImageSlider(
                onShopNow: _scrollToGrid,
                onCategory: _openCategoryPage,
              ),
            ),

            // 4. Shop by Category — circular rings
            // SliverToBoxAdapter(
            //   child: _ShopByCategory(
            //     onCategory: _openCategoryPage,
            //     selectedCategory: catalog.category,
            //     categories: catalog.categories,
            //     categoryImages: catalog.categoryImages,
            //     products: catalog.products,
            //   ),
            // ),

            // 5. Menu sections (Blinkit-style 4-column category grids)
            SliverToBoxAdapter(
              child: _CatalogueMenuSections(
                products: catalog.products,
                categoryImages: catalog.categoryImages,
                onCategory: _openCategoryPage,
              ),
            ),

            // 6. Best Sellers Section
            SliverToBoxAdapter(
              child: _BestSellersBar(
                products: catalog.bestSellers,
                cart: cart,
              ),
            ),

            // 7. New Arrivals Section
            SliverToBoxAdapter(
              child: _NewArrivalsBar(
                products: catalog.newArrivals,
                cart: cart,
              ),
            ),

            // 8. Fresh Milk & Dairy (Fast Expire Daily Products)
            SliverToBoxAdapter(
              child: _FreshMilkBar(
                products: catalog.products,
                cart: cart,
                onSeeAll: () => _openCategoryPage('Milk'),
              ),
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
                      quantity: cart.quantityOfProduct(product.id),
                      onIncrement: () =>
                          context.read<CartCubit>().incrementProduct(product),
                      onDecrement: () =>
                          context.read<CartCubit>().decrementProduct(product.id),
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
  const _DeliveryHeader({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

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
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/logo.png',
                  color: Colors.white,
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Column(
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
              Expanded(
                child: GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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
          onTap: () {
    context.read<ShellCubit>().select(AppTab.profile);
  },
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
// 3. Hero Promo Banner Slider (Auto-playing image slider below search bar)
// ---------------------------------------------------------------------------
class _SlideItem {
  const _SlideItem({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageAsset,
    required this.gradient,
    required this.borderColor,
    this.category,
  });

  final String tag;
  final Color tagColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageAsset;
  final List<Color> gradient;
  final Color borderColor;
  final String? category;
}

const _heroSlides = [
  _SlideItem(
    tag: 'SHEETAL SPECIAL',
    tagColor: AppColors.royalPurple,
    title: 'Passion for\nPerfect Taste',
    subtitle: 'Pure dairy indulgence & rich sundaes',
    buttonText: 'Shop now',
    imageAsset: 'assets/images/slider-novelties.png',
    gradient: [Color(0xFFFFF1FA), Color(0xFFF1EAFB)],
    borderColor: Color(0xFFF3CEE6),
  ),
  _SlideItem(
    tag: 'ROYAL HERITAGE',
    tagColor: Color(0xFFC2410C),
    title: 'Authentic\nShahi Kulfi',
    subtitle: 'Rich creamy malai & crunchy pista',
    buttonText: 'Explore Kulfi',
    imageAsset: 'assets/images/slider-kulfi.png',
    gradient: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
    borderColor: Color(0xFFFED7AA),
    category: 'Kulfi',
  ),
  _SlideItem(
    tag: 'CRISPY WAFFLE',
    tagColor: AppColors.primary,
    title: 'Crunchy\nWaffle Cones',
    subtitle: 'Topped with roasted nuts & fudge',
    buttonText: 'Try Cones',
    imageAsset: 'assets/images/slider-cone.png',
    gradient: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
    borderColor: Color(0xFFFBCFE8),
    category: 'Cones',
  ),
  _SlideItem(
    tag: 'CELEBRATIONS',
    tagColor: Color(0xFF7C3AED),
    title: 'Ice Cream\nParty Cakes',
    subtitle: 'Sweeten every birthday & party',
    buttonText: 'Order Cake',
    imageAsset: 'assets/images/slider-cake.png',
    gradient: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
    borderColor: Color(0xFFDDD6FE),
    category: 'Cake',
  ),
  _SlideItem(
    tag: 'GUILT-FREE',
    tagColor: Color(0xFF15803D),
    title: '100% Guilt-Free\nSugar-Free',
    subtitle: 'Pure authentic taste with zero added sugar',
    buttonText: 'Discover',
    imageAsset: 'assets/images/slider-sugar-free.png',
    gradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
    borderColor: Color(0xFFBBF7D0),
    category: 'Sugar Free',
  ),
  _SlideItem(
    tag: 'FAMILY PACKS',
    tagColor: Color(0xFF0369A1),
    title: 'Delicious\nFamily Tubs',
    subtitle: 'Stock up your home freezer with joy',
    buttonText: 'Stock Up',
    imageAsset: 'assets/images/slider-take-home-1.png',
    gradient: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
    borderColor: Color(0xFFBAE6FD),
  ),
];

class _HeroImageSlider extends StatefulWidget {
  const _HeroImageSlider({
    required this.onShopNow,
    required this.onCategory,
  });

  final VoidCallback onShopNow;
  final ValueChanged<String> onCategory;

  @override
  State<_HeroImageSlider> createState() => _HeroImageSliderState();
}

class _HeroImageSliderState extends State<_HeroImageSlider> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % _heroSlides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: _heroSlides.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final slide = _heroSlides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: slide.gradient,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: slide.borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: slide.tagColor.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: slide.tagColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                slide.tag,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide.title,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepInk,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              slide.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.softMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    if (slide.category != null) {
                                      widget.onCategory(slide.category!);
                                    } else {
                                      widget.onShopNow();
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          slide.buttonText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Slide Image
                      SizedBox(
                        width: 118,
                        height: 118,
                        child: Image.asset(
                          slide.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/images/purity_milk.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroSlides.length, (idx) {
            final isActive = idx == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.borderPink.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Shop by Category Circular Rings
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.deepInk,
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
// 5. Catalogue menus — Blinkit-style 4-column category grids
// ---------------------------------------------------------------------------
class _CatalogueMenuSections extends StatelessWidget {
  const _CatalogueMenuSections({
    required this.products,
    required this.categoryImages,
    required this.onCategory,
  });

  final List<Product> products;
  final Map<String, String> categoryImages;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final available = {
      for (final p in products) p.category,
    };
    final menus = CatalogueMenus.menusWithProducts(available);
    if (menus.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final menu in menus) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              child: Text(
                menu.menu,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F1F1F),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menu.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final category = menu.categories[index];
                  final categoryProducts = products
                      .where((p) => p.category == category)
                      .toList();
                  return _MenuCategoryTile(
                    category: category,
                    products: categoryProducts,
                    imageUrl: categoryImages[category],
                    onTap: () => onCategory(category),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuCategoryTile extends StatelessWidget {
  const _MenuCategoryTile({
    required this.category,
    required this.products,
    required this.imageUrl,
    required this.onTap,
  });

  final String category;
  final List<Product> products;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = categoryImageFallback(products, category, imageUrl);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF2),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
              child: _CategoryProductCollage(
                products: products,
                imageUrl: imageUrl,
                fallbackUrl: fallback,
                label: category,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CatalogueMenus.tileLabel(category),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryProductCollage extends StatelessWidget {
  const _CategoryProductCollage({
    required this.products,
    required this.imageUrl,
    required this.fallbackUrl,
    required this.label,
  });

  final List<Product> products;
  final String? imageUrl;
  final String? fallbackUrl;
  final String label;

  List<Product> get _preview {
    final withImage = products
        .where((p) => p.image != null && p.image!.trim().isNotEmpty)
        .toList();
    final source = withImage.isNotEmpty ? withImage : products;
    return source.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _preview;
    if (items.isEmpty) {
      return CategoryImage(
        imageUrl: imageUrl,
        fallbackUrl: fallbackUrl,
        label: label,
        fontSize: 18,
      );
    }
    if (items.length == 1) {
      return ProductImage(product: items.first, showProgress: false);
    }

    // Blinkit-style: products sit side-by-side inside the soft tile.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (items.length == 2) {
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 0,
                bottom: h * 0.02,
                width: w * 0.56,
                height: h * 0.92,
                child: ProductImage(
                  product: items[0],
                  showProgress: false,
                ),
              ),
              Positioned(
                right: 0,
                bottom: h * 0.02,
                width: w * 0.56,
                height: h * 0.92,
                child: ProductImage(
                  product: items[1],
                  showProgress: false,
                ),
              ),
            ],
          );
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 0,
              bottom: h * 0.04,
              width: w * 0.42,
              height: h * 0.82,
              child: ProductImage(
                product: items[0],
                showProgress: false,
              ),
            ),
            Positioned(
              left: w * 0.29,
              bottom: h * 0.02,
              width: w * 0.42,
              height: h * 0.9,
              child: ProductImage(
                product: items[1],
                showProgress: false,
              ),
            ),
            Positioned(
              right: 0,
              bottom: h * 0.04,
              width: w * 0.42,
              height: h * 0.82,
              child: ProductImage(
                product: items[2],
                showProgress: false,
              ),
            ),
          ],
        );
      },
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
                  key: ValueKey('best-seller-${product.id}'),
                  product: product,
                  quantity: cart.quantityOfProduct(product.id),
                  onIncrement: () =>
                      context.read<CartCubit>().incrementProduct(product),
                  onDecrement: () =>
                      context.read<CartCubit>().decrementProduct(product.id),
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
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
                  key: ValueKey('new-arrival-${product.id}'),
                  product: product,
                  quantity: cart.quantityOfProduct(product.id),
                  onIncrement: () =>
                      context.read<CartCubit>().incrementProduct(product),
                  onDecrement: () =>
                      context.read<CartCubit>().decrementProduct(product.id),
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
// Fresh Milk & Dairy Section (Fast expiring daily essentials)
// ---------------------------------------------------------------------------
class _FreshMilkBar extends StatelessWidget {
  const _FreshMilkBar({
    required this.products,
    required this.cart,
    required this.onSeeAll,
  });

  final List<Product> products;
  final CartState cart;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    // Filter milk & dairy products (fast expiring daily essentials)
    final milkProducts = products.where((p) {
      final cat = p.category.trim().toLowerCase();
      return cat == 'milk' ||
          cat == 'buttermilk' ||
          cat == 'dahi' ||
          cat == 'paneer & butter' ||
          cat == 'flavoured milk' ||
          cat == 'milk & milk products';
    }).toList();

    if (milkProducts.isEmpty) return const SizedBox.shrink();

    // Sort to show pure Milk first, followed by Dahi, Buttermilk, Paneer, Flavoured Milk
    milkProducts.sort((a, b) {
      int rank(Product p) {
        final cat = p.category.trim().toLowerCase();
        if (cat == 'milk') return 0;
        if (cat == 'dahi') return 1;
        if (cat == 'buttermilk') return 2;
        if (cat == 'paneer & butter') return 3;
        if (cat == 'flavoured milk') return 4;
        return 5;
      }
      return rank(a).compareTo(rank(b));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Fresh Milk & Dairy',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 11, color: Color(0xFF2E7D32)),
                          SizedBox(width: 2),
                          Text(
                            'DAILY FRESH',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E7D32),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'Daily essentials delivered cold & fresh within 10 minutes',
            style: TextStyle(fontSize: 12, color: AppColors.softMuted),
          ),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: milkProducts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = milkProducts[index];
              return SizedBox(
                width: 158,
                child: ProductCard(
                  key: ValueKey('milk-product-${product.id}'),
                  product: product,
                  quantity: cart.quantityOfProduct(product.id),
                  onIncrement: () =>
                      context.read<CartCubit>().incrementProduct(product),
                  onDecrement: () =>
                      context.read<CartCubit>().decrementProduct(product.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
