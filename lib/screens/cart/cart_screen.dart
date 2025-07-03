// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_furnish/providers/cart_provider.dart';
import 'package:ar_furnish/widgets/cart_item_card.dart';

// Define the primary color to use throughout
const Color primaryColor = Color(0xFF854836);

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with AutomaticKeepAliveClientMixin {
  // Set to track selected items for checkout
  final Set<int> _selectedItems = {};
  bool _selectAllItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty || cart.isLoading) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  _selectAllItems
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _selectAllItems = !_selectAllItems;
                    if (_selectAllItems) {
                      _selectedItems.addAll(cart.items.keys);
                    } else {
                      _selectedItems.clear();
                    }
                  });
                },
                tooltip: _selectAllItems ? 'Unselect All' : 'Select All',
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // Show loading spinner while cart is loading
          if (cart.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          // Show empty cart message
          if (cart.isEmpty) {
            return _buildEmptyCart(context);
          }

          // Show cart with items
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final itemId = cart.items.keys.toList()[i];
                    final item = cart.items.values.toList()[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Checkbox for item selection
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 0),
                          child: Transform.scale(
                            scale: 0.9,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setState(() {
                                    if (_selectedItems.contains(itemId)) {
                                      _selectedItems.remove(itemId);
                                    } else {
                                      _selectedItems.add(itemId);
                                    }
                                    // Update select all status
                                    _selectAllItems = _selectedItems.length ==
                                        cart.items.length;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedItems.contains(itemId)
                                        ? primaryColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedItems.contains(itemId)
                                          ? primaryColor
                                          : theme.dividerColor,
                                      width: 2,
                                    ),
                                  ),
                                  width: 24,
                                  height: 24,
                                  child: _selectedItems.contains(itemId)
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Item card
                        Expanded(
                          child: CartItemCard(cartItem: item),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildCartSummary(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_bag, color: Colors.white),
            label: const Text('Start Shopping',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              // Navigate to products/home screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cart) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate total of selected items
    double selectedTotal = 0.0;
    for (var id in _selectedItems) {
      if (cart.items.containsKey(id)) {
        selectedTotal += cart.items[id]!.totalPrice;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(isDark ? 0.2 : 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedItems.isEmpty
                    ? 'Total:'
                    : 'Selected Items (${_selectedItems.length}):',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PKR ${(_selectedItems.isEmpty ? 0.0 : selectedTotal).toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedItems.isEmpty
                  ? null // Disable button if no items selected
                  : () {
                      // Pass selected items to checkout
                      Provider.of<CartProvider>(context, listen: false)
                          .setSelectedItemsForCheckout(_selectedItems.toList());
                      Navigator.of(context).pushNamed('/checkout');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: theme.disabledColor,
                disabledForegroundColor: theme.disabledColor.withOpacity(0.6),
              ),
              child: Text(
                _selectedItems.isEmpty
                    ? 'Select Items to Checkout'
                    : 'Proceed to Checkout (${_selectedItems.length})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
