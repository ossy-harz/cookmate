import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/recipe_service.dart';
import '../../services/meal_plan_service.dart';
import '../../services/auth_service.dart';
import '../../models/recipe_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailsScreen({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool _isLoading = true;
  RecipeModel? _recipe;
  int _servings = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final recipe = await recipeService.getRecipeById(widget.recipeId);
      
      setState(() {
        _recipe = recipe;
        _servings = recipe?.servings ?? 1;
        _isFavorite = recipe?.isFavorite ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipe: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getIngredientQuantity(String quantity, int originalServings) {
    try {
      final originalQuantity = double.parse(quantity);
      final ratio = _servings / originalServings;
      return originalQuantity * ratio;
    } catch (e) {
      // If parsing fails, return the original quantity
      return 0;
    }
  }

  void _toggleFavorite() async {
    if (_recipe != null) {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      try {
        await recipeService.toggleFavorite(_recipe!.id, _isFavorite);
      } catch (e) {
        // Revert state if operation fails
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite status: $e')),
        );
      }
    }
  }

  void _shareRecipe() {
    if (_recipe != null) {
      final ingredients = _recipe!.ingredients.map((i) => '• ${i.quantity} ${i.unit} ${i.name}').join('\n');
      final instructions = _recipe!.instructions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
      
      final shareText = '''
Check out this recipe I found on CookMate!

${_recipe!.title}
${_recipe!.description}

Prep: ${_recipe!.prepTimeMinutes} min | Cook: ${_recipe!.cookTimeMinutes} min | Servings: ${_recipe!.servings}

INGREDIENTS:
$ingredients

INSTRUCTIONS:
$instructions
''';
      
      Share.share(shareText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Details'),
        ),
        body: const LoadingIndicator(message: 'Loading recipe...'),
      );
    }
    
    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Details'),
        ),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Recipe not found',
          message: 'The recipe you are looking for could not be found.',
        ),
      );
    }
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Recipe Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _recipe!.title,
                style: const TextStyle(
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
                  Image.network(
                    _recipe!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        child: Icon(
                          Icons.restaurant,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
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
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                color: _isFavorite ? Colors.red : Colors.white,
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareRecipe,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // Navigate to edit recipe screen
                  Navigator.pushNamed(
                    context,
                    '/edit-recipe',
                    arguments: _recipe!.id,
                  ).then((_) => _loadRecipe());
                },
              ),
            ],
          ),
          
          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        context,
                        'Prep',
                        '${_recipe!.prepTimeMinutes} min',
                        Icons.timer,
                      ),
                      _buildInfoItem(
                        context,
                        'Cook',
                        '${_recipe!.cookTimeMinutes} min',
                        Icons.microwave,
                      ),
                      _buildInfoItem(
                        context,
                        'Total',
                        '${_recipe!.prepTimeMinutes + _recipe!.cookTimeMinutes} min',
                        Icons.access_time,
                      ),
                      _buildInfoItem(
                        context,
                        'Calories',
                        '${_recipe!.nutritionInfo['calories']} cal',
                        Icons.local_fire_department,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Recipe Tags
                  if (_recipe!.dietaryTypes.isNotEmpty || _recipe!.cuisineTypes.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._recipe!.dietaryTypes.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                          ),
                        )),
                        ..._recipe!.cuisineTypes.map((cuisine) => Chip(
                          label: Text(cuisine),
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.secondary,
                          ),
                        )),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    _recipe!.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  
                  // Servings Adjuster
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Servings:',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _servings > 1
                            ? () {
                                setState(() {
                                  _servings--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '$_servings',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            _servings++;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Ingredients
                  Text(
                    'Ingredients',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recipe!.ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _recipe!.ingredients[index];
                        final adjustedQuantity = _getIngredientQuantity(
                          ingredient.quantity,
                          _recipe!.servings,
                        );
                        
                        return ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(ingredient.name),
                          subtitle: Text(
                            adjustedQuantity > 0
                                ? '${adjustedQuantity.toStringAsFixed(adjustedQuantity.truncateToDouble() == adjustedQuantity ? 0 : 1)} ${ingredient.unit}'
                                : ingredient.quantity + ' ' + ingredient.unit,
                          ),
                          trailing: ingredient.notes != null
                              ? Tooltip(
                                  message: ingredient.notes!,
                                  child: const Icon(Icons.info_outline),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Text(
                    'Instructions',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recipe!.instructions.length,
                      itemBuilder: (context, index) {
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
                          title: Text(_recipe!.instructions[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutrition Information
                  Text(
                    'Nutrition Information',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutritionItem(
                            context,
                            'Calories',
                            '${(_recipe!.nutritionInfo['calories'] * _servings / _recipe!.servings).round()}',
                            'kcal',
                            Colors.red,
                          ),
                          _buildNutritionItem(
                            context,
                            'Protein',
                            '${(_recipe!.nutritionInfo['protein'] * _servings / _recipe!.servings).round()}',
                            'g',
                            Colors.blue,
                          ),
                          _buildNutritionItem(
                            context,
                            'Carbs',
                            '${(_recipe!.nutritionInfo['carbs'] * _servings / _recipe!.servings).round()}',
                            'g',
                            Colors.green,
                          ),
                          _buildNutritionItem(
                            context,
                            'Fat',
                            '${(_recipe!.nutritionInfo['fat'] * _servings / _recipe!.servings).round()}',
                            'g',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddToMealPlanDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add to Meal Plan'),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
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
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showAddToMealPlanDialog(BuildContext context) {
    final selectedDate = DateTime.now();
    String selectedMealType = 'breakfast';
    int selectedServings = _servings;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add to Meal Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          
                          if (pickedDate != null) {
                            setState(() {
                              // selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                    
                    // Meal Type Selector
                    const Text(
                      'Meal Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildMealTypeChip(
                          'Breakfast',
                          selectedMealType == 'breakfast',
                          () => setState(() => selectedMealType = 'breakfast'),
                        ),
                        _buildMealTypeChip(
                          'Lunch',
                          selectedMealType == 'lunch',
                          () => setState(() => selectedMealType = 'lunch'),
                        ),
                        _buildMealTypeChip(
                          'Dinner',
                          selectedMealType == 'dinner',
                          () => setState(() => selectedMealType = 'dinner'),
                        ),
                        _buildMealTypeChip(
                          'Snack',
                          selectedMealType == 'snack',
                          () => setState(() => selectedMealType = 'snack'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Servings Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Servings:'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: selectedServings > 1
                              ? () {
                                  setState(() {
                                    selectedServings--;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          '$selectedServings',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              selectedServings++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    
                    try {
                      final mealPlanService = Provider.of<MealPlanService>(
                        context,
                        listen: false,
                      );
                      
                      final authService = Provider.of<AuthService>(
                        context,
                        listen: false,
                      );
                      
                      final userData = await authService.getUserData();
                      
                      if (userData != null) {
                        await mealPlanService.addMealToDate(
                          userData.uid,
                          selectedDate,
                          _recipe!.id,
                          selectedMealType,
                          selectedServings,
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_recipe!.title} added to meal plan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error adding to meal plan: $e');
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add to meal plan'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMealTypeChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
    );
  }
}

