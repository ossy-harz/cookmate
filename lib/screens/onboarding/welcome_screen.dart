import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome_background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0x66000000),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and app name
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CookMate',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Personal Kitchen Assistant',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Features list
                  GlassCard(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          context,
                          Icons.restaurant,
                          'Personalized Meal Planning',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          context,
                          Icons.auto_awesome,
                          'AI-Driven Recipe Generation',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          context,
                          Icons.inventory_2,
                          'Inventory Tracking',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          context,
                          Icons.shopping_cart,
                          'Smart Grocery Management',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Login and register buttons
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _signInWithGoogle(context);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: ${e.toString()}')),
      );
    }
  }
}

