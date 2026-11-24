import 'package:material_ui/material_ui.dart';

enum ItemCategory {
  books('Books'),
  notes('Notes'),
  chargers('Chargers'),
  labGear('Lab gear'),
  other('Other');

  final String displayName;
  const ItemCategory(this.displayName);

  static ItemCategory fromString(String? value) {
    if (value == null) return ItemCategory.other;
    final normalized = value.trim().toLowerCase();
    for (final cat in ItemCategory.values) {
      if (cat.displayName.toLowerCase() == normalized ||
          cat.name.toLowerCase() == normalized) {
        return cat;
      }
    }
    return ItemCategory.other;
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.books:
        return Icons.menu_book_rounded;
      case ItemCategory.notes:
        return Icons.description_rounded;
      case ItemCategory.chargers:
        return Icons.electrical_services_rounded;
      case ItemCategory.labGear:
        return Icons.biotech_rounded;
      case ItemCategory.other:
        return Icons.inventory_2_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ItemCategory.books:
        return const Color(0xFF2E7D32); // Deep green
      case ItemCategory.notes:
        return const Color(0xFFF57C00); // Amber orange
      case ItemCategory.chargers:
        return const Color(0xFF0288D1); // Light blue
      case ItemCategory.labGear:
        return const Color(0xFF7B1FA2); // Deep purple
      case ItemCategory.other:
        return const Color(0xFF616161); // Slate grey
    }
  }
}
