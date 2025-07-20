import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';
import 'routes.dart';

class CookMateApp extends StatelessWidget {
  const CookMateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CookMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Remove the home property and use initialRoute instead
      initialRoute: '/',
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

