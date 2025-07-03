import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_furnish/providers/cart_provider.dart';
import 'package:ar_furnish/services/payment_method_service.dart';
import 'package:ar_furnish/screens/profile/payment_method.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:ar_furnish/screens/profile/address.dart';
import 'package:ar_furnish/services/address_service.dart';
import 'package:ar_furnish/services/stripe_service.dart';
import 'package:flutter/services.dart';

// Define the primary color to use throughout
const Color primaryColor = Color(0xFF854836);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  final _shippingFormKey = GlobalKey<FormState>();

  // Shipping information
  String _name = '';
  String _address = '';
  String _phone = '';

  // Payment information
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoadingPaymentMethods = true;
  List<PaymentMethod> _paymentMethods = [];

  // Address information
  Address? _selectedAddress;
  bool _isLoadingAddresses = true;
  List<Address> _addresses = [];

  // Services
  late final PaymentMethodService _paymentService;
  late final AddressService _addressService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Payment processing

  @override
  void initState() {
    super.initState();

    // Initialize services with try-catch to handle any errors
    try {
      _paymentService = PaymentMethodService();
      _addressService = AddressService();

      _loadPaymentMethods();
      _loadAddresses();
    } catch (e) {
      print('Error initializing services: $e');
      // Continue with app initialization even if services fail

      // Set states to not loading so UI doesn't wait forever
      setState(() {
        _isLoadingPaymentMethods = false;
        _isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _paymentService.getUserPaymentMethods().listen((methods) {
          setState(() {
            _paymentMethods = methods;
            _isLoadingPaymentMethods = false;
            if (methods.isNotEmpty && _selectedPaymentMethod == null) {
              _selectedPaymentMethod = methods.first;
            }
          });
        });
      } else {
        setState(() {
          _isLoadingPaymentMethods = false;
        });
      }
    } catch (e) {
      print('Error loading payment methods: $e');
      setState(() {
        _isLoadingPaymentMethods = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _addressService.getUserAddresses().listen((addresses) {
          setState(() {
            _addresses = addresses;
            _isLoadingAddresses = false;

            // Select default address or first address if available
            if (_selectedAddress == null && addresses.isNotEmpty) {
              // First try to find the default address
              final defaultAddress = addresses.firstWhere(
                  (address) => address.isDefault,
                  orElse: () => addresses.first);

              _selectedAddress = defaultAddress;

              // Pre-fill shipping form with selected address
              _fillShippingFormWithAddress(defaultAddress);
            }
          });
        });
      } else {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  void _fillShippingFormWithAddress(Address address) {
    setState(() {
      _address = address.address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          // Order progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),

          Expanded(
            child: Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: Text(
                            _currentStep == 2 ? 'Place Order' : 'Continue'),
                      ),
                      if (_currentStep > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: TextButton(
                            onPressed: details.onStepCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                    ],
                  ),
                );
              },
              onStepContinue: () {
                if (_currentStep == 0) {
                  // First check if an address is selected
                  if (_selectedAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select or add a delivery address'),
                        backgroundColor: primaryColor,
                      ),
                    );
                    return;
                  }

                  // Then validate the shipping form
                  if (_shippingFormKey.currentState!.validate()) {
                    _shippingFormKey.currentState!.save();
                    setState(() => _currentStep++);
                  }
                } else if (_currentStep == 1) {
                  // Validate payment selection
                  if (_selectedPaymentMethod != null) {
                    setState(() => _currentStep++);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a payment method')),
                    );
                  }
                } else {
                  _processOrder(cart);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: [
                Step(
                  title: const Text('Shipping'),
                  content: _buildShippingForm(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Payment'),
                  content: _buildPaymentForm(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Review'),
                  content: _buildOrderSummary(cart, currencyFormat),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address selection section
        _buildAddressSelection(),

        const SizedBox(height: 24),

        // Additional shipping details
        Form(
          key: _shippingFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                initialValue: _name,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Required' : null,
                onSaved: (value) => _name = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  hintText: '03001234567',
                ),
                initialValue: _phone,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  // Remove any whitespace
                  final cleanedValue = value.trim();
                  // Check if contains only digits
                  if (!RegExp(r'^[0-9]+$').hasMatch(cleanedValue)) {
                    return 'Only numbers are allowed';
                  }
                  // Check for exactly 11 digits
                  if (cleanedValue.length != 11) {
                    return 'Phone number must be exactly 11 digits';
                  }
                  return null;
                },
                onSaved: (value) => _phone = value?.trim() ?? '',
                maxLength: 11,
                buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) {
                  return Text('$currentLength/$maxLength');
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Delivery Instructions (Optional)',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  hintText:
                      'Apartment number, gate code, delivery preferences...',
                ),
                maxLines: 2,
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _address = "$_address\nNote: $value";
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSelection() {
    if (_isLoadingAddresses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (_addresses.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.add_location, size: 18),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                  onPressed: () => _navigateToAddressScreen(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_addresses.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.location_off,
                        size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'No saved addresses',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please add a delivery address to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_location),
                      label: const Text('Add New Address'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: () => _navigateToAddressScreen(),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      final isSelected = _selectedAddress?.id == address.id;

                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedAddress = address;
                              _address = address.address;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          child: Text(
                                              address.type[0].toUpperCase()),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            address.type,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        address.address,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${address.city}, ${address.postalCode}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              if (address.isDefault)
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: primaryColor, width: 1),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Error message if no address is selected
                if (_selectedAddress == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select a delivery address',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    } catch (e) {
      print('Error building address selection: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading addresses: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadAddresses();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _navigateToAddressScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressScreen(selectionMode: true),
      ),
    );

    if (result is Address) {
      setState(() {
        _selectedAddress = result;
        _fillShippingFormWithAddress(result);
      });
    }
  }

  Widget _buildPaymentForm() {
    if (_isLoadingPaymentMethods) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              primaryColor), // Using the primary color
        ),
      );
    }

    try {
      if (_paymentMethods.isEmpty) {
        return Column(
          children: [
            const Icon(
              Icons.credit_card_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No payment methods saved',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a payment method to continue',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, // Using the primary color
              ),
              onPressed: () async {
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodScreen(),
                    ),
                  );
                  // Refresh the payment methods list when returning
                  _loadPaymentMethods();
                } catch (e) {
                  print('Error navigating to payment screen: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(_paymentMethods.length, (index) {
            final method = _paymentMethods[index];
            return RadioListTile<PaymentMethod>(
              value: method,
              groupValue: _selectedPaymentMethod,
              title: Text(method.type),
              subtitle: Text(
                '**** **** **** ${method.cardNumber.substring(method.cardNumber.length - 4)}',
              ),
              secondary: CircleAvatar(
                backgroundColor: primaryColor, // Using the primary color
                foregroundColor: Colors.white,
                child: Text(method.type[0]),
              ),
              activeColor: primaryColor, // Using the primary color
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Payment Method'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor, // Using the primary color
                side: const BorderSide(
                    color: primaryColor), // Using the primary color
              ),
              onPressed: () async {
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodScreen(),
                    ),
                  );
                  _loadPaymentMethods();
                } catch (e) {
                  print('Error navigating to payment screen: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error building payment form: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading payment methods: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadPaymentMethods();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOrderSummary(CartProvider cart, NumberFormat currencyFormat) {
    // Use selected items for calculation instead of all cart items
    final total = cart.selectedItemsTotal;
    final shipping = 150.0;
    final tax = total * 0.05;
    final grandTotal = total + shipping + tax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected address display
        if (_selectedAddress != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Address',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor), // Using the primary color
                ),
                const SizedBox(height: 8),
                Text('$_name'),
                Text(_selectedAddress!.type),
                Text(_selectedAddress!.address),
                Text(
                    '${_selectedAddress!.city}, ${_selectedAddress!.postalCode}'),
                Text(_phone),
              ],
            ),
          ),

        // Selected payment method display
        if (_selectedPaymentMethod != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor), // Using the primary color
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor, // Using the primary color
                      foregroundColor: Colors.white,
                      child: Text(_selectedPaymentMethod!.type[0]),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedPaymentMethod!.type),
                        Text(
                            '**** ${_selectedPaymentMethod!.cardNumber.substring(_selectedPaymentMethod!.cardNumber.length - 4)}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Order items
        const Text(
          'Order Items',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryColor), // Using the primary color
        ),
        const SizedBox(height: 8),

        // Product list - use selectedItems instead of all items
        ...cart.selectedItems.values.map((cartItem) {
          return _buildCartItem(cartItem);
        }).toList(),

        const Divider(thickness: 1),

        // Order total
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(currencyFormat.format(total)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shipping'),
              Text(currencyFormat.format(shipping)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (5%)'),
              Text(currencyFormat.format(tax)),
            ],
          ),
        ),
        const Divider(thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                currencyFormat.format(grandTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor), // Using the primary color
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.featureImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PKR ${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: item.quantity > 1
                            ? () {
                                context.read<CartProvider>().updateQuantity(
                                      item.product.id,
                                      item.quantity - 1,
                                    );
                              }
                            : null,
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: item.quantity < item.product.quantity
                            ? () {
                                context.read<CartProvider>().updateQuantity(
                                      item.product.id,
                                      item.quantity + 1,
                                    );
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Total price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (item.quantity >= item.product.quantity)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Max quantity',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to place an order')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    // Show loading dialog
    setState(() {});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );

    try {
      // Use selectedItemsTotal instead of totalAmount
      final subtotal = cart.selectedItemsTotal;
      final shipping = 150.0;
      final tax = subtotal * 0.05;
      final total = subtotal + shipping + tax;

      // Create shipping address string
      final shippingAddress =
          '$_name\n${_selectedAddress!.type}\n${_selectedAddress!.address}\n${_selectedAddress!.city}, ${_selectedAddress!.postalCode}\n$_phone';

      // Generate order ID
      final orderId = const Uuid().v4();

      // Process payment with Stripe
      Map<String, dynamic>? paymentResult;

      // Create order in Firestore first with pending status
      final orderRef = _firestore.collection('orders').doc(orderId);

      // Convert selected cart items to a format suitable for Firestore
      final List<Map<String, dynamic>> orderItems = cart.selectedItems.values
          .map((cartItem) => {
                'productId': cartItem.product.id,
                'productName': cartItem.product.name,
                'price': cartItem.product.price,
                'quantity': cartItem.quantity,
                'image': cartItem.product.featureImage,
              })
          .toList();

      // Create initial order with pending status
      await orderRef.set({
        'id': orderId,
        'userId': user.uid,
        'items': orderItems,
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'currency': 'PKR',
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'shippingAddress': shippingAddress,
        'paymentMethod': {
          'id': _selectedPaymentMethod!.id,
          'type': _selectedPaymentMethod!.type,
          'last4': _selectedPaymentMethod!.cardNumber
              .substring(_selectedPaymentMethod!.cardNumber.length - 4),
        },
      });

      try {
        // Close loading dialog before showing payment sheet
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        // Process Stripe payment using static method
        paymentResult = await StripeService.makePayment(
          amount: total,
          currency: 'pkr',
          context: context,
        );

        if (paymentResult['success'] != true) {
          throw Exception(paymentResult['message'] ?? 'Payment failed');
        }

        // Update order with payment details
        await orderRef.update({
          'status': 'paid',
          'paymentDetails': {
            'paymentIntentId': paymentResult.containsKey('payment_intent')
                ? paymentResult['payment_intent']
                : '',
            'paymentMethod': 'stripe',
            'paymentStatus': 'completed',
          },
        });
      } catch (e) {
        // Payment was cancelled or failed - don't delete the order, just mark it as failed
        await orderRef.update({
          'status': 'payment_failed',
          'paymentFailureReason': e.toString(),
        });

        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog again for order processing
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );

      // Save payment details in Firestore
      if (paymentResult.containsKey('payment_intent')) {
        // Save payment details using static method
        await StripeService.saveOrderDetails(
          paymentIntentId: paymentResult['payment_intent'],
          amount: total,
          orderId: orderId,
        );
      }

      // Create order confirmation notification
      await _createOrderNotification(orderId, total);

      // Close loading dialog if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      setState(() {});

      // Only remove checked out items from cart, not the entire cart
      if (cart.selectedItems.length < cart.items.length) {
        // Remove only the selected items
        for (int productId in cart.selectedItems.keys) {
          cart.removeItem(productId);
        }
      } else {
        // If all items were selected, clear the entire cart
        await cart.clear();
      }

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order placed successfully!'),
          backgroundColor: primaryColor,
        ),
      );

      // Navigate to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Close loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      setState(() {});

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  // Method to create a notification for order confirmation
  Future<void> _createOrderNotification(String orderId, double total) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'Order Confirmation',
        'message':
            'Your order #${orderId.substring(0, 8)} for PKR ${total.toStringAsFixed(2)} has been received and is being processed.',
        'type': 'order',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'orderId': orderId,
        }
      });
    } catch (e) {
      print('Error creating order notification: $e');
      // Continue with order process even if notification fails
    }
  }
}
