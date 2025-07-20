import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe_model.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  List<String> _selectedCuisines = [];
  List<String> _selectedDiets = [];
  late TabController _tabController;
  bool _isGridView = true;

  final List<String> _categories = [
    'All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack', 'Appetizer'
  ];

  final List<String> _cuisines = [
    'Italian', 'Mexican', 'Asian', 'American', 'Mediterranean', 'Indian'
  ];

  final List<String> _diets = [
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Keto', 'Low-Carb', 'Dairy-Free'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Recipes'),
              floating: true,
              pinned: true,
              snap: true,
              actions: [
                IconButton(
                  icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),

                    // Category tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
                      indicatorColor: theme.colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: _categories.map((category) => Tab(text: category)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Filter chips
            if (_selectedCategories.isNotEmpty || _selectedCuisines.isNotEmpty || _selectedDiets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._selectedCategories.map((category) => _buildFilterChip(category, 'category')),
                      ..._selectedCuisines.map((cuisine) => _buildFilterChip(cuisine, 'cuisine')),
                      ..._selectedDiets.map((diet) => _buildFilterChip(diet, 'diet')),
                    ],
                  ),
                ),
              ),

            // Recipe grid/list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  return _buildRecipeList(category);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add recipe screen
          Navigator.pushNamed(context, '/add-recipe');
        },
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        labelStyle: TextStyle(color: theme.colorScheme.primary),
        deleteIconColor: theme.colorScheme.primary,
        onDeleted: () {
          setState(() {
            switch (type) {
              case 'category':
                _selectedCategories.remove(label);
                break;
              case 'cuisine':
                _selectedCuisines.remove(label);
                break;
              case 'diet':
                _selectedDiets.remove(label);
                break;
            }
          });
        },
      ),
    );
  }

  Widget _buildRecipeList(String category) {
    final recipeService = Provider.of<RecipeService>(context);
    final theme = Theme.of(context);

    return StreamBuilder<List<RecipeModel>>(
      stream: recipeService.getRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var recipes = snapshot.data ?? [];

        // Apply category filter from tab
        if (category != 'All') {
          recipes = recipes.where((recipe) {
            return recipe.categories.contains(category);
          }).toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          recipes = recipes.where((recipe) {
            return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                recipe.description.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Apply cuisine filter
        if (_selectedCuisines.isNotEmpty) {
          recipes = recipes.where((recipe) {
            return recipe.cuisineTypes.any((cuisine) => _selectedCuisines.contains(cuisine));
          }).toList();
        }

        // Apply diet filter
        if (_selectedDiets.isNotEmpty) {
          recipes = recipes.where((recipe) {
            return recipe.dietaryTypes.any((diet) => _selectedDiets.contains(diet));
          }).toList();
        }

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No recipes found',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to add recipe screen
                    Navigator.pushNamed(context, '/add-recipe');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipe'),
                ),
              ],
            ),
          );
        }

        return _isGridView
            ? _buildRecipeGrid(recipes)
            : _buildRecipeListView(recipes);
      },
    );
  }

  Widget _buildRecipeGrid(List<RecipeModel> recipes) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _buildRecipeGridCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeListView(List<RecipeModel> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return _buildRecipeListCard(recipe);
      },
    );
  }

  Widget _buildRecipeGridCard(RecipeModel recipe) {
    final theme = Theme.of(context);
    // Remove the height variable since we don't need it

    return GestureDetector(
      onTap: () {
        // Navigate to recipe details
        Navigator.pushNamed(context, '/recipe-details', arguments: recipe.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    recipe.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (recipe.isAIGenerated)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 18,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.pushNamed(
                                  context,
                                  '/edit-recipe',
                                  arguments: recipe.id,
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(recipe);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recipe info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (recipe.rating != null) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.rating!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeListCard(RecipeModel recipe) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to recipe details
          Navigator.pushNamed(context, '/recipe-details', arguments: recipe.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Recipe image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                recipe.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
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

            // Recipe info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                '/edit-recipe',
                                arguments: recipe.id,
                              );
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(recipe);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (recipe.isAIGenerated)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        if (recipe.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.rating!.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
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
                            'Filter Recipes',
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
                            const Text(
                              'Cuisines',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _cuisines.map((cuisine) {
                                final isSelected = _selectedCuisines.contains(cuisine);
                                return FilterChip(
                                  label: Text(cuisine),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                                  checkmarkColor: theme.colorScheme.primary,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCuisines.add(cuisine);
                                      } else {
                                        _selectedCuisines.remove(cuisine);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Dietary Preferences',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _diets.map((diet) {
                                final isSelected = _selectedDiets.contains(diet);
                                return FilterChip(
                                  label: Text(diet),
                                  selected: isSelected,
                                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                                  checkmarkColor: theme.colorScheme.primary,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDiets.add(diet);
                                      } else {
                                        _selectedDiets.remove(diet);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCuisines = [];
                                _selectedDiets = [];
                              });
                              this.setState(() {
                                _selectedCuisines = [];
                                _selectedDiets = [];
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              this.setState(() {
                                // Filters are already updated in the local state
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(RecipeModel recipe) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Recipe'),
          content: Text('Are you sure you want to delete "${recipe.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final recipeService = Provider.of<RecipeService>(context, listen: false);
                recipeService.deleteRecipe(recipe.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${recipe.title} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // This would require storing the recipe before deletion
                        // and implementing a restore function
                      },
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

