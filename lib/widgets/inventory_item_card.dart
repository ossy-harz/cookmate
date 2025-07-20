import 'package:flutter/material.dart';
import '../models/inventory_item_model.dart';
import 'glass_card.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItemModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const InventoryItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpiringSoon = item.expiryDate != null &&
        item.expiryDate!.difference(DateTime.now()).inDays < 3;
    final isLowStock = item.quantity < 2; // Default low stock threshold

    return GlassCard(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Category Icon or Item Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(item.category),
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantity: ${item.quantity} ${item.unit}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (item.expiryDate != null)
                    Text(
                      'Expires: ${_formatDate(item.expiryDate!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isExpiringSoon ? Colors.red : null,
                        fontWeight: isExpiringSoon ? FontWeight.bold : null,
                      ),
                    ),
                ],
              ),
            ),

            // Status Indicators and Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Low',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.egg;
      case 'meat & seafood':
        return Icons.restaurant;
      case 'grains & bakery':
        return Icons.grain;
      case 'condiments & spices':
        return Icons.spa;
      case 'beverages':
        return Icons.local_drink;
      default:
        return Icons.kitchen;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

