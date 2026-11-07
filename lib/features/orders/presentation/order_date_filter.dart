import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';

enum OrderDateFilter {
  all,
  today,
  yesterday,
  last7Days,
  thisMonth,
  custom,
}

extension OrderDateFilterExt on OrderDateFilter {
  String get label {
    switch (this) {
      case OrderDateFilter.all:
        return 'All';
      case OrderDateFilter.today:
        return 'Today';
      case OrderDateFilter.yesterday:
        return 'Yesterday';
      case OrderDateFilter.last7Days:
        return 'Last 7 Days';
      case OrderDateFilter.thisMonth:
        return 'This Month';
      case OrderDateFilter.custom:
        return 'Custom Date';
    }
  }

  bool matches(DateTime date, DateTimeRange? customRange) {
    final now = DateTime.now();
    switch (this) {
      case OrderDateFilter.all:
        return true;
      case OrderDateFilter.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case OrderDateFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;
      case OrderDateFilter.last7Days:
        final sevenDaysAgo = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
        return date.isAfter(sevenDaysAgo);
      case OrderDateFilter.thisMonth:
        return date.year == now.year && date.month == now.month;
      case OrderDateFilter.custom:
        if (customRange == null) return true;
        final start = DateTime(
          customRange.start.year,
          customRange.start.month,
          customRange.start.day,
        );
        final end = DateTime(
          customRange.end.year,
          customRange.end.month,
          customRange.end.day,
          23,
          59,
          59,
        );
        return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
            (date.isBefore(end) || date.isAtSameMomentAs(end));
    }
  }
}

class OrderDateFilterBar extends StatelessWidget {
  const OrderDateFilterBar({
    super.key,
    required this.selectedFilter,
    required this.customRange,
    required this.onFilterChanged,
    required this.onCustomRangeChanged,
  });

  final OrderDateFilter selectedFilter;
  final DateTimeRange? customRange;
  final ValueChanged<OrderDateFilter> onFilterChanged;
  final ValueChanged<DateTimeRange?> onCustomRangeChanged;

  String _formatRange(DateTimeRange range) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final s = '${range.start.day} ${months[range.start.month - 1]}';
    final e = '${range.end.day} ${months[range.end.month - 1]}';
    return s == e ? s : '$s – $e';
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year, now.month, now.day + 1),
      initialDateRange: customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.royalPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onCustomRangeChanged(picked);
      onFilterChanged(OrderDateFilter.custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final filter in OrderDateFilter.values)
              if (filter != OrderDateFilter.custom)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: filter.label,
                    isSelected: selectedFilter == filter,
                    onTap: () => onFilterChanged(filter),
                  ),
                ),

            // Custom Date Range Chip
            _FilterChip(
              icon: Icons.calendar_month_rounded,
              label: (selectedFilter == OrderDateFilter.custom && customRange != null)
                  ? _formatRange(customRange!)
                  : 'Pick Date',
              isSelected: selectedFilter == OrderDateFilter.custom,
              showClear: selectedFilter == OrderDateFilter.custom,
              onClear: () {
                onCustomRangeChanged(null);
                onFilterChanged(OrderDateFilter.all);
              },
              onTap: () => _pickRange(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.showClear = false,
    this.onClear,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool showClear;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: showClear ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.brandGradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.borderPink,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : AppColors.royalPurple,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.royalPurple,
                ),
              ),
              if (showClear && onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppColors.linePink,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : AppColors.deepInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

