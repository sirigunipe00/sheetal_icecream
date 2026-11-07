import 'package:flutter/material.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';

class CustomerOrderItem {
  const CustomerOrderItem({
    this.id,
    this.orderId,
    this.productId,
    this.variantId,
    required this.productName,
    required this.unitLabel,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.imageUrl,
  });

  final int? id;
  final String? orderId;
  final int? productId;
  final int? variantId;
  final String productName;
  final String unitLabel;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final String? imageUrl;

  factory CustomerOrderItem.fromMap(Map<String, dynamic> map) {
    return CustomerOrderItem(
      id: map['id'] is num ? (map['id'] as num).toInt() : null,
      orderId: map['order_id']?.toString(),
      productId: map['product_id'] is num ? (map['product_id'] as num).toInt() : null,
      variantId: map['variant_id'] is num ? (map['variant_id'] as num).toInt() : null,
      productName: map['product_name']?.toString() ?? 'Ice Cream',
      unitLabel: map['unit_label']?.toString() ?? '',
      unitPrice: map['unit_price'] is num ? (map['unit_price'] as num).round() : 0,
      quantity: map['quantity'] is num ? (map['quantity'] as num).toInt() : 1,
      lineTotal: map['line_total'] is num ? (map['line_total'] as num).round() : 0,
      imageUrl: map['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (variantId != null && variantId! > 0) 'variant_id': variantId,
      'product_name': productName,
      'unit_label': unitLabel,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.handlingFee,
    required this.total,
    required this.customerName,
    required this.customerPhone,
    required this.addressText,
    this.addressLabel = 'Home',
    this.etaMinutes = 30,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String userId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int subtotal;
  final int deliveryFee;
  final int handlingFee;
  final int total;
  final String customerName;
  final String customerPhone;
  final String addressText;
  final String? addressLabel;
  final int etaMinutes;
  final DateTime createdAt;
  final List<CustomerOrderItem> items;

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] ?? map['order_items'];
    final itemsList = <CustomerOrderItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          itemsList.add(CustomerOrderItem.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final id = map['id']?.toString() ?? '';
    final orderNum = map['order_number']?.toString() ??
        (id.length > 8 ? 'SHT${id.substring(0, 6).toUpperCase()}' : 'SHT100000');

    return CustomerOrder(
      id: id,
      orderNumber: orderNum,
      userId: map['user_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'placed',
      paymentMethod: map['payment_method']?.toString() ?? 'cod',
      paymentStatus: map['payment_status']?.toString() ?? 'pending',
      subtotal: map['subtotal'] is num ? (map['subtotal'] as num).round() : 0,
      deliveryFee: map['delivery_fee'] is num ? (map['delivery_fee'] as num).round() : 0,
      handlingFee: map['handling_fee'] is num ? (map['handling_fee'] as num).round() : 0,
      total: map['total'] is num
          ? (map['total'] as num).round()
          : (map['grand_total'] is num ? (map['grand_total'] as num).round() : 0),
      customerName: map['customer_name']?.toString() ?? '',
      customerPhone: map['customer_phone']?.toString() ?? '',
      addressText: map['address_text']?.toString() ??
          map['delivery_address']?.toString() ??
          '',
      addressLabel: map['address_label']?.toString() ?? 'Home',
      etaMinutes: map['eta_minutes'] is num ? (map['eta_minutes'] as num).toInt() : 30,
      createdAt: parsedDate,
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_number': orderNumber,
      'user_id': userId,
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'handling_fee': handlingFee,
      'total': total,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': addressText,
      'items': items.map((i) => i.toMap()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts this order to the legacy in-memory [StoreOrder] format
  StoreOrder toStoreOrder() {
    final lines = items.isNotEmpty
        ? items.map((i) => '${i.quantity} × ${i.productName} (${i.unitLabel})').toList()
        : <String>['Order #$orderNumber'];

    return StoreOrder(
      number: orderNumber,
      date: formattedDateShort,
      lines: lines,
      total: total,
      address: '$customerName, $customerPhone\n$addressText',
      payment: paymentMethod == 'cod' ? 'Cash on Delivery' : 'Online',
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Order Placed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'placed':
        return const Color(0xFF2563EB); // Vibrant Blue
      case 'preparing':
        return const Color(0xFFD97706); // Amber
      case 'out_for_delivery':
        return const Color(0xFF7C3AED); // Purple
      case 'delivered':
        return const Color(0xFF16A34A); // Green
      case 'cancelled':
        return const Color(0xFFDC2626); // Red
      default:
        return Colors.grey;
    }
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[createdAt.month - 1];
    final d = createdAt.day.toString().padLeft(2, '0');
    final y = createdAt.year;
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final min = createdAt.minute.toString().padLeft(2, '0');
    final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$d $m $y, $hour:$min $ampm';
  }

  String get formattedDateShort {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[createdAt.month - 1];
    return '$m ${createdAt.day}, ${createdAt.year}';
  }
}

