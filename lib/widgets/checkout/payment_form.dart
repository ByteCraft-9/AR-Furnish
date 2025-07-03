// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ar_furnish/services/stripe_service.dart';

class PaymentForm extends StatefulWidget {
  final Function(CardFieldInputDetails)? onCardChanged;
  final double amount;
  final String currency;

  const PaymentForm({
    super.key,
    this.onCardChanged,
    this.amount = 0.0,
    this.currency = 'USD',
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderNameController = TextEditingController();
  CardFieldInputDetails? _cardFieldInputDetails;
  bool _isCardComplete = false;
  bool _isProcessing = false;

  // Show test card information dialog
  void _showTestCardInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Card Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('This app is in test mode. Please use these test cards:'),
            SizedBox(height: 8),
            Text('• Visa: 4242 4242 4242 4242'),
            Text('• Mastercard: 5555 5555 5555 4444'),
            Text('• American Express: 3782 822463 10005'),
            Text('• Discover: 6011 1111 1111 1117'),
            SizedBox(height: 8),
            Text('Any future date for expiry'),
            Text('Any 3 digits for CVV (4 for Amex)'),
            Text('Any name for cardholder'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Test Cards'),
                onPressed: _showTestCardInfo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add cardholder name field
          TextFormField(
            controller: _cardHolderNameController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'Enter name on card',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF854836),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the cardholder name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CardField(
            onCardChanged: _onCardChanged,
            decoration: InputDecoration(
              labelText: 'Card Information',
              hintText: 'Enter card details',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF854836),
                  width: 2,
                ),
              ),
            ),
          ),
          if (_cardFieldInputDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildCardValidationMessage(),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Payment summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:'),
                    Text(
                      '${widget.currency.toUpperCase()} ${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Test mode - No actual charge',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : (_isCardComplete ? _processPayment : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF854836),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Processing...',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  )
                : const Text(
                    'Pay Now',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  // Display appropriate validation messages for card input
  Widget _buildCardValidationMessage() {
    final details = _cardFieldInputDetails!;

    if (details.complete) {
      return const Text(
        'Card information is valid',
        style: TextStyle(color: Colors.green),
      );
    }

    if (details.validNumber == false) {
      return const Text(
        'Card number is invalid',
        style: TextStyle(color: Colors.red),
      );
    }

    if (details.validExpiryDate == false) {
      return const Text(
        'Expiration date is invalid',
        style: TextStyle(color: Colors.red),
      );
    }

    if (details.validCVC == false) {
      return const Text(
        'CVC is invalid',
        style: TextStyle(color: Colors.red),
      );
    }

    return const Text(
      'Please complete card information',
      style: TextStyle(color: Colors.orange),
    );
  }

  void _onCardChanged(CardFieldInputDetails? details) {
    if (details == null) return;

    setState(() {
      _cardFieldInputDetails = details;
      _isCardComplete = details.complete;

      if (widget.onCardChanged != null && details.complete == true) {
        widget.onCardChanged!(details);
      }
    });
  }

  Future<void> _processPayment() async {
    // Validate the form first
    if (!_formKey.currentState!.validate() || !_isCardComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all payment information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing payment...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Extract card details to pass to the payment service
      final cardDetails = _extractCardDetails();

      final paymentResult = await StripeService.processPaymentWithCardDetails(
        amount: widget.amount.toString(),
        currency: widget.currency.toLowerCase(),
        merchantDisplayName: 'AR Furnish',
        description: 'Purchase from AR Furnish',
        cardDetails: cardDetails,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (paymentResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to success screen or order confirmation
        Navigator.of(context).pushReplacementNamed('/order-success');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${paymentResult['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extract the card details from the form
  Map<String, dynamic> _extractCardDetails() {
    final cardDetails = _cardFieldInputDetails!;

    return {
      'cardHolderName': _cardHolderNameController.text.trim(),
      'number': cardDetails.number ?? '',
      'expiryMonth': cardDetails.expiryMonth?.toString() ?? '',
      'expiryYear': cardDetails.expiryYear?.toString() ?? '',
      'cvc': cardDetails.cvc ?? '',
      'brand': cardDetails.brand ?? 'visa', // Default to visa for test cards
    };
  }

  @override
  void dispose() {
    _cardHolderNameController.dispose();
    super.dispose();
  }
}
