import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ar_furnish/screens/notifications/rating_dialog.dart';

const Color primaryColor = Color(0xFF854836);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  Map<String, bool> _notificationPrefs = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_auth.currentUser == null) return;

    try {
      final doc =
          await _db.collection('users').doc(_auth.currentUser?.uid).get();
      if (doc.exists) {
        setState(() {
          _notificationPrefs = Map<String, bool>.from(
              doc.data()?['notificationPreferences'] ?? {});
        });
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
    }
  }

  bool _isNotificationAllowed(String type) {
    // Map notification types to preference keys
    final Map<String, String> typeToPreferenceKey = {
      'new_product': 'newProducts',
      'promo': 'priceDrops',
      'restock': 'restocks',
      'order': 'orderConfirmation',
      'shipping': 'shippingUpdates',
      'wishlist': 'wishlistPriceChange',
      'wishlist_availability': 'wishlistAvailability',
      'security': 'securityAlerts',
      'password': 'passwordChanges',
      'rating': 'ratingRequests', // Added for rating notifications
    };

    final preferenceKey = typeToPreferenceKey[type] ?? '';
    if (preferenceKey.isEmpty) return true;
    // If the preference doesn't exist, default to showing the notification
    return _notificationPrefs.isEmpty ||
        (_notificationPrefs[preferenceKey] ?? true);
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_auth.currentUser == null) return;

    try {
      await _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _db.batch();
      final unreadSnapshot = await _db
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error marking notifications as read: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewNotificationDetails(DocumentSnapshot notification) {
    final data = notification.data() as Map<String, dynamic>;
    final type = data['type'] as String? ?? '';
    final title = data['title'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};

    // Special handling for rating notifications
    if (type == 'rating' && !(notificationData['rated'] ?? false)) {
      _showRatingDialog(
        notification.id,
        notificationData['productId'] ?? '',
        notificationData['productName'] ?? '',
      );
      return;
    }

    // Mark notification as read when opened
    if (!(data['read'] ?? true)) {
      _markNotificationAsRead(notification.id);
    }

    // Show a bottom sheet with notification details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _buildNotificationDetailsSheet(
          type, title, message, notificationData),
    );
  }

  // Show rating dialog for product ratings
  void _showRatingDialog(
      String notificationId, String productId, String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RatingDialog(
        notificationId: notificationId,
        productId: productId,
        productName: productName,
      ),
    ).then((rated) {
      if (rated == true) {
        // Refresh the notification list if a rating was submitted
        setState(() {});
      }
    });
  }

  Widget _buildNotificationDetailsSheet(
      String type, String title, String message, Map<String, dynamic> data) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getIconBackgroundColor(type),
                      child: Icon(
                        _getIcon(type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Display additional notification data if available
                if (data.isNotEmpty) ...[
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...data.entries.map((entry) {
                    // Skip displaying notification IDs as they're not user-friendly
                    if (entry.key.toLowerCase().contains('id') &&
                        entry.value is String &&
                        entry.value.toString().length > 10) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatDataKey(entry.key)}: ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              _formatDataValue(entry.value),
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                const SizedBox(height: 40),
                // Add action buttons based on notification type
                _buildActionButtons(type, data),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDataKey(String key) {
    // Convert camelCase or snake_case to Title Case
    String formatted = key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ');

    return formatted.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatDataValue(dynamic value) {
    if (value == null) return 'N/A';

    if (value is double) {
      return NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2)
          .format(value);
    }

    if (value is int && value > 1500000000) {
      // It's likely a timestamp
      return DateFormat('MMM d, yyyy - h:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(value * 1000));
    }

    return value.toString();
  }

  Widget _buildActionButtons(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'order':
        final orderId = data['orderId'];
        if (orderId != null) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to order details
                Navigator.pushNamed(
                  context,
                  '/orders',
                  arguments: orderId,
                );
              },
              child: const Text('View Order Details'),
            ),
          );
        }
        break;

      case 'new_product':
      case 'promo':
      case 'restock':
        final productId = data['productId'];
        if (productId != null) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to product details
                Navigator.pushNamed(
                  context,
                  '/product-details',
                  arguments: productId,
                );
              },
              child: const Text('View Product'),
            ),
          );
        }
        break;

      case 'rating':
        final productId = data['productId'];
        final productName = data['productName'];
        final rated = data['rated'] ?? false;

        if (productId != null && !rated) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Show rating dialog
                _showRatingDialog(
                  data['notificationId'] ?? '',
                  productId,
                  productName ?? 'Product',
                );
              },
              child: const Text('Rate Product'),
            ),
          );
        }
        break;

      case 'wishlist':
      case 'wishlist_availability':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to wishlist screen
              Navigator.pushNamed(context, '/wishlist');
            },
            child: const Text('Go to Wishlist'),
          ),
        );

      case 'security':
      case 'password':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to settings screen
              Navigator.pushNamed(context, '/settings');
            },
            child: const Text('Go to Settings'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primaryColor,
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllNotificationsAsRead,
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            tooltip: 'Notification Settings',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearConfirmation(),
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final allNotifications = snapshot.data?.docs ?? [];

                // Filter notifications based on user preferences
                final notifications = allNotifications.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _isNotificationAllowed(data['type'] ?? '');
                }).toList();

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll be notified about orders, updates and offers',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/notification-settings'),
                          child: const Text('Manage Notification Settings',
                              style: TextStyle(color: primaryColor)),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    // Just wait briefly - the stream will auto-update
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final data = notification.data() as Map<String, dynamic>;
                      final isRead = data['read'] ?? true;
                      final timestamp = data['timestamp'] as Timestamp;
                      final date = timestamp.toDate();

                      return Dismissible(
                        key: Key(notification.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteNotification(notification.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Notification deleted'),
                              backgroundColor: primaryColor,
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: Colors.white,
                                onPressed: () => _undoDelete(),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: isRead ? 0 : 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          color: isRead
                              ? null
                              : const Color(
                                  0xFFE3F2FD), // Light blue for unread
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isRead
                                  ? Colors.grey.shade200
                                  : primaryColor.withOpacity(0.3),
                              width: isRead ? 0.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _viewNotificationDetails(notification),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        _getIconBackgroundColor(data['type']),
                                    child: Icon(
                                      _getIcon(data['type']),
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                data['title'],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['message'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDateTime(date),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    if (_auth.currentUser == null) return;

    try {
      await _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _undoDelete() async {
    // Implement if needed - would require storing the deleted notification
  }

  Future<void> _showClearConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
              onPressed: () {
                _clearAllNotifications();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllNotifications() async {
    if (_auth.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications cleared'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      print('Error clearing notifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_product':
        return Icons.new_releases;
      case 'order':
        return Icons.local_shipping;
      case 'shipping':
        return Icons.local_shipping;
      case 'wishlist':
        return Icons.favorite;
      case 'wishlist_availability':
        return Icons.inventory;
      case 'promo':
        return Icons.discount;
      case 'restock':
        return Icons.inventory;
      case 'security':
        return Icons.security;
      case 'password':
        return Icons.password;
      case 'update':
        return Icons.system_update;
      case 'rating':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'new_product':
        return Colors.purple;
      case 'order':
      case 'shipping':
        return Colors.green;
      case 'wishlist':
      case 'wishlist_availability':
        return Colors.red;
      case 'promo':
        return Colors.orange;
      case 'restock':
        return Colors.blue;
      case 'security':
      case 'password':
        return Colors.deepOrange;
      case 'update':
        return Colors.blue;
      case 'rating':
        return Colors.amber;
      default:
        return primaryColor;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
    } else if (difference.inDays < 7) {
      // Less than a week
      return DateFormat('EEEE').format(dateTime);
    } else {
      // More than a week
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}
