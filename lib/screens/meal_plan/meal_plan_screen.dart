import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/meal_plan_model.dart';
import '../../services/meal_plan_service.dart';
import '../../services/recipe_service.dart';
import '../../widgets/meal_plan_card.dart';
import '../../widgets/glass_card.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  DateTime _selectedDate = DateTime.now();
  final PageController _weekController = PageController(initialPage: 0);
  int _currentWeekPage = 0;

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    final mealPlanService = Provider.of<MealPlanService>(context, listen: false);

    // Calculate start and end dates for the current week
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    await mealPlanService.fetchMealPlans(
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealPlanService = Provider.of<MealPlanService>(context);

    // Get meal plans for the selected date
    final dayMealPlans = mealPlanService.getMealPlansForDate(_selectedDate);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Meal Plan',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            floating: true,
            pinned: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  // Week Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentWeekPage > 0
                              ? () {
                            _weekController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                              : null,
                        ),
                        Text(
                          _getWeekRangeText(),
                          style: theme.textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            _weekController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Day Selector
                  SizedBox(
                    height: 100,
                    child: PageView.builder(
                      controller: _weekController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentWeekPage = page;

                          // Update selected date to the first day of the new week
                          final now = DateTime.now();
                          final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
                              .subtract(Duration(days: now.weekday - 1));

                          final startOfSelectedWeek = startOfCurrentWeek.add(
                            Duration(days: 7 * page),
                          );

                          _selectedDate = startOfSelectedWeek;

                          // Load meal plans for the new week
                          final endOfSelectedWeek = startOfSelectedWeek.add(
                            const Duration(days: 6),
                          );

                          mealPlanService.fetchMealPlans(
                            startDate: startOfSelectedWeek,
                            endDate: endOfSelectedWeek,
                          );
                        });
                      },
                      itemBuilder: (context, weekIndex) {
                        // Calculate the start date of this week
                        final now = DateTime.now();
                        final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
                            .subtract(Duration(days: now.weekday - 1));

                        final startOfThisWeek = startOfCurrentWeek.add(
                          Duration(days: 7 * weekIndex),
                        );

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: 7,
                          itemBuilder: (context, dayIndex) {
                            final date = startOfThisWeek.add(Duration(days: dayIndex));
                            final isSelected = _isSameDay(date, _selectedDate);
                            final isToday = _isSameDay(date, DateTime.now());

                            // Count meals for this day
                            final mealCount = mealPlanService.getMealPlansForDate(date).length;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isToday
                                      ? theme.colorScheme.primary.withOpacity(0.1)
                                      : null),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isToday
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withOpacity(0.2)),
                                    width: isSelected || isToday ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getDayName(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      date.day.toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.3)
                                            : theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$mealCount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {
                  // Show calendar picker
                  _showDatePicker(context);
                },
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                onPressed: () {
                  // Generate meal plan
                  _showGenerateMealPlanDialog(context);
                },
              ),
            ],
          ),

          // Selected Date Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Nutritional summary for the day
                  GlassCard(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_calculateTotalCalories(dayMealPlans)} cal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Meal Plans for Selected Date
          if (mealPlanService.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (dayMealPlans.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meals planned for this day',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a meal',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return MealPlanCard(
                    mealPlan: dayMealPlans[index],
                    onTap: () {
                      // Navigate to meal plan details
                    },
                  );
                },
                childCount: dayMealPlans.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add meal plan screen
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getWeekRangeText() {
    // Calculate the start and end of the selected week
    final now = DateTime.now();
    final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final startOfSelectedWeek = startOfCurrentWeek.add(
      Duration(days: 7 * _currentWeekPage),
    );

    final endOfSelectedWeek = startOfSelectedWeek.add(const Duration(days: 6));

    // Format the dates
    final startMonth = _getMonthName(startOfSelectedWeek.month);
    final endMonth = _getMonthName(endOfSelectedWeek.month);

    if (startOfSelectedWeek.month == endOfSelectedWeek.month) {
      return '$startMonth ${startOfSelectedWeek.day} - ${endOfSelectedWeek.day}';
    } else {
      return '$startMonth ${startOfSelectedWeek.day} - $endMonth ${endOfSelectedWeek.day}';
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(int month) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (_isSameDay(date, today)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Tomorrow';
    } else {
      return '${_getDayName(date)}, ${date.day} ${_getMonthName(date.month)}';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _calculateTotalCalories(List<MealPlanModel> mealPlans) {
    int total = 0;
    for (final mealPlan in mealPlans) {
      if (mealPlan.nutritionSummary != null && mealPlan.nutritionSummary!.containsKey('calories')) {
        total += (mealPlan.nutritionSummary!['calories'] as num).toInt();
      } else {
        // Calculate from individual meals
        for (final meal in mealPlan.meals) {
          if (meal.nutritionInfo != null && meal.nutritionInfo!.containsKey('calories')) {
            total += (meal.nutritionInfo!['calories'] as num).toInt();
          }
        }
      }
    }
    return total;
  }

  void _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;

        // Calculate which week page this date belongs to
        final now = DateTime.now();
        final startOfCurrentWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        final diffDays = pickedDate.difference(startOfCurrentWeek).inDays;
        final weekOffset = (diffDays / 7).floor();

        _currentWeekPage = weekOffset;
        _weekController.jumpToPage(weekOffset);
      });
    }
  }

  void _showGenerateMealPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Meal Plan'),
        content: const Text(
            'This will generate a meal plan for the entire week based on your preferences and available recipes. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final recipeService = Provider.of<RecipeService>(context, listen: false);
                final mealPlanService = Provider.of<MealPlanService>(context, listen: false);

                // Get available recipes
                await recipeService.fetchUserRecipes();
                final recipes = recipeService.recipes;

                if (recipes.isEmpty) {
                  Navigator.pop(context); // Dismiss loading

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No recipes available. Add some recipes first.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Generate meal plan
                final weeklyPlan = await mealPlanService.generateWeeklyMealPlan(recipes);

                // Add meal plans to the service
                for (final mealPlan in weeklyPlan) {
                  await mealPlanService.addMealPlan(mealPlan);
                }

                Navigator.pop(context); // Dismiss loading

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meal plan generated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Dismiss loading

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to generate meal plan: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

