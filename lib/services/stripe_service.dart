import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  static String apiBase = 'https://api.stripe.com/v1';
  static String paymentApiUrl = '${apiBase}/payment_intents';
  static String publishableKey =
      'Your_Publishable_Key_Here'; // Replace with your actual publishable key
  static String secretKey =
      'Your_Secret_Key_Here'; // Replace with your actual secret key
  static String merchantCountryCode = 'US';

  // Initialize Stripe with your publishable key
  static Future<void> initialize() async {
    try {
      // Only set the publishable key
      stripe.Stripe.publishableKey = publishableKey;
      print('Stripe publishable key set successfully');
    } catch (e) {
      print('Error initializing Stripe: $e');
      // Don't throw exception to avoid crashing the app
    }
  }

  // Create a payment intent on the server
  static Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
    String customerId, {
    String? description,
  }) async {
    try {
      // Convert amount to the smallest currency unit (e.g., cents for USD)
      final amountInSmallestUnit =
          (double.parse(amount) * 100).round().toString();

      // First create a payment intent without confirming
      Map<String, dynamic> intentBody = {
        'amount': amountInSmallestUnit,
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        intentBody['description'] = description;
      }

      // Add customer if provided
      if (customerId.isNotEmpty) {
        intentBody['customer'] = customerId;
      }

      var intentResponse = await http.post(
        Uri.parse(paymentApiUrl),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: intentBody,
      );

      var paymentIntent =
          jsonDecode(intentResponse.body) as Map<String, dynamic>;

      if (paymentIntent.containsKey('error')) {
        throw Exception(paymentIntent['error']['message']);
      }

      // Create a payment method using a test token
      final paymentMethodResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_methods'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'card',
          'card[token]': 'tok_visa', // Use Stripe's test token
        },
      );

      final paymentMethod =
          jsonDecode(paymentMethodResponse.body) as Map<String, dynamic>;

      if (paymentMethod.containsKey('error')) {
        throw Exception(paymentMethod['error']['message']);
      }

      // Now confirm the payment intent with the payment method and return URL
      final confirmResponse = await http.post(
        Uri.parse('${paymentApiUrl}/${paymentIntent['id']}/confirm'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethod['id'],
          'return_url':
              'https://arfurnish.com/payment-success', // Use a real URL, not a custom scheme
        },
      );

      return jsonDecode(confirmResponse.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error creating payment intent: $e');
      // Return a properly formatted error response instead of rethrowing
      return {
        'error': {'message': e.toString()}
      };
    }
  }

  // Process a payment with Stripe Checkout (redirect flow)
  static Future<Map<String, dynamic>> processPaymentWithRedirect({
    required String amount,
    required String currency,
    String? customerId,
    required String merchantDisplayName,
    String? description,
  }) async {
    try {
      // Create a payment intent on the server
      final paymentIntent = await createPaymentIntent(
        amount,
        currency,
        customerId ?? '', // Use empty string if customerId is null
        description: description,
      );

      if (paymentIntent.containsKey('error')) {
        throw Exception(paymentIntent['error']['message']);
      }

      // Safely extract the checkout URL with null safety
      String? checkoutUrl;
      if (paymentIntent.containsKey('next_action')) {
        var nextAction = paymentIntent['next_action'];
        if (nextAction is Map && nextAction.containsKey('redirect_to_url')) {
          var redirectToUrl = nextAction['redirect_to_url'];
          if (redirectToUrl is Map && redirectToUrl.containsKey('url')) {
            checkoutUrl = redirectToUrl['url'] as String;
          }
        }
      }

      // If there's no checkout URL, create a checkout session instead
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        checkoutUrl = await _createCheckoutSession(amount, currency,
            customerId ?? '', description ?? 'Purchase from AR Furnish');
      }

      // Launch the URL
      final success = await _launchStripeCheckout(checkoutUrl);

      if (success) {
        return {
          'success': true,
          'payment_intent': paymentIntent['id'],
          'client_secret': paymentIntent['client_secret'],
          'message': 'Redirected to Stripe Checkout'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to open Stripe Checkout',
        };
      }
    } catch (e) {
      print('Error processing payment: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Create a checkout session
  static Future<String> _createCheckoutSession(String amount, String currency,
      String customerId, String description) async {
    try {
      // Convert amount to cents (or smallest unit)
      final amountInSmallestUnit = (double.parse(amount) * 100).round();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types[]': 'card',
          'mode': 'payment',
          'success_url':
              'https://arfurnish.com/payment-success', // Use a real URL instead of custom scheme
          'cancel_url':
              'https://arfurnish.com/payment-cancelled', // Use a real URL instead of custom scheme
          'line_items[0][price_data][currency]': currency,
          'line_items[0][price_data][product_data][name]': description,
          'line_items[0][price_data][unit_amount]':
              amountInSmallestUnit.toString(),
          'line_items[0][quantity]': '1',
        },
      );

      final responseData = jsonDecode(response.body);

      if (responseData['error'] != null) {
        throw Exception(responseData['error']['message']);
      }

      // Validate returned URL before returning it
      String url = responseData['url'];
      if (url.isEmpty) {
        throw Exception('Stripe returned an empty checkout URL');
      }

      // Ensure URL starts with http:// or https://
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      return url;
    } catch (e) {
      print('Error creating checkout session: $e');
      rethrow;
    }
  }

  // Launch Stripe checkout in browser
  static Future<bool> _launchStripeCheckout(String url) async {
    try {
      // Make sure URL is properly formatted
      String formattedUrl = url.trim();

      // Ensure the URL starts with http:// or https://
      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }

      print('Launching URL: $formattedUrl');

      final Uri uri = Uri.parse(formattedUrl);

      // Validate if this is a proper URL
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw 'Invalid URL format: $formattedUrl';
      }

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $formattedUrl';
      }
    } catch (e) {
      print('Error launching URL: $e');
      return false;
    }
  }

  // For backwards compatibility with checkout screen
  static Future<Map<String, dynamic>> makePayment({
    required double amount,
    required String currency,
    required BuildContext context,
  }) async {
    try {
      return await processPaymentWithRedirect(
        amount: amount.toString(),
        currency: currency,
        merchantDisplayName: 'AR Furnish',
        description: 'Purchase from AR Furnish',
      );
    } catch (e) {
      print('Error in makePayment: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Method for backwards compatibility with checkout screen
  static Future<void> saveOrderDetails({
    required String paymentIntentId,
    required double amount,
    required String orderId,
  }) async {
    try {
      // Save payment details in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'orderId': orderId,
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving payment details: $e');
      throw Exception('Failed to save payment details: $e');
    }
  }

  // Process a payment using the redirect flow (needed by cart_provider.dart)
  static Future<Map<String, dynamic>> processPayment({
    required String amount,
    required String currency,
    String? customerId,
    required String merchantDisplayName,
    String? description,
  }) async {
    // Delegate to our existing processPaymentWithRedirect method
    return await processPaymentWithRedirect(
      amount: amount,
      currency: currency,
      customerId: customerId,
      merchantDisplayName: merchantDisplayName,
      description: description,
    );
  }

  // Process a payment with card details provided by the user
  static Future<Map<String, dynamic>> processPaymentWithCardDetails({
    required String amount,
    required String currency,
    String? customerId,
    required String merchantDisplayName,
    required String description,
    required Map<String, dynamic> cardDetails,
  }) async {
    try {
      // Convert amount to the smallest currency unit (e.g., cents for USD)
      final amountInSmallestUnit =
          (double.parse(amount) * 100).round().toString();

      // Step 1: Create a payment intent
      Map<String, dynamic> intentBody = {
        'amount': amountInSmallestUnit,
        'currency': currency,
        'payment_method_types[]': 'card',
        'description': description,
      };

      // Add customer if provided
      if (customerId != null && customerId.isNotEmpty) {
        intentBody['customer'] = customerId;
      }

      var intentResponse = await http.post(
        Uri.parse(paymentApiUrl),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: intentBody,
      );

      var paymentIntent =
          jsonDecode(intentResponse.body) as Map<String, dynamic>;

      if (paymentIntent.containsKey('error')) {
        throw Exception(paymentIntent['error']['message']);
      }

      // Step 2: Create a payment method with the actual card details
      final paymentMethodResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_methods'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'card',
          'card[number]': cardDetails['number'],
          'card[exp_month]': cardDetails['expiryMonth'],
          'card[exp_year]': cardDetails['expiryYear'],
          'card[cvc]': cardDetails['cvc'],
          'billing_details[name]': cardDetails['cardHolderName'],
        },
      );

      final paymentMethod =
          jsonDecode(paymentMethodResponse.body) as Map<String, dynamic>;

      if (paymentMethod.containsKey('error')) {
        throw Exception(paymentMethod['error']['message']);
      }

      // Step 3: Confirm the payment intent with the payment method
      final confirmResponse = await http.post(
        Uri.parse('${paymentApiUrl}/${paymentIntent['id']}/confirm'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method': paymentMethod['id'],
          'return_url': 'https://arfurnish.com/payment-success',
        },
      );

      final confirmResult =
          jsonDecode(confirmResponse.body) as Map<String, dynamic>;

      // Handle successful card payment that doesn't require further action
      if (confirmResult['status'] == 'succeeded') {
        return {
          'success': true,
          'payment_intent': confirmResult['id'],
          'client_secret': confirmResult['client_secret'],
          'message': 'Payment successful'
        };
      }

      // Handle redirect flow if needed
      if (confirmResult['next_action'] != null) {
        var nextAction = confirmResult['next_action'];
        String? redirectUrl;

        if (nextAction.containsKey('redirect_to_url') &&
            nextAction['redirect_to_url'] != null &&
            nextAction['redirect_to_url'].containsKey('url')) {
          redirectUrl = nextAction['redirect_to_url']['url'] as String;

          // Launch the URL
          final success = await _launchStripeCheckout(redirectUrl);

          if (success) {
            return {
              'success': true,
              'payment_intent': confirmResult['id'],
              'client_secret': confirmResult['client_secret'],
              'message': 'Redirected to payment page'
            };
          } else {
            return {
              'success': false,
              'message': 'Failed to open payment page',
            };
          }
        }
      }

      // If we get here, check the payment status
      if (confirmResult['status'] == 'requires_payment_method') {
        return {
          'success': false,
          'message': 'Payment failed. Please try another payment method.'
        };
      }

      // Return general success message if nothing else matched
      return {
        'success': true,
        'payment_intent': confirmResult['id'],
        'message': 'Payment processing initiated'
      };
    } catch (e) {
      print('Error processing payment with card details: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Check a payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(
      String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$paymentApiUrl/$paymentIntentId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('Error checking payment status: $e');
      rethrow;
    }
  }
}
