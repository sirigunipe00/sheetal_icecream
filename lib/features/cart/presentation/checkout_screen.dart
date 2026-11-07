import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/user_address.dart';
import 'package:sheetal_icecream/features/address/presentation/address_form_sheet.dart';
import 'package:sheetal_icecream/features/address/presentation/saved_addresses_sheet.dart';
import 'package:sheetal_icecream/features/auth/presentation/auth_bottom_sheet.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  UserAddress? _selectedAddress;
  List<UserAddress> _savedAddresses = [];
  bool _loadingAddresses = true;
  bool _submittingOrder = false;
  String _payment = 'cod';
  String? _nameError;
  String? _phoneError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    final list = await SupabaseService.instance.fetchAddresses();
    if (mounted) {
      setState(() {
        _savedAddresses = list;
        _loadingAddresses = false;
        if (list.isNotEmpty) {
          // Pre-select default address if available, otherwise first address
          final defaultAddr = list.firstWhere(
            (a) => a.isDefault,
            orElse: () => list.first,
          );
          _selectedAddress = defaultAddr;
          if (_name.text.isEmpty) _name.text = defaultAddr.recipientName;
          if (_phone.text.isEmpty) _phone.text = defaultAddr.phone;
          _addressError = null;
        } else {
          _selectedAddress = null;
        }
      });
    }
  }

  Future<void> _changeAddress() async {
    final picked = await SavedAddressesSheet.show(
      context,
      selectedAddressId: _selectedAddress?.id,
      isPicker: true,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedAddress = picked;
        _name.text = picked.recipientName;
        _phone.text = picked.phone;
        _addressError = null;
      });
      // Refresh address list in background
      final list = await SupabaseService.instance.fetchAddresses();
      if (mounted) setState(() => _savedAddresses = list);
    }
  }

  Future<void> _addAddress() async {
    final added = await AddressFormSheet.show(
      context,
      forceDefault: _savedAddresses.isEmpty,
    );
    if (added != null && mounted) {
      await _loadAddresses();
      setState(() {
        _selectedAddress = added;
        _name.text = added.recipientName;
        _phone.text = added.phone;
        _addressError = null;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!SupabaseService.instance.isSignedIn) {
      final signedIn = await AuthBottomSheet.requireAuth(
        context,
        title: 'Sign In to Order',
        subtitle: 'Please sign in to place your order and save delivery address',
        onAuthenticated: () {},
      );
      if (!signedIn) return;
      await _loadAddresses();
    }

    if (_selectedAddress == null) {
      setState(() => _addressError = 'Please select or add a delivery address.');
      await _addAddress();
      if (_selectedAddress == null) return;
    }

    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final nameError = name.isEmpty ? 'Please enter your name.' : null;
    final phoneError = RegExp(r'^[6-9]\d{9}$').hasMatch(phone)
        ? null
        : 'Enter a valid 10-digit mobile number.';

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _addressError = null;
    });
    if (nameError != null || phoneError != null) {
      return;
    }

    if (!mounted) return;
    final cart = context.read<CartCubit>().state;
    if (cart.isEmpty) return;

    setState(() => _submittingOrder = true);

    final formattedAddress = _selectedAddress!.formattedAddress;
    final orderNumber = 'SHT${100000 + Random().nextInt(900000)}';
    StoreOrder finalOrder;

    try {
      final customerOrder = await SupabaseService.instance.createOrder(
        orderNumber: orderNumber,
        customerName: name,
        customerPhone: phone,
        addressText: formattedAddress,
        addressLabel: _selectedAddress!.label,
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFee,
        handlingFee: cart.handlingFee,
        total: cart.total,
        paymentMethod: _payment,
        lines: cart.lines,
      );
      finalOrder = customerOrder.toStoreOrder();
    } catch (e) {
      debugPrint('[Order Save Error] Could not save to database: $e');
      finalOrder = StoreOrder(
        number: orderNumber,
        date: _today(),
        lines: [
          for (final line in cart.lines)
            '${line.quantity} × ${line.product.name} (${line.unitLabel})',
        ],
        total: cart.total,
        address: '$name, $phone\n$formattedAddress',
        payment: _payment == 'cod' ? 'Cash on Delivery' : 'Online (demo)',
      );
    }

    if (!mounted) return;
    context.read<OrdersCubit>().add(finalOrder);
    context.read<CartCubit>().clear();
    setState(() => _submittingOrder = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: finalOrder)),
    );
  }

  String _today() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.deepInk,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Delivery address',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _deliveryAddressCard(),
          const SizedBox(height: 14),
          const Text(
            'Recipient name',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _field('Your name', _nameError),
          ),
          const SizedBox(height: 14),
          const Text(
            'Contact phone number',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: _field('10-digit mobile number', _phoneError),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _PayOption(
            label: 'Cash on Delivery',
            selected: _payment == 'cod',
            onTap: () => setState(() => _payment = 'cod'),
          ),
          const SizedBox(height: 8),
          _PayOption(
            label: 'Online payment (simulated)',
            selected: _payment == 'online',
            onTap: () => setState(() => _payment = 'online'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.linePink),
            ),
            child: Column(
              children: [
                _Row(label: 'Items (${cart.itemCount})', value: '₹${cart.subtotal}'),
                _Row(
                  label: 'Delivery',
                  value: cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee}',
                ),
                _Row(label: 'Handling fee', value: '₹${cart.handlingFee}'),
                const Divider(),
                _Row(label: 'Total', value: '₹${cart.total}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('place-order'),
                borderRadius: BorderRadius.circular(12),
                onTap: (cart.isEmpty || _submittingOrder) ? null : _placeOrder,
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: _submittingOrder
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Place Order · ₹${cart.total}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryAddressCard() {
    if (_loadingAddresses) {
      return Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.linePink),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_selectedAddress == null) {
      return InkWell(
        onTap: _addAddress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _addressError != null ? const Color(0xFFD32F2F) : AppColors.linePink,
              width: _addressError != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Delivery Address',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.royalPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _addressError ?? 'Tap to enter your delivery location',
                      style: TextStyle(
                        fontSize: 12,
                        color: _addressError != null ? const Color(0xFFD32F2F) : AppColors.softMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.softMuted),
            ],
          ),
        ),
      );
    }

    final a = _selectedAddress!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                a.label.toLowerCase() == 'work'
                    ? Icons.business_rounded
                    : a.label.toLowerCase() == 'home'
                        ? Icons.home_rounded
                        : Icons.location_on_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                a.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.royalPurple,
                ),
              ),
              const SizedBox(width: 8),
              if (a.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _changeAddress,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${a.recipientName} • ${a.phone}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.deepInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.formattedAddress,
            style: const TextStyle(fontSize: 12, color: AppColors.softMuted, height: 1.3),
          ),
          if (_savedAddresses.length > 1 && !a.isDefault) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                await SupabaseService.instance.setDefaultAddress(a.id);
                await _loadAddresses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${a.label} is now your default delivery address'),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                '★ Set as my default address',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _field(String hint, String? error) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key, required this.order});

  final StoreOrder order;

  void _leave(BuildContext context, AppTab tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<ShellCubit>().select(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Order placed!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Order No. ${order.number}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.softMuted),
            ),
            const SizedBox(height: 16),
            _Summary(
              children: [
                for (final line in order.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line),
                  ),
                const Divider(),
                Text(
                  'Total (${order.payment})  ₹${order.total}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Summary(
              children: [
                const Text(
                  'Delivering to',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(order.address),
                const SizedBox(height: 10),
                const Text(
                  'Estimated delivery: 25–30 min',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _leave(context, AppTab.home),
              child: const Text('Continue Shopping'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _leave(context, AppTab.profile),
              child: const Text('View Order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.linePink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.linePink,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.softMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
