class FilterOptions {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final List<String> materials;
  final List<String> colors;
  final String? color;

  const FilterOptions({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.materials = const [],
    this.colors = const [],
    this.color,
  });

  FilterOptions copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? materials,
    List<String>? colors,
    String? color,
  }) {
    return FilterOptions(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      materials: materials ?? this.materials,
      colors: colors ?? this.colors,
      color: color ?? this.color,
    );
  }
}
