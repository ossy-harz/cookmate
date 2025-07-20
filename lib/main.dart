import 'package:cookmate/services/ai_service.dart';
import 'package:cookmate/services/auth_service.dart';
import 'package:cookmate/services/inventory_service.dart';
import 'package:cookmate/services/meal_plan_service.dart';
import 'package:cookmate/services/recipe_service.dart';
import 'package:cookmate/services/social_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RecipeService()),
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => MealPlanService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => SocialService()),
      ],
      child: const CookMateApp(),
    ),
  );
}

