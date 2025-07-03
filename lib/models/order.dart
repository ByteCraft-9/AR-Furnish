import 'package:ar_furnish/providers/cart_provider.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime orderDate;
  final OrderStatus status;
  final String shippingAddress;
  final String? trackingNumber;
  final String currency;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
    this.trackingNumber,
    this.currency = 'PKR',
  });

  Order copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? total,
    DateTime? orderDate,
    OrderStatus? status,
    String? shippingAddress,
    String? trackingNumber,
    String? currency,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      currency: currency ?? this.currency,
    );
  }

  // Helper method to get status string
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get status color
  int get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return 0xFFFFA000; // Amber
      case OrderStatus.processing:
        return 0xFF2196F3; // Blue
      case OrderStatus.shipped:
        return 0xFF9C27B0; // Purple
      case OrderStatus.delivered:
        return 0xFF4CAF50; // Green
      case OrderStatus.cancelled:
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
