import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

const Color primaryColor = Color(0xFF854836);

class Address {
  final String id;
  final String type;
  final String address;
  final String city;
  final String postalCode;
  final String userId;
  final bool isDefault;

  Address({
    required this.id,
    required this.type,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.userId,
    this.isDefault = false,
  });

  // Validate address
  bool isValid() {
    return _validateType() == null &&
        _validateAddress() == null &&
        _validateCity() == null &&
        _validatePostalCode() == null;
  }

  // Validation methods for each field
  String? _validateType() {
    if (type.isEmpty) {
      return 'Address type is required';
    }
    if (type.length < 2) {
      return 'Address type must be at least 2 characters';
    }
    if (type.length > 20) {
      return 'Address type must be less than 20 characters';
    }
    return null;
  }

  String? _validateAddress() {
    if (address.isEmpty) {
      return 'Address is required';
    }
    if (address.length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (address.length > 100) {
      return 'Address must be less than 100 characters';
    }
    return null;
  }

  String? _validateCity() {
    if (city.isEmpty) {
      return 'City is required';
    }
    if (city.length < 2) {
      return 'City must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(city)) {
      return 'City should only contain letters, spaces, and hyphens';
    }
    return null;
  }

  String? _validatePostalCode() {
    if (postalCode.isEmpty) {
      return 'Postal code is required';
    }
    if (!RegExp(r'^\d{5,6}$').hasMatch(postalCode)) {
      return 'Please enter a valid 5-6 digit postal code';
    }
    return null;
  }

  // Get validation errors as a map
  Map<String, String?> getValidationErrors() {
    return {
      'type': _validateType(),
      'address': _validateAddress(),
      'city': _validateCity(),
      'postalCode': _validatePostalCode(),
    };
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'userId': userId,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Address from Firestore document
  factory Address.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      type: data['type'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      postalCode: data['postalCode'] ?? '',
      userId: data['userId'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  // Create a copy of this address with modified fields
  Address copyWith({
    String? id,
    String? type,
    String? address,
    String? city,
    String? postalCode,
    String? userId,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressScreen extends StatefulWidget {
  final bool selectionMode;
  final Function(Address)? onAddressSelected;

  const AddressScreen({
    super.key,
    this.selectionMode = false,
    this.onAddressSelected,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Address> _addresses = [];
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isLoading = true;
  bool _isDefault = false;

  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('addresses')
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          _addresses =
              snapshot.docs.map((doc) => Address.fromDocument(doc)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAddress(Address address) async {
    try {
      // Check if address is valid
      if (!address.isValid()) {
        final errors = address
            .getValidationErrors()
            .entries
            .where((entry) => entry.value != null)
            .map((entry) => entry.value)
            .join("\n");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation errors: $errors'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If this is set as default, update all other addresses to non-default
      if (address.isDefault) {
        final user = _auth.currentUser;
        if (user != null) {
          final batch = _firestore.batch();
          final snapshot = await _firestore
              .collection('addresses')
              .where('userId', isEqualTo: user.uid)
              .where('isDefault', isEqualTo: true)
              .get();

          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {'isDefault': false});
          }
          await batch.commit();
        }
      }

      // Create or update the address in Firestore
      if (address.id.isEmpty) {
        // New address
        await _firestore.collection('addresses').add(address.toMap());
      } else {
        // Update existing address
        await _firestore
            .collection('addresses')
            .doc(address.id)
            .update(address.toMap());
      }

      // Reload addresses
      _loadAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error saving address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      await _firestore.collection('addresses').doc(id).delete();
      _loadAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error deleting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete address: $e')),
      );
    }
  }

  Future<void> _setAsDefault(Address address) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // First, set all addresses to non-default
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection('addresses')
            .where('userId', isEqualTo: user.uid)
            .where('isDefault', isEqualTo: true)
            .get();

        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();

        // Then set this address as default
        await _firestore
            .collection('addresses')
            .doc(address.id)
            .update({'isDefault': true});

        _loadAddresses();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      print('Error setting default address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update default address: $e')),
      );
    }
  }

  void _addAddress() {
    // Reset form values
    _typeController.clear();
    _addressController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const Text(
                  'Add New Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'Address Type (e.g., Home, Office)',
                    prefixIcon: const Icon(Icons.category, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Home, Office, etc.',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address type';
                    }
                    if (value.length < 2) {
                      return 'Address type must be at least 2 characters';
                    }
                    if (value.length > 20) {
                      return 'Address type must be less than 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon:
                        const Icon(Icons.location_on, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '123 Main Street, Apt 4B',
                    helperText: 'Enter complete address with house/flat number',
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    if (value.length < 5) {
                      return 'Address must be at least 5 characters';
                    }
                    if (value.length > 100) {
                      return 'Address must be less than 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon:
                        const Icon(Icons.location_city, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'New York',
                    helperText:
                        'Enter city name (letters, spaces & hyphens only)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    if (value.length < 2) {
                      return 'City name must be at least 2 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
                      return 'City name should only contain letters, spaces, and hyphens';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'Postal Code',
                    prefixIcon: const Icon(Icons.pin, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '123456',
                    helperText: 'Enter 5-6 digit postal code',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter postal code';
                    }
                    // Basic postal code validation - adjust for your country's format
                    if (!RegExp(r'^\d{5,6}$').hasMatch(value)) {
                      return 'Please enter a valid 5-6 digit postal code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: _isDefault,
                  activeColor: primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setModalState(() {
                      _isDefault = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _confirmSaveAddress();
                    }
                  },
                  child: const Text('Save Address',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSaveAddress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please confirm your address details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Type: ${_typeController.text}'),
            const SizedBox(height: 8),
            Text('Address: ${_addressController.text}'),
            const SizedBox(height: 8),
            Text('City: ${_cityController.text}'),
            const SizedBox(height: 8),
            Text(
                'Postal Code: ${_formatPostalCode(_postalCodeController.text)}'),
            const SizedBox(height: 8),
            Text('Default Address: ${_isDefault ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context); // Close the confirmation dialog
              final user = _auth.currentUser;
              if (user != null) {
                final newAddress = Address(
                  id: '', // Firebase will generate ID
                  type: _typeController.text,
                  address: _addressController.text,
                  city: _cityController.text,
                  postalCode: _postalCodeController.text,
                  userId: user.uid,
                  isDefault: _isDefault,
                );
                _saveAddress(newAddress);
              }
              Navigator.pop(context); // Close the form
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Addresses'),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAddress,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No addresses added yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new address',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _addAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: address.isDefault
                ? const BorderSide(color: primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: Column(
            children: [
              if (address.isDefault)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Default Address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  child: Text(address.type[0].toUpperCase()),
                ),
                title: Text(
                  address.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(address.address),
                    Text(
                        '${address.city}, ${_formatPostalCode(address.postalCode)}'),
                  ],
                ),
                trailing: widget.selectionMode
                    ? IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: primaryColor),
                        onPressed: () {
                          if (widget.onAddressSelected != null) {
                            widget.onAddressSelected!(address);
                          }
                          Navigator.pop(context, address);
                        },
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit address',
                            onPressed: () => _editAddress(address),
                          ),
                          if (!address.isDefault)
                            IconButton(
                              icon: const Icon(Icons.star_border),
                              tooltip: 'Set as default',
                              onPressed: () => _setAsDefault(address),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(address),
                          ),
                        ],
                      ),
                onTap: widget.selectionMode
                    ? () {
                        if (widget.onAddressSelected != null) {
                          widget.onAddressSelected!(address);
                        }
                        Navigator.pop(context, address);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _editAddress(Address address) {
    // Set form values
    _typeController.text = address.type;
    _addressController.text = address.address;
    _cityController.text = address.city;
    _postalCodeController.text = address.postalCode;
    _isDefault = address.isDefault;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                const Text(
                  'Edit Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'Address Type (e.g., Home, Office)',
                    prefixIcon: const Icon(Icons.category, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Home, Office, etc.',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address type';
                    }
                    if (value.length < 2) {
                      return 'Address type must be at least 2 characters';
                    }
                    if (value.length > 20) {
                      return 'Address type must be less than 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon:
                        const Icon(Icons.location_on, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '123 Main Street, Apt 4B',
                    helperText: 'Enter complete address with house/flat number',
                  ),
                  textCapitalization: TextCapitalization.words,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    if (value.length < 5) {
                      return 'Address must be at least 5 characters';
                    }
                    if (value.length > 100) {
                      return 'Address must be less than 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    prefixIcon:
                        const Icon(Icons.location_city, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'New York',
                    helperText:
                        'Enter city name (letters, spaces & hyphens only)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\-]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    if (value.length < 2) {
                      return 'City name must be at least 2 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
                      return 'City name should only contain letters, spaces, and hyphens';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'Postal Code',
                    prefixIcon: const Icon(Icons.pin, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '123456',
                    helperText: 'Enter 5-6 digit postal code',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter postal code';
                    }
                    // Basic postal code validation - adjust for your country's format
                    if (!RegExp(r'^\d{5,6}$').hasMatch(value)) {
                      return 'Please enter a valid 5-6 digit postal code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: _isDefault,
                  activeColor: primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setModalState(() {
                      _isDefault = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _confirmUpdateAddress(address);
                    }
                  },
                  child: const Text('Update Address',
                      style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmUpdateAddress(Address originalAddress) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please confirm your updated address details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Type: ${_typeController.text}'),
            const SizedBox(height: 8),
            Text('Address: ${_addressController.text}'),
            const SizedBox(height: 8),
            Text('City: ${_cityController.text}'),
            const SizedBox(height: 8),
            Text(
                'Postal Code: ${_formatPostalCode(_postalCodeController.text)}'),
            const SizedBox(height: 8),
            Text('Default Address: ${_isDefault ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            onPressed: () {
              Navigator.pop(context); // Close the confirmation dialog

              final updatedAddress = Address(
                id: originalAddress.id,
                type: _typeController.text,
                address: _addressController.text,
                city: _cityController.text,
                postalCode: _postalCodeController.text,
                userId: originalAddress.userId,
                isDefault: _isDefault,
              );

              _updateAddress(updatedAddress);
              Navigator.pop(context); // Close the form
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAddress(Address address) async {
    try {
      // Check if address is valid
      if (!address.isValid()) {
        final errors = address
            .getValidationErrors()
            .entries
            .where((entry) => entry.value != null)
            .map((entry) => entry.value)
            .join("\n");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation errors: $errors'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If this is set as default, update all other addresses to non-default
      if (address.isDefault) {
        final user = _auth.currentUser;
        if (user != null) {
          final batch = _firestore.batch();
          final snapshot = await _firestore
              .collection('addresses')
              .where('userId', isEqualTo: user.uid)
              .where('isDefault', isEqualTo: true)
              .get();

          for (var doc in snapshot.docs) {
            batch.update(doc.reference, {'isDefault': false});
          }
          await batch.commit();
        }
      }

      // Update address
      await _firestore
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());

      // Reload addresses
      _loadAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Address address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
            'Are you sure you want to delete the ${address.type} address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              _deleteAddress(address.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Format postal code for better readability
  String _formatPostalCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    } else if (code.length == 5) {
      return '${code.substring(0, 2)} ${code.substring(2)}';
    }
    return code;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}
