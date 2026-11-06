import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/features/admin/presentation/admin_orders_screen.dart';
import 'package:sheetal_icecream/features/admin/presentation/inventory_screen.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

enum AdminTab { inventory, orders, account }

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _tab = AdminTab.inventory;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _tab.index,
          children: const [
            InventoryScreen(embedded: true),
            AdminOrdersScreen(),
            _AdminAccountScreen(),
          ],
        ),
        bottomNavigationBar: Material(
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
                    _AdminNavButton(
                      label: 'Inventory',
                      icon: Icons.inventory_2_outlined,
                      selected: _tab == AdminTab.inventory,
                      onTap: () => setState(() => _tab = AdminTab.inventory),
                    ),
                    _AdminNavButton(
                      label: 'Orders',
                      icon: Icons.receipt_long_rounded,
                      selected: _tab == AdminTab.orders,
                      onTap: () => setState(() => _tab = AdminTab.orders),
                    ),
                    _AdminNavButton(
                      label: 'Account',
                      icon: Icons.admin_panel_settings_outlined,
                      selected: _tab == AdminTab.account,
                      onTap: () => setState(() => _tab = AdminTab.account),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavButton extends StatelessWidget {
  const _AdminNavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.softMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAccountScreen extends StatelessWidget {
  const _AdminAccountScreen();

  @override
  Widget build(BuildContext context) {
    final user = SupabaseGate.ready
        ? Supabase.instance.client.auth.currentUser
        : null;
    final email = user?.email ?? 'Admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderPink),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.softMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.royalPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.royalPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Manage catalogue stock & customer orders from this panel. '
            'The shopping home is hidden for admin accounts.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.softMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                // SessionRoot listens to auth and switches to the shop shell.
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
              label: const Text(
                'Log out',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
