// ignore_for_file: unused_local_variable

import 'package:ar_furnish/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ar_furnish/widgets/home/category_chips.dart';
import 'package:ar_furnish/widgets/product/product_card_improved.dart';
import 'package:ar_furnish/providers/wishlist_provider.dart';
import 'package:ar_furnish/services/product_service.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ar_furnish/screens/settings/notification.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreenImproved extends StatefulWidget {
  const HomeScreenImproved({super.key});

  @override
  State<HomeScreenImproved> createState() => _HomeScreenImprovedState();
}

class _HomeScreenImprovedState extends State<HomeScreenImproved>
    with AutomaticKeepAliveClientMixin {
  String? _selectedCategory;
  final _productService = ProductService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<String> carouselImages = [];
  bool _isCarouselLoading = true;
  List<Product> _products = [];
  bool _isLoading = true;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCarouselImages();
    _fetchProducts();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    if (_auth.currentUser == null) return;

    try {
      // First get user notification preferences
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      final Map<String, bool> notificationPrefs = userDoc.exists
          ? Map<String, bool>.from(
              userDoc.data()?['notificationPreferences'] ?? {})
          : {};

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
      };

      // Function to check if notification is allowed based on preferences
      bool isNotificationAllowed(String type) {
        final preferenceKey = typeToPreferenceKey[type] ?? '';
        if (preferenceKey.isEmpty) return true;
        // If preferences are empty, show all notifications
        return notificationPrefs.isEmpty ||
            (notificationPrefs[preferenceKey] ?? true);
      }

      // Listen to notifications collection for real-time updates
      _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        // Count only notifications that match user preferences
        final filteredCount = snapshot.docs.where((doc) {
          final data = doc.data();
          return isNotificationAllowed(data['type'] ?? '');
        }).length;

        setState(() {
          _notificationCount = filteredCount;
        });
      });
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  Future<void> _fetchCarouselImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('promotion')
          .doc('kofu1TezEPjKHMZX9XMJ')
          .get();

      if (snapshot.exists) {
        final imageUrls = List<String>.from(snapshot['image_urls'] ?? []);
        setState(() {
          carouselImages = imageUrls;
          _isCarouselLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching images: $e");
      setState(() {
        _isCarouselLoading = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // Get only enabled products (is_enable = true)
      List<Product> enabledProducts =
          await _productService.getEnabledProducts();

      if (_selectedCategory != null) {
        _products = enabledProducts
            .where((product) => product.category == _selectedCategory)
            .toList();
      } else {
        _products = _getRandomProducts(enabledProducts, 10);
      }
    } catch (e) {
      print("Error fetching products: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Product> _getRandomProducts(List<Product> products, int count) {
    if (products.isEmpty) return [];
    products.shuffle(Random());
    return products.take(min(count, products.length)).toList();
  }

  void _openNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );

    // Mark notifications as read when user views them
    if (_auth.currentUser != null && _notificationCount > 0) {
      _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'read': true});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF854836),
        toolbarHeight: 80.0,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('AR ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                Text('Furnish',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: badges.Badge(
              showBadge: _notificationCount > 0,
              badgeContent: Text(
                _notificationCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(5),
              ),
              child:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: _openNotificationsScreen,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchProducts(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: 30.0),
            ),
            SliverToBoxAdapter(
              child: _isCarouselLoading
                  ? Center(
                      child: CircularProgressIndicator(
                      color: const Color(0xFF854836),
                    ))
                  : CarouselSlider(
                      options: CarouselOptions(
                        height: 200.0,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        autoPlayCurve: Curves.fastOutSlowIn,
                        enableInfiniteScroll: true,
                        autoPlayAnimationDuration:
                            const Duration(milliseconds: 800),
                        viewportFraction: 0.8,
                      ),
                      items: carouselImages.map((url) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: theme.cardColor,
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CategoryChips(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                      _fetchProducts();
                    });
                  },
                  categories: [
                    'Sofa',
                    'Living Room',
                    'Bed',
                    'Office',
                    'Outdoor',
                    'Dining',
                  ],
                ),
              ),
            ),
            Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                return _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Color(0xFF854836),
                        )),
                      )
                    : _products.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 64, color: const Color(0xFF854836)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No available products found',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please check back later',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = _products[index];
                                  return ProductCardImproved(
                                    product: product,
                                    isWishlisted:
                                        wishlist.isInWishlist(product.id),
                                    onWishlistTap: () =>
                                        wishlist.toggleWishlist(product),
                                    onTap: () {
                                      Navigator.pushNamed(context, '/product',
                                          arguments: product);
                                    },
                                  );
                                },
                                childCount: _products.length,
                              ),
                            ),
                          );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF854836),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/search');
                  },
                  child: const Text('See All Products'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
