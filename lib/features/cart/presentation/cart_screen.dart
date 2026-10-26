import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/dashed_line.dart';
import 'package:sheetal_icecream/core/widgets/product_thumb.dart';
import 'package:sheetal_icecream/core/widgets/quantity_stepper.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_state.dart';
import 'package:sheetal_icecream/features/cart/presentation/checkout_screen.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;
    return SafeArea(
      bottom: false,
      child: cart.isEmpty ? const _EmptyCart() : _CartBody(cart: cart),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add delicious ice creams to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.read<ShellCubit>().select(AppTab.home),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.primary,
                side: BorderSide(color: scheme.primary, width: 1.5),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Browse products'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  const _CartBody({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text(
          'My cart',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              for (var i = 0; i < cart.lines.length; i++) ...[
                _CartLineTile(line: cart.lines[i]),
                if (i != cart.lines.length - 1)
                  Divider(height: 1, thickness: 1, color: colors.line),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(child: _Bill(cart: cart)),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('checkout-button'),
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      color: scheme.onPrimary,
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
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: child,
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ProductThumb(
            product: line.product,
            width: 48,
            height: 48,
            fontSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  line.product.unit,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: line.quantity,
            compact: true,
            onIncrement: () =>
                context.read<CartCubit>().increment(line.product.id),
            onDecrement: () =>
                context.read<CartCubit>().decrement(line.product.id),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              '₹${line.lineTotal}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        _BillRow(label: 'Item total', value: '₹${cart.subtotal}'),
        _BillRow(
          label: 'Delivery fee',
          value: cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee}',
        ),
        _BillRow(label: 'Handling fee', value: '₹${cart.handlingFee}'),
        const SizedBox(height: 4),
        DashedLine(color: colors.line, height: 1),
        const SizedBox(height: 10),
        _BillRow(label: 'To pay', value: '₹${cart.total}', emphasize: true),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
