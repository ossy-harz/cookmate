import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _selectedLanguage = 'English';
  
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Japanese',
    'Chinese',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    // In a real app, these would be loaded from shared preferences or user settings
    setState(() {
      _darkMode = Theme.of(context).brightness == Brightness.dark;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Settings
                Text(
                  'Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        subtitle: Text(userData?.displayName ?? 'Not set'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(userData?.email ?? 'Not set'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to email settings
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.password),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to change password
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Settings
                Text(
                  'App Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Enable dark theme'),
                        secondary: const Icon(Icons.dark_mode),
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                          // In a real app, this would update the theme
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Notifications'),
                        subtitle: const Text('Enable push notifications'),
                        secondary: const Icon(Icons.notifications),
                        value: _notifications,
                        onChanged: (value) {
                          setState(() {
                            _notifications = value;
                          });
                          // In a real app, this would update notification settings
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        subtitle: Text(_selectedLanguage),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showLanguageDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Data Management
                Text(
                  'Data Management',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup),
                        title: const Text('Backup Data'),
                        subtitle: const Text('Backup your recipes and meal plans'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Backup data
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.restore),
                        title: const Text('Restore Data'),
                        subtitle: const Text('Restore from a backup'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Restore data
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
                        subtitle: const Text('Delete all your data from the app'),
                        onTap: () {
                          _showClearDataConfirmation(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // About
                Text(
                  'About',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Show terms of service
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Show privacy policy
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await authService.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _languages.map((language) {
                return RadioListTile<String>(
                  title: Text(language),
                  value: language,
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  void _showClearDataConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'This will permanently delete all your recipes, meal plans, and inventory data. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Clear all data
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been cleared'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }
}

