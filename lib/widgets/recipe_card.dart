import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'glass_card.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        height: 200,
        child: Stack(
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                recipe.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 50),
                  );
                },
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Recipe Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassCard(
                height: 80,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookTime} min',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.calories} cal',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recipe Tags
            if (recipe.tags.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recipe.tags.first,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

