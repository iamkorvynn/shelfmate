// [ShelfMate Dev Step 1/2]: Create CategoryBadge widget with category icon and label
import 'package:material_ui/material_ui.dart';
import '../../models/category.dart';

class CategoryBadge extends StatelessWidget {
  final ItemCategory category;
  final bool showIcon;

  const CategoryBadge({
    super.key,
    required this.category,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(category.icon, size: 13, color: category.color),
            const SizedBox(width: 4),
          ],
          Text(
            category.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}
