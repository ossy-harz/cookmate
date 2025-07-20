import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  List<String> _selectedDietaryPreferences = [];
  List<String> _selectedAllergies = [];
  List<String> _selectedHealthGoals = [];

  final List<String> _dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'High-Protein',
  ];

  final List<String> _allergies = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Soy',
    'Wheat',
  ];

  final List<String> _healthGoals = [
    'Weight Loss',
    'Weight Gain',
    'Muscle Building',
    'Maintenance',
    'Heart Health',
    'Diabetes Management',
    'Energy Boost',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserData();

    if (userData != null) {
      setState(() {
        _nameController.text = userData.displayName ?? '';

        // In a real app, these would be loaded from user preferences in Firestore
        _selectedDietaryPreferences = ['Vegetarian', 'High-Protein'];
        _selectedAllergies = ['Peanuts'];
        _selectedHealthGoals = ['Weight Loss', 'Energy Boost'];
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        await authService.updateProfile(
          name: _nameController.text,
          // In a real app, these would be saved to user preferences in Firestore
          preferences: {
            'dietaryPreferences': _selectedDietaryPreferences,
            'allergies': _selectedAllergies,
            'healthGoals': _selectedHealthGoals,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
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
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'U',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Dietary Preferences
              Text(
                'Dietary Preferences',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dietaryPreferences.map((preference) {
                    final isSelected = _selectedDietaryPreferences.contains(preference);

                    return FilterChip(
                      label: Text(preference),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDietaryPreferences.add(preference);
                          } else {
                            _selectedDietaryPreferences.remove(preference);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Allergies
              Text(
                'Allergies',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allergies.map((allergy) {
                    final isSelected = _selectedAllergies.contains(allergy);

                    return FilterChip(
                      label: Text(allergy),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.error.withOpacity(0.2),
                      checkmarkColor: theme.colorScheme.error,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.error : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAllergies.add(allergy);
                          } else {
                            _selectedAllergies.remove(allergy);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Health Goals
              Text(
                'Health Goals',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _healthGoals.map((goal) {
                    final isSelected = _selectedHealthGoals.contains(goal);

                    return FilterChip(
                      label: Text(goal),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.secondary.withOpacity(0.2),
                      checkmarkColor: theme.colorScheme.secondary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedHealthGoals.add(goal);
                          } else {
                            _selectedHealthGoals.remove(goal);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Save Profile'),
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await authService.signOut();
                      // Navigate to welcome screen after sign out
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
