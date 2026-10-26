import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/category_image.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_state.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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

        final currentSegment = segments.firstWhere(
          (s) => s.name == state.selectedSegment,
          orElse: () => segments.first,
        );

        final catNames = currentSegment.categoryNames;

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
              // Horizontal Segments Bar
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: segments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final seg = segments[index];
                    final isSelected = seg.name == state.selectedSegment;
                    final totalCount = seg.categoryNames.fold<int>(
                      0,
                      (sum, cat) => sum + state.products.where((p) => p.category == cat).length,
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

              const SizedBox(height: 14),

              // Categories Grid
              Expanded(
                child: GridView.builder(
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
                    final count = state.products.where((p) => p.category == cat).length;
                    final imgPath = state.categoryImages[cat];
                    final fallback = categoryImageFallback(state.products, cat, imgPath);

                    return GestureDetector(
                      onTap: () {
                        context.read<CatalogCubit>().selectCategory(cat);
                        context.read<ShellCubit>().select(AppTab.home);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderPink, width: 1.5),
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

