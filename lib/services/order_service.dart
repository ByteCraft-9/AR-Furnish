import 'package:ar_furnish/models/order.dart' as app_models;
import 'package:ar_furnish/models/product.dart';
import 'package:ar_furnish/providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get ordersCollection => _firestore.collection('orders');

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Get all orders for current user
  Stream<List<app_models.Order>> getUserOrdersStream() {
    try {
      final userId = _getCurrentUserId();

      return ordersCollection
          .where('userId', isEqualTo: userId)
          // Comment out the orderBy until the index is created
          .orderBy('orderDate', descending: true)
          .snapshots()
          .map((snapshot) {
        final orders =
            snapshot.docs.map((doc) => _orderFromDocument(doc)).toList();

        // Sort in memory instead
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        return orders;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      return Stream.value([]);
    }
  }

  // Get user orders as Future (for backward compatibility)
  Future<List<app_models.Order>> getUserOrders() async {
    try {
      final userId = _getCurrentUserId();
      final snapshot = await ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => _orderFromDocument(doc)).toList();
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Get a single order by ID
  Future<app_models.Order?> getOrderById(String id) async {
    try {
      final doc = await ordersCollection.doc(id).get();
      if (doc.exists) {
        return _orderFromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Create order from Firestore document
  app_models.Order _orderFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse items from Firestore
    final List<CartItem> items = (data['items'] as List)
        .map((item) => CartItem(
              product: _productFromOrderItem(item as Map<String, dynamic>),
              quantity: item['quantity'],
            ))
        .toList();

    // Parse status
    app_models.OrderStatus status =
        _parseOrderStatus(data['status'] ?? 'pending');

    // Parse date
    DateTime orderDate;
    if (data['orderDate'] is Timestamp) {
      orderDate = (data['orderDate'] as Timestamp).toDate();
    } else {
      orderDate = DateTime.now();
    }

    return app_models.Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: items,
      total: (data['total'] ?? 0).toDouble(),
      orderDate: orderDate,
      status: status,
      shippingAddress: data['shippingAddress'] ?? '',
      trackingNumber: data['trackingNumber'],
      currency: data['currency'] ?? 'PKR',
    );
  }

  // Helper to create a product from order item data
  Product _productFromOrderItem(Map<String, dynamic> item) {
    return Product(
      id: item['productId'],
      name: item['productName'] ?? '',
      description: '',
      color: '',
      price: (item['price'] ?? 0).toDouble(),
      images: [item['image'] ?? ''],
      featureImage: item['image'] ?? '',
      category: '',
      rating: 0,
      reviewCount: 0,
    );
  }

  // Parse order status from string
  app_models.OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return app_models.OrderStatus.pending;
      case 'processing':
        return app_models.OrderStatus.processing;
      case 'shipped':
        return app_models.OrderStatus.shipped;
      case 'delivered':
        return app_models.OrderStatus.delivered;
      case 'cancelled':
        return app_models.OrderStatus.cancelled;
      default:
        return app_models.OrderStatus.pending;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(
      String orderId, app_models.OrderStatus status) async {
    try {
      String statusString;
      switch (status) {
        case app_models.OrderStatus.pending:
          statusString = 'pending';
          break;
        case app_models.OrderStatus.processing:
          statusString = 'processing';
          break;
        case app_models.OrderStatus.shipped:
          statusString = 'shipped';
          break;
        case app_models.OrderStatus.delivered:
          statusString = 'delivered';
          break;
        case app_models.OrderStatus.cancelled:
          statusString = 'cancelled';
          break;
      }

      await ordersCollection.doc(orderId).update({
        'status': statusString,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel an order if within 24 hours
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final orderDoc = await ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderDate = (orderData['orderDate'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(orderDate);

      // Check if order is within 24 hours
      if (difference.inHours <= 24) {
        await ordersCollection.doc(orderId).update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationReason': 'Cancelled by user within 24 hours',
        });

        return {
          'success': true,
          'message': 'Order cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              'Orders can only be cancelled within 24 hours. Please contact the manager for cancellation.',
        };
      }
    } catch (e) {
      print('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Failed to cancel order: $e',
      };
    }
  }
}
