import 'package:flutter/material.dart';

import 'package:sheetal_icecream/core/theme/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (quantity <= 0) {
      return _AddButton(onPressed: onIncrement, compact: compact);
    }

    final scheme = Theme.of(context).colorScheme;
    final side = compact ? 34.0 : 40.0;
    final height = compact ? 40.0 : 44.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            label: '−',
            semanticsLabel: 'Decrease quantity',
            onPressed: onDecrement,
            width: side,
            height: height,
            color: scheme.onPrimary,
          ),
          SizedBox(
            width: 18,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          _StepButton(
            label: '+',
            semanticsLabel: 'Increase quantity',
            onPressed: onIncrement,
            width: side,
            height: height,
            color: scheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: scheme.secondary,
        backgroundColor: scheme.surface,
        minimumSize: Size(compact ? 64 : 72, compact ? 40 : 44),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.secondary, width: 1.5),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: const Text('ADD'),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.color,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(label, style: TextStyle(color: color, fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
