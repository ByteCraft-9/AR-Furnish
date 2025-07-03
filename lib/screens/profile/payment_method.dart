import 'package:flutter/material.dart';
import 'package:ar_furnish/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ar_furnish/services/payment_method_service.dart';

class PaymentMethod {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String cvv;
  final String type;
  final String userId;
  final String? stripePaymentMethodId;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.type,
    required this.userId,
    this.stripePaymentMethodId,
    this.isDefault = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'type': type,
      'userId': userId,
      'stripePaymentMethodId': stripePaymentMethodId,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create PaymentMethod from Firestore document
  factory PaymentMethod.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod(
      id: doc.id,
      cardNumber: data['cardNumber'] ?? '',
      cardHolder: data['cardHolder'] ?? '',
      expiryDate: data['expiryDate'] ?? '',
      cvv: data['cvv'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'] ?? '',
      stripePaymentMethodId: data['stripePaymentMethodId'],
      isDefault: data['isDefault'] ?? false,
    );
  }

  // Returns last 4 digits of the card number
  String get last4Digits {
    if (cardNumber.length >= 4) {
      return cardNumber.substring(cardNumber.length - 4);
    }
    return '';
  }

  // Returns a masked version of the card number (e.g., **** **** **** 1234)
  String get maskedCardNumber {
    if (cardNumber.isEmpty) return '';
    return '**** **** **** ${last4Digits}';
  }
}

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isEditing = false;
  String? _editingId;

  final PaymentMethodService _paymentService = PaymentMethodService();

  // Helper function to show test card information
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

  void _showPaymentMethodForm({PaymentMethod? method}) {
    // Reset form or populate with existing data if editing
    if (method != null) {
      // We're editing an existing payment method
      _isEditing = true;
      _editingId = method.id;
      _cardNumberController.text = method.cardNumber;
      _cardHolderController.text = method.cardHolder;
      _expiryDateController.text = method.expiryDate;
      _cvvController.text = method.cvv;
      _typeController.text = method.type;
    } else {
      // We're adding a new payment method
      _isEditing = false;
      _editingId = null;
      _cardNumberController.clear();
      _cardHolderController.clear();
      _expiryDateController.clear();
      _cvvController.clear();
      _typeController.clear();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to manage payment methods')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Payment Method' : 'Add Payment Method',
                    style: const TextStyle(
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
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  // Simple validation for test cards
                  if (value.startsWith('4') && value.length != 16) {
                    return 'Visa card should be 16 digits';
                  }
                  if (value.startsWith('5') && value.length != 16) {
                    return 'Mastercard should be 16 digits';
                  }
                  if (value.startsWith('3') &&
                      !value.startsWith('37') &&
                      value.length != 15) {
                    return 'American Express should be 15 digits';
                  }
                  if (value.startsWith('6') && value.length != 16) {
                    return 'Discover card should be 16 digits';
                  }
                  // Basic validation - at least digits and proper length
                  if (value.length < 15 || value.length > 16) {
                    return 'Card number should be 15-16 digits';
                  }
                  // Only allow digits
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Card number should contain only digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Card Holder Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card holder name';
                  }
                  if (value.length < 3) {
                    return 'Name should be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (MM/YY)',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expiry date';
                        }

                        // Check format MM/YY
                        if (!RegExp(r'^(0[1-9]|1[0-2])/[0-9]{2}$')
                            .hasMatch(value)) {
                          return 'Format: MM/YY (e.g., 12/25)';
                        }

                        // Check if card is expired
                        final parts = value.split('/');
                        final month = int.parse(parts[0]);
                        final year = int.parse('20${parts[1]}');

                        final now = DateTime.now();
                        final cardDate = DateTime(year, month);
                        final today = DateTime(now.year, now.month);

                        if (cardDate.isBefore(today)) {
                          return 'Card is expired';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.security),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter CVV';
                        }

                        // Amex has 4 digits, others have 3
                        final cardNumber = _cardNumberController.text;
                        final isAmex = cardNumber.startsWith('3');

                        if (isAmex && value.length != 4) {
                          return 'Amex CVV should be 4 digits';
                        } else if (!isAmex && value.length != 3) {
                          return 'CVV should be 3 digits';
                        }

                        // Only allow digits
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'CVV should contain only digits';
                        }

                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Card Type (e.g., Visa, Mastercard)',
                  prefixIcon: Icon(Icons.credit_score),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card type';
                  }

                  // Auto-suggest card type based on number
                  final cardNumber = _cardNumberController.text;
                  String expectedType = "";

                  if (cardNumber.startsWith('4'))
                    expectedType = "Visa";
                  else if (cardNumber.startsWith('5'))
                    expectedType = "Mastercard";
                  else if (cardNumber.startsWith('3'))
                    expectedType = "American Express";
                  else if (cardNumber.startsWith('6'))
                    expectedType = "Discover";

                  if (expectedType.isNotEmpty &&
                      !value
                          .toLowerCase()
                          .contains(expectedType.toLowerCase())) {
                    return 'Card type should match number (expected: $expectedType)';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      if (_isEditing && _editingId != null) {
                        // Update existing payment method
                        final updatedMethod = PaymentMethod(
                          id: _editingId!,
                          cardNumber: _cardNumberController.text,
                          cardHolder: _cardHolderController.text,
                          expiryDate: _expiryDateController.text,
                          cvv: _cvvController.text,
                          type: _typeController.text,
                          userId: user.uid,
                        );

                        await _paymentService
                            .updatePaymentMethod(updatedMethod);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Payment method updated successfully')),
                        );
                      } else {
                        // Create new payment method
                      final newMethod = PaymentMethod(
                        id: DateTime.now().toString(),
                        cardNumber: _cardNumberController.text,
                        cardHolder: _cardHolderController.text,
                        expiryDate: _expiryDateController.text,
                        cvv: _cvvController.text,
                        type: _typeController.text,
                        userId: user.uid,
                      );

                      await _paymentService.addPaymentMethod(newMethod);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Payment method added successfully')),
                        );
                      }

                      // Clear form and close modal
                      _cardNumberController.clear();
                      _cardHolderController.clear();
                      _expiryDateController.clear();
                      _cvvController.clear();
                      _typeController.clear();

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: Text(_isEditing
                    ? 'Update Payment Method'
                    : 'Add Payment Method'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _addPaymentMethod() {
    _showPaymentMethodForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Methods'),
      ),
      body: StreamBuilder<List<PaymentMethod>>(
          stream: _paymentService.getUserPaymentMethods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final paymentMethods = snapshot.data ?? [];

            if (paymentMethods.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No payment methods added',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add a new payment method',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCardColor(method.type),
                      child: Text(method.type[0],
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Row(
                      children: [
                        Text(method.type),
                        if (method.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(method.maskedCardNumber),
                        Text(
                            '${method.cardHolder} - Expires ${method.expiryDate}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showPaymentMethodForm(method: method),
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(method),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!method.isDefault) {
                        _showSetDefaultConfirmation(method);
                      }
                    },
                  ),
                );
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        backgroundColor: AppTheme.accentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getCardColor(String type) {
    if (type.toLowerCase().contains('visa')) {
      return Colors.blue.shade800;
    } else if (type.toLowerCase().contains('master')) {
      return Colors.orange.shade800;
    } else if (type.toLowerCase().contains('amex') ||
        type.toLowerCase().contains('express')) {
      return Colors.green.shade800;
    } else if (type.toLowerCase().contains('discover')) {
      return Colors.red.shade800;
    }
    return Colors.purple.shade800; // Default color
  }

  void _showDeleteConfirmation(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
            'Are you sure you want to delete ${method.type} ending in ${method.last4Digits}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _paymentService.deletePaymentMethod(method.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment method deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to delete payment method: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSetDefaultConfirmation(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Default'),
        content: Text(
            'Set ${method.type} ending in ${method.last4Digits} as your default payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _paymentService.setDefaultPaymentMethod(method.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Default payment method updated')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update default: $e')),
                );
              }
            },
            child: const Text('Set as Default'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _typeController.dispose();
    super.dispose();
  }
}
