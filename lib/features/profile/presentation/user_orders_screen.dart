import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/order.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/features/orders/presentation/order_date_filter.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  String? _error;

  OrderDateFilter _selectedFilter = OrderDateFilter.all;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final remote = await SupabaseService.instance.fetchUserOrders();
      if (!mounted) return;
      setState(() {
        _orders = remote;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<CustomerOrder> _filteredOrders(List<StoreOrder> localFallback) {
    List<CustomerOrder> list = _orders;

    // If Supabase returned empty, map local in-memory StoreOrder items
    if (list.isEmpty && localFallback.isNotEmpty) {
      list = localFallback.map((s) {
        return CustomerOrder(
          id: s.number,
          orderNumber: s.number,
          userId: SupabaseService.instance.currentUserId,
          status: 'placed',
          paymentMethod: s.payment.toLowerCase().contains('cash') ? 'cod' : 'online',
          paymentStatus: 'pending',
          subtotal: s.total,
          deliveryFee: 0,
          handlingFee: 0,
          total: s.total,
          customerName: s.address.split('\n').first,
          customerPhone: '',
          addressText: s.address,
          createdAt: DateTime.now(),
          items: s.lines.map((l) => CustomerOrderItem(
            productName: l,
            unitLabel: '',
            unitPrice: 0,
            quantity: 1,
            lineTotal: 0,
          )).toList(),
        );
      }).toList();
    }

    return list.where((o) => _selectedFilter.matches(o.createdAt, _customRange)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localOrders = context.watch<OrdersCubit>().state;
    final filtered = _filteredOrders(localOrders);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.royalPurple, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order history',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.royalPurple),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Bar
          OrderDateFilterBar(
            selectedFilter: _selectedFilter,
            customRange: _customRange,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            onCustomRangeChanged: (range) => setState(() => _customRange = range),
          ),

          // Count Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilter == OrderDateFilter.all
                      ? 'All orders (${filtered.length})'
                      : 'Filtered orders (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softMuted,
                  ),
                ),
                if (_selectedFilter != OrderDateFilter.all)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = OrderDateFilter.all;
                        _customRange = null;
                      });
                    },
                    child: const Text(
                      'Clear filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _CustomerOrderCard(order: filtered[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _selectedFilter != OrderDateFilter.all;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              hasFilter ? Icons.event_busy_rounded : Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasFilter ? 'No orders in this date range' : 'No past orders yet',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Try selecting a different date range or clear the filter.'
              : (_error != null
                  ? 'Could not connect to orders server. Showing local records if available.'
                  : 'Your delicious ice cream orders will show up here once placed!'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.softMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: hasFilter
              ? OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = OrderDateFilter.all;
                      _customRange = null;
                    });
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    context.read<ShellCubit>().select(AppTab.home);
                  },
                  icon: const Icon(Icons.icecream_rounded, size: 18),
                  label: const Text('Start Shopping'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.royalPurple,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: order.statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: order.statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: order.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.softMuted),
              const SizedBox(width: 4),
              Text(
                order.formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.softMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                order.paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.royalPurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.linePink),
          const SizedBox(height: 10),

          // Items List
          if (order.items.isNotEmpty) ...[
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity} × ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.unitLabel.isNotEmpty
                            ? '${item.productName} (${item.unitLabel})'
                            : item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepInk,
                        ),
                      ),
                    ),
                    if (item.lineTotal > 0)
                      Text(
                        '₹${item.lineTotal}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.royalPurple,
                        ),
                      ),
                  ],
                ),
              ),
          ] else ...[
            Text(
              order.addressText.isNotEmpty ? order.addressText : 'Items placed via COD',
              style: const TextStyle(fontSize: 12.5, color: AppColors.deepInk),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.linePink),
          const SizedBox(height: 10),

          // Total & Delivery Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.softMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.addressText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.softMuted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Paid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.softMuted,
                    ),
                  ),
                  Text(
                    '₹${order.total}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
