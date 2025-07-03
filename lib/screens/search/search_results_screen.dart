import 'package:ar_furnish/models/product.dart';
import 'package:ar_furnish/providers/filter_provider.dart';
import 'package:ar_furnish/utils/product_filters.dart';
import 'package:ar_furnish/models/filter_options.dart';
import 'package:ar_furnish/widgets/product_grid.dart';
import 'package:ar_furnish/widgets/search/filter_drawer.dart';
import 'package:flutter/material.dart';
import 'package:ar_furnish/services/product_service.dart';
import 'package:ar_furnish/widgets/search/custom_search_bar.dart';
import 'package:provider/provider.dart';

// Add the accent color
const Color accentColor = Color(0xFF854836);

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _searchQuery;
  final ProductService _productService = ProductService();
  List<Product> _searchResults = [];
  List<Product> _filteredResults = [];
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery;
    _mounted = true;

    // Load products first
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    } else {
      _fetchAllProducts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up listener for filter changes
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    _applyFilters(filterProvider.appliedOptions);
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _applyFilters(FilterOptions options) {
    if (!_mounted) return;

    // Debug loaded products
    if (_searchResults.isNotEmpty) {
      ProductFilters.debugProducts(_searchResults.take(3).toList());
    }

    setState(() {
      // Use the ProductFilters utility class for consistent filtering
      _filteredResults = ProductFilters.applyFilters(_searchResults, options);
    });
  }

  Future<void> _fetchAllProducts() async {
    if (!_mounted) return;

    setState(() => _isLoading = true);
    try {
      final results = await _productService.getProducts();
      if (!_mounted) return;

      setState(() {
        _searchResults = results;
        _filteredResults = results;
      });

      // Apply current filters to the loaded products
      final filterProvider =
          Provider.of<FilterProvider>(context, listen: false);
      _applyFilters(filterProvider.appliedOptions);
    } catch (e) {
      if (!_mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching products: $e')),
      );
    } finally {
      if (!_mounted) return;

      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (!_mounted) return;

    if (query.isEmpty) {
      _fetchAllProducts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _productService.searchProducts(query);
      if (!_mounted) return;

      setState(() {
        _searchResults = results;
        _filteredResults = results;
      });

      // Apply current filters to the loaded products
      final filterProvider =
          Provider.of<FilterProvider>(context, listen: false);
      _applyFilters(filterProvider.appliedOptions);
    } catch (e) {
      if (!_mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!_mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: CustomSearchBar(
          initialValue: _searchQuery,
          onSearch: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const FilterDrawer(),
      body: Consumer<FilterProvider>(
        builder: (context, filterProvider, child) {
          // Apply filters when they change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyFilters(filterProvider.appliedOptions);
          });

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No results found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Only showing available products',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              filterProvider.resetFilters();
                              filterProvider.applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                            ),
                            child: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    )
                  : ProductGrid(products: _filteredResults);
        },
      ),
    );
  }
}
