import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../services/recipe_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';
import '../../models/recipe_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_app_bar.dart';

class AIRecipeScreen extends StatefulWidget {
  const AIRecipeScreen({Key? key}) : super(key: key);

  @override
  _AIRecipeScreenState createState() => _AIRecipeScreenState();
}

class _AIRecipeScreenState extends State<AIRecipeScreen> {
  final TextEditingController _ingredientController = TextEditingController();

  List<String> _selectedIngredients = [];
  List<String> _selectedDietaryPreferences = [];
  bool _isGenerating = false;
  RecipeModel? _generatedRecipe;

  final List<String> _dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Low-Carb',
    'High-Protein',
    'Low-Fat',
    'Paleo',
  ];

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _selectedIngredients.add(_ingredientController.text);
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
  }

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
      } else {
        _selectedDietaryPreferences.add(preference);
      }
    });
  }

  Future<void> _generateRecipe() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _generatedRecipe = null;
    });
    
    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final userData = await authService.getUserData();
      
      if (userData != null) {
        // Generate recipe using AI
        final recipe = await aiService.generateRecipe(
          ingredients: _selectedIngredients,
          dietaryPreferences: _selectedDietaryPreferences,
          userId: userData.uid,
        );
        
        // Save the generated recipe
        await recipeService.addRecipe(recipe, null);
        
        setState(() {
          _generatedRecipe = recipe;
          _isGenerating = false;
        });
      }
    } catch (e) {
      print('Error generating recipe: $e');
      
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'AI Recipe Generator',
      ),
      body: _generatedRecipe != null
          ? _buildGeneratedRecipeView(context)
          : _buildRecipeGeneratorView(context),
    );
  }

  Widget _buildRecipeGeneratorView(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Generate a Recipe',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI will create a recipe based on your ingredients and preferences',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // Ingredients Section
          Text(
            'Select Ingredients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: const InputDecoration(
                    hintText: 'Enter an ingredient',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addIngredient,
                color: theme.colorScheme.primary,
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Inventory Items
          FutureBuilder(
            future: authService.getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              
              final userData = snapshot.data;
              
              return StreamBuilder<List<InventoryItemModel>>(
                stream: Provider.of<InventoryService>(context).getUserInventory(userData!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  
                  final inventoryItems = snapshot.data!;
                  
                  if (inventoryItems.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From Your Inventory',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: inventoryItems.map((item) {
                          final isSelected = _selectedIngredients.contains(item.name);
                          
                          return FilterChip(
                            label: Text(item.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedIngredients.add(item.name);
                                } else {
                                  _selectedIngredients.remove(item.name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Selected Ingredients
          if (_selectedIngredients.isNotEmpty) ...[
            Text(
              'Selected Ingredients',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedIngredients.map((ingredient) {
                return Chip(
                  label: Text(ingredient),
                  onDeleted: () => _removeIngredient(ingredient),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  deleteIconColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Dietary Preferences
          Text(
            'Dietary Preferences',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryPreferences.map((preference) {
              final isSelected = _selectedDietaryPreferences.contains(preference);
              
              return FilterChip(
                label: Text(preference),
                selected: isSelected,
                onSelected: (_) => _toggleDietaryPreference(preference),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateRecipe,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generating Recipe...'),
                      ],
                    )
                  : const Text('Generate Recipe'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedRecipeView(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = _generatedRecipe!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Recipe Title
          Text(
            recipe.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // AI Generated Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI Generated',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Recipe Description
          Text(
            recipe.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // Recipe Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                context,
                'Prep',
                '${recipe.prepTimeMinutes} min',
                Icons.timer,
              ),
              _buildInfoItem(
                context,
                'Cook',
                '${recipe.cookTimeMinutes} min',
                Icons.microwave,
              ),
              _buildInfoItem(
                context,
                'Servings',
                '${recipe.servings}',
                Icons.people,
              ),
              _buildInfoItem(
                context,
                'Calories',
                '${recipe.nutritionInfo['calories']} cal',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Ingredients
          Text(
            'Ingredients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = recipe.ingredients[index];
                
                return ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(ingredient.name),
                  subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            'Instructions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipe.instructions.length,
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
                  title: Text(recipe.instructions[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedRecipe = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Generate Another'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to recipe details
                    Navigator.pushNamed(
                      context,
                      '/recipe-details',
                      arguments: recipe.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('View Recipe'),
                ),
              ),
            ],
          ),
        ],
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
}

