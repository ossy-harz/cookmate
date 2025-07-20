import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/meal_plan_service.dart';
import '../../widgets/glass_card.dart';
import '../../models/inventory_item_model.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  
  List<Map<String, dynamic>> _groceryList = [];
  List<Map<String, dynamic>> _manualItems = [];
  Map<String, bool> _checkedItems = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadGroceryList();
  }
  
  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGroceryList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      final mealPlanService = Provider.of<MealPlanService>(context, listen: false);
      
      final userData = await authService.getUserData();
      
      if (userData != null) {
        // Get meal plans for the next 7 days
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day);
        final endDate = startDate.add(const Duration(days: 7));
        
        final mealPlansStream = mealPlanService.getMealPlans(
          userData.uid,
          startDate,
          endDate,
        );
        
        final mealPlans = await mealPlansStream.first;
        
        // Extract recipes from meal plans
        final plannedRecipes = <Map<String, dynamic>>[];
        
        for (final mealPlan in mealPlans) {
          for (final meal in mealPlan.meals) {
            plannedRecipes.add({
              'recipeId': meal.recipeId,
              'servings': meal.servings,
            });
          }
        }
        
        // Generate grocery list based on planned recipes
        final groceryList = await inventoryService.generateGroceryList(
          userData.uid,
          plannedRecipes,
        );
        
        setState(() {
          _groceryList = groceryList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading grocery list: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _addManualItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _manualItems.add({
          'name': _itemController.text,
          'quantity': double.tryParse(_quantityController.text) ?? 1,
          'unit': 'pcs',
          'category': 'Other',
          'isManual': true,
        });
        
        _itemController.clear();
        _quantityController.text = '1';
      });
    }
  }
  
  void _toggleItemCheck(String itemName) {
    setState(() {
      _checkedItems[itemName] = !(_checkedItems[itemName] ?? false);
    });
  }
  
  void _addToInventory(Map<String, dynamic> item) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      
      final userData = await authService.getUserData();
      
      if (userData != null) {
        final newItem = InventoryItemModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: item['name'],
          category: item['category'],
          quantity: item['quantity'],
          unit: item['unit'],
          purchaseDate: DateTime.now(),
          userId: userData.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await inventoryService.addInventoryItem(newItem);
        
        // Mark as checked
        _toggleItemCheck(item['name']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['name']} added to inventory'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding to inventory: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Combine grocery list and manual items
    final allItems = [..._groceryList, ..._manualItems];
    
    // Group items by category
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    
    for (final item in allItems) {
      final category = item['category'] as String;
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroceryList,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add item form
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Item name
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _itemController,
                          decoration: const InputDecoration(
                            hintText: 'Add item',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Quantity
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            hintText: 'Qty',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Add button
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addManualItem,
                        color: theme.colorScheme.primary,
                        iconSize: 32,
                      ),
                    ],
                  ),
                ),
                
                // Shopping list
                Expanded(
                  child: allItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Your shopping list is empty',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add items manually or generate from your meal plan',
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: groupedItems.length,
                          itemBuilder: (context, index) {
                            final category = groupedItems.keys.elementAt(index);
                            final items = groupedItems[category]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category header
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    category,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                // Category items
                                ...items.map((item) {
                                  final isChecked = _checkedItems[item['name']] ?? false;
                                  
                                  return ListTile(
                                    leading: Checkbox(
                                      value: isChecked,
                                      onChanged: (_) => _toggleItemCheck(item['name']),
                                    ),
                                    title: Text(
                                      item['name'],
                                      style: TextStyle(
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                        color: isChecked ? Colors.grey : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item['quantity']} ${item['unit']}',
                                      style: TextStyle(
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                        color: isChecked ? Colors.grey : null,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_shopping_cart),
                                      onPressed: () => _addToInventory(item),
                                    ),
                                  );
                                }).toList(),
                                
                                const Divider(),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Clear checked items
          setState(() {
            _checkedItems.clear();
          });
        },
        icon: const Icon(Icons.cleaning_services),
        label: const Text('Clear Checked'),
      ),
    );
  }
}

