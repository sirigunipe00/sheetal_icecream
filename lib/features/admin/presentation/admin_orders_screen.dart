import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/order.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/features/orders/presentation/order_date_filter.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<CustomerOrder> _orders = [];
  bool _loading = true;
  String? _remoteError;

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
      _remoteError = null;
    });

    try {
      final remote = await SupabaseService.instance.fetchAdminOrders();
      if (!mounted) return;
      setState(() {
        _orders = remote;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _remoteError = e.toString();
      });
    }
  }

  Future<void> _changeStatus(CustomerOrder order, String newStatus) async {
    try {
      await SupabaseService.instance.updateOrderStatus(order.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderNumber} updated to $newStatus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<CustomerOrder> _filteredOrders(List<StoreOrder> localFallback) {
    List<CustomerOrder> list = _orders;

    // Fallback to local in-memory orders if remote is empty
    if (list.isEmpty && localFallback.isNotEmpty) {
      list = localFallback.map((s) {
        return CustomerOrder(
          id: s.number,
          orderNumber: s.number,
          userId: 'local_device',
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
    final local = context.watch<OrdersCubit>().state;
    final filtered = _filteredOrders(local);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.royalPurple),
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

          // Count & Status Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilter == OrderDateFilter.all
                      ? 'Total Orders: ${filtered.length}'
                      : 'Filtered Orders: ${filtered.length}',
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
                      'Clear Filter',
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

          const SizedBox(height: 6),

          // List
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
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return _AdminOrderCard(
                              order: order,
                              onStatusChanged: (newStatus) => _changeStatus(order, newStatus),
                            );
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
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              hasFilter ? Icons.event_busy_rounded : Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasFilter ? 'No orders match this date range' : 'No orders found',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.deepInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasFilter
              ? 'Select another date range or tap clear to view all orders.'
              : (_remoteError == null
                  ? 'Customer orders placed via COD will appear here.'
                  : 'Could not load orders from Supabase:\n$_remoteError'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.softMuted,
            height: 1.4,
          ),
        ),
        if (hasFilter) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = OrderDateFilter.all;
                  _customRange = null;
                });
              },
              child: const Text('Clear Filter'),
            ),
          ),
        ],
      ],
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.onStatusChanged,
  });

  final CustomerOrder order;
  final ValueChanged<String> onStatusChanged;

  void _showStatusDialog(BuildContext context) {
    const statuses = [
      ('placed', 'Order Placed'),
      ('preparing', 'Preparing'),
      ('out_for_delivery', 'Out for Delivery'),
      ('delivered', 'Delivered'),
      ('cancelled', 'Cancelled'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Update Status: #${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.royalPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                for (final (key, label) in statuses)
                  ListTile(
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight: order.status == key ? FontWeight.w800 : FontWeight.w500,
                        color: order.status == key ? AppColors.primary : AppColors.deepInk,
                      ),
                    ),
                    trailing: order.status == key
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (order.status != key) {
                        onStatusChanged(key);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number & Clickable Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.royalPurple,
                ),
              ),
              InkWell(
                onTap: () => _showStatusDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: order.statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: order.statusColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: order.statusColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_drop_down, size: 16, color: order.statusColor),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.softMuted),
              const SizedBox(width: 5),
              Text(
                order.formattedDate,
                style: const TextStyle(fontSize: 12, color: AppColors.softMuted),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.linePink),
          const SizedBox(height: 10),

          // Customer Info
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.royalPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerName.isNotEmpty ? order.customerName : 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              if (order.customerPhone.isNotEmpty) ...[
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),

          if (order.addressText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppColors.softMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.addressText,
                    style: const TextStyle(fontSize: 12, color: AppColors.softMuted),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Items
          if (order.items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.unitLabel.isNotEmpty
                                  ? '${item.productName} (${item.unitLabel})'
                                  : item.productName,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (item.lineTotal > 0)
                            Text(
                              '₹${item.lineTotal}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 13,
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
    );
  }
}
