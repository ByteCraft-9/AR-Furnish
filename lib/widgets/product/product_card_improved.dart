import 'package:ar_furnish/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:ar_furnish/models/product.dart';

class ProductCardImproved extends StatelessWidget {
  final Product product;
  final bool isWishlisted;
  final VoidCallback onWishlistTap;
  final VoidCallback onTap;

  const ProductCardImproved({
    Key? key,
    required this.product,
    required this.isWishlisted,
    required this.onWishlistTap,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          height: 300,
          child: Stack(
            children: [
              // Product content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(product.featureImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Product info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PKR ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Wishlist button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted ? Colors.red : Colors.grey,
                  ),
                  onPressed: onWishlistTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
