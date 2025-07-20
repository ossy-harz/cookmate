import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/inventory_service.dart';
import '../../models/meal_plan_model.dart';
import '../../models/inventory_item_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder(
        future: authService.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading your dashboard...');
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: 'Error: ${snapshot.error}',
              buttonText: 'Try Again',
              onButtonPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
            );
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const EmptyState(
              icon: Icons.person_off,
              title: 'User data not found',
              message: 'Please sign in again to access your dashboard',
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Welcome, ${userData.displayName?.split(' ')[0] ?? 'Chef'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/dashboard_header.jpg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
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
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Today\'s Meals', _buildTodaysMeals(context, userData.uid)),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Expiring Soon', _buildExpiringItems(context, userData.uid)),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Quick Actions', _buildQuickActions(context)),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Today\'s Nutrition', _buildNutritionSummary(context, userData.uid)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildTodaysMeals(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return StreamBuilder<List<MealPlanModel>>(
      stream: Provider.of<MealPlanService>(context).getMealPlans(
        userId,
        startOfDay,
        endOfDay,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final mealPlans = snapshot.data ?? [];

        if (mealPlans.isEmpty) {
          return GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  'No meals planned for today',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/meal-planner');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Meal'),
                ),
              ],
            ),
          );
        }

        final meals = mealPlans.first.meals;

        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          meal.recipeImageUrl ?? 'https://via.placeholder.com/160x100',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.restaurant,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.mealType.toUpperCase(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal.recipeName,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${meal.servings} serving${meal.servings > 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpiringItems(BuildContext context, String userId) {
    final theme = Theme.of(context);

    return StreamBuilder<List<InventoryItemModel>>(
      stream: Provider.of<InventoryService>(context).getExpiringItems(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final expiringItems = snapshot.data ?? [];

        if (expiringItems.isEmpty) {
          return GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  'No items expiring soon',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: expiringItems.length,
            itemBuilder: (context, index) {
              final item = expiringItems[index];
              final daysUntilExpiry = item.expiryDate != null
                  ? item.expiryDate!.difference(DateTime.now()).inDays
                  : 0;

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: GlassCard(
                  backgroundColor: daysUntilExpiry <= 2
                      ? Colors.red.withOpacity(0.1)
                      : daysUntilExpiry <= 5
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.expiryDate != null
                            ? 'Expires in $daysUntilExpiry day${daysUntilExpiry != 1 ? 's' : ''}'
                            : 'No expiry date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: daysUntilExpiry <= 2
                              ? Colors.red
                              : daysUntilExpiry <= 5
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/recipes');
            },
            child: GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 32,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Recipe',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/shopping-list');
            },
            child: GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shopping List',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/ai-recipe');
            },
            child: GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI Recipe',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/inventory');
            },
            child: GlassCard(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 32,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add Item',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSummary(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return StreamBuilder<List<MealPlanModel>>(
      stream: Provider.of<MealPlanService>(context).getMealPlans(
        userId,
        startOfDay,
        endOfDay,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final mealPlans = snapshot.data ?? [];

        if (mealPlans.isEmpty || mealPlans.first.nutritionSummary == null) {
          return GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.pie_chart,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  'No nutrition data available',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final nutritionSummary = mealPlans.first.nutritionSummary!;

        return GlassCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutritionItem(
                    context,
                    'Calories',
                    '${nutritionSummary['calories']}',
                    'kcal',
                    Colors.red,
                  ),
                  _buildNutritionItem(
                    context,
                    'Protein',
                    '${nutritionSummary['protein']}',
                    'g',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutritionItem(
                    context,
                    'Carbs',
                    '${nutritionSummary['carbs']}',
                    'g',
                    Colors.green,
                  ),
                  _buildNutritionItem(
                    context,
                    'Fat',
                    '${nutritionSummary['fat']}',
                    'g',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionItem(
      BuildContext context,
      String label,
      String value,
      String unit,
      Color color,
      ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
