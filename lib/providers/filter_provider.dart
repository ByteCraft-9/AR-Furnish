import 'package:flutter/foundation.dart';
import 'package:ar_furnish/models/filter_options.dart';

class FilterProvider with ChangeNotifier {
  FilterOptions _options = const FilterOptions();
  FilterOptions _appliedOptions = const FilterOptions();

  FilterOptions get options => _options;
  FilterOptions get appliedOptions => _appliedOptions;

  void updateFilters(FilterOptions newOptions) {
    _options = newOptions;
    notifyListeners();
  }

  void resetFilters() {
    _options = const FilterOptions();
    notifyListeners();
  }

  void applyFilters() {
    _appliedOptions = _options;
    notifyListeners();
  }
}
