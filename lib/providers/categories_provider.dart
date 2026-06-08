import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/manage_service_model.dart';

/// Holds the list of categories fetched from /api/partner/categories.
/// Only categories where [ManageService.isSelected] == true are kept.
class SelectedCategoriesNotifier extends StateNotifier<List<ManageService>> {
  SelectedCategoriesNotifier() : super(const []);

  void setCategories(List<ManageService> categories) {
    state = categories.where((c) => c.isSelected).toList();
  }
}

final selectedCategoriesProvider =
    StateNotifierProvider<SelectedCategoriesNotifier, List<ManageService>>(
  (ref) => SelectedCategoriesNotifier(),
);
