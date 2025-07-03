import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF854836);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              selected: isSelected,
              onSelected: (_) =>
                  onCategorySelected(isSelected ? null : category),
              backgroundColor: isDark ? theme.cardColor : Colors.grey[100],
              selectedColor: primaryColor.withOpacity(0.2),
              checkmarkColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
