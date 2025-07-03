import 'package:ar_furnish/data/dummy_data.dart';
import 'package:ar_furnish/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('is_enabled', isEqualTo: true)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        final product = Product(
          id: data['id'] is int
              ? data['id']
              : int.parse(data['id']), // Ensure id is an int
          name: data['name'] ?? 'Unknown Product', // Default name
          description: data['description'] ?? '',
          color: data['color'] ?? 'Unknown', // Default color
          price: (data['price'] as num).toDouble(),
          images:
              List<String>.from(data['images'] ?? []), // Default to empty list
          featureImage: data['feature_image'] ?? '',
          category: data['category'] ?? 'General', // Default category
          rating: (data['rating'] as num).toDouble(),
          reviewCount: (data['review_count'] as num).toInt(),
          isEnabled: data['is_enabled'] ?? true,
        );

        // Debug product information
        print(
            'Product loaded: ${product.name}, Category: ${product.category}, Color: ${product.color}, Price: ${product.price}, Enabled: ${product.isEnabled}');

        return product;
      }).toList();

      print('Total products loaded: ${products.length}');
      return products;
    } catch (e) {
      print("Error fetching products: $e");
      return []; // Return an empty list on error
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('is_enabled', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      print("Error fetching products by category: $e");
      return []; // Return an empty list on error
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('is_enabled', isEqualTo: true)
          .get();
      final searchTerm = query.toLowerCase();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .where((product) => product.name.toLowerCase().contains(searchTerm))
          .toList();
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  Future<Product?> getProductById(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final productJson =
          DummyData.products.firstWhere((product) => product['id'] == id);
      return Product.fromJson(productJson);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> getEnabledProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('is_enabled', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching enabled products: $e");
      return []; // Return an empty list on error
    }
  }
}
