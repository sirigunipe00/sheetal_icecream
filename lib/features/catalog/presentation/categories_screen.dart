import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/category_image.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_state.dart';
import 'package:sheetal_icecream/features/catalog/presentation/category_products_view.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        final segments = state.segments;
        if (segments.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: state.loading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Text(
                      state.error ?? 'No categories yet.',
                      style: const TextStyle(color: AppColors.softMuted),
                    ),
            ),
          );
        }

        final opened = state.openedCategory;
        if (opened != null) {
          return CategoryProductsView(category: opened);
        }

        final currentSegment = segments.firstWhere(
          (s) => s.name == state.selectedSegment,
          orElse: () => segments.first,
        );

        final catNames = currentSegment.categoryNames.where((cat) {
          if (_query.isEmpty) return true;
          return cat.toLowerCase().contains(_query);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.royalPurple,
              ),
            ),
            centerTitle: false,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: segments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final seg = segments[index];
                    final isSelected = seg.name == state.selectedSegment;
                    final totalCount = seg.categoryNames.fold<int>(
                      0,
                      (sum, cat) =>
                          sum + state.products.where((p) => p.category == cat).length,
                    );

                    return GestureDetector(
                      onTap: () {
                        context.read<CatalogCubit>().selectSegment(seg.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.linePink,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${seg.name} · $totalCount',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.deepInk,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    key: const Key('categories-search-field'),
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.deepInk,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search categories',
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
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: AppColors.softMuted,
                              onPressed: () {
                                _search.clear();
                                _onSearch('');
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

              Expanded(
                child: catNames.isEmpty
                    ? const Center(
                        child: Text(
                          'No categories match your search.',
                          style: TextStyle(color: AppColors.softMuted),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: catNames.length,
                        itemBuilder: (context, index) {
                          final cat = catNames[index];
                          final count =
                              state.products.where((p) => p.category == cat).length;
                          final imgPath = state.categoryImages[cat];
                          final fallback =
                              categoryImageFallback(state.products, cat, imgPath);

                          return GestureDetector(
                            onTap: () {
                              context.read<CatalogCubit>().openCategory(cat);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.borderPink,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 82,
                                    height: 82,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.ringGradient,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: CategoryImage(
                                        imageUrl: imgPath,
                                        fallbackUrl: fallback,
                                        label: cat,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    cat,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.royalPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count products',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.softMuted,
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
          ),
        );
      },
    );
  }
}
