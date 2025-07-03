import 'package:flutter/material.dart';
import 'package:ar_furnish/data/dummy_data.dart';

class CategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: DummyData.categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : DummyData.categories[index - 1];
          final isSelected = isAll
              ? selectedCategory == null
              : selectedCategory == category?['name'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(isAll ? 'All' : category!['name']),
              selected: isSelected,
              onSelected: (_) =>
                  onCategorySelected(isAll ? null : category!['name']),
            ),
          );
        },
      ),
    );
  }
}
