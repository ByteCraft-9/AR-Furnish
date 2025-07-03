import 'package:ar_furnish/widgets/product_grid.dart';
import 'package:flutter/material.dart';
import 'package:ar_furnish/services/product_service.dart';
import 'package:ar_furnish/widgets/category/category_filter.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String? initialCategory;

  const CategoryProductsScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final _productService = ProductService();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() => _selectedCategory = category);
            },
          ),
          Expanded(
            child: FutureBuilder(
              future: _selectedCategory == null
                  ? _productService.getProducts()
                  : _productService.getProductsByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProductGrid(isLoading: true);
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return ProductGrid(products: snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
    );
  }
}
