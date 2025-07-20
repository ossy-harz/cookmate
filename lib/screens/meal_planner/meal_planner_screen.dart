import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/auth_service.dart';
import '../../services/meal_plan_service.dart';
import '../../models/meal_plan_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({Key? key}) : super(key: key);

  @override
  _MealPlannerScreenState createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Meal Planner'),
              floating: true,
              pinned: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    setState(() {
                      if (_calendarFormat == CalendarFormat.week) {
                        _calendarFormat = CalendarFormat.month;
                      } else {
                        _calendarFormat = CalendarFormat.week;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddMealDialog(context);
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: theme.textTheme.titleLarge!,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.primary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: FutureBuilder(
          future: authService.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final userData = snapshot.data;

            if (userData == null) {
              return const Center(child: Text('User data not found'));
            }

            return _buildMealList(context, userData.uid);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddMealDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }

  Widget _buildMealList(BuildContext context, String userId) {
    final theme = Theme.of(context);
    final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);

    return StreamBuilder<List<MealPlanModel>>(
      stream: Provider.of<MealPlanService>(context).getMealPlans(
        userId,
        startOfDay,
        endOfDay,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final mealPlans = snapshot.data ?? [];

        if (mealPlans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No meals planned for ${DateFormat('MMMM d, yyyy').format(_selectedDay)}',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddMealDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Meal'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        final meals = mealPlans.first.meals;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Breakfast
              _buildMealTypeSection(context, 'Breakfast', meals.where((m) => m.mealType.toLowerCase() == 'breakfast').toList()),
              const SizedBox(height: 24),

              // Lunch
              _buildMealTypeSection(context, 'Lunch', meals.where((m) => m.mealType.toLowerCase() == 'lunch').toList()),
              const SizedBox(height: 24),

              // Dinner
              _buildMealTypeSection(context, 'Dinner', meals.where((m) => m.mealType.toLowerCase() == 'dinner').toList()),
              const SizedBox(height: 24),

              // Snacks
              _buildMealTypeSection(context, 'Snacks', meals.where((m) => m.mealType.toLowerCase() == 'snack').toList()),

              // Nutrition Summary
              if (mealPlans.first.nutritionSummary != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Nutrition Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionItem(
                        context,
                        'Calories',
                        '${mealPlans.first.nutritionSummary!['calories']}',
                        'kcal',
                        theme.colorScheme.secondary,
                      ),
                      _buildNutritionItem(
                        context,
                        'Protein',
                        '${mealPlans.first.nutritionSummary!['protein']}',
                        'g',
                        theme.colorScheme.primary,
                      ),
                      _buildNutritionItem(
                        context,
                        'Carbs',
                        '${mealPlans.first.nutritionSummary!['carbs']}',
                        'g',
                        theme.colorScheme.tertiary,
                      ),
                      _buildNutritionItem(
                        context,
                        'Fat',
                        '${mealPlans.first.nutritionSummary!['fat']}',
                        'g',
                        AppTheme.tertiaryColor,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealTypeSection(BuildContext context, String mealType, List<MealEntry> meals) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mealType,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAddMealDialog(context, initialMealType: mealType.toLowerCase());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        meals.isEmpty
            ? Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'No $mealType planned',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        )
            : Column(
          children: meals.map((meal) => _buildMealCard(context, meal)).toList(),
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, MealEntry meal) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: Text('Are you sure you want to remove ${meal.recipeName}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        final userData = await authService.getUserData();
        if (userData != null) {
          Provider.of<MealPlanService>(context, listen: false).removeMealFromDate(
            userData.uid,
            _selectedDay,
            meal.id,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${meal.recipeName} removed from meal plan'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // This would require storing the meal before deletion
                  // and implementing a restore function
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            // Navigate to recipe details
            Navigator.pushNamed(context, '/recipe-details', arguments: meal.recipeId);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Recipe image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: meal.recipeImageUrl != null
                      ? Image.network(
                    meal.recipeImageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.restaurant,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.restaurant,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Recipe info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.recipeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meal.servings} serving${meal.servings > 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (meal.nutritionInfo != null && meal.nutritionInfo!.containsKey('calories'))
                        Text(
                          '${meal.nutritionInfo!['calories']} calories',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Servings controls
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        final userData = await authService.getUserData();
                        if (userData != null) {
                          Provider.of<MealPlanService>(context, listen: false).updateMealServings(
                            userData.uid,
                            _selectedDay,
                            meal.id,
                            meal.servings + 1,
                          );
                        }
                      },
                    ),
                    Text(
                      '${meal.servings}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: meal.servings > 1 ? theme.colorScheme.primary : Colors.grey,
                      ),
                      onPressed: meal.servings > 1
                          ? () async {
                        final userData = await authService.getUserData();
                        if (userData != null) {
                          Provider.of<MealPlanService>(context, listen: false).updateMealServings(
                            userData.uid,
                            _selectedDay,
                            meal.id,
                            meal.servings - 1,
                          );
                        }
                      }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
            color: color.withOpacity(0.1),
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context, {String? initialMealType}) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Meal to Plan',
                        style: theme.textTheme.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Date display
                        Text(
                          'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay)}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),

                        // Meal type selection
                        Text(
                          'Meal Type',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildMealTypeChip(
                              'Breakfast',
                              initialMealType == 'breakfast',
                              theme,
                            ),
                            _buildMealTypeChip(
                              'Lunch',
                              initialMealType == 'lunch',
                              theme,
                            ),
                            _buildMealTypeChip(
                              'Dinner',
                              initialMealType == 'dinner',
                              theme,
                            ),
                            _buildMealTypeChip(
                              'Snack',
                              initialMealType == 'snack',
                              theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Navigate to recipe browser
                                  Navigator.pushNamed(
                                    context,
                                    '/recipes',
                                    arguments: {
                                      'selectMode': true,
                                      'date': _selectedDay,
                                      'mealType': initialMealType ?? 'breakfast',
                                    },
                                  );
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('Browse Recipes'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Navigate to AI recipe generator
                                  Navigator.pushNamed(
                                    context,
                                    '/ai-recipe',
                                    arguments: {
                                      'date': _selectedDay,
                                      'mealType': initialMealType ?? 'breakfast',
                                    },
                                  );
                                },
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('AI Recipe'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMealTypeChip(String label, bool isSelected, ThemeData theme) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onSelected: (selected) {},
    );
  }
}

