
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/business_service.dart';
import '../business/business_setup_screen.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;

  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    _checkAuthentication();
  }

 Future<void> _checkAuthentication() async {
  await Future.delayed(
    const Duration(milliseconds: 1800),
  );

  if (!mounted) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _openLogin();
    return;
  }

  try {
    final business =
        await BusinessService.instance
            .getCurrentBusiness();

    if (!mounted) return;

    if (business == null) {
      _openBusinessSetup();
    } else {
      _openDashboard();
    }
  } catch (e) {
    if (!mounted) return;

    _openBusinessSetup();
  }
}
void _openBusinessSetup() {
  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return const BusinessSetupScreen();
      },
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration:
          const Duration(milliseconds: 400),
    ),
  );
}

  void _openLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LoginScreen();
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 400,
        ),
      ),
    );
  }

  void _openDashboard() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const DashboardScreen();
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(
          milliseconds: 400,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,

            child: ScaleTransition(
              scale: _scaleAnimation,

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  // ------------------------------------------------
                  // LOGO
                  // ------------------------------------------------

                  Container(
                    width: 92,
                    height: 92,

                    decoration: BoxDecoration(
                      color: AppColors.primary,

                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.xl,
                      ),

                      boxShadow:
                          AppShadows.floating,
                    ),

                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(
                    height: AppSpacing.xxl,
                  ),

                  // ------------------------------------------------
                  // APP NAME
                  // ------------------------------------------------

                  Text(
                    'Car Rental',

                    style: Theme.of(context)
                        .textTheme
                        .displaySmall,
                  ),

                  const SizedBox(
                    height: AppSpacing.sm,
                  ),

                  Text(
                    'Rental business management,\nsimplified.',

                    textAlign: TextAlign.center,

                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),

                  const SizedBox(
                    height: AppSpacing.huge,
                  ),

                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  const SizedBox(
                    width: 22,
                    height: 22,

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accent,
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
}
