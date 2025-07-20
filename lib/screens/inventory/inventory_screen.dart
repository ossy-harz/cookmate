import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_item_model.dart';
import '../../widgets/glass_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Dairy',
    'Meat & Seafood',
    'Fruits',
    'Vegetables',
    'Grains & Bakery',
    'Condiments & Spices',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
              title: const Text('Pantry'),
              floating: true,
              pinned: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // Navigate to shopping list
                    Navigator.pushNamed(context, '/shopping-list');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddItemDialog(context);
                  },
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
                          hintText: 'Search pantry...',
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

            return TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildInventoryList(context, userData.uid, category);
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddItemDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context, String userId, String category) {
    final inventoryService = Provider.of<InventoryService>(context);
    final theme = Theme.of(context);

    return StreamBuilder<List<InventoryItemModel>>(
      stream: category == 'All'
          ? inventoryService.getUserInventory(userId)
          : inventoryService.getInventoryByCategory(userId, category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var inventoryItems = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          inventoryItems = inventoryItems.where((item) {
            return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (inventoryItems.isEmpty) {
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
                    Icons.inventory_2,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  category == 'All'
                      ? 'Your pantry is empty'
                      : 'No $category items in your pantry',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddItemDialog(context, initialCategory: category == 'All' ? null : category);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inventoryItems.length,
          itemBuilder: (context, index) {
            final item = inventoryItems[index];
            return _buildInventoryItemCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildInventoryItemCard(BuildContext context, InventoryItemModel item) {
    final theme = Theme.of(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);

    // Calculate days until expiry
    final daysUntilExpiry = item.expiryDate != null
        ? item.expiryDate!.difference(DateTime.now()).inDays
        : null;

    // Determine if item is expiring soon
    final isExpiringSoon = daysUntilExpiry != null && daysUntilExpiry <= 3;

    Color statusColor;
    if (daysUntilExpiry != null) {
      if (daysUntilExpiry <= 0) {
        statusColor = theme.colorScheme.error;
      } else if (daysUntilExpiry <= 3) {
        statusColor = theme.colorScheme.secondary;
      } else {
        statusColor = theme.colorScheme.primary;
      }
    } else {
      statusColor = theme.colorScheme.primary;
    }

    return Dismissible(
      key: Key(item.id),
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
              content: Text('Are you sure you want to delete ${item.name}?'),
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
      onDismissed: (direction) {
        inventoryService.deleteInventoryItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Re-add the item
                inventoryService.addInventoryItem(item);
              },
            ),
          ),
        );
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
            _showEditItemDialog(context, item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (item.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: isExpiringSoon ? statusColor : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expires: ${DateFormat('MMM d, yyyy').format(item.expiryDate!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isExpiringSoon ? statusColor : theme.colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: isExpiringSoon ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Quantity Controls
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      onPressed: () {
                        inventoryService.updateItemQuantity(item.id, item.quantity + 1);
                      },
                    ),
                    Text(
                      '${item.quantity.toInt()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: item.quantity > 1 ? theme.colorScheme.primary : Colors.grey,
                        size: 28,
                      ),
                      onPressed: item.quantity > 1
                          ? () {
                        inventoryService.updateItemQuantity(item.id, item.quantity - 1);
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Dairy':
        return Icons.egg_alt;
      case 'Meat & Seafood':
        return Icons.restaurant;
      case 'Fruits':
        return Icons.apple;
      case 'Vegetables':
        return Icons.eco;
      case 'Grains & Bakery':
        return Icons.bakery_dining;
      case 'Condiments & Spices':
        return Icons.spa;
      default:
        return Icons.kitchen;
    }
  }

  void _showAddItemDialog(BuildContext context, {String? initialCategory}) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    String selectedCategory = initialCategory ?? 'Other';
    String selectedUnit = 'pcs';
    DateTime? expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Pantry Item',
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
                              // Name Field
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Item Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an item name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Category Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categories
                                    .where((category) => category != 'All')
                                    .map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Quantity and Unit Row
                              Row(
                                children: [
                                  // Quantity Field
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: quantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Unit Dropdown
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedUnit,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                                        DropdownMenuItem(value: 'g', child: Text('g')),
                                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                                        DropdownMenuItem(value: 'L', child: Text('L')),
                                        DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                                        DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedUnit = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Expiry Date Picker
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Expiry Date',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            expiryDate != null
                                                ? DateFormat('MMM d, yyyy').format(expiryDate!)
                                                : 'No expiry date set',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ),
                                        if (expiryDate != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                expiryDate = null;
                                              });
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.calendar_today),
                                          onPressed: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                            );

                                            if (pickedDate != null) {
                                              setState(() {
                                                expiryDate = pickedDate;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notes Field
                              TextFormField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final inventoryService = Provider.of<InventoryService>(
                                  context,
                                  listen: false,
                                );

                                final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );

                                final userData = await authService.getUserData();

                                if (userData != null) {
                                  final newItem = InventoryItemModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: nameController.text,
                                    category: selectedCategory,
                                    quantity: double.parse(quantityController.text),
                                    unit: selectedUnit,
                                    expiryDate: expiryDate,
                                    purchaseDate: DateTime.now(),
                                    notes: notesController.text.isEmpty ? null : notesController.text,
                                    userId: userData.uid,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  await inventoryService.addInventoryItem(newItem);
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${newItem.name} added to pantry'),
                                      backgroundColor: theme.colorScheme.primary,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Add Item'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(BuildContext context, InventoryItemModel item) {
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final notesController = TextEditingController(text: item.notes ?? '');

    String selectedCategory = item.category;
    String selectedUnit = item.unit;
    DateTime? expiryDate = item.expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Pantry Item',
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
                              // Name Field
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Item Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an item name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Category Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: _categories
                                    .where((category) => category != 'All')
                                    .map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Quantity and Unit Row
                              Row(
                                children: [
                                  // Quantity Field
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: quantityController,
                                      decoration: const InputDecoration(
                                        labelText: 'Quantity',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Unit Dropdown
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedUnit,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                                        DropdownMenuItem(value: 'g', child: Text('g')),
                                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                                        DropdownMenuItem(value: 'L', child: Text('L')),
                                        DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                                        DropdownMenuItem(value: 'tsp', child: Text('tsp')),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedUnit = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Expiry Date Picker
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Expiry Date',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            expiryDate != null
                                                ? DateFormat('MMM d, yyyy').format(expiryDate!)
                                                : 'No expiry date set',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ),
                                        if (expiryDate != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                expiryDate = null;
                                              });
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.calendar_today),
                                          onPressed: () async {
                                            final pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                            );

                                            if (pickedDate != null) {
                                              setState(() {
                                                expiryDate = pickedDate;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notes Field
                              TextFormField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Action Buttons
                        Row(
                          children: [
                            // Delete Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showDeleteConfirmation(context, item);
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(color: theme.colorScheme.error),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Update Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    final inventoryService = Provider.of<InventoryService>(
                                      context,
                                      listen: false,
                                    );

                                    final updatedItem = InventoryItemModel(
                                      id: item.id,
                                      name: nameController.text,
                                      category: selectedCategory,
                                      quantity: double.parse(quantityController.text),
                                      unit: selectedUnit,
                                      expiryDate: expiryDate,
                                      purchaseDate: item.purchaseDate,
                                      notes: notesController.text.isEmpty ? null : notesController.text,
                                      userId: item.userId,
                                      createdAt: item.createdAt,
                                      updatedAt: DateTime.now(),
                                    );

                                    inventoryService.updateInventoryItem(updatedItem);
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${updatedItem.name} updated'),
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Update Item'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, InventoryItemModel item) {
    final theme = Theme.of(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                inventoryService.deleteInventoryItem(item.id);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        inventoryService.addInventoryItem(item);
                      },
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
