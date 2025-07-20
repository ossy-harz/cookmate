import 'package:flutter/material.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/login_screen.dart';
import 'screens/onboarding/register_screen.dart';
import 'screens/onboarding/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/recipes/recipes_screen.dart';
import 'screens/recipe_details/recipe_details_screen.dart';
import 'screens/recipe_edit/recipe_edit_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/meal_planner/meal_planner_screen.dart';
import 'screens/shopping_list/shopping_list_screen.dart';
import 'screens/ai_recipe/ai_recipe_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/social/social_feed_screen.dart';
import 'screens/social/create_post_screen.dart';
import 'screens/social/post_details_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) {
      // Check authentication status and return appropriate screen
      final authService = Provider.of<AuthService>(context, listen: false);
      return StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          return const WelcomeScreen();
        },
      );
    },
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
    '/home': (context) => const HomeScreen(),
    '/dashboard': (context) => const DashboardScreen(),
    '/recipes': (context) => const RecipesScreen(),
    '/inventory': (context) => const InventoryScreen(),
    '/meal-planner': (context) => const MealPlannerScreen(),
    '/shopping-list': (context) => const ShoppingListScreen(),
    '/ai-recipe': (context) => const AIRecipeScreen(),
    '/analytics': (context) => const AnalyticsScreen(),
    '/profile': (context) => const ProfileScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/add-recipe': (context) => const RecipeEditScreen(),
    '/social': (context) => const SocialFeedScreen(),
    '/create-post': (context) => const CreatePostScreen(),
    '/notifications': (context) => const NotificationsScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/recipe-details') {
      final args = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(recipeId: args),
      );
    }

    if (settings.name == '/edit-recipe') {
      final args = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => RecipeEditScreen(recipeId: args),
      );
    }

    if (settings.name == '/post-details') {
      final args = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => PostDetailsScreen(postId: args),
      );
    }

    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(
          child: Text('Route not found'),
        ),
      ),
    );
  }
}
