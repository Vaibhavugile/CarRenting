
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../business/business_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  bool _loading = false;

  bool _resetLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final UserModel user =
          await AuthService.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // CHECK BUSINESS SETUP
      //
      // User is registered but may not have created their
      // business/branch yet.
      // ----------------------------------------------------------

      final hasBusiness =
          user.businessId != null &&
          user.businessId!.isNotEmpty &&
          user.branchId != null &&
          user.branchId!.isNotEmpty &&
          user.branchCode != null &&
          user.branchCode!.isNotEmpty;

      if (hasBusiness) {
        _openDashboard();
      } else {
        _openBusinessSetup();
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        _getErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN BUSINESS SETUP
  // ============================================================

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
            const Duration(
          milliseconds: 350,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN DASHBOARD
  // ============================================================

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

        transitionDuration:
            const Duration(
          milliseconds: 350,
        ),
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    final email =
        _emailController.text.trim();

    if (email.isEmpty) {
      _showError(
        'Enter your email address first.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showError(
        'Please enter a valid email address.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _resetLoading = true;
    });

    try {
      await AuthService.instance
          .sendPasswordResetEmail(
        email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              AppColors.success,

          behavior:
              SnackBarBehavior.floating,

          margin:
              const EdgeInsets.all(
            AppSpacing.lg,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              AppRadius.md,
            ),
          ),

          content: const Row(
            children: [
              Icon(
                Icons
                    .mark_email_read_outlined,
                color: Colors.white,
              ),

              SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: Text(
                  'Password reset email sent. Check your inbox.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _getErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resetLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.contains(
      'invalid-credential',
    )) {
      return 'Incorrect email or password.';
    }

    if (message.contains(
      'user-not-found',
    )) {
      return 'No account found with this email.';
    }

    if (message.contains(
      'wrong-password',
    )) {
      return 'Incorrect password.';
    }

    if (message.contains(
      'invalid-email',
    )) {
      return 'Please enter a valid email address.';
    }

    if (message.contains(
      'user-disabled',
    )) {
      return 'This account has been disabled.';
    }

    if (message.contains(
      'network-request-failed',
    )) {
      return 'Please check your internet connection.';
    }

    if (message.contains(
      'profile-not-found',
    )) {
      return 'Your account profile could not be found.';
    }

    if (message.contains(
      'account-disabled',
    )) {
      return 'Your account has been disabled.';
    }

    return 'Unable to sign in. Please try again.';
  }

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            AppColors.danger,

        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
        ),

        content: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Text(
                message,

                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),

            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 480,
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    // ==================================================
                    // BRAND
                    // ==================================================

                    Container(
                      width: 58,
                      height: 58,

                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primary,

                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius.lg,
                        ),

                        boxShadow:
                            AppShadows.card,
                      ),

                      child: const Icon(
                        Icons
                            .directions_car_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.xxxl,
                    ),

                    // ==================================================
                    // HEADER
                    // ==================================================

                    Text(
                      'Welcome back',

                      style:
                          Theme.of(context)
                              .textTheme
                              .headlineLarge,
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.sm,
                    ),

                    Text(
                      'Sign in to manage your rental business.',

                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyMedium,
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.xxxl,
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    Text(
                      'Email address',

                      style:
                          Theme.of(context)
                              .textTheme
                              .labelLarge,
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.sm,
                    ),

                    TextFormField(
                      controller:
                          _emailController,

                      keyboardType:
                          TextInputType
                              .emailAddress,

                      textInputAction:
                          TextInputAction.next,

                      autofillHints: const [
                        AutofillHints.email,
                      ],

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Enter your email',

                        prefixIcon:
                            Icon(
                          Icons
                              .email_outlined,
                        ),
                      ),

                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .trim()
                                .isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!value
                            .contains(
                          '@',
                        )) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.lg,
                    ),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    Text(
                      'Password',

                      style:
                          Theme.of(context)
                              .textTheme
                              .labelLarge,
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.sm,
                    ),

                    TextFormField(
                      controller:
                          _passwordController,

                      obscureText:
                          _obscurePassword,

                      textInputAction:
                          TextInputAction.done,

                      autofillHints: const [
                        AutofillHints.password,
                      ],

                      onFieldSubmitted:
                          (_) {
                        if (!_loading) {
                          _login();
                        }
                      },

                      decoration:
                          InputDecoration(
                        hintText:
                            'Enter your password',

                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_outline_rounded,
                        ),

                        suffixIcon:
                            IconButton(
                          onPressed:
                              _loading
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        },
                                      );
                                    },

                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                      ),

                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value
                                .isEmpty) {
                          return 'Please enter your password';
                        }

                        if (value.length <
                            6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.md,
                    ),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment:
                          Alignment
                              .centerRight,

                      child:
                          TextButton(
                        onPressed:
                            _loading ||
                                    _resetLoading
                                ? null
                                : _forgotPassword,

                        child:
                            _resetLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    'Forgot password?',
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.lg,
                    ),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width:
                          double.infinity,

                      child:
                          ElevatedButton(
                        onPressed:
                            _loading
                                ? null
                                : _login,

                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: [
                                  Text(
                                    'Sign In',
                                  ),

                                  SizedBox(
                                    width: 8,
                                  ),

                                  Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.xl,
                    ),

                    // ==================================================
                    // REGISTER
                    // ==================================================

                    Center(
                      child:
                          RichText(
                        text:
                            TextSpan(
                          style:
                              Theme.of(
                            context,
                          )
                                      .textTheme
                                      .bodyMedium,

                          children: [
                            const TextSpan(
                              text:
                                  "Don't have an account? ",
                            ),

                            WidgetSpan(
                              alignment:
                                  PlaceholderAlignment
                                      .middle,

                              child:
                                  GestureDetector(
                                onTap:
                                    _loading
                                        ? null
                                        : () {
                                            Navigator.of(
                                              context,
                                            ).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const RegisterScreen(),
                                              ),
                                            );
                                          },

                                child:
                                    const Text(
                                  'Create account',

                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.accent,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height:
                          AppSpacing.xxxl,
                    ),

                    // ==================================================
                    // SECURITY
                    // ==================================================

                    Center(
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          const Icon(
                            Icons
                                .verified_user_outlined,
                            size: 16,
                            color:
                                AppColors.textMuted,
                          ),

                          const SizedBox(
                            width:
                                AppSpacing.xs,
                          ),

                          Text(
                            'Your data is securely protected',

                            style:
                                Theme.of(
                              context,
                            )
                                        .textTheme
                                        .bodySmall,
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
      ),
    );
  }
}

