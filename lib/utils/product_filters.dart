import 'package:ar_furnish/models/filter_options.dart';
import 'package:ar_furnish/models/product.dart';

class ProductFilters {
  static List<Product> applyFilters(
    List<Product> products,
    FilterOptions options,
  ) {
    // Log filter options being applied
    print('Applying filters: Category=${options.category}, '
        'Price=${options.minPrice}-${options.maxPrice}, '
        'Rating=${options.minRating}, Color=${options.color}');

    final filteredProducts = products.where((product) {
      bool includeProduct = true;
      String filterFailReason = '';

      // Apply category filter
      if (options.category != null) {
        final productCategory = product.category.toLowerCase();
        final filterCategory = options.category!.toLowerCase();
        final categoryMatches = productCategory.contains(filterCategory) ||
            filterCategory.contains(productCategory);

        if (!categoryMatches) {
          includeProduct = false;
          filterFailReason =
              'Category mismatch: ${product.category} != ${options.category}';
        }
      }

      // Apply price filter
      if (includeProduct &&
          options.minPrice != null &&
          product.price < options.minPrice!) {
        includeProduct = false;
        filterFailReason =
            'Price below min: ${product.price} < ${options.minPrice}';
      }

      if (includeProduct &&
          options.maxPrice != null &&
          product.price > options.maxPrice!) {
        includeProduct = false;
        filterFailReason =
            'Price above max: ${product.price} > ${options.maxPrice}';
      }

      // Apply rating filter with a small tolerance (0.1) for floating point comparison
      if (includeProduct && options.minRating != null) {
        // Only filter if minRating is greater than 0 (default slider position)
        if (options.minRating! > 0 &&
            product.rating < options.minRating! - 0.1) {
          includeProduct = false;
          filterFailReason =
              'Rating too low: ${product.rating} < ${options.minRating}';
        }
      }

      // Apply color filter
      if (includeProduct && options.color != null) {
        final productColor = product.color.toLowerCase();
        final filterColor = options.color!.toLowerCase();

        // More flexible color matching - check for partial matches
        final colorMatches = productColor.contains(filterColor) ||
            filterColor.contains(productColor);

        if (!colorMatches) {
          includeProduct = false;
          filterFailReason =
              'Color mismatch: ${product.color} != ${options.color}';
        }
      }

      // Print why this product was filtered out
      if (!includeProduct) {
        print('Filtered out: ${product.name} - $filterFailReason');
      }

      return includeProduct;
    }).toList();

    // Log result counts
    print(
        'Filter results: ${filteredProducts.length} of ${products.length} products');

    // If we got no results, debug all the products
    if (filteredProducts.isEmpty && products.isNotEmpty) {
      print('No matches found. All available products:');
      debugProducts(products);
    }

    return filteredProducts;
  }

  // Debug function to print product information
  static void debugProducts(List<Product> products) {
    print('=== DEBUG PRODUCTS (${products.length}) ===');
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      print('[$i] ${p.name} - Category: ${p.category}, '
          'Color: ${p.color}, Price: ${p.price}, Rating: ${p.rating}');
    }
    print('===================================');
  }
}
