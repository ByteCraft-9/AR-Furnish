// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ar_furnish/models/product.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:ar_furnish/providers/cart_provider.dart';
import 'package:ar_furnish/providers/wishlist_provider.dart';
import 'package:ar_furnish/screens/chat/chat_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'dart:io' show Platform;
import 'dart:io';

const Color primaryColor = Color(0xFF854836);

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product})
      : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _expanded = false;
  bool _isFullScreenView = false;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize quantity to 1 or 0 if out of stock
    _quantity = widget.product.quantity > 0 ? 1 : 0;
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.quantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Color _getStockBadgeColor() {
    if (widget.product.quantity == 0) {
      return Colors.red;
    } else if (widget.product.quantity <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStockText() {
    if (widget.product.quantity == 0) {
      return 'Out of Stock';
    } else if (widget.product.quantity <= 3) {
      return '${widget.product.quantity} items remaining';
    } else {
      return 'In Stock';
    }
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1 ? _decrementQuantity : null,
            icon: const Icon(Icons.remove, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _quantity.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            onPressed:
                _quantity < widget.product.quantity ? _incrementQuantity : null,
            icon: const Icon(Icons.add, size: 20),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.product.quantity > 0
          ? () {
              final cart = context.read<CartProvider>();
              cart.addItem(widget.product, _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to cart'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            widget.product.quantity > 0 ? primaryColor : Colors.grey,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
      child: Text(
        widget.product.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStockBadgeColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getStockText(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _isFullScreenView
          ? null // No AppBar in full-screen mode
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Share functionality with error handling
                    try {
                      Share.share(
                        'Check out ${widget.product.name} for PKR ${widget.product.price.toStringAsFixed(0)} on AR Furnish App!',
                        subject: 'Great furniture I found in AR Furnish',
                      );
                    } catch (e) {
                      // Fallback if Share.share fails
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Sharing not available on this device'),
                          backgroundColor: primaryColor,
                        ),
                      );
                      print('Error sharing: $e');
                    }
                  },
                ),
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final isInWishlist =
                        wishlistProvider.isInWishlist(widget.product.id);
                    return IconButton(
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? primaryColor : Colors.white,
                      ),
                      onPressed: () {
                        wishlistProvider.toggleWishlist(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isInWishlist
                                ? '${widget.product.name} removed from wishlist'
                                : '${widget.product.name} added to wishlist'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          // Full-screen image view
          if (_isFullScreenView)
            Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  // Image carousel
                  CarouselSlider(
                    items: widget.product.images.map((imageUrl) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                        ),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height,
                      viewportFraction: 1.0,
                      enlargeCenterPage: false,
                      enableInfiniteScroll: true,
                      initialPage: _currentImageIndex,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                  ),

                  // Custom close button positioned at top-right
                  Positioned(
                    top: 40,
                    right: 20,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isFullScreenView = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ),

                  // Image indicator dots
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedSmoothIndicator(
                        activeIndex: _currentImageIndex,
                        count: widget.product.images.length,
                        effect: ExpandingDotsEffect(
                          dotWidth: 8,
                          dotHeight: 8,
                          activeDotColor: primaryColor,
                          dotColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Stack(
              children: [
                // Product Images Section
                Column(
                  children: [
                    Stack(
                      children: [
                        // Image carousel
                        CarouselSlider(
                          items: widget.product.images.map((imageUrl) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isFullScreenView = true;
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.center,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          options: CarouselOptions(
                            height: MediaQuery.of(context).size.height * 0.5,
                            viewportFraction: 1.0,
                            enlargeCenterPage: false,
                            enableInfiniteScroll: true,
                            autoPlay: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                        ),

                        // Image indicator dots using smooth_page_indicator
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSmoothIndicator(
                              activeIndex: _currentImageIndex,
                              count: widget.product.images.length,
                              effect: ExpandingDotsEffect(
                                dotWidth: 8,
                                dotHeight: 8,
                                activeDotColor: primaryColor,
                                dotColor: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Expand image button
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isFullScreenView = true;
                              });
                            },
                            icon: const Icon(Icons.fullscreen),
                            label: const Text('Full Screen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),

                        // View in AR button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (Platform.isAndroid) {
                                const String arPackageName =
                                    "com.unity.arfurnish";

                                try {
                                  final intent = AndroidIntent(
                                    action: 'NAVIGATE_ACTION',
                                    package: arPackageName,
                                    flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                                  );

                                  await intent.launch();
                                } catch (error) {
                                  print("Error launching AR app: $error");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to start AR app: ${error.toString()}'),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'AR view is only available on Android devices'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.view_in_ar),
                            label: const Text('View in AR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.blue, // Replace with your primaryColor
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Product Details Card (DraggableScrollableSheet)
                DraggableScrollableSheet(
                  initialChildSize: 0.52,
                  minChildSize: 0.52,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor
                                .withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Drag handle indicator
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Product name and price section
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.product.name,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'PKR ${widget.product.price.toStringAsFixed(0)}',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      if (widget.product.price > 1000)
                                        Text(
                                          '${(widget.product.price * 0.9).toStringAsFixed(0)} with discount',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: theme
                                                .textTheme.bodyMedium?.color
                                                ?.withOpacity(0.6),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      _buildStockBadge(),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Rating and reviews
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.product.rating
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${widget.product.reviewCount} reviews)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                    ),
                                  ),
                                  const Spacer(),

                                  // Color indicator
                                  Text(
                                    'Color: ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _getColorFromString(
                                          widget.product.color),
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: theme.dividerColor),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Description
                              Text(
                                'Description',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _expanded = !_expanded;
                                  });
                                },
                                child: AnimatedCrossFade(
                                  firstChild: Text(
                                    widget.product.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondChild: Text(
                                    widget.product.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                  crossFadeState: _expanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ),
                              if (!_expanded)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _expanded = true;
                                      });
                                    },
                                    child: const Text(
                                      'Read more',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Product specifications
                              Text(
                                'Specifications',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSpecifications(),

                              const SizedBox(height: 24),

                              // Delivery info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.cardColor.withOpacity(0.5)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping_outlined,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Free Delivery',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Orders over PKR 5,000',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .textTheme.bodyMedium?.color
                                                  ?.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.access_time,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Returns',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '30 Days Return Policy',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .textTheme.bodyMedium?.color
                                                  ?.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Bottom Bar for Add to Cart
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor
                              .withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity controls
                        _buildQuantitySelector(),

                        const SizedBox(width: 8),

                        // Chat button
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatScreen(productId: widget.product.id),
                                ),
                              );
                            },
                            icon:
                                const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Chat',
                                style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Add to cart button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: _buildAddToCartButton(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSpecifications() {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSpecItem('Category', widget.product.category),
        _buildSpecItem('Color', widget.product.color),
        _buildSpecItem('Material', 'Premium Quality'),
        _buildSpecItem('Dimensions',
            '${70 + widget.product.id}cm × ${50 + widget.product.id}cm × ${40 + widget.product.id}cm'),
        _buildSpecItem('Weight', '${5 + (widget.product.id % 10)} kg'),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'brown':
        return Colors.brown;
      case 'teal':
        return Colors.teal;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.grey; // Default color if not found
    }
  }
}
