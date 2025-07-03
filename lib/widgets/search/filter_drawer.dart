import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ar_furnish/providers/filter_provider.dart';
import 'package:ar_furnish/widgets/search/filter_section.dart';

// Add the accent color
const Color accentColor = Color(0xFF854836);

class FilterDrawer extends StatelessWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<FilterProvider>(
        builder: (context, filterProvider, child) {
          final options = filterProvider.options;

          return Column(
            children: [
              AppBar(
                title: const Text('Filters'),
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: () {
                      filterProvider.resetFilters();
                      // Apply the reset filters immediately
                      filterProvider.applyFilters();
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilterSection(
                      title: 'Price Range (PKR)',
                      child: RangeSlider(
                        values: RangeValues(
                          options.minPrice ?? 0,
                          options.maxPrice ?? 100000,
                        ),
                        min: 0,
                        max: 100000,
                        divisions: 20,
                        activeColor: accentColor,
                        inactiveColor: accentColor.withOpacity(0.3),
                        labels: RangeLabels(
                          'PKR ${options.minPrice?.toStringAsFixed(0) ?? '0'}',
                          'PKR ${options.maxPrice?.toStringAsFixed(0) ?? '100000'}',
                        ),
                        onChanged: (values) {
                          filterProvider.updateFilters(options.copyWith(
                            minPrice: values.start,
                            maxPrice: values.end,
                          ));
                        },
                      ),
                    ),
                    FilterSection(
                      title:
                          'Rating (${options.minRating?.toStringAsFixed(1) ?? 'Any'}+)',
                      child: Slider(
                        value: options.minRating ?? 0,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: accentColor,
                        inactiveColor: accentColor.withOpacity(0.3),
                        label: options.minRating == 0
                            ? 'Any Rating'
                            : '${options.minRating?.toStringAsFixed(1)}+',
                        onChanged: (value) {
                          // Round to nearest 0.5
                          final roundedValue = (value * 2).round() / 2;
                          filterProvider.updateFilters(
                            options.copyWith(minRating: roundedValue),
                          );
                        },
                      ),
                    ),
                    // Add categories filter
                    FilterSection(
                      title: 'Categories',
                      child: Wrap(
                        spacing: 8.0,
                        children: [
                          'All',
                          'Chair',
                          'Table',
                          'Sofa',
                          'Bed',
                          'Living Room',
                          'outdoor',
                          'Storage',
                          'General'
                        ].map((category) {
                          final isSelected = options.category == category ||
                              (category == 'All' && options.category == null);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: accentColor.withOpacity(0.2),
                            checkmarkColor: accentColor,
                            onSelected: (selected) {
                              filterProvider.updateFilters(options.copyWith(
                                category: selected && category != 'All'
                                    ? category
                                    : null,
                              ));
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    // Add color filter
                    FilterSection(
                      title: 'Colors',
                      child: Wrap(
                        spacing: 8.0,
                        children: [
                          {'name': 'Black', 'color': Colors.black},
                          {'name': 'White', 'color': Colors.white},
                          {'name': 'Brown', 'color': Colors.brown},
                          {'name': 'Brawn', 'color': Colors.brown.shade700},
                          {'name': 'Grey', 'color': Colors.grey},
                          {'name': 'Blue', 'color': Colors.blue},
                          {'name': 'Red', 'color': Colors.red},
                          {'name': 'Green', 'color': Colors.green},
                          {'name': 'Yellow', 'color': Colors.yellow},
                          {'name': 'Teal', 'color': Colors.teal},
                        ].map((colorOption) {
                          final colorName = colorOption['name'] as String;
                          final color = colorOption['color'] as Color;
                          final isSelected = options.color == colorName;
                          return FilterChip(
                            label: Text(colorName),
                            selected: isSelected,
                            selectedColor: accentColor.withOpacity(0.2),
                            avatar: CircleAvatar(
                              backgroundColor: color,
                              radius: 10,
                            ),
                            onSelected: (selected) {
                              filterProvider.updateFilters(options.copyWith(
                                color: selected ? colorName : null,
                              ));
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Debug info
                    Text(
                      'Current filters: ${options.category ?? 'All categories'}, '
                      '${options.minRating != null && options.minRating! > 0 ? '${options.minRating}+ rating' : 'Any rating'}, '
                      '${options.color ?? 'Any color'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      filterProvider.applyFilters();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Filters applied successfully!')),
                      );
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
