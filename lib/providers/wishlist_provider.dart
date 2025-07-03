import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ar_furnish/models/product.dart';

class WishlistProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final Set<int> _productIds = {};
  final Map<int, Product> _products = {};
  bool _isLoading = false;

  List<Product> get products => _products.values.toList();
  bool get isLoading => _isLoading;

  WishlistProvider() {
    initialize();
  }

  bool isInWishlist(int productId) => _productIds.contains(productId);

  Future<void> loadWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('wishlists').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final productIds = List<int>.from(data['product_ids'] ?? []);

        if (productIds.isNotEmpty) {
          // Clear existing data before loading new data
          _productIds.clear();
          _products.clear();

          // Add all product IDs to the set
          _productIds.addAll(productIds);

          // Get products in batches to handle potential large wishlists
          final batches = <List<int>>[];
          for (var i = 0; i < productIds.length; i += 10) {
            batches.add(
              productIds.sublist(
                i,
                i + 10 > productIds.length ? productIds.length : i + 10,
              ),
            );
          }

          // Fetch product details for each batch
          for (final batch in batches) {
            try {
              final productsSnapshot = await _firestore
                  .collection('products')
                  .where(FieldPath.documentId,
                      whereIn: batch.map((id) => id.toString()).toList())
                  .get();

              for (var doc in productsSnapshot.docs) {
                final data = doc.data();
                data['id'] = int.parse(doc.id); // Ensure ID is properly set
                final product = Product.fromFirestore(data);
                _products[product.id] = product;
              }
            } catch (e) {
              print('Error fetching products batch: $e');
            }
          }
        }
      } else {
        // Create empty wishlist document for new users
        await _firestore.collection('wishlists').doc(user.uid).set({
          'product_ids': [],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        _productIds.clear();
        _products.clear();
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update local state first for immediate feedback
      final isRemove = _productIds.contains(product.id);

      if (isRemove) {
        _productIds.remove(product.id);
        _products.remove(product.id);
      } else {
        _productIds.add(product.id);
        _products[product.id] = product;
      }
      notifyListeners();

      // Update Firestore
      final docRef = _firestore.collection('wishlists').doc(user.uid);
      await docRef.set({
        'product_ids': _productIds.toList(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Rollback on error
      final isRemove = !_productIds.contains(product.id);

      if (isRemove) {
        _productIds.add(product.id);
        _products[product.id] = product;
      } else {
        _productIds.remove(product.id);
        _products.remove(product.id);
      }

      notifyListeners();
      print('Error updating wishlist: $e');
    }
  }

  Future<void> initialize() async {
    // Wait for Firebase Auth to initialize
    await Future.delayed(Duration(milliseconds: 500));

    final user = _auth.currentUser;
    if (user != null) {
      await loadWishlist();
    }

    // Add listener for auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadWishlist();
      } else {
        _productIds.clear();
        _products.clear();
        notifyListeners();
      }
    });
  }
}
