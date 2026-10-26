import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController(text: 'HSR Layout, Bengaluru');
  String _payment = 'cod';
  String? _nameError;
  String? _phoneError;
  String? _addressError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _placeOrder() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    final nameError = name.isEmpty ? 'Please enter your name.' : null;
    final phoneError = RegExp(r'^[6-9]\d{9}$').hasMatch(phone)
        ? null
        : 'Enter a valid 10-digit mobile number.';
    final addressError =
        address.isEmpty ? 'Please add a delivery address.' : null;
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _addressError = addressError;
    });
    if (nameError != null || phoneError != null || addressError != null) {
      return;
    }

    final cart = context.read<CartCubit>().state;
    if (cart.isEmpty) return;

    final order = StoreOrder(
      number: 'SHT${100000 + Random().nextInt(900000)}',
      date: _today(),
      lines: [
        for (final line in cart.lines)
          '${line.quantity} × ${line.product.name} (${line.product.unit})',
      ],
      total: cart.total,
      address: address,
      payment: _payment == 'cod' ? 'Cash on Delivery' : 'Online (demo)',
    );
    context.read<OrdersCubit>().add(order);
    context.read<CartCubit>().clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
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
          TextField(
            controller: _address,
            minLines: 2,
            maxLines: 3,
            decoration: _field('Flat, street, area', _addressError),
          ),
          const SizedBox(height: 14),
          const Text(
            'Full name',
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
            'Phone number',
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
                onTap: cart.isEmpty ? null : _placeOrder,
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: Text(
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
