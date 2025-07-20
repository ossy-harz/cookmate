import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';

class RecipeEditScreen extends StatefulWidget {
  final String? recipeId;

  const RecipeEditScreen({
    Key? key,
    this.recipeId,
  }) : super(key: key);

  @override
  _RecipeEditScreenState createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitialized = false;
  File? _imageFile;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _ingredientNameController = TextEditingController();
  final _ingredientQuantityController = TextEditingController();
  final _ingredientUnitController = TextEditingController();
  final _instructionController = TextEditingController();
  
  // Recipe data
  List<String> _categories = [];
  List<String> _cuisineTypes = [];
  List<String> _dietaryTypes = [];
  List<Ingredient> _ingredients = [];
  List<String> _instructions = [];
  
  // Available options
  final List<String> _availableCategories = [
    'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack', 'Appetizer'
  ];
  
  final List<String> _availableCuisines = [
    'Italian', 'Mexican', 'Asian', 'American', 'Mediterranean', 'Indian'
  ];
  
  final List<String> _availableDiets = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Keto', 'Low-Carb', 'Dairy-Free'
  ];
  
  final List<String> _availableUnits = [
    'g', 'kg', 'ml', 'L', 'tsp', 'tbsp', 'cup', 'oz', 'lb', 'piece', 'slice'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _ingredientNameController.dispose();
    _ingredientQuantityController.dispose();
    _ingredientUnitController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    if (widget.recipeId == null) {
      // New recipe
      setState(() {
        _isInitialized = true;
        _prepTimeController.text = '15';
        _cookTimeController.text = '30';
        _servingsController.text = '4';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final recipe = await recipeService.getRecipeById(widget.recipeId!);
      
      if (recipe != null) {
        _titleController.text = recipe.title;
        _descriptionController.text = recipe.description;
        _prepTimeController.text = recipe.prepTimeMinutes.toString();
        _cookTimeController.text = recipe.cookTimeMinutes.toString();
        _servingsController.text = recipe.servings.toString();
        
        setState(() {
          _categories = List<String>.from(recipe.categories);
          _cuisineTypes = List<String>.from(recipe.cuisineTypes);
          _dietaryTypes = List<String>.from(recipe.dietaryTypes);
          _ingredients = List<Ingredient>.from(recipe.ingredients);
          _instructions = List<String>.from(recipe.instructions);
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recipe: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _addIngredient() {
    if (_ingredientNameController.text.isEmpty ||
        _ingredientQuantityController.text.isEmpty ||
        _ingredientUnitController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _ingredients.add(
        Ingredient(
          name: _ingredientNameController.text,
          quantity: _ingredientQuantityController.text,
          unit: _ingredientUnitController.text,
        ),
      );
      
      _ingredientNameController.clear();
      _ingredientQuantityController.clear();
      _ingredientUnitController.text = _availableUnits.first;
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    if (_instructionController.text.isEmpty) {
      return;
    }
    
    setState(() {
      _instructions.add(_instructionController.text);
      _instructionController.clear();
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  void _moveInstruction(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _instructions.length) return;
    
    setState(() {
      final instruction = _instructions.removeAt(oldIndex);
      _instructions.insert(newIndex, instruction);
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }
    
    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one instruction')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final userData = await authService.getUserData();
      
      if (userData == null) {
        throw Exception('User not logged in');
      }
      
      // Create recipe model
      final recipe = RecipeModel(
        id: widget.recipeId ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: '', // Will be updated after upload
        categories: _categories.isEmpty ? ['Other'] : _categories,
        cuisineTypes: _cuisineTypes,
        dietaryTypes: _dietaryTypes,
        prepTimeMinutes: int.parse(_prepTimeController.text),
        cookTimeMinutes: int.parse(_cookTimeController.text),
        servings: int.parse(_servingsController.text),
        ingredients: _ingredients,
        instructions: _instructions,
        nutritionInfo: {
          'calories': 0, // These would be calculated or entered separately
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        },
        authorId: userData.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (widget.recipeId == null) {
        // Add new recipe
        final recipeId = await recipeService.addRecipe(recipe, _imageFile);
        
        if (recipeId.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe added successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing recipe
        await recipeService.updateRecipe(recipe, _imageFile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewRecipe = widget.recipeId == null;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isNewRecipe ? 'Add Recipe' : 'Edit Recipe'),
        ),
        body: const LoadingIndicator(message: 'Loading recipe...'),
      );
    }
    
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isNewRecipe ? 'Add Recipe' : 'Edit Recipe'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isNewRecipe ? 'Add Recipe' : 'Edit Recipe',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Recipe Photo',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              
              // Basic Info
              Text(
                'Basic Information',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Time and Servings
              Row(
                children: [
                  // Prep Time
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Cook Time
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Cook Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Servings
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Servings',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Categories
              Text(
                'Categories',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _categories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _categories.add(category);
                        } else {
                          _categories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Cuisine Types
              Text(
                'Cuisine Types',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCuisines.map((cuisine) {
                  final isSelected = _cuisineTypes.contains(cuisine);
                  return FilterChip(
                    label: Text(cuisine),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _cuisineTypes.add(cuisine);
                        } else {
                          _cuisineTypes.remove(cuisine);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Dietary Types
              Text(
                'Dietary Types',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableDiets.map((diet) {
                  final isSelected = _dietaryTypes.contains(diet);
                  return FilterChip(
                    label: Text(diet),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _dietaryTypes.add(diet);
                        } else {
                          _dietaryTypes.remove(diet);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Ingredients
              Text(
                'Ingredients',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Ingredient Form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredient Name
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _ingredientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ingredient',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Quantity
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ingredientQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Unit
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _ingredientUnitController.text.isEmpty 
                          ? _availableUnits.first 
                          : _ingredientUnitController.text,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _ingredientUnitController.text = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Add Button
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addIngredient,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Ingredients List
              if (_ingredients.isNotEmpty) ...[
                GlassCard(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return ListTile(
                        title: Text(ingredient.name),
                        subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeIngredient(index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Instructions
              Text(
                'Instructions',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              
              // Instruction Form
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instruction Text
                  Expanded(
                    child: TextFormField(
                      controller: _instructionController,
                      decoration: const InputDecoration(
                        labelText: 'Instruction Step',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Add Button
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addInstruction,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Instructions List
              if (_instructions.isNotEmpty) ...[
                GlassCard(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: _moveInstruction,
                    children: _instructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final instruction = entry.value;
                      return ListTile(
                        key: ValueKey(index),
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
                        title: Text(instruction),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: index > 0 
                                  ? () => _moveInstruction(index, index - 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: index < _instructions.length - 1 
                                  ? () => _moveInstruction(index, index + 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeInstruction(index),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isNewRecipe ? 'Add Recipe' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

