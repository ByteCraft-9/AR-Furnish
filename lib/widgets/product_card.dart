import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_furnish/models/product.dart';
import 'package:ar_furnish/providers/wishlist_provider.dart';

const Color primaryColor = Color(0xFF854836);

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/product',
          arguments: product,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Stack(
                  children: [
                    if (product.images.isNotEmpty)
                      Image.network(
                        product.images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.4),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.4),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<WishlistProvider>(
                        builder: (context, wishlist, _) => IconButton(
                          icon: Icon(
                            wishlist.isInWishlist(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: wishlist.isInWishlist(product.id)
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                          ),
                          onPressed: () => wishlist.toggleWishlist(product),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        Text(
                          '${product.rating}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${product.reviewCount})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
