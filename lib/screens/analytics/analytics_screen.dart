import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/inventory_service.dart';
import '../../models/meal_plan_model.dart';
import '../../models/inventory_item_model.dart';
import '../../widgets/glass_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nutrition'),
            Tab(text: 'Meals'),
            Tab(text: 'Inventory'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNutritionTab(context),
          _buildMealsTab(context),
          _buildInventoryTab(context),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTab(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return FutureBuilder(
      future: authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Failed to load user data'));
        }
        
        final userData = snapshot.data!;
        
        return StreamBuilder<List<MealPlanModel>>(
          stream: Provider.of<MealPlanService>(context).getMealPlans(
            userData.uid,
            _startDate,
            _endDate,
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
                    const Icon(
                      Icons.analytics,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meal data available',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add meals to your meal plan to see nutrition analytics',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // Calculate daily nutrition data
            final Map<DateTime, Map<String, dynamic>> dailyNutrition = {};
            
            for (final mealPlan in mealPlans) {
              final date = DateTime(
                mealPlan.date.year,
                mealPlan.date.month,
                mealPlan.date.day,
              );
              
              if (!dailyNutrition.containsKey(date)) {
                dailyNutrition[date] = {
                  'calories': 0,
                  'protein': 0,
                  'carbs': 0,
                  'fat': 0,
                };
              }
              
              if (mealPlan.nutritionSummary != null) {
                dailyNutrition[date]!['calories'] += mealPlan.nutritionSummary!['calories'] ?? 0;
                dailyNutrition[date]!['protein'] += mealPlan.nutritionSummary!['protein'] ?? 0;
                dailyNutrition[date]!['carbs'] += mealPlan.nutritionSummary!['carbs'] ?? 0;
                dailyNutrition[date]!['fat'] += mealPlan.nutritionSummary!['fat'] ?? 0;
              }
            }
            
            // Calculate averages
            int totalCalories = 0;
            double totalProtein = 0;
            double totalCarbs = 0;
            double totalFat = 0;
            
            dailyNutrition.forEach((date, nutrition) {
              totalCalories += nutrition['calories'] as int;
              totalProtein += nutrition['protein'] as double;
              totalCarbs += nutrition['carbs'] as double;
              totalFat += nutrition['fat'] as double;
            });
            
            final daysCount = dailyNutrition.length;
            final avgCalories = daysCount > 0 ? totalCalories / daysCount : 0;
            final avgProtein = daysCount > 0 ? totalProtein / daysCount : 0;
            final avgCarbs = daysCount > 0 ? totalCarbs / daysCount : 0;
            final avgFat = daysCount > 0 ? totalFat / daysCount : 0;
            
            // Prepare chart data
            final caloriesSpots = <FlSpot>[];
            final proteinSpots = <FlSpot>[];
            final carbsSpots = <FlSpot>[];
            final fatSpots = <FlSpot>[];
            
            final sortedDates = dailyNutrition.keys.toList()..sort();
            
            for (int i = 0; i < sortedDates.length; i++) {
              final date = sortedDates[i];
              final nutrition = dailyNutrition[date]!;
              
              caloriesSpots.add(FlSpot(i.toDouble(), nutrition['calories'].toDouble()));
              proteinSpots.add(FlSpot(i.toDouble(), nutrition['protein'].toDouble()));
              carbsSpots.add(FlSpot(i.toDouble(), nutrition['carbs'].toDouble()));
              fatSpots.add(FlSpot(i.toDouble(), nutrition['fat'].toDouble()));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  Text(
                    'Data from ${DateFormat('MMM d').format(_startDate)} to ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutrition Summary
                  Text(
                    'Daily Average',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutritionSummaryItem(
                        context,
                        'Calories',
                        avgCalories.round().toString(),
                        'kcal',
                        Colors.red,
                      ),
                      _buildNutritionSummaryItem(
                        context,
                        'Protein',
                        avgProtein.round().toString(),
                        'g',
                        Colors.blue,
                      ),
                      _buildNutritionSummaryItem(
                        context,
                        'Carbs',
                        avgCarbs.round().toString(),
                        'g',
                        Colors.green,
                      ),
                      _buildNutritionSummaryItem(
                        context,
                        'Fat',
                        avgFat.round().toString(),
                        'g',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Calories Chart
                  Text(
                    'Calories Trend',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                                    final date = sortedDates[value.toInt()];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('MM/dd').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: caloriesSpots,
                              isCurved: true,
                              color: Colors.red,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.red.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Macronutrients Chart
                  Text(
                    'Macronutrients Trend',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    height: 250,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                                    final date = sortedDates[value.toInt()];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('MM/dd').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: proteinSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: carbsSpots,
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: fatSpots,
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(context, 'Protein', Colors.blue),
                      const SizedBox(width: 16),
                      _buildLegendItem(context, 'Carbs', Colors.green),
                      const SizedBox(width: 16),
                      _buildLegendItem(context, 'Fat', Colors.orange),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildMealsTab(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return FutureBuilder(
      future: authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Failed to load user data'));
        }
        
        final userData = snapshot.data!;
        
        return StreamBuilder<List<MealPlanModel>>(
          stream: Provider.of<MealPlanService>(context).getMealPlans(
            userData.uid,
            _startDate,
            _endDate,
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
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No meal data available',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add meals to your meal plan to see meal analytics',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // Calculate meal type distribution
            final Map<String, int> mealTypeCounts = {};
            
            for (final mealPlan in mealPlans) {
              for (final meal in mealPlan.meals) {
                final mealType = meal.mealType;
                mealTypeCounts[mealType] = (mealTypeCounts[mealType] ?? 0) + 1;
              }
            }
            
            // Calculate most common recipes
            final Map<String, int> recipeCounts = {};
            final Map<String, String> recipeNames = {};
            
            for (final mealPlan in mealPlans) {
              for (final meal in mealPlan.meals) {
                final recipeId = meal.recipeId;
                recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
                recipeNames[recipeId] = meal.recipeName;
              }
            }
            
            // Sort recipes by count
            final sortedRecipes = recipeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            
            // Prepare pie chart data
            final mealTypeData = mealTypeCounts.entries.map((entry) {
              Color color;
              switch (entry.key.toLowerCase()) {
                case 'breakfast':
                  color = Colors.orange;
                  break;
                case 'lunch':
                  color = Colors.green;
                  break;
                case 'dinner':
                  color = Colors.indigo;
                  break;
                case 'snack':
                  color = Colors.purple;
                  break;
                default:
                  color = Colors.grey;
              }
              
              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: '${entry.key}\n${entry.value}',
                color: color,
                radius: 100,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  Text(
                    'Data from ${DateFormat('MMM d').format(_startDate)} to ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Meal Type Distribution
                  Text(
                    'Meal Type Distribution',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PieChart(
                        PieChartData(
                          sections: mealTypeData,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(context, 'Breakfast', Colors.orange),
                      const SizedBox(width: 16),
                      _buildLegendItem(context, 'Lunch', Colors.green),
                      const SizedBox(width: 16),
                      _buildLegendItem(context, 'Dinner', Colors.indigo),
                      const SizedBox(width: 16),
                      _buildLegendItem(context, 'Snack', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Most Common Recipes
                  Text(
                    'Most Common Recipes',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedRecipes.length > 5 ? 5 : sortedRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = sortedRecipes[index];
                        final recipeName = recipeNames[recipe.key] ?? 'Unknown Recipe';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(recipeName),
                          subtitle: Text('Used ${recipe.value} times'),
                          trailing: Text(
                            '${(recipe.value * 100 / mealPlans.length).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
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
  
  Widget _buildInventoryTab(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return FutureBuilder(
      future: authService.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Failed to load user data'));
        }
        
        final userData = snapshot.data!;
        
        return StreamBuilder<List<InventoryItemModel>>(
          stream: Provider.of<InventoryService>(context).getUserInventory(userData.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final inventoryItems = snapshot.data ?? [];
            
            if (inventoryItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No inventory data available',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items to your inventory to see analytics',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // Calculate category distribution
            final Map<String, int> categoryCounts = {};
            final Map<String, double> categoryQuantities = {};
            
            for (final item in inventoryItems) {
              final category = item.category;
              categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
              categoryQuantities[category] = (categoryQuantities[category] ?? 0) + item.quantity;
            }
            
            // Calculate expiring items
            final now = DateTime.now();
            final expiringItems = inventoryItems
                .where((item) => item.expiryDate != null && 
                    item.expiryDate!.difference(now).inDays <= 7)
                .toList();
            
            // Sort expiring items by expiry date
            expiringItems.sort((a, b) => 
                (a.expiryDate ?? DateTime.now()).compareTo(b.expiryDate ?? DateTime.now()));
            
            // Prepare pie chart data
            final categoryData = categoryCounts.entries.map((entry) {
              Color color;
              switch (entry.key) {
                case 'Dairy':
                  color = Colors.blue;
                  break;
                case 'Meat & Seafood':
                  color = Colors.red;
                  break;
                case 'Fruits':
                  color = Colors.orange;
                  break;
                case 'Vegetables':
                  color = Colors.green;
                  break;
                case 'Grains & Bakery':
                  color = Colors.brown;
                  break;
                case 'Condiments & Spices':
                  color = Colors.purple;
                  break;
                default:
                  color = Colors.grey;
              }
              
              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: entry.key,
                color: color,
                radius: 100,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inventory Summary
                  Text(
                    'Inventory Summary',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInventorySummaryItem(
                        context,
                        'Total Items',
                        inventoryItems.length.toString(),
                        Icons.inventory_2,
                      ),
                      _buildInventorySummaryItem(
                        context,
                        'Categories',
                        categoryCounts.length.toString(),
                        Icons.category,
                      ),
                      _buildInventorySummaryItem(
                        context,
                        'Expiring Soon',
                        expiringItems.length.toString(),
                        Icons.warning,
                        expiringItems.isNotEmpty ? Colors.red : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Category Distribution
                  Text(
                    'Category Distribution',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PieChart(
                        PieChartData(
                          sections: categoryData,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Expiring Items
                  Text(
                    'Expiring Soon',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  expiringItems.isEmpty
                      ? GlassCard(
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No items expiring soon'),
                            ),
                          ),
                        )
                      : GlassCard(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: expiringItems.length,
                            itemBuilder: (context, index) {
                              final item = expiringItems[index];
                              final daysUntilExpiry = item.expiryDate != null
                                  ? item.expiryDate!.difference(now).inDays
                                  : 0;
                              
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: daysUntilExpiry <= 0
                                        ? Colors.red
                                        : daysUntilExpiry <= 3
                                            ? Colors.orange
                                            : Colors.yellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      daysUntilExpiry.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.quantity} ${item.unit} - ${item.category}',
                                ),
                                trailing: Text(
                                  item.expiryDate != null
                                      ? DateFormat('MMM d, yyyy').format(item.expiryDate!)
                                      : 'No expiry date',
                                  style: TextStyle(
                                    color: daysUntilExpiry <= 0
                                        ? Colors.red
                                        : daysUntilExpiry <= 3
                                            ? Colors.orange
                                            : null,
                                    fontWeight: daysUntilExpiry <= 3
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              );
                            },
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
  
  Widget _buildNutritionSummaryItem(
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
  
  Widget _buildInventorySummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
  
  void _showDateRangePicker(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate,
      end: _endDate,
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
    }
  }
}

