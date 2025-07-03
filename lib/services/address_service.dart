import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ar_furnish/screens/profile/address.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get addressCollection =>
      _firestore.collection('addresses');

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Get all addresses for current user
  Stream<List<Address>> getUserAddresses() {
    try {
      final userId = _getCurrentUserId();
      return addressCollection
          .where('userId', isEqualTo: userId)
          .orderBy('isDefault', descending: true) // Default addresses first
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Address.fromDocument(doc)).toList();
      });
    } catch (e) {
      print('Error fetching addresses: $e');
      return Stream.value([]);
    }
  }

  // Get default address for current user
  Future<Address?> getDefaultAddress() async {
    try {
      final userId = _getCurrentUserId();
      final snapshot = await addressCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Address.fromDocument(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching default address: $e');
      return null;
    }
  }

  // Add new address
  Future<String> addAddress(Address address) async {
    try {
      // Validate address before saving
      if (!address.isValid()) {
        final errors = address
            .getValidationErrors()
            .entries
            .where((entry) => entry.value != null)
            .map((entry) => "${entry.key}: ${entry.value}")
            .join(", ");
        throw Exception('Invalid address: $errors');
      }

      // If this is set as default, update all other addresses to non-default
      if (address.isDefault) {
        await _clearDefaultAddresses();
      }

      // Create a new document and get its reference
      final docRef = await addressCollection.add({
        'type': address.type,
        'address': address.address,
        'city': address.city,
        'postalCode': address.postalCode,
        'userId': address.userId,
        'isDefault': address.isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id; // Return the document ID
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('Failed to add address: $e');
    }
  }

  // Set an address as default
  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _clearDefaultAddresses();
      await addressCollection.doc(addressId).update({'isDefault': true});
    } catch (e) {
      print('Error setting default address: $e');
      throw Exception('Failed to set default address: $e');
    }
  }

  // Clear all default addresses
  Future<void> _clearDefaultAddresses() async {
    try {
      final userId = _getCurrentUserId();
      final batch = _firestore.batch();
      final snapshot = await addressCollection
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing default addresses: $e');
      throw Exception('Failed to clear default addresses: $e');
    }
  }

  // Delete address
  Future<void> deleteAddress(String id) async {
    try {
      await addressCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('Failed to delete address: $e');
    }
  }

  // Update address
  Future<void> updateAddress(Address address) async {
    try {
      // Validate address before updating
      if (!address.isValid()) {
        final errors = address
            .getValidationErrors()
            .entries
            .where((entry) => entry.value != null)
            .map((entry) => "${entry.key}: ${entry.value}")
            .join(", ");
        throw Exception('Invalid address: $errors');
      }

      if (address.isDefault) {
        await _clearDefaultAddresses();
      }

      await addressCollection.doc(address.id).update(address.toMap());
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('Failed to update address: $e');
    }
  }
}
