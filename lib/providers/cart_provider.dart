import 'package:flutter/foundation.dart';
import 'package:ar_furnish/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ar_furnish/services/stripe_service.dart';
import 'package:ar_furnish/services/notification_service.dart';

// Define the primary color to use throughout
const Color primaryColor = Color(0xFF854836);

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final Map<int, CartItem> _items = {};
  bool _isLoading = true;
  List<int> _selectedItemsForCheckout = [];
  String? _lastOrderId;

  // Payment processing states
  bool _isProcessingPayment = false;
  String? _paymentError;
  bool _paymentSuccess = false;

  Map<int, CartItem> get items => {..._items};
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get paymentError => _paymentError;
  bool get paymentSuccess => _paymentSuccess;
  String? get lastOrderId => _lastOrderId;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Get only the selected items for checkout
  Map<int, CartItem> get selectedItems {
    if (_selectedItemsForCheckout.isEmpty) {
      return {..._items}; // Return all items if none specifically selected
    }

    Map<int, CartItem> selected = {};
    for (int id in _selectedItemsForCheckout) {
      if (_items.containsKey(id)) {
        selected[id] = _items[id]!;
      }
    }
    return selected;
  }

  // Get total amount for selected items only
  double get selectedItemsTotal {
    if (_selectedItemsForCheckout.isEmpty) {
      return totalAmount; // Return total of all items if none specifically selected
    }

    double total = 0.0;
    for (int id in _selectedItemsForCheckout) {
      if (_items.containsKey(id)) {
        total += _items[id]!.totalPrice;
      }
    }
    return total;
  }

  // Set selected items for checkout
  void setSelectedItemsForCheckout(List<int> selectedIds) {
    _selectedItemsForCheckout = selectedIds;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await loadCart();

    _isLoading = false;
    notifyListeners();
  }

  // Process payment with Stripe
  Future<Map<String, dynamic>> processPayment({
    required String currency,
    String? customerId,
    required String merchantDisplayName,
  }) async {
    try {
      _isProcessingPayment = true;
      _paymentError = null;
      _paymentSuccess = false;
      notifyListeners();

      // Create an order in Firestore
      _lastOrderId = await _createOrder();

      // Process the payment with Stripe
      final paymentResult = await StripeService.processPayment(
        amount: selectedItemsTotal.toString(),
        currency: currency.toLowerCase(),
        customerId: customerId,
        merchantDisplayName: merchantDisplayName,
        description: 'Order #$_lastOrderId',
      );

      // Update payment status
      if (paymentResult['success']) {
        _paymentSuccess = true;

        // Update order status in Firestore
        await _updateOrderPaymentStatus(
            _lastOrderId!, 'paid', paymentResult['payment_intent']);

        // Create rating notifications for the purchased products
        await _createRatingNotifications(_lastOrderId!);

        // Clear cart after successful payment
        await clear();
      } else {
        _paymentError = paymentResult['message'];
        // Update order status in Firestore
        await _updateOrderPaymentStatus(_lastOrderId!, 'failed', null);
      }

      _isProcessingPayment = false;
      notifyListeners();
      return paymentResult;
    } catch (e) {
      _isProcessingPayment = false;
      _paymentError = e.toString();

      if (_lastOrderId != null) {
        // Update order status in Firestore
        await _updateOrderPaymentStatus(_lastOrderId!, 'failed', null);
      }

      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Create rating notifications for purchased products
  Future<void> _createRatingNotifications(String orderId) async {
    try {
      // Get purchased items
      final purchasedProducts = selectedItems.values
          .map((item) => {
                'productId': item.product.id.toString(),
                'productName': item.product.name,
                'quantity': item.quantity,
              })
          .toList();

      // Create rating notifications
      await _notificationService.createRatingNotification(
        orderId: orderId,
        products: purchasedProducts,
      );
    } catch (e) {
      print('Error creating rating notifications: $e');
      // Don't throw - this is a secondary operation
    }
  }

  // Create an order in Firestore
  Future<String> _createOrder() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Reference to collection
      final ordersRef = _firestore.collection('orders');

      // Create new order document
      final orderDoc = await ordersRef.add({
        'userId': user.uid,
        'items': selectedItems.values
            .map((item) => {
                  'productId': item.product.id.toString(),
                  'productName': item.product.name,
                  'quantity': item.quantity,
                  'unitPrice': item.product.price,
                  'totalPrice': item.totalPrice,
                })
            .toList(),
        'totalAmount': selectedItemsTotal,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return orderDoc.id;
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order payment status
  Future<void> _updateOrderPaymentStatus(
      String orderId, String status, String? paymentIntentId) async {
    try {
      final data = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (paymentIntentId != null) {
        data['paymentIntentId'] = paymentIntentId;
      }

      await _firestore.collection('orders').doc(orderId).update(data);
    } catch (e) {
      print('Error updating order status: $e');
      // Don't throw - this is a secondary operation
    }
  }

  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('cart').doc(user.uid).get();
      if (doc.exists) {
        List<dynamic> itemsData = doc['items'];
        _items.clear();

        // If there are no items, return early
        if (itemsData.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Convert string IDs to integers
        final productIds =
            itemsData.map((item) => int.parse(item['productId'])).toList();

        // Query using numeric product IDs
        final productsSnapshot = await _firestore
            .collection('products')
            .where('id', whereIn: productIds)
            .get();

        final products = productsSnapshot.docs
            .map((doc) => Product.fromFirestore(doc.data()))
            .toList();

        for (var itemData in itemsData) {
          final product = products.firstWhere(
            (p) => p.id == int.parse(itemData['productId']),
            orElse: () => Product(
              id: -1,
              name: '',
              description: '',
              color: '',
              price: 0,
              images: [],
              featureImage: '',
              category: '',
            ),
          );

          if (product.id != -1) {
            _items[product.id] = CartItem(
              product: product,
              quantity: itemData['quantity'],
            );
          }
        }
      }
    } catch (e) {
      print("Error loading cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartData = {
        'items': _items.values
            .map((item) => {
                  'productId': item.product.id.toString(),
                  'quantity': item.quantity
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('cart').doc(user.uid).set(cartData);
    } catch (e) {
      print("Error saving cart: $e");
    }
  }

  void addItem(Product product, [int quantity = 1]) {
    if (product.quantity == 0) {
      return; // Don't add if out of stock
    }

    if (_items.containsKey(product.id)) {
      // Check if adding more would exceed available quantity
      final currentQuantity = _items[product.id]!.quantity;
      final newQuantity = currentQuantity + quantity;

      if (newQuantity <= product.quantity) {
        _items.update(
          product.id,
          (existingItem) => CartItem(
            product: existingItem.product,
            quantity: newQuantity,
          ),
        );
      }
    } else {
      // Check if requested quantity is available
      if (quantity <= product.quantity) {
        _items.putIfAbsent(
          product.id,
          () => CartItem(
            product: product,
            quantity: quantity,
          ),
        );
      }
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    final item = _items[productId]!;
    if (newQuantity <= 0) {
      removeItem(productId);
    } else if (newQuantity <= item.product.quantity) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: newQuantity,
        ),
      );
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _selectedItemsForCheckout = [];

    // Also delete from Firebase completely
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Set an empty items array
        await _firestore.collection('cart').doc(user.uid).set({
          'items': [],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error clearing cart in Firebase: $e");
      }
    }

    notifyListeners();
  }

  // Reset payment state
  void resetPaymentState() {
    _isProcessingPayment = false;
    _paymentError = null;
    _paymentSuccess = false;
    _lastOrderId = null;
    notifyListeners();
  }

  // Check if cart is empty (excluding loading state)
  bool get isEmpty => !_isLoading && _items.isEmpty;
}

@immutable
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}
