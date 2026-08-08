
import 'package:flutter/material.dart';

import '../screens/splash/splash_screen.dart';
import 'theme.dart';

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Car Rental',

      theme: AppTheme.light,

      themeMode: ThemeMode.light,

      home: const SplashScreen(),
    );
  }
}

