import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blinkit_clone/core/theme/app_colors.dart';
import 'package:blinkit_clone/features/cart/cubit/cart_cubit.dart';
import 'package:blinkit_clone/features/cart/cubit/cart_state.dart';
import 'package:blinkit_clone/features/cart/presentation/cart_screen.dart';
import 'package:blinkit_clone/features/catalog/presentation/categories_screen.dart';
import 'package:blinkit_clone/features/catalog/presentation/home_screen.dart';
import 'package:blinkit_clone/features/catalog/presentation/wishlist_screen.dart';
import 'package:blinkit_clone/features/profile/presentation/profile_screen.dart';
import 'package:blinkit_clone/features/shell/cubit/shell_cubit.dart';
import 'package:blinkit_clone/features/shell/cubit/shell_state.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, ShellState>(
      builder: (context, shell) {
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.pageGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                IndexedStack(
                  index: shell.tab.index,
                  children: const [
                    HomeScreen(),
                    CategoriesScreen(),
                    WishlistScreen(),
                    CartScreen(),
                    ProfileScreen(),
                  ],
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: _CartBar(
                    visible: shell.tab == AppTab.home ||
                        shell.tab == AppTab.categories ||
                        shell.tab == AppTab.wishlist,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _BottomNav(current: shell.tab),
          ),
        );
      },
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, (int, int)>(
      selector: (state) => (state.itemCount, state.subtotal),
      builder: (context, selection) {
        final (count, subtotal) = selection;
        if (!visible || count == 0) return const SizedBox.shrink();
        final noun = count == 1 ? 'item' : 'items';
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('cart-bar'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.read<ShellCubit>().select(AppTab.cart),
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$count $noun · ₹$subtotal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.linePink)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavButton(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: current == AppTab.home,
                  onTap: () => context.read<ShellCubit>().select(AppTab.home),
                ),
                _NavButton(
                  label: 'Categories',
                  icon: Icons.grid_view_rounded,
                  selected: current == AppTab.categories,
                  onTap: () => context.read<ShellCubit>().select(AppTab.categories),
                ),
                _NavButton(
                  label: 'Wishlist',
                  icon: Icons.favorite_border_rounded,
                  selected: current == AppTab.wishlist,
                  onTap: () => context.read<ShellCubit>().select(AppTab.wishlist),
                ),
                _CartNavButton(selected: current == AppTab.cart),
                _NavButton(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  selected: current == AppTab.profile,
                  onTap: () => context.read<ShellCubit>().select(AppTab.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartNavButton extends StatelessWidget {
  const _CartNavButton({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) => state.itemCount,
      builder: (context, count) {
        return _NavButton(
          label: 'Cart',
          icon: Icons.shopping_cart_outlined,
          selected: selected,
          badgeCount: count,
          onTap: () => context.read<ShellCubit>().select(AppTab.cart),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.icon,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final int badgeCount;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.softMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) Icon(icon, size: 21, color: color),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.royalPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
