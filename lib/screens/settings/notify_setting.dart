import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF854836);

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  Map<String, bool> _preferences = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        Map<String, dynamic>? data = doc.data();

        // Load saved preferences or use defaults
        if (data != null && data.containsKey('notificationPreferences')) {
          setState(() {
            _preferences = Map<String, bool>.from(
                data['notificationPreferences'] as Map<dynamic, dynamic>);
          });
        } else {
          // Default values
          setState(() {
            _preferences = {
              'orderConfirmation': true,
              'shippingUpdates': true,
              'priceDrops': true,
              'newProducts': true,
              'restocks': true,
              'wishlistPriceChange': true,
              'wishlistAvailability': true,
              'securityAlerts': true,
              'passwordChanges': true,
              'ratingRequests': true, // Added for rating notifications
            };
          });
        }
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
      // Use defaults on error
      setState(() {
        _preferences = {
          'orderConfirmation': true,
          'shippingUpdates': true,
          'priceDrops': true,
          'newProducts': true,
          'restocks': true,
          'wishlistPriceChange': true,
          'wishlistAvailability': true,
          'securityAlerts': true,
          'passwordChanges': true,
          'ratingRequests': true, // Added for rating notifications
        };
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'notificationPreferences': _preferences,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      print('Error saving notification preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: primaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose which notifications you want to receive',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Divider(),
                _buildSectionHeader('Orders & Shipping'),
                _buildSettingSwitch(
                  'Order confirmations',
                  'Get notified when your order is confirmed',
                  'orderConfirmation',
                ),
                _buildSettingSwitch(
                  'Shipping updates',
                  'Get notified about shipment status changes',
                  'shippingUpdates',
                ),
                _buildSettingSwitch(
                  'Rating requests',
                  'Get notified to rate products after purchase',
                  'ratingRequests',
                ),
                const Divider(),
                _buildSectionHeader('Products & Offers'),
                _buildSettingSwitch(
                  'Price drops',
                  'Get notified when product prices drop',
                  'priceDrops',
                ),
                _buildSettingSwitch(
                  'New products',
                  'Get notified when new products are added',
                  'newProducts',
                ),
                _buildSettingSwitch(
                  'Restocks',
                  'Get notified when out-of-stock items are back',
                  'restocks',
                ),
                const Divider(),
                _buildSectionHeader('Wishlist'),
                _buildSettingSwitch(
                  'Price changes',
                  'Get notified when wishlist items change price',
                  'wishlistPriceChange',
                ),
                _buildSettingSwitch(
                  'Availability',
                  'Get notified when wishlist items are back in stock',
                  'wishlistAvailability',
                ),
                const Divider(),
                _buildSectionHeader('Account'),
                _buildSettingSwitch(
                  'Security alerts',
                  'Important alerts about your account security',
                  'securityAlerts',
                ),
                _buildSettingSwitch(
                  'Password changes',
                  'Get notified when your password is changed',
                  'passwordChanges',
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save Preferences'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
      String title, String subtitle, String preferenceName) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      value: _preferences[preferenceName] ?? true,
      onChanged: (bool value) {
        setState(() {
          _preferences[preferenceName] = value;
        });
      },
      activeColor: primaryColor,
    );
  }
}

class NotificationCategory {
  final String title;
  final List<NotificationType> types;

  NotificationCategory({required this.title, required this.types});
}

class NotificationType {
  final String key;
  final String title;
  final String description;

  NotificationType({
    required this.key,
    required this.title,
    required this.description,
  });
}

final List<NotificationCategory> notificationCategories = [
  NotificationCategory(
    title: 'Product Updates',
    types: [
      NotificationType(
        key: 'newProducts',
        title: 'New Products',
        description: 'Get notified when new products are added',
      ),
      NotificationType(
        key: 'priceDrops',
        title: 'Price Drops',
        description: 'Receive alerts when items go on sale',
      ),
      NotificationType(
        key: 'restocks',
        title: 'Restock Alerts',
        description: 'Notify me when out-of-stock items are available',
      ),
    ],
  ),
  NotificationCategory(
    title: 'Order Updates',
    types: [
      NotificationType(
        key: 'orderConfirmation',
        title: 'Order Confirmations',
        description: 'Receive confirmation when orders are placed',
      ),
      NotificationType(
        key: 'shippingUpdates',
        title: 'Shipping Updates',
        description: 'Get updates about order delivery status',
      ),
    ],
  ),
  NotificationCategory(
    title: 'Wishlist Alerts',
    types: [
      NotificationType(
        key: 'wishlistAvailability',
        title: 'Item Availability',
        description: 'Notify when wishlist items are back in stock',
      ),
      NotificationType(
        key: 'wishlistPriceChange',
        title: 'Price Changes',
        description: 'Alert me when wishlist items change price',
      ),
    ],
  ),
  NotificationCategory(
    title: 'Account Activity',
    types: [
      NotificationType(
        key: 'passwordChanges',
        title: 'Password Changes',
        description: 'Get notified when your password is changed',
      ),
      NotificationType(
        key: 'securityAlerts',
        title: 'Security Alerts',
        description: 'Important notifications about account security',
      ),
    ],
  ),
];
