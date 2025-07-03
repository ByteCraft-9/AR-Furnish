import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Create a rating notification for an order
  Future<void> createRatingNotification({
    required String orderId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final userId = _getCurrentUserId();
      final timestamp = DateTime.now();

      // Add notification for each product
      for (final product in products) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'userId': userId,
          'type': 'rating',
          'title': 'Rate Your Purchase',
          'message': 'How would you rate ${product['productName']}?',
          'read': false,
          'timestamp': timestamp,
          'data': {
            'orderId': orderId,
            'productId': product['productId'],
            'productName': product['productName'],
            'rated': false,
          },
        });
      }
    } catch (e) {
      print('Error creating rating notification: $e');
      throw Exception('Failed to create rating notification: $e');
    }
  }

  // Submit a product rating
  Future<void> submitProductRating({
    required String notificationId,
    required String productId,
    required double rating,
  }) async {
    try {
      final userId = _getCurrentUserId();

      // Start a batch
      final batch = _firestore.batch();

      // 1. Update the notification as rated
      final notificationRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);

      batch.update(notificationRef, {
        'read': true,
        'data.rated': true,
      });

      // 2. Add the rating to the product
      final productRef = _firestore.collection('products').doc(productId);

      // Get the current product data
      final productDoc = await productRef.get();

      if (productDoc.exists) {
        final data = productDoc.data() as Map<String, dynamic>;
        final currentRating = data['rating'] ?? 0.0;
        final reviewCount = data['review_count'] ?? 0;

        // Calculate new average rating
        final newReviewCount = reviewCount + 1;
        final totalRatingPoints = (currentRating * reviewCount) + rating;
        final newRating = totalRatingPoints / newReviewCount;

        // Update product with new rating
        batch.update(productRef, {
          'rating': newRating,
          'review_count': newReviewCount,
        });
      } else {
        // If product doesn't exist, just set the rating
        batch.update(productRef, {
          'rating': rating,
          'review_count': 1,
        });
      }

      // 3. Record this rating in user's ratings collection
      final ratingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc(productId);

      batch.set(ratingRef, {
        'productId': productId,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Commit all the changes
      await batch.commit();
    } catch (e) {
      print('Error submitting product rating: $e');
      throw Exception('Failed to submit product rating: $e');
    }
  }

  // Check if user has already rated a product
  Future<bool> hasUserRatedProduct(String productId) async {
    try {
      final userId = _getCurrentUserId();

      final ratingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .doc(productId)
          .get();

      return ratingDoc.exists;
    } catch (e) {
      print('Error checking if user rated product: $e');
      return false;
    }
  }
}
