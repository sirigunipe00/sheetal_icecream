import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/features/auth/presentation/auth_bottom_sheet.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  User? get _currentUser {
    if (!SupabaseGate.ready) return null;
    return Supabase.instance.client.auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final isLoggedIn = user != null;
    final displayName = user?.userMetadata?['display_name'] as String? ??
        user?.email?.split('@').first ??
        'Guest';
    final email = user?.email ?? 'Not signed in';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderPink),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isLoggedIn ? AppColors.brandGradient : null,
                      color: isLoggedIn ? null : const Color(0xFFF3E5F5),
                    ),
                    child: Center(
                      child: isLoggedIn
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isLoggedIn ? displayName : 'Guest User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepInk,
                                ),
                              ),
                            ),
                            if (isLoggedIn) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.royalPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MEMBER',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.royalPurple,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isLoggedIn ? email : 'Sign in to sync your cart & track orders',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.softMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  if (!isLoggedIn)
                    ElevatedButton(
                      onPressed: () {
                        AuthBottomSheet.show(context, onSuccess: () {
                          setState(() {});
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Account & Orders
            const Text(
              'ACCOUNT & ORDERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.softMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            _MenuTile(
              icon: Icons.receipt_long_rounded,
              title: 'Order history',
              subtitle: 'Past ice cream orders & receipts',
              onTap: () => _showOrders(context),
            ),
            _MenuTile(
              icon: Icons.location_on_outlined,
              title: 'Saved addresses',
              subtitle: 'Delivery locations',
              onTap: () {
                if (!isLoggedIn) {
                  AuthBottomSheet.show(context, onSuccess: () => setState(() {}));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No saved addresses yet.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 18),

            const Text(
              'PREFERENCES & SUPPORT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.softMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            _MenuTile(
              icon: Icons.headset_mic_outlined,
              title: 'Help & support',
              subtitle: 'Customer care: +91 73000 51000',
              onTap: () => _showHelpSupport(context),
            ),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              title: 'About Sheetal Ice Cream',
              subtitle: '32+ years of pure dairy heritage',
              onTap: () => _showAboutSheetal(context),
            ),

            // Order Notifications switch
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.borderPink.withValues(alpha: 0.6)),
                ),
                child: SwitchListTile(
                value: _notifications,
                onChanged: (val) => setState(() => _notifications = val),
                title: const Text(
                  'Order Notifications',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepInk,
                  ),
                ),
                subtitle: const Text(
                  'Updates when scoop is dispatched',
                  style: TextStyle(fontSize: 11, color: AppColors.softMuted),
                ),
                activeColor: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log Out Button (Only visible if logged in)
            if (isLoggedIn)
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFE53935)),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOrders(BuildContext context) {
    final orders = context.read<OrdersCubit>().state;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orders yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'Order history',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.royalPurple,
              ),
            ),
            const SizedBox(height: 12),
            for (final order in orders)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderPink),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.number, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(order.date, style: const TextStyle(color: AppColors.softMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final line in order.lines) Text(line),
                    const SizedBox(height: 6),
                    Text('Total ₹${order.total}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(order.address, style: const TextStyle(fontSize: 12, color: AppColors.softMuted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.royalPurple),
            ),
            const SizedBox(height: 14),
            const Text(
              'Need assistance with your Sheetal Ice Cream order? We are here 24x7 with our instant melt replacement guarantee.',
              style: TextStyle(fontSize: 13, color: AppColors.softMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: AppColors.primary),
              title: const Text('Customer Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('+91 73000 51000', style: TextStyle(fontSize: 13)),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.royalPurple),
              title: const Text('Email Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('chatwithus@sheetalfoodworld.com', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAboutSheetal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Sheetal Ice Cream',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.royalPurple),
            ),
            SizedBox(height: 12),
            Text(
              'Passion for Perfect Taste\n\nBorn from a passion for quality food, Sheetal offers delicious, authentic, and affordable ice creams made from 100% pure milk.\n\n• 32+ Years of Heritage\n• 100+ Exclusive Franchises\n• Pure Dairy Ingredients',
              style: TextStyle(fontSize: 13.5, color: AppColors.deepInk, height: 1.6),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.borderPink.withValues(alpha: 0.6)),
        ),
        child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.deepInk),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.softMuted)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black26),
        ),
      ),
    );
  }
}
