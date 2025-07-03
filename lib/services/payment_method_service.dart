import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ar_furnish/screens/profile/payment_method.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentMethodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _stripeSecretKey =
      'sk_test_51R74fjRrW9QD4ume2OTuna7Uu2VI8qNYrig9O6lRx7GLn9K05kdZa3Gs53Hgxx3PFmV96Q0HECr5GX9hRmHaAL9a00sEr4kh8f';

  // Collection reference
  CollectionReference get paymentMethodsCollection =>
      _firestore.collection('paymentMethods');

  PaymentMethodService() {
    // No need to load from dotenv anymore
  }

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Get all payment methods for current user
  Stream<List<PaymentMethod>> getUserPaymentMethods() {
    try {
      final userId = _getCurrentUserId();
      return paymentMethodsCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => PaymentMethod.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching payment methods: $e');
      return Stream.value([]);
    }
  }

  // Create a Stripe Customer if one doesn't exist
  Future<String> _getOrCreateStripeCustomer() async {
    final userId = _getCurrentUserId();

    // First, check if customer exists in Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data()?['stripeCustomerId'] != null) {
      return userDoc.data()!['stripeCustomerId'];
    }

    // If no Stripe customer ID, create one
    final user = _auth.currentUser!;
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/customers'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'email': user.email,
        'name': user.displayName ?? 'Customer',
        'metadata[firebaseUserId]': userId,
      },
    );

    final responseData = jsonDecode(response.body);

    if (responseData['id'] != null) {
      // Save the Stripe customer ID to Firestore
      await _firestore.collection('users').doc(userId).set({
        'stripeCustomerId': responseData['id'],
      }, SetOptions(merge: true));

      return responseData['id'];
    } else {
      throw Exception(
          'Failed to create Stripe customer: ${responseData['error']['message']}');
    }
  }

  // Create a Stripe payment method
  Future<String> _createStripePaymentMethod(PaymentMethod method) async {
    // Instead of sending actual card details, use a test token
    // This is the recommended approach for testing with Stripe

    // Determine which test token to use based on the card number
    // These match Stripe's test cards: https://stripe.com/docs/testing
    String testToken;

    // Use different test tokens based on the card number pattern
    // This simulates different card types without sending real card data
    if (method.cardNumber.startsWith('4')) {
      // Visa test token
      testToken = 'tok_visa';
    } else if (method.cardNumber.startsWith('5')) {
      // Mastercard test token
      testToken = 'tok_mastercard';
    } else if (method.cardNumber.startsWith('3')) {
      // Amex test token
      testToken = 'tok_amex';
    } else if (method.cardNumber.startsWith('6')) {
      // Discover test token
      testToken = 'tok_discover';
    } else {
      // Default to Visa if can't determine card type
      testToken = 'tok_visa';
    }

    // Create a payment method in Stripe using the test token
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_methods'),
      headers: {
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'type': 'card',
        'card[token]': testToken,
        'billing_details[name]': method.cardHolder,
      },
    );

    final responseData = jsonDecode(response.body);

    if (responseData['id'] != null) {
      // Attach the payment method to the customer
      final customerId = await _getOrCreateStripeCustomer();

      final attachResponse = await http.post(
        Uri.parse(
            'https://api.stripe.com/v1/payment_methods/${responseData['id']}/attach'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
        },
      );

      final attachData = jsonDecode(attachResponse.body);

      if (attachData['id'] != null) {
        return responseData['id'];
      } else {
        throw Exception(
            'Failed to attach payment method: ${attachData['error']['message']}');
      }
    } else {
      throw Exception(
          'Failed to create payment method: ${responseData['error']['message']}');
    }
  }

  // Add new payment method
  Future<void> addPaymentMethod(PaymentMethod method) async {
    try {
      // Create a payment method in Stripe
      final stripePaymentMethodId = await _createStripePaymentMethod(method);

      // Check if this is the first payment method (set as default)
      final methods = await paymentMethodsCollection
          .where('userId', isEqualTo: method.userId)
          .get();

      final isDefault = methods.docs.isEmpty;

      // Create a map with the updated payment method
      final updatedMethod = PaymentMethod(
        id: method.id,
        cardNumber: method.cardNumber,
        cardHolder: method.cardHolder,
        expiryDate: method.expiryDate,
        cvv: method.cvv,
        type: method.type,
        userId: method.userId,
        stripePaymentMethodId: stripePaymentMethodId,
        isDefault: isDefault,
      );

      // Add to Firestore
      await paymentMethodsCollection.add(updatedMethod.toMap());
    } catch (e) {
      print('Error adding payment method: $e');
      throw Exception('Failed to add payment method: $e');
    }
  }

  // Set a payment method as default
  Future<void> setDefaultPaymentMethod(String id) async {
    try {
      final userId = _getCurrentUserId();

      // Clear existing default payment methods
      final batch = _firestore.batch();
      final defaultMethods = await paymentMethodsCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();

      for (var doc in defaultMethods.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set the new default
      batch.update(paymentMethodsCollection.doc(id), {'isDefault': true});

      await batch.commit();
    } catch (e) {
      print('Error setting default payment method: $e');
      throw Exception('Failed to set default payment method: $e');
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String id) async {
    try {
      final methodDoc = await paymentMethodsCollection.doc(id).get();
      if (!methodDoc.exists) {
        throw Exception('Payment method not found');
      }

      final data = methodDoc.data() as Map<String, dynamic>?;
      final stripePaymentMethodId = data?['stripePaymentMethodId'];

      if (stripePaymentMethodId != null) {
        // Detach from Stripe
        try {
          await http.post(
            Uri.parse(
                'https://api.stripe.com/v1/payment_methods/$stripePaymentMethodId/detach'),
            headers: {
              'Authorization': 'Bearer $_stripeSecretKey',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );
        } catch (e) {
          print('Warning: Failed to detach payment method from Stripe: $e');
          // Continue with deletion even if Stripe detach fails
        }
      }

      // Delete from Firestore
      await paymentMethodsCollection.doc(id).delete();

      // If this was the default method, set a new one if available
      if (data?['isDefault'] == true) {
        final methods = await paymentMethodsCollection
            .where('userId', isEqualTo: _getCurrentUserId())
            .limit(1)
            .get();

        if (methods.docs.isNotEmpty) {
          await setDefaultPaymentMethod(methods.docs.first.id);
        }
      }
    } catch (e) {
      print('Error deleting payment method: $e');
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Get default payment method for current user
  Future<PaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final userId = _getCurrentUserId();
      final snapshot = await paymentMethodsCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return PaymentMethod.fromDocument(snapshot.docs.first);
      } else {
        // If no default, return the first payment method if available
        final allMethods = await paymentMethodsCollection
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (allMethods.docs.isNotEmpty) {
          return PaymentMethod.fromDocument(allMethods.docs.first);
        }
      }
      return null;
    } catch (e) {
      print('Error getting default payment method: $e');
      return null;
    }
  }

  // Update existing payment method
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    try {
      // First delete the old Stripe payment method if it exists
      final methodDoc = await paymentMethodsCollection.doc(method.id).get();
      if (!methodDoc.exists) {
        throw Exception('Payment method not found');
      }

      final data = methodDoc.data() as Map<String, dynamic>?;
      final oldStripePaymentMethodId = data?['stripePaymentMethodId'];

      if (oldStripePaymentMethodId != null) {
        // Detach from Stripe
        try {
          await http.post(
            Uri.parse(
                'https://api.stripe.com/v1/payment_methods/$oldStripePaymentMethodId/detach'),
            headers: {
              'Authorization': 'Bearer $_stripeSecretKey',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          );
        } catch (e) {
          print('Warning: Failed to detach old payment method from Stripe: $e');
          // Continue with update even if Stripe detach fails
        }
      }

      // Create a new Stripe payment method
      final stripePaymentMethodId = await _createStripePaymentMethod(method);

      // Update the payment method in Firestore
      final updatedMethod = PaymentMethod(
        id: method.id,
        cardNumber: method.cardNumber,
        cardHolder: method.cardHolder,
        expiryDate: method.expiryDate,
        cvv: method.cvv,
        type: method.type,
        userId: method.userId,
        stripePaymentMethodId: stripePaymentMethodId,
        isDefault: data?['isDefault'] ?? false,
      );

      await paymentMethodsCollection
          .doc(method.id)
          .update(updatedMethod.toMap());
    } catch (e) {
      print('Error updating payment method: $e');
      throw Exception('Failed to update payment method: $e');
    }
  }
}
