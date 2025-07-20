import 'package:flutter/material.dart';
import '../models/meal_plan_model.dart';
import 'glass_card.dart';

class MealPlanCard extends StatelessWidget {
  final MealPlanModel mealPlan;
  final VoidCallback onTap;

  const MealPlanCard({
    Key? key,
    required this.mealPlan,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate total calories for this meal plan
    int totalCalories = 0;
    for (final meal in mealPlan.meals) {
      if (meal.nutritionInfo != null && meal.nutritionInfo!.containsKey('calories')) {
        totalCalories += (meal.nutritionInfo!['calories'] as num).toInt();
      }
    }

    return GlassCard(
      height: 150,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Meal Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(mealPlan.date),
                  style: theme.textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${mealPlan.meals.length} meals',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meal Types
            Text(
              _getMealTypesText(mealPlan.meals),
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Nutritional Info
            if (mealPlan.nutritionSummary != null)
              Row(
                children: [
                  _nutritionItem(context, 'Calories', '${mealPlan.nutritionSummary!['calories'] ?? totalCalories} cal', Icons.local_fire_department),
                  _nutritionItem(context, 'Protein', '${mealPlan.nutritionSummary!['protein'] ?? 0}g', Icons.fitness_center),
                  _nutritionItem(context, 'Carbs', '${mealPlan.nutritionSummary!['carbs'] ?? 0}g', Icons.grain),
                  _nutritionItem(context, 'Fat', '${mealPlan.nutritionSummary!['fat'] ?? 0}g', Icons.opacity),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getMealTypesText(List<MealEntry> meals) {
    final mealTypes = meals.map((meal) => _capitalizeFirst(meal.mealType)).toSet().toList();
    return mealTypes.join(', ');
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

