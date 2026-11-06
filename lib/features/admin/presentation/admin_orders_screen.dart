import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<_AdminOrder> _remote = const [];
  bool _loading = true;
  String? _remoteError;

  @override
  void initState() {
    super.initState();
    _loadRemote();
  }

  Future<void> _loadRemote() async {
    setState(() {
      _loading = true;
      _remoteError = null;
    });
    if (!SupabaseGate.ready) {
      setState(() {
        _loading = false;
        _remote = const [];
      });
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      final rows = <_AdminOrder>[];
      for (final raw in data as List) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        rows.add(_AdminOrder.fromMap(map));
      }
      if (!mounted) return;
      setState(() {
        _remote = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _remoteError = e.toString();
        _remote = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = context.watch<OrdersCubit>().state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.royalPurple,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadRemote,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRemote,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _buildList(local),
      ),
    );
  }

  Widget _buildList(List<StoreOrder> local) {
    if (_remote.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _remote.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = _remote[index];
          return _OrderCard(
            title: order.title,
            subtitle: order.subtitle,
            trailing: order.trailing,
            body: order.body,
          );
        },
      );
    }

    if (local.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: local.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              _remoteError == null
                  ? 'Showing orders placed on this device (no remote orders table rows yet).'
                  : 'Remote orders unavailable. Showing local device orders.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.softMuted,
              ),
            );
          }
          final order = local[index - 1];
          return _OrderCard(
            title: order.number,
            subtitle: '${order.date} · ${order.payment}',
            trailing: '₹${order.total}',
            body: [...order.lines, order.address],
          );
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: AppColors.softMuted,
        ),
        const SizedBox(height: 12),
        const Text(
          'No orders yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.deepInk,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _remoteError == null
              ? 'Customer orders will appear here once checkout saves them to Supabase.'
              : 'Could not load remote orders.\n$_remoteError',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.softMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _AdminOrder {
  const _AdminOrder({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final List<String> body;

  factory _AdminOrder.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? map['order_number']?.toString() ?? 'Order';
    final status = map['status']?.toString() ?? map['payment_status']?.toString() ?? '';
    final created = map['created_at']?.toString() ?? '';
    final total = map['total'] ?? map['grand_total'] ?? map['amount'];
    final totalText = total == null ? '' : '₹${(total as num).round()}';
    final body = <String>[];
    if (map['user_id'] != null) body.add('User: ${map['user_id']}');
    if (map['payment_method'] != null) {
      body.add('Payment: ${map['payment_method']}');
    }
    if (map['delivery_address'] != null) {
      body.add('${map['delivery_address']}');
    }
    return _AdminOrder(
      title: id.length > 12 ? 'Order ${id.substring(0, 8)}…' : 'Order $id',
      subtitle: [
        if (status.isNotEmpty) status,
        if (created.isNotEmpty) created.split('.').first.replaceFirst('T', ' '),
      ].join(' · '),
      trailing: totalText,
      body: body,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepInk,
                  ),
                ),
              ),
              if (trailing.isNotEmpty)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.royalPurple,
                  ),
                ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.softMuted),
            ),
          ],
          for (final line in body) ...[
            const SizedBox(height: 4),
            Text(
              line,
              style: const TextStyle(fontSize: 12, color: AppColors.deepInk),
            ),
          ],
        ],
      ),
    );
  }
}
